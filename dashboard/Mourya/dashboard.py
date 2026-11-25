"""Mourya's dashboard section: Q20 monthly spending and Q21 repeat shopping.

Self-contained on purpose: it imports no teammate code (not even the shared
db.py), and each query renders inside its own error boundary, so changes
elsewhere in the group dashboard cannot break this section.
"""

import calendar
import os
from pathlib import Path

import altair as alt
import pandas as pd
import pymysql
import streamlit as st
from dotenv import load_dotenv

# Same MYSQL_* settings as the rest of the dashboard (dashboard/.env or the OS
# environment); only the connection code is private to this section.
load_dotenv(Path(__file__).resolve().parents[1] / '.env')


# Exact Q20 statement from Mourya_advanced.sql (no modifications).
MONTHLY_SALES_SQL = """WITH monthly_sales AS (
    SELECT YEAR(order_date) AS order_year,
           MONTH(order_date) AS order_month,
           COUNT(DISTINCT response_id) AS active_customers,
           SUM(unit_price * quantity) AS spend_usd
    FROM purchase_line
    WHERE order_date BETWEEN '2018-01-01' AND '2021-12-31'
    GROUP BY YEAR(order_date), MONTH(order_date)
),
monthly_comparison AS (
    SELECT order_year,
           order_month,
           order_year * 12 + order_month AS month_number,
           active_customers,
           spend_usd,
           LAG(order_year * 12 + order_month) OVER (
               ORDER BY order_year, order_month
           ) AS previous_month_number,
           LAG(spend_usd) OVER (
               ORDER BY order_year, order_month
           ) AS previous_month_spend
    FROM monthly_sales
)
SELECT order_year,
       order_month,
       active_customers,
       ROUND(spend_usd, 2) AS monthly_spend_usd,
       CASE
           WHEN previous_month_number = month_number - 1
               THEN ROUND(previous_month_spend, 2)
           ELSE NULL
       END AS prior_month_spend_usd,
       CASE
           WHEN previous_month_number = month_number - 1
                AND previous_month_spend IS NOT NULL
                AND previous_month_spend <> 0
               THEN ROUND(100.0 * (spend_usd - previous_month_spend)
                          / previous_month_spend, 1)
           ELSE NULL
       END AS month_over_month_change_pct
FROM monthly_comparison
ORDER BY order_year, order_month;"""


# Exact Q21 CREATE OR REPLACE VIEW statement from Mourya_advanced.sql.
# Run once in MySQL Workbench; do NOT invoke using the read-only db.query().
Q21_VIEW_SQL = """CREATE OR REPLACE VIEW vw_mourya_customer_month_activity AS
SELECT YEAR(order_date) AS order_year,
       MONTH(order_date) AS order_month,
       response_id,
       COUNT(DISTINCT order_date) AS shopping_days
FROM purchase_line
WHERE order_date BETWEEN '2018-01-01' AND '2021-12-31'
GROUP BY YEAR(order_date), MONTH(order_date), response_id;"""


# Exact Q21 WITH/SELECT statement from Mourya_advanced.sql (no modifications).
REPEAT_SQL = """WITH monthly_repeat AS (
    SELECT order_year,
           order_month,
           COUNT(*) AS active_customers,
           SUM(CASE WHEN shopping_days >= 2 THEN 1 ELSE 0 END)
               AS repeat_day_customers
    FROM vw_mourya_customer_month_activity
    GROUP BY order_year, order_month
),
monthly_rates AS (
    SELECT order_year,
           order_month,
           active_customers,
           repeat_day_customers,
           100.0 * repeat_day_customers / active_customers AS repeat_day_pct
    FROM monthly_repeat
)
SELECT order_year,
       order_month,
       active_customers,
       repeat_day_customers,
       ROUND(repeat_day_pct, 1) AS repeat_day_customers_pct,
       CASE
           WHEN repeat_day_pct > (
               SELECT AVG(repeat_day_pct) FROM monthly_rates
           ) THEN 'Above typical month'
           ELSE 'At or below typical month'
       END AS comparison_to_study_monthly_average,
       DENSE_RANK() OVER (
           PARTITION BY order_year
           ORDER BY repeat_day_pct DESC
       ) AS rank_within_year
FROM monthly_rates
ORDER BY order_year, rank_within_year, order_month;"""




MONTH_ABBREVIATIONS = [calendar.month_abbr[month] for month in range(1, 13)]
YEAR_LABELS = ['2018', '2019', '2020', '2021']


