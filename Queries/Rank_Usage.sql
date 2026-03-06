WITH supplier_performance AS (
    SELECT
        s.s_name                                    AS supplier_name,
        n.n_name                                    AS country,
        COUNT(DISTINCT l.l_orderkey)                AS total_orders_supplied,
        SUM(l.l_extendedprice)                      AS total_supply_value,
        AVG(l.l_extendedprice)                      AS avg_order_value,
        SUM(CASE WHEN l.l_returnflag = 'R' 
                 THEN 1 ELSE 0 END)                 AS returned_items,
        ROUND(SUM(CASE WHEN l.l_returnflag = 'R' 
                       THEN 1 ELSE 0 END) * 100.0 
              / COUNT(*), 2)                        AS return_rate_pct
    FROM
        supplier s
        JOIN lineitem l  ON s.s_suppkey  = l.l_suppkey
        JOIN nation n    ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_name, n.n_name
)
SELECT
    supplier_name,
    country,
    total_supply_value,
    return_rate_pct,
    RANK() OVER (PARTITION BY country ORDER BY total_supply_value DESC) AS rank_in_country,
    DENSE_RANK() OVER (ORDER BY total_supply_value DESC)  AS global_rank,
    NTILE(4) OVER (ORDER BY total_supply_value DESC) AS performance_quartile,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_supply_value) * 100, 2)       AS percentile_rank

FROM supplier_performance
ORDER BY global_rank;
