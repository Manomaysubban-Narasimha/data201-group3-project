"""Waqas's SQL-backed product-category visualizations (Q24 and Q25).

Both SQL statements are verbatim copies from Waqas_advanced.sql.
Requires the shared dashboard/db.py `query` helper and Altair, Pandas, Streamlit.
"""

import altair as alt
import pandas as pd
import streamlit as st

from db import query


# Identical to Waqas_advanced.sql, @Q24. Do not edit without updating the source SQL.
REGIONAL_CATEGORY_SQL = """
WITH region_category_spend AS (
    SELECT r.region_name AS shipping_region,
           p.category,
           COUNT(DISTINCT pl.response_id) AS category_buyers,
           SUM(pl.unit_price * pl.quantity) AS category_spend
    FROM purchase_line pl
    JOIN product p
        ON p.asin = pl.asin
    JOIN state s
        ON s.state_code = pl.ship_state_code
    JOIN census_division d
        ON d.division_id = s.division_id
    JOIN census_region r
        ON r.region_id = d.region_id
    WHERE pl.order_date BETWEEN '2018-01-01' AND '2022-10-31'
      AND p.category IS NOT NULL
      AND p.category NOT LIKE '%GIFT_CARD%'
    GROUP BY r.region_name, p.category
),
regional_ranks AS (
    SELECT shipping_region,
           category,
           category_buyers,
           category_spend,
           DENSE_RANK() OVER (
               PARTITION BY shipping_region
               ORDER BY category_spend DESC
           ) AS category_rank,
           SUM(category_spend) OVER (
               PARTITION BY shipping_region
           ) AS total_region_category_spend
    FROM region_category_spend
)
SELECT shipping_region,
       category_rank,
       category,
       category_buyers,
       ROUND(category_spend, 2) AS category_spend_usd,
       CASE
           WHEN total_region_category_spend = 0 THEN NULL
           ELSE ROUND(100.0 * category_spend /
                      total_region_category_spend, 1)
       END AS share_of_region_spend_pct
FROM regional_ranks
WHERE category_rank <= 3
ORDER BY shipping_region, category_rank, category;
"""


# Identical to Waqas_advanced.sql, @Q25. Do not edit without updating the source SQL.
MULTIUNIT_SQL = """
WITH category_line_metrics AS (
    SELECT p.category,
           COUNT(*) AS purchase_lines,
           SUM(CASE WHEN pl.quantity >= 2 THEN 1 ELSE 0 END)
               AS multi_unit_lines,
           SUM(pl.quantity) AS units_purchased
    FROM purchase_line pl
    JOIN product p
        ON p.asin = pl.asin
    WHERE pl.order_date BETWEEN '2018-01-01' AND '2022-10-31'
      AND pl.quantity > 0
      AND p.category IS NOT NULL
      AND p.category NOT LIKE '%GIFT_CARD%'
    GROUP BY p.category
),
eligible_categories AS (
    SELECT category,
           purchase_lines,
           multi_unit_lines,
           units_purchased,
           100.0 * multi_unit_lines / purchase_lines AS multi_unit_pct
    FROM category_line_metrics
    WHERE purchase_lines >= 500
)
SELECT DENSE_RANK() OVER (
           ORDER BY multi_unit_pct DESC
       ) AS category_rank,
       category,
       purchase_lines,
       multi_unit_lines,
       units_purchased,
       ROUND(multi_unit_pct, 1) AS multi_unit_purchase_line_pct
FROM eligible_categories
ORDER BY category_rank, category
LIMIT 15;
"""


def _numeric_columns(data, columns):
    """Convert decimal/numeric values returned by the MySQL helper for charting."""
    result = data.copy()
    for column in columns:
        result[column] = pd.to_numeric(result[column], errors='coerce')
    return result


def _ranked_categories(data):
    """Retain SQL DENSE_RANK ties and keep category labels distinct."""
    data = data.copy()
    ranks = data['category_rank'].astype('Int64').astype(str)
    data['ranked_category'] = '#' + ranks + '  ' + data['category'].astype(str)
    return data


def _plot_ranked_bars(data, measure, x_title, label_format, tooltips, height):
    """Use a horizontal bar chart so long product categories remain legible."""
    data = data.dropna(subset=[measure]).copy()
    if data.empty:
        st.info('No non-null values are available for this metric.')
        return

    # Include zero and enough room for a label to the right of every bar.
    maximum = float(data[measure].max())
    upper = max(1.0, maximum * 1.20)
    category_order = data['ranked_category'].tolist()
    data['value_label'] = data[measure].map(
        lambda value: (f'${float(value):,.0f}' if label_format == 'money'
                       else f'{float(value):.1f}%')
        if pd.notna(value) else 'N/A'
    )

    base = alt.Chart(data).encode(
        y=alt.Y(
            'ranked_category:N',
            sort=category_order,
            axis=alt.Axis(title=None, labelLimit=300, labelFontSize=12),
        ),
        x=alt.X(
            f'{measure}:Q',
            scale=alt.Scale(domain=[0, upper], zero=True),
            axis=alt.Axis(title=x_title, tickCount=6),
        ),
        tooltip=tooltips,
    )

    bars = base.mark_bar(size=24, cornerRadiusEnd=3)
    values = base.mark_text(align='left', baseline='middle', dx=7, fontSize=12).encode(
        text='value_label:N'
    )
    chart = (bars + values).properties(height=height)
    st.altair_chart(chart, use_container_width=True)


