SELECT
    reg.r_name                              AS region,
    EXTRACT(YEAR FROM ord.o_orderdate)      AS order_year,
    COUNT(DISTINCT ord.o_orderkey)          AS total_orders,
    COUNT(DISTINCT ord.o_custkey)           AS unique_customers,
    SUM(li.l_extendedprice)                AS gross_revenue,
    SUM(li.l_extendedprice * (1 - li.l_discount))          AS net_revenue,
    SUM(li.l_extendedprice * (1 - li.l_discount) 
        * (1 - li.l_tax))                  AS net_revenue_after_tax,
    ROUND(AVG(li.l_discount) * 100, 2)    AS avg_discount_pct
FROM
    orders ord
    JOIN lineitem li    ON ord.o_orderkey  = li.l_orderkey
    JOIN customer cust    ON ord.o_custkey   = cust.c_custkey
    JOIN nation nat      ON cust.c_nationkey = nat.n_nationkey
    JOIN region reg      ON nat.n_regionkey = reg.r_regionkey
WHERE
    ord.o_orderdate BETWEEN '1994-01-01' AND '1997-12-31'
GROUP BY
    reg.r_name,
    EXTRACT(YEAR FROM ord.o_orderdate)
HAVING
    SUM(li.l_extendedprice) > 1000000
ORDER BY
    region,order_year;
