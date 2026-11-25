"""MySQL-backed dashboard visualizations for analytical queries Q18 and Q19."""

import altair as alt
import pandas as pd
import streamlit as st

from db import query


# Keep these SQL statements identical to Q18 and Q19 in 06_analytical_queries.sql.
SPENDING_SQL = """
WITH age_year_spend AS (
    SELECT COALESCE(c.age_group, 'Unknown') AS age_group,
           YEAR(pl.order_date) AS order_year,
           COUNT(DISTINCT c.response_id) AS purchasing_customers,
           SUM(pl.unit_price * pl.quantity) AS total_spend,
           SUM(pl.unit_price * pl.quantity) /
               COUNT(DISTINCT c.response_id) AS spend_per_customer
    FROM customer c
    JOIN purchase_line pl
        ON pl.response_id = c.response_id
    WHERE pl.order_date BETWEEN '2018-01-01' AND '2021-12-31'
    GROUP BY COALESCE(c.age_group, 'Unknown'),
             YEAR(pl.order_date)
),
spending_trends AS (
    SELECT age_group,
           order_year,
           purchasing_customers,
           total_spend,
           spend_per_customer,
           LAG(order_year) OVER (
               PARTITION BY age_group
               ORDER BY order_year
           ) AS previous_year,
           LAG(spend_per_customer) OVER (
               PARTITION BY age_group
               ORDER BY order_year
           ) AS previous_year_spend_per_customer
    FROM age_year_spend
)
SELECT age_group,
       order_year,
       purchasing_customers,
       ROUND(total_spend, 2) AS total_spend_usd,
       ROUND(spend_per_customer, 2) AS spend_per_customer_usd,
       CASE
           WHEN previous_year = order_year - 1
               THEN ROUND(previous_year_spend_per_customer, 2)
           ELSE NULL
       END AS previous_year_spend_per_customer_usd,
       CASE
           WHEN previous_year = order_year - 1
                AND previous_year_spend_per_customer IS NOT NULL
                AND previous_year_spend_per_customer <> 0
           THEN ROUND(
               100 * (spend_per_customer -
                      previous_year_spend_per_customer)
                   / previous_year_spend_per_customer, 1
           )
           ELSE NULL
       END AS yoy_spending_change_pct
FROM spending_trends
ORDER BY age_group, order_year;
"""

RETENTION_SQL = """
WITH yearly_buyers AS (
    SELECT DISTINCT
           pl.response_id,
           COALESCE(c.age_group, 'Unknown') AS age_group,
           YEAR(pl.order_date) AS order_year
    FROM purchase_line pl
    JOIN customer c
        ON c.response_id = pl.response_id
    WHERE pl.order_date BETWEEN '2018-01-01' AND '2021-12-31'
),

retention_flags AS (
    SELECT y.response_id,
           y.age_group,
           y.order_year,
           CASE
               WHEN EXISTS (
                   SELECT 1
                   FROM yearly_buyers next_year
                   WHERE next_year.response_id = y.response_id
                     AND next_year.order_year = y.order_year + 1
               ) THEN 1
               ELSE 0
           END AS returned_next_year
    FROM yearly_buyers y
    WHERE y.order_year BETWEEN 2018 AND 2020
)

SELECT order_year,
       order_year + 1 AS following_year,
       age_group,
       COUNT(*) AS purchasing_customers,
       SUM(returned_next_year) AS returning_customers,
       ROUND(100.0 * SUM(returned_next_year) / COUNT(*), 1)
           AS retention_rate_pct
FROM retention_flags
GROUP BY order_year, age_group
ORDER BY order_year, age_group;
"""

AGE_ORDER = [
    '18 - 24 years',
    '25 - 34 years',
    '35 - 44 years',
    '45 - 54 years',
    '55 - 64 years',
    '65 and older',
]


def _number_columns(df, columns):
    df = df.copy()
    for column in columns:
        df[column] = pd.to_numeric(df[column], errors='coerce')
    return df


def _year_label(series):
    return pd.to_numeric(series, errors='coerce').astype('Int64').astype(str)


def _age_color():
    return alt.Color('age_group:N', title='Age group', sort=AGE_ORDER)


