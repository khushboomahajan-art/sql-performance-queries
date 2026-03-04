-- ================================================
-- setup.sql
-- TPC-H Showcase — Snowflake Setup
-- ================================================
-- STEP 1: ENVIRONMENT SETUP
-- ================================================

USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS TPCH_SHOWCASE;
USE DATABASE TPCH_SHOWCASE;

CREATE SCHEMA IF NOT EXISTS TPCH;
USE SCHEMA TPCH;

CREATE WAREHOUSE IF NOT EXISTS TPCH_WH
    WAREHOUSE_SIZE    = 'X-SMALL'
    AUTO_SUSPEND      = 60
    AUTO_RESUME       = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT           = 'Warehouse for TPC-H SQL showcase';

USE WAREHOUSE TPCH_WH;


-- ================================================
-- STEP 2: CREATE VIEWS OVER SAMPLE DATA
-- ================================================

CREATE OR REPLACE VIEW customer AS
    SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER;

CREATE OR REPLACE VIEW orders AS
    SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;

CREATE OR REPLACE VIEW lineitem AS
    SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM;

CREATE OR REPLACE VIEW supplier AS
    SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER;

CREATE OR REPLACE VIEW part AS
    SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PART;

CREATE OR REPLACE VIEW partsupp AS
    SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP;

CREATE OR REPLACE VIEW nation AS
    SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION;

CREATE OR REPLACE VIEW region AS
    SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION;


-- ================================================
-- STEP 3: VERIFY ROW COUNTS
-- ================================================

SELECT 'customer' AS table_name, COUNT(*) AS row_count 
FROM customer
UNION ALL SELECT 'orders',   COUNT(*) FROM orders
UNION ALL SELECT 'lineitem', COUNT(*) FROM lineitem
UNION ALL SELECT 'supplier', COUNT(*) FROM supplier
UNION ALL SELECT 'part',     COUNT(*) FROM part
UNION ALL SELECT 'partsupp', COUNT(*) FROM partsupp
UNION ALL SELECT 'nation',   COUNT(*) FROM nation
UNION ALL SELECT 'region',   COUNT(*) FROM region
ORDER BY table_name;

-- Expected output (SF1 scale):
-- customer    150,000
-- lineitem  6,001,215
-- nation           25
-- orders    1,500,000
-- part        200,000
-- partsupp    800,000
-- region            5
-- supplier     10,000


-- ================================================
-- STEP 4: SNOWFLAKE FEATURES
-- ================================================

-- 4a: Create a clustered table
ALTER WAREHOUSE TPCH_WH RESUME;
USE WAREHOUSE TPCH_WH;
USE DATABASE TPCH_SHOWCASE;
USE SCHEMA TPCH;

-- Now try creating the clustered table
CREATE OR REPLACE TABLE orders_clustered
    CLUSTER BY (O_ORDERDATE, O_ORDERSTATUS)
AS 
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;


-- 4b: Time Travel ( Query 1 hour old data)
SELECT COUNT(*) FROM orders_clustered
    AT (OFFSET => -3600);

-- 4c: Clone a table 
CREATE OR REPLACE TABLE orders_dev
    CLONE orders_clustered;

-- 4d: Create a result cache
SELECT
    O_ORDERSTATUS,
    COUNT(*)          AS order_count,
    SUM(O_TOTALPRICE) AS total_value
FROM orders
GROUP BY O_ORDERSTATUS;
