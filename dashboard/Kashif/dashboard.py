"""MySQL-backed visualizations for Kashif's Q26 and Q28 analytical queries.

SQL statements are copied exactly from Kashif_advanced.sql.
Q26 relies on a VIEW which must be created once in MySQL before running its SELECT.
"""

import math

import altair as alt
import pandas as pd
import pymysql
import streamlit as st

from db import query


# Q26 requires this view in the amazon_ecommerce database. Run it once in
# MySQL Workbench; do not execute schema-changing SQL in the read-only db.query().
Q26_VIEW_SQL = """
CREATE OR REPLACE VIEW vw_kashif_home_region_shipping AS
SELECT r.region_name AS customer_home_region,
       COUNT(*) AS shipped_purchase_lines,
       COUNT(DISTINCT c.response_id) AS customers_with_shipped_lines,
       SUM(CASE
           WHEN pl.ship_state_code <> c.state_code THEN 1
           ELSE 0
       END) AS out_of_state_lines,
       SUM(pl.unit_price * pl.quantity) AS shipped_spend,
       SUM(CASE
           WHEN pl.ship_state_code <> c.state_code
               THEN pl.unit_price * pl.quantity
           ELSE 0
       END) AS out_of_state_spend
FROM customer c
JOIN state s
    ON s.state_code = c.state_code
JOIN census_division d
    ON d.division_id = s.division_id
JOIN census_region r
    ON r.region_id = d.region_id
JOIN purchase_line pl
    ON pl.response_id = c.response_id
WHERE pl.order_date BETWEEN '2018-01-01' AND '2022-10-31'
  AND pl.ship_state_code IS NOT NULL
GROUP BY r.region_name;
"""


# The exact Q26 SELECT after the CREATE VIEW statement in Kashif_advanced.sql.
OUT_OF_STATE_SQL = """
SELECT customer_home_region,
       customers_with_shipped_lines,
       shipped_purchase_lines,
       out_of_state_lines,
       ROUND(100.0 * out_of_state_lines / shipped_purchase_lines, 1)
           AS out_of_state_lines_pct,
       ROUND(shipped_spend, 2) AS shipped_spend_usd,
       CASE
           WHEN shipped_spend = 0 THEN NULL
           ELSE ROUND(100.0 * out_of_state_spend / shipped_spend, 1)
       END AS out_of_state_spend_pct
FROM vw_kashif_home_region_shipping
ORDER BY out_of_state_lines_pct DESC, customer_home_region;
"""


# The exact Q28 SELECT (including CTEs and DENSE_RANK()) in Kashif_advanced.sql.
MULTISTATE_SQL = """
WITH shipping_breadth AS (
    SELECT c.response_id,
           r.region_name AS customer_home_region,
           COUNT(DISTINCT pl.ship_state_code) AS distinct_ship_state_codes
    FROM customer c
    JOIN state s
        ON s.state_code = c.state_code
    JOIN census_division d
        ON d.division_id = s.division_id
    JOIN census_region r
        ON r.region_id = d.region_id
    JOIN purchase_line pl
        ON pl.response_id = c.response_id
    WHERE pl.order_date BETWEEN '2018-01-01' AND '2022-10-31'
      AND pl.ship_state_code IS NOT NULL
    GROUP BY c.response_id, r.region_name
),
region_shipping_metrics AS (
    SELECT customer_home_region,
           COUNT(*) AS customers_with_shipping_addresses,
           SUM(CASE
               WHEN distinct_ship_state_codes >= 2 THEN 1
               ELSE 0
           END) AS multi_state_shipping_customers,
           100.0 * AVG(CASE
               WHEN distinct_ship_state_codes >= 2 THEN 1
               ELSE 0
           END) AS multi_state_shipping_customer_pct,
           AVG(distinct_ship_state_codes) AS avg_shipping_state_codes_per_customer
    FROM shipping_breadth
    GROUP BY customer_home_region
)
SELECT DENSE_RANK() OVER (
           ORDER BY multi_state_shipping_customer_pct DESC
       ) AS region_rank,
       customer_home_region,
       customers_with_shipping_addresses,
       multi_state_shipping_customers,
       ROUND(multi_state_shipping_customer_pct, 1)
           AS multi_state_shipping_customer_pct,
       ROUND(avg_shipping_state_codes_per_customer, 2)
           AS avg_shipping_state_codes_per_customer
FROM region_shipping_metrics
ORDER BY region_rank, customer_home_region;
"""


