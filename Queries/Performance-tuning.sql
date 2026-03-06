
## Case 1: Eliminating Correlated Subquery

### Before (Slow — correlated subquery runs once per row)
SELECT 
    o_orderkey,
    o_totalprice,
    (SELECT SUM(l_extendedprice) 
     FROM lineitem 
     WHERE l_orderkey = o.o_orderkey) AS calculated_total
FROM orders o;

-- Execution: Full table scan on lineitem 
-- for every row in orders
-- Cost: O(n²) — extremely slow at scale

### After (Fast — single JOIN)
SELECT 
    o.o_orderkey,
    o.o_totalprice,
    SUM(l.l_extendedprice) AS calculated_total
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY o.o_orderkey, o.o_totalprice;

-- Execution: Single pass with hash join
-- Cost: O(n) — dramatically faster at scale
-- Real impact: On 1M+ row tables this 
-- reduces runtime from minutes to seconds

---

## Case 2: Partition Pruning (SAP HANA / Snowflake)

### Before (Full table scan)
SELECT * FROM sales_data
WHERE sale_date = '2024-01-15';

-- Without partitioning: scans entire table

### After (Partition pruning)
-- Table partitioned by YEAR(sale_date), 
-- MONTH(sale_date)
SELECT * FROM sales_data
WHERE sale_date = '2024-01-15';

-- With partitioning: scans only Jan 2024 
-- partition
-- Real impact: Reduced query time by ~70% 
-- on 400GB+ tables (implemented at Apple)

---

## Case 3: Replacing DISTINCT with GROUP BY

### Before
SELECT DISTINCT customer_id, order_date
FROM orders
WHERE status = 'ACTIVE';

### After
SELECT customer_id, order_date
FROM orders
WHERE status = 'ACTIVE'
GROUP BY customer_id, order_date;

-- GROUP BY allows the optimizer to use 
-- more efficient aggregation strategies
-- vs DISTINCT which sorts entire result set