def render():
    st.header('Product and category analytics')
    st.caption("Purchase data: January 2018–October 2022. Charts display results from Waqas's original SQL queries.")

    st.subheader('Q24 · Highest-revenue categories by shipping region')
    st.caption(
        'Three highest-revenue product categories in each U.S. Census shipping region. '
        'Only known non-gift-card categories with a mapped shipping region are included. '
        'SQL DENSE_RANK preserves ties, so more than three categories may appear.'
    )
    regional = query(REGIONAL_CATEGORY_SQL)
    if regional.empty:
        st.warning('No regional category data is available.')
    else:
        regional = _numeric_columns(regional, [
            'category_rank', 'category_buyers',
            'category_spend_usd', 'share_of_region_spend_pct',
        ])
        regions = sorted(regional['shipping_region'].dropna().unique().tolist())
        if not regions:
            st.warning('The query returned no known shipping regions.')
        else:
            selected_region = st.selectbox('Shipping region', regions, key='waqas_q24_region')
            regional_selected = regional.loc[
                regional['shipping_region'] == selected_region
            ].sort_values(['category_rank', 'category'])
            regional_selected = _ranked_categories(regional_selected)

            metric = st.radio(
                'Q24 metric',
                ['Revenue (USD)', 'Share of regional category spend (%)'],
                horizontal=True,
                key='waqas_q24_metric',
            )
            if metric == 'Revenue (USD)':
                measure = 'category_spend_usd'
                x_title = 'Category revenue (USD)'
                fmt = 'money'
            else:
                measure = 'share_of_region_spend_pct'
                x_title = 'Regional category spend share (%)'
                fmt = 'pct'
                st.caption(
                    'The denominator includes spending across all eligible categories in '
                    'this region, not only the top three shown.'
                )

            _plot_ranked_bars(
                regional_selected,
                measure=measure,
                x_title=x_title,
                label_format=fmt,
                tooltips=[
                    alt.Tooltip('shipping_region:N', title='Shipping region'),
                    alt.Tooltip('category:N', title='Product category'),
                    alt.Tooltip('category_rank:Q', title='Regional rank', format='.0f'),
                    alt.Tooltip('category_buyers:Q', title='Category buyers', format=',.0f'),
                    alt.Tooltip('category_spend_usd:Q', title='Revenue (USD)', format='$,.2f'),
                    alt.Tooltip('share_of_region_spend_pct:Q', title='Regional spend share (%)', format='.1f'),
                ],
                height=max(225, 70 * len(regional_selected)),
            )
        with st.expander('Full Q24 query results'):
            st.dataframe(regional, use_container_width=True, hide_index=True)

    st.subheader('Q25 · Product categories with the highest multi-unit purchase rates')
    st.caption(
        'Percentage of purchase lines containing at least two units, among categories '
        'with 500 or more eligible purchase lines. Rates refer to purchase lines, not customers or orders.'
    )
    multiunit = query(MULTIUNIT_SQL)
    if multiunit.empty:
        st.warning('No eligible product-category data is available.')
    else:
        multiunit = _numeric_columns(multiunit, [
            'category_rank', 'purchase_lines', 'multi_unit_lines',
            'units_purchased', 'multi_unit_purchase_line_pct',
        ])
        multiunit = multiunit.sort_values(['category_rank', 'category'])
        chart_data = _ranked_categories(multiunit)
        _plot_ranked_bars(
            chart_data,
            measure='multi_unit_purchase_line_pct',
            x_title='Purchase lines with multiple units (%)',
            label_format='pct',
            tooltips=[
                alt.Tooltip('category:N', title='Product category'),
                alt.Tooltip('category_rank:Q', title='Rank', format='.0f'),
                alt.Tooltip('purchase_lines:Q', title='Purchase lines', format=',.0f'),
                alt.Tooltip('multi_unit_lines:Q', title='Multi-unit lines', format=',.0f'),
                alt.Tooltip('units_purchased:Q', title='Total units purchased', format=',.0f'),
                alt.Tooltip('multi_unit_purchase_line_pct:Q', title='Multi-unit lines (%)', format='.1f'),
            ],
            height=max(350, 37 * len(chart_data)),
        )
        st.caption('Bars are ranked by the unrounded rate. A shared rank means a tie.')
        with st.expander('Full Q25 query results'):
            st.dataframe(multiunit, use_container_width=True, hide_index=True)