def _numbers(frame: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    """Convert DECIMAL values from PyMySQL into numbers for Altair."""
    frame = frame.copy()
    for col in columns:
        if col in frame.columns:
            frame[col] = pd.to_numeric(frame[col], errors='coerce')
    return frame


def _regional_percentage_chart(
    frame: pd.DataFrame,
    percentage_column: str,
    y_title: str,
    tooltip: list,
) -> alt.Chart:
    """Vertical bar chart: home region on X, percentage on Y; preserve SQL order."""
    data = frame.dropna(subset=[percentage_column]).copy()
    if data.empty:
        return alt.Chart(pd.DataFrame({'message': []})).mark_bar()

    data['percent_label'] = data[percentage_column].map(
        lambda value: f'{value:.1f}%')
    sorted_regions = data['customer_home_region'].tolist()

    # A 0-100% scale makes observed values around 7-11% unnecessarily small.
    # Retain the honest zero baseline and choose a round upper limit with headroom.
    # SQL percentages are already expressed on a 0-100 scale (not 0-1).
    highest_pct = max(0.0, float(data[percentage_column].max()))
    y_max = min(100, max(5, 5 * math.ceil(highest_pct * 1.2 / 5)))
    tick_step = 1 if y_max <= 5 else 2 if y_max <= 10 else (
        5 if y_max <= 25 else 10 if y_max <= 50 else 20
    )

    base = alt.Chart(data).encode(
        x=alt.X(
            'customer_home_region:N',
            sort=sorted_regions,
            axis=alt.Axis(
                title='Customer home Census region',
                labelAngle=0,
                labelLimit=160,
            ),
        ),
        y=alt.Y(
            f'{percentage_column}:Q',
            scale=alt.Scale(domain=[0, y_max], nice=False, zero=True),
            axis=alt.Axis(
                title=y_title,
                values=list(range(0, y_max + 1, tick_step)),
                labelExpr="datum.value + '%'",
            ),
        ),
        tooltip=tooltip,
    )
    bars = base.mark_bar(size=48, cornerRadiusTopLeft=3,
                         cornerRadiusTopRight=3)
    # Place labels inside the pale-blue bars so they remain legible in both
    # Streamlit light and dark themes (black labels above bars were hard to see).
    labels = base.mark_text(
        align='center', baseline='top', dy=7,
        color='#14283d', fontWeight='bold', fontSize=13,
    ).encode(text=alt.Text('percent_label:N'))
    return (bars + labels).properties(height=355)


def render() -> None:
    """Render Kashif's two SQL-based visualizations."""
    st.header('Regional shipping patterns')
    st.caption(
        'Data covers January 2018 through October 2022. Customer home region '
        'uses surveyed current residence, not necessarily residence at the time '
        'of purchase. Customers without a known U.S. home Census region and '
        'purchase lines without a shipping state are excluded.'
    )
    st.caption(
        'Percentage chart axes start at 0% and adjust their upper limit to '
        'the displayed values, rather than always extending to 100%.'
    )

    st.subheader('Q26 · Out-of-state shipment lines by customer home region')
    st.caption(
        'Percentage of shipped purchase lines sent outside the customer’s '
        'current home state (not the percentage of customers).'
    )

    # Q26's SELECT depends on a database VIEW created by its separate exact SQL.
    with st.expander('Q26 database setup · create the required view once'):
        st.write(
            'Before running Q26 for the first time, execute this exact '
            '`CREATE OR REPLACE VIEW` statement from `Kashif_advanced.sql` '
            'in MySQL Workbench using the `amazon_ecommerce` database.'
        )
        st.code(Q26_VIEW_SQL.strip(), language='sql')

    view_missing = False
    try:
        shipping = query(OUT_OF_STATE_SQL)
    except (pymysql.err.ProgrammingError, pymysql.err.OperationalError) as exc:
        # A missing (or invalid) view requires the one-time setup above.
        if exc.args and exc.args[0] in (1146, 1356):
            st.warning(
                'Q26 cannot load until `vw_kashif_home_region_shipping` '
                'has been created and is valid. See the setup instructions above.'
            )
            shipping = pd.DataFrame()
            view_missing = True
        else:
            raise

    if not shipping.empty:
        shipping = _numbers(
            shipping,
            [
                'customers_with_shipped_lines',
                'shipped_purchase_lines',
                'out_of_state_lines',
                'out_of_state_lines_pct',
                'shipped_spend_usd',
                'out_of_state_spend_pct',
            ],
        )
        metric = st.radio(
            'Q26 percentage measure',
            options=['Shipped lines (%)', 'Shipped spending (%)'],
            horizontal=True,
            key='kashif_q26_measure',
        )
        if metric == 'Shipped lines (%)':
            col = 'out_of_state_lines_pct'
            ylabel = 'Out-of-state lines (%)'
        else:
            col = 'out_of_state_spend_pct'
            ylabel = 'Out-of-state spending (%)'
            st.caption(
                'This optional measure is the share of shipped spending sent '
                'outside the customer’s current home state, not the share of lines.'
            )

        q26_tooltip = [
            alt.Tooltip('customer_home_region:N', title='Home region'),
            alt.Tooltip('customers_with_shipped_lines:Q',
                        title='Customers', format=','),
            alt.Tooltip('shipped_purchase_lines:Q',
                        title='Shipped lines', format=','),
            alt.Tooltip('out_of_state_lines:Q',
                        title='Out-of-state lines', format=','),
            alt.Tooltip('out_of_state_lines_pct:Q',
                        title='Out-of-state lines (%)', format='.1f'),
            alt.Tooltip('shipped_spend_usd:Q',
                        title='Shipped spend (USD)', format='$,.2f'),
            alt.Tooltip('out_of_state_spend_pct:Q',
                        title='Out-of-state spend (%)', format='.1f'),
        ]
        st.altair_chart(
            _regional_percentage_chart(shipping, col, ylabel, q26_tooltip),
            use_container_width=True,
        )
        with st.expander('Full Q26 query results'):
            st.dataframe(shipping, hide_index=True, use_container_width=True)
    elif not view_missing:
        st.info('Q26 returned no rows for the selected analysis period.')

    st.subheader('Q28 · Customers shipping to multiple states by home region')
    st.caption(
        'Percentage of customers with shipped purchases who used at least '
        'two distinct state/territory codes. Regions are ordered by the SQL '
        '`DENSE_RANK()` result (ties share the same rank).'
    )

    multistate = query(MULTISTATE_SQL)
    if multistate.empty:
        st.warning('Q28 returned no shipping-breadth data for this period.')
    else:
        multistate = _numbers(
            multistate,
            [
                'region_rank',
                'customers_with_shipping_addresses',
                'multi_state_shipping_customers',
                'multi_state_shipping_customer_pct',
                'avg_shipping_state_codes_per_customer',
            ],
        )
        q28_tooltip = [
            alt.Tooltip('customer_home_region:N', title='Home region'),
            alt.Tooltip('region_rank:Q', title='Regional rank', format='.0f'),
            alt.Tooltip('customers_with_shipping_addresses:Q',
                        title='Customers with shipped purchases', format=','),
            alt.Tooltip('multi_state_shipping_customers:Q',
                        title='Multi-state customers', format=','),
            alt.Tooltip('multi_state_shipping_customer_pct:Q',
                        title='Multi-state customers (%)', format='.1f'),
            alt.Tooltip('avg_shipping_state_codes_per_customer:Q',
                        title='Avg. shipping state codes', format='.2f'),
        ]
        st.altair_chart(
            _regional_percentage_chart(
                multistate,
                'multi_state_shipping_customer_pct',
                'Multi-state customers (%)',
                q28_tooltip,
            ),
            use_container_width=True,
        )
        with st.expander('Full Q28 query results'):
            st.dataframe(multistate, hide_index=True, use_container_width=True)
