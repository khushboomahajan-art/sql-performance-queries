WITH order_financials AS (
    -- Base level: line item financials
    SELECT
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_orderstatus,
        l.l_extendedprice AS gross_amount,
        l.l_extendedprice * l.l_discount AS discount_amount,
        l.l_extendedprice * (1 - l.l_discount) AS net_amount,
        l.l_extendedprice * (1 - l.l_discount) * l.l_tax AS tax_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),

customer_summary AS (
    -- Customer level rollup
    SELECT
        o.o_custkey,
        c.c_name,
        c.c_mktsegment,
        n.n_name AS country,
        r.r_name AS region,
        SUM(of.gross_amount) AS total_gross,
        SUM(of.discount_amount) AS total_discounts,
        SUM(of.net_amount) AS total_net,
        SUM(of.tax_amount) AS total_tax,
        COUNT(DISTINCT of.o_orderkey) AS order_count
    FROM order_financials of
    JOIN customer c  ON of.o_custkey   = c.c_custkey
    JOIN nation n    ON c.c_nationkey  = n.n_nationkey
    JOIN region r    ON n.n_regionkey  = r.r_regionkey
    GROUP BY
        o.o_custkey, c.c_name, c.c_mktsegment,
        n.n_name, r.r_name
),

customer_classified AS (
    -- Classify customers by revenue tier
    SELECT
        *,
        CASE
            WHEN total_net >= 500000  THEN 'Platinum'
            WHEN total_net >= 200000  THEN 'Gold'
            WHEN total_net >= 100000  THEN 'Silver'
            ELSE                           'Bronze'
        END AS customer_tier
    FROM customer_summary
)

-- Final output: Regional financial summary by tier
SELECT
    region,
    country,
    customer_tier,
    COUNT(DISTINCT o_custkey)  AS customer_count,
    SUM(total_gross) AS gross_revenue,
    SUM(total_discounts) AS total_discounts,
    SUM(total_net) AS net_revenue,
    SUM(total_tax) AS total_taxes,
    ROUND(SUM(total_discounts) / NULLIF(SUM(total_gross), 0) * 100, 2) AS discount_pct,
    ROUND(SUM(total_net) / COUNT(DISTINCT o_custkey), 2) AS revenue_per_customer
FROM customer_classified
GROUP BY ROLLUP(region, country, customer_tier)
ORDER BY region, country, customer_tier;