def render():
    st.header('Customer spending and retention')

    st.subheader('Q18 · Annual spending per purchasing customer')
    st.caption('2018–2021. Changes compare each age group with its previous calendar year.')
    spending = query(SPENDING_SQL)
    if spending.empty:
        st.warning('No spending rows for the selected period.')
    else:
        spending = _number_columns(
            spending,
            [
                'order_year',
                'purchasing_customers',
                'total_spend_usd',
                'spend_per_customer_usd',
                'previous_year_spend_per_customer_usd',
                'yoy_spending_change_pct',
            ],
        )
        spending['year_label'] = _year_label(spending['order_year'])

        # Switch between the annual spending level and its year-over-year change.
        q18_metric = st.radio(
            'Q18 metric',
            ['Annual spending (USD)', 'Year-over-year change (%)'],
            horizontal=True,
            key='q18_metric',
        )

        # Both charts use the identical SQL result and show the same tooltips.
        tooltip = [
            alt.Tooltip('age_group:N', title='Age group'),
            alt.Tooltip('year_label:O', title='Year'),
            alt.Tooltip('purchasing_customers:Q', title='Purchasing customers', format=','),
            alt.Tooltip('spend_per_customer_usd:Q', title='USD per customer', format='$,.2f'),
            alt.Tooltip(
                'previous_year_spend_per_customer_usd:Q',
                title='Previous-year USD per customer',
                format='$,.2f',
            ),
            alt.Tooltip('yoy_spending_change_pct:Q', title='Year-over-year change (%)', format='.1f'),
        ]

        if q18_metric == 'Annual spending (USD)':
            # A line chart is most useful for spending trends over four years.
            spending_chart = (
                alt.Chart(spending)
                .mark_line(point=True, strokeWidth=2.5)
                .encode(
                    x=alt.X(
                        'year_label:O',
                        sort=['2018', '2019', '2020', '2021'],
                        axis=alt.Axis(title='Year', labelAngle=0),
                    ),
                    y=alt.Y(
                        'spend_per_customer_usd:Q',
                        axis=alt.Axis(title='Annual USD per purchasing customer', format='$,.0f'),
                        scale=alt.Scale(zero=False),
                    ),
                    color=_age_color(),
                    tooltip=tooltip,
                )
                .properties(height=400)
            )
        else:
            # 2018 is excluded because it has no earlier year to compare against.
            # Within each age group, put 2019, 2020, and 2021 next to one another.
            # The zero baseline allows increases and decreases to be read correctly.
            chart_data = spending.dropna(subset=['yoy_spending_change_pct'])
            spending_chart = (
                alt.Chart(chart_data)
                .mark_bar()
                .encode(
                    x=alt.X(
                        'age_group:N',
                        sort=AGE_ORDER + ['Unknown'],
                        axis=alt.Axis(title='Age group', labelAngle=-25, labelLimit=150),
                    ),
                    xOffset=alt.XOffset(
                        'year_label:N',
                        sort=['2019', '2020', '2021'],
                    ),
                    y=alt.Y(
                        'yoy_spending_change_pct:Q',
                        axis=alt.Axis(title='Year-over-year spending change (%)', format='.1f'),
                        scale=alt.Scale(zero=True),
                    ),
                    color=alt.Color(
                        'year_label:N',
                        title='Year',
                        sort=['2019', '2020', '2021'],
                    ),
                    tooltip=tooltip,
                )
                .properties(height=420)
            )
            st.caption(
                'Three bars per age group show 2019, 2020, and 2021. '
                'There is no 2018 percentage change because the query has no earlier comparison year.'
            )

        st.altair_chart(spending_chart, use_container_width=True)
        with st.expander('Full Q18 query results'):
            st.dataframe(
                spending.drop(columns=['year_label']),
                use_container_width=True,
                hide_index=True,
            )

    st.subheader('Q19 · Next-year customer retention')
    st.caption('Share of each age group’s buyers who purchased again the following year (2018–2020 cohorts).')
    retention = query(RETENTION_SQL)
    if retention.empty:
        st.warning('No retention rows for the selected period.')
    else:
        retention = _number_columns(
            retention,
            [
                'order_year',
                'following_year',
                'purchasing_customers',
                'returning_customers',
                'retention_rate_pct',
            ],
        )
        retention['year_label'] = _year_label(retention['order_year'])

        # A heatmap makes all six age groups easy to compare across three years.
        # Each cell shows the exact rate; color emphasizes differences within
        # the displayed data rather than suggesting a 0–100% difference.
        retention['retention_label'] = retention['retention_rate_pct'].map(
            lambda value: f'{value:.1f}%' if pd.notna(value) else 'N/A'
        )

        heatmap_base = alt.Chart(retention).encode(
            x=alt.X(
                'year_label:O',
                sort=['2018', '2019', '2020'],
                axis=alt.Axis(title='Base year', labelAngle=0),
            ),
            y=alt.Y(
                'age_group:N',
                sort=AGE_ORDER + ['Unknown'],
                axis=alt.Axis(title='Age group', labelLimit=180),
            ),
        )

        heatmap_cells = heatmap_base.mark_rect(
            stroke='white',
            strokeWidth=2,
        ).encode(
            color=alt.Color(
                'retention_rate_pct:Q',
                title='Retention (%)',
                scale=alt.Scale(
                    zero=False,
                    range=['#eaf6f3', '#5cae9b'],
                ),
                legend=alt.Legend(format='.1f'),
            ),
            tooltip=[
                alt.Tooltip('year_label:O', title='Base year'),
                alt.Tooltip('following_year:Q', title='Following year', format='.0f'),
                alt.Tooltip('age_group:N', title='Age group'),
                alt.Tooltip('purchasing_customers:Q', title='Base-year customers', format=','),
                alt.Tooltip('returning_customers:Q', title='Returning customers', format=','),
                alt.Tooltip('retention_rate_pct:Q', title='Retention (%)', format='.1f'),
            ],
        )

        heatmap_labels = heatmap_base.mark_text(
            fontSize=15,
            fontWeight='bold',
            color='#17382f',
        ).encode(
            text=alt.Text('retention_label:N'),
        )

        retention_chart = (heatmap_cells + heatmap_labels).properties(height=350)
        st.caption('Each cell shows the percentage of that age group’s buyers who returned the following year. Darker cells mean higher retention within the displayed range.')
        st.altair_chart(retention_chart, use_container_width=True)
        with st.expander('Full Q19 query results'):
            st.dataframe(
                retention.drop(columns=['year_label']),
                use_container_width=True,
                hide_index=True,
            )
