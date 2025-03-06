-- Create the database
CREATE DATABASE IF NOT EXISTS superstore_sales;
USE superstore_sales;

-- Create the table with appropriate data types
CREATE TABLE sales_data (
    `Row ID` FLOAT,
    `Order Priority` VARCHAR(255),
    Discount FLOAT,
    `Unit Price` FLOAT,
    `Shipping Cost` FLOAT,
    `Customer ID` FLOAT,
    `Customer Name` VARCHAR(255),
    `Ship Mode` VARCHAR(255),
    `Customer Segment` VARCHAR(255),
    `Product Category` VARCHAR(255),
    `Product Sub-Category` VARCHAR(255),
    `Product Container` VARCHAR(255),
    `Product Name` VARCHAR(255),
    `Product Base Margin` FLOAT,
    Region VARCHAR(255),
    Manager VARCHAR(255),
    `State or Province` VARCHAR(255),
    City VARCHAR(255),
    `Postal Code` FLOAT,
    `Order Date` FLOAT,
    `Ship Date` FLOAT,
    Profit FLOAT,
    `Quantity ordered new` FLOAT,
    Sales FLOAT,
    `Order ID` FLOAT,
    `Return Status` VARCHAR(255)
);


-- Load data from CSV (adjust the path)
LOAD DATA INFILE 'C:\Users\reyad\OneDrive\Desktop\SQL_project\Superstore Sales Data.csv'
INTO TABLE sales_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Add new DATE columns
ALTER TABLE sales_data
ADD COLUMN OrderDate DATE,
ADD COLUMN ShipDate DATE;

-- Update using DATE conversion
UPDATE sales_data
SET 
  OrderDate = DATE_ADD('1899-12-30', INTERVAL `Order Date` DAY),
  ShipDate = DATE_ADD('1899-12-30', INTERVAL `Ship Date` DAY);

-- Drop old columns
ALTER TABLE sales_data
DROP COLUMN `Order Date`,
DROP COLUMN `Ship Date`;

-- Replace empty strings with NULL for Product Base Margin
UPDATE sales_data
SET `Product Base Margin` = NULL
WHERE `Product Base Margin` = '';

-- EDA
-- Total Sales and Profit
SELECT 
  SUM(Sales) AS TotalSales,
  SUM(Profit) AS TotalProfit
FROM sales_data;

-- Top Customers
SELECT 
  `Customer Name`,
  SUM(Sales) AS TotalSpent,
  COUNT(`Order ID`) AS OrderCount
FROM sales_data
GROUP BY `Customer Name`
ORDER BY TotalSpent DESC
LIMIT 10;

-- Calculate RFM 
WITH rfm_raw AS (
  SELECT
    `Customer ID`,
    -- Recency: Days since last order (lower = better)
    DATEDIFF(CURRENT_DATE(), MAX(OrderDate)) AS Recency,
    -- Frequency: Total number of orders
    COUNT(`Order ID`) AS Frequency,
    -- Monetary: Total spending
    SUM(Sales) AS Monetary
  FROM sales_data
  GROUP BY `Customer ID`
),
rfm_scores AS (
  SELECT
    `Customer ID`,
    Recency,
    Frequency,
    Monetary,
    -- Score 1-4 (4=best) for each dimension
    NTILE(4) OVER (ORDER BY Recency DESC) AS R_Score,  -- Lower recency = better
    NTILE(4) OVER (ORDER BY Frequency ASC) AS F_Score, -- Higher frequency = better
    NTILE(4) OVER (ORDER BY Monetary ASC) AS M_Score   -- Higher monetary = better
  FROM rfm_raw
)
SELECT
  `Customer ID`,
  CONCAT(R_Score, F_Score, M_Score) AS RFM,
  CASE
    WHEN RFM IN ('444', '443', '434') THEN 'Champions'
    WHEN RFM LIKE '4__' THEN 'Loyal Customers'
    WHEN RFM LIKE '_4_' THEN 'Potential Loyalists'
    WHEN RFM LIKE '__4' THEN 'Big Spenders'
    WHEN RFM IN ('311', '312', '313') THEN 'At Risk'
    WHEN RFM IN ('111', '112', '113') THEN 'Lost Customers'
    ELSE 'Needs Attention'
  END AS Segment
FROM rfm_scores;