@st.cache_data(ttl=900, show_spinner=False)
def _query(sql: str) -> pd.DataFrame:
    """Return the rows of one read-only SELECT. Never write to the database here."""
    db = pymysql.connect(
        host=os.environ.get('MYSQL_HOST', '127.0.0.1'),
        port=int(os.environ.get('MYSQL_PORT', '3306')),
        user=os.environ.get('MYSQL_USER', 'root'),
        password=os.environ.get('MYSQL_PASSWORD', ''),
        database=os.environ.get('MYSQL_DATABASE', 'amazon_ecommerce'),
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=10,
        read_timeout=180,
        autocommit=True,
    )
    try:
        with db.cursor() as cursor:
            cursor.execute(sql)
            return pd.DataFrame(cursor.fetchall())
    finally:
        db.close()


def _prepare_monthly_rows(df, numeric_fields):
    """Prepare chart-friendly types without changing any SQL result values."""
    df = df.copy()
    for col in ('order_year', 'order_month', *numeric_fields):
        df[col] = pd.to_numeric(df[col], errors='coerce')

    # A null in a SQL metric stays missing (not zero).
    valid_dates = df['order_year'].notna() & df['order_month'].notna()
    df = df.loc[valid_dates].copy()
    df['month_date'] = pd.to_datetime(
        dict(year=df['order_year'].astype(int),
             month=df['order_month'].astype(int), day=1)
    )
    df['month_label'] = df['month_date'].dt.strftime('%b %Y')
    df['year_label'] = df['order_year'].astype(int).astype(str)
    df['month_short'] = df['order_month'].astype(int).map(
        {month: calendar.month_abbr[month] for month in range(1, 13)}
    )
    return df.sort_values('month_date')


def _q20_tooltips():
    return [
        alt.Tooltip('month_label:N', title='Month'),
        alt.Tooltip('monthly_spend_usd:Q', title='Spending (USD)', format='$,.2f'),
        alt.Tooltip('prior_month_spend_usd:Q', title='Prior month (USD)', format='$,.2f'),
        alt.Tooltip('month_over_month_change_pct:Q', title='Change vs. prior month (%)', format='.1f'),
        alt.Tooltip('active_customers:Q', title='Active customers', format=','),
    ]


def _q20_chart(monthly):
    chart_mode = st.radio(
        'Q20 metric',
        ['Monthly spending (USD)', 'Month-over-month change (%)'],
        horizontal=True,
        key='mourya_q20_chart_mode',
    )

    x = alt.X(
        'month_date:T',
        axis=alt.Axis(title='Month', format='%b %Y', labelAngle=-35),
    )
    if chart_mode == 'Monthly spending (USD)':
        st.caption(
            'Line chart: follows spending over all 48 months. '
            'Hover for the exact previous-month amount and percentage change.'
        )
        chart = (
            alt.Chart(monthly)
            .mark_line(point=True, strokeWidth=2.5)
            .encode(
                x=x,
                y=alt.Y(
                    'monthly_spend_usd:Q',
                    axis=alt.Axis(title='Monthly spending (USD)', format='$,.0f'),
                    scale=alt.Scale(zero=False),
                ),
                tooltip=_q20_tooltips(),
            )
        )
    else:
        st.caption(
            'Bar chart: each bar is the percentage change from the immediately '
            'preceding calendar month. Months without a valid comparison are omitted.'
        )
        chart = (
            alt.Chart(monthly.dropna(subset=['month_over_month_change_pct']))
            .mark_bar()
            .encode(
                x=x,
                y=alt.Y(
                    'month_over_month_change_pct:Q',
                    axis=alt.Axis(title='Change vs. prior month (%)', format='.1f'),
                    scale=alt.Scale(zero=True),
                ),
                tooltip=_q20_tooltips(),
            )
        )

    st.altair_chart(chart.properties(height=380), width='stretch')


def _q21_heatmap(repeat):
    """A month-by-year heatmap makes the strongest repeat-shopping months clear."""
    month_axis = alt.X(
        'month_short:N',
        sort=MONTH_ABBREVIATIONS,
        axis=alt.Axis(title='Calendar month', labelAngle=0),
    )
    year_axis = alt.Y(
        'year_label:N',
        sort=YEAR_LABELS,
        axis=alt.Axis(title='Year'),
    )
    hover = [
        alt.Tooltip('year_label:N', title='Year'),
        alt.Tooltip('month_short:N', title='Month'),
        alt.Tooltip('repeat_day_customers_pct:Q', title='Repeat-day customers (%)', format='.1f'),
        alt.Tooltip('rank_within_year:Q', title='Rank within year', format='.0f'),
        alt.Tooltip('comparison_to_study_monthly_average:N', title='Study-average comparison'),
        alt.Tooltip('repeat_day_customers:Q', title='Customers shopping on 2+ days', format=','),
        alt.Tooltip('active_customers:Q', title='Active customers', format=','),
    ]
    cells = (
        alt.Chart(repeat)
        .mark_rect(stroke='white', strokeWidth=1)
        .encode(
            x=month_axis,
            y=year_axis,
            color=alt.Color(
                'repeat_day_customers_pct:Q',
                title='Repeat customers (%)',
                scale=alt.Scale(scheme='teals'),
            ),
            tooltip=hover,
        )
    )
    # Show precise percentages directly; ranks and the unweighted benchmark
    # remain available on hover and in the unmodified SQL results table.
    low = repeat['repeat_day_customers_pct'].min()
    high = repeat['repeat_day_customers_pct'].max()
    contrast_cutoff = low + 0.65 * (high - low)
    numbers = (
        alt.Chart(repeat)
        .mark_text(fontSize=11)
        .encode(
            x=month_axis,
            y=year_axis,
            text=alt.Text('repeat_day_customers_pct:Q', format='.1f'),
            color=alt.condition(
                alt.datum.repeat_day_customers_pct >= contrast_cutoff,
                alt.value('white'),
                alt.value('#172524'),
            ),
        )
    )
    st.caption(
        'Heatmap: one cell per month and year. Darker cells mean a higher '
        'share of customers shopping on at least two distinct days. '
        'Hover for the exact annual rank and comparison to the study average. '
        'Color intensity is relative to the displayed months.'
    )
    st.altair_chart((cells + numbers).properties(height=210), width='stretch')


def _render_q20():
    st.subheader('Q20 · Monthly spending and month-over-month change')
    monthly = _query(MONTHLY_SALES_SQL)
    if monthly.empty:
        st.warning('No spending rows returned for Q20.')
        return

    monthly = _prepare_monthly_rows(
        monthly,
        ('active_customers', 'monthly_spend_usd',
         'prior_month_spend_usd', 'month_over_month_change_pct'),
    )
    if monthly.empty:
        st.warning('Q20 did not return usable calendar months.')
        return

    _q20_chart(monthly)
    with st.expander('Full Q20 query results'):
        st.dataframe(
            monthly.drop(columns=['month_date', 'month_label',
                                  'year_label', 'month_short']),
            width='stretch',
            hide_index=True,
        )


def _render_q21():
    st.subheader('Q21 · Repeat-shopping activity by month')
    st.caption(
        'A repeat-day customer shopped on at least two distinct dates within '
        'the same month. The benchmark is the unweighted average of monthly rates.'
    )
    try:
        repeat = _query(REPEAT_SQL)
    except pymysql.MySQLError as err:
        if err.args and err.args[0] == 1146:
            st.error('Q21 requires the SQL view vw_mourya_customer_month_activity.')
            st.info(
                'Run the exact view statement below once in MySQL Workbench '
                'against the amazon_ecommerce database, then rerun Streamlit. '
                'The shared db.py intentionally performs SELECT queries only.'
            )
            with st.expander('Show the exact CREATE OR REPLACE VIEW SQL', expanded=True):
                st.code(Q21_VIEW_SQL, language='sql')
            return
        raise

    if repeat.empty:
        st.warning('No repeat-shopping rows returned for Q21.')
        return

    repeat = _prepare_monthly_rows(
        repeat,
        ('active_customers', 'repeat_day_customers',
         'repeat_day_customers_pct', 'rank_within_year'),
    )
    if repeat.empty:
        st.warning('Q21 did not return usable calendar months.')
        return

    _q21_heatmap(repeat)

    with st.expander('Top-ranked months in each year'):
        ranking = (
            repeat.loc[repeat['rank_within_year'] <= 3]
            .sort_values(['order_year', 'rank_within_year', 'order_month'])
            [['order_year', 'month_short', 'rank_within_year',
              'repeat_day_customers_pct', 'comparison_to_study_monthly_average']]
            .rename(columns={
                'order_year': 'Year',
                'month_short': 'Month',
                'rank_within_year': 'Rank within year',
                'repeat_day_customers_pct': 'Repeat-day customers (%)',
                'comparison_to_study_monthly_average': 'Vs. study average',
            })
        )
        st.dataframe(ranking, width='stretch', hide_index=True)

    with st.expander('Full Q21 query results'):
        st.dataframe(
            repeat.drop(columns=['month_date', 'month_label',
                                 'year_label', 'month_short']),
            width='stretch',
            hide_index=True,
        )


def _run_isolated(label, render_section):
    """Contain a failure to one query so the other still renders.

    Shows the full traceback here instead of relying on app.py's handler,
    which reports only a one-line message. Streamlit's rerun/stop signals
    derive from BaseException, so they pass through untouched.
    """
    try:
        render_section()
    except Exception as err:
        st.error(f'{label} could not be displayed.')
        st.exception(err)


def render():
    st.header('Monthly spending and repeat shopping')
    st.caption('Q20 and Q21 use all twelve months of each year from 2018 through 2021.')
    _run_isolated('Q20', _render_q20)
    _run_isolated('Q21', _render_q21)


if __name__ == '__main__':
    # Fallback that works even if the shared app.py breaks:
    #   streamlit run dashboard/Mourya/dashboard.py
    st.set_page_config(page_title='DATA 201 | Monthly spending', layout='wide')
    render()