-- Database: AdventureWorksDW2019
-- Write a query joining the DimCustomer, and FactInternetSales tables to return CustomerKey, FullName with their number of order (SalesOrderNumber)
SELECT
    DC.CustomerKey
    , CASE
        WHEN MiddleName IS NOT NULL THEN
            CONCAT(FirstName, ' ', MiddleName, ' ', LastName)
        ELSE
            CONCAT(FirstName, ' ', LastName)
    END AS Full_Name
    , COUNT (DISTINCT FIS.SalesOrderNumber) AS Number_Of_Orders
FROM DimCustomer AS DC
JOIN FactInternetSales AS FIS
ON FIS.CustomerKey = DC.CustomerKey
GROUP BY DC.CustomerKey, DC.FirstName, DC.MiddleName, DC.LastName
ORDER BY DC.CustomerKey ASC;

-- Write a query that create new Color_Group, if product color is 'Black' or 'Silver' or 'Silver/Black' leave 'Basic', else keep Color. Then Caculate total SalesAmount by new Color_group
SELECT
    CASE
        WHEN Color IN ('Black', 'Silver', 'Black/Silver') THEN 'Basic'
        ELSE Color
    END AS Color_Group
    , SUM(FIS.SalesAmount) AS Total_Amount
FROM dbo.DimProduct AS DP
JOIN dbo.FactInternetSales AS FIS 
ON DP.ProductKey = FIS.ProductKey
GROUP BY 
    CASE
        WHEN Color IN ('Black', 'Silver', 'Black/Silver') THEN 'Basic'
        ELSE Color
    END;

-- Retrieve saleordernumber, productkey, orderdate, shipdate of orders in October 2011, along with sales type ('Resell' or 'Internet')

WITH CombinedSales AS
(
SELECT
    SalesOrderNumber
    , ProductKey
    , OrderDate
    , ShipDate
    , 'Internet' AS SalesType
FROM FactInternetSales
UNION ALL
SELECT
    SalesOrderNumber
    , ProductKey
    , OrderDate
    , ShipDate
    , 'Reseller'
FROM FactResellerSales
)
SELECT * 
FROM CombinedSales 
WHERE YEAR(ShipDate) = 2011 AND MONTH(ShipDate) = 10;

SELECT  
    SalesOrderNumber
    , ProductKey
    , OrderDate
    , ShipDate
    , 'Internet' AS SalesType
FROM FactInternetSales
WHERE ShipDate BETWEEN '2011-10-01' AND '2011-10-31'
UNION
SELECT  
    SalesOrderNumber
    , ProductKey
    , OrderDate
    , ShipDate
    , 'Reseller' AS SalesType
FROM FactResellerSales
WHERE ShipDate BETWEEN '2011-10-01' AND '2011-10-31';


-- Display ProductKey, EnglishProductName, Total OrderQuantity (caculate from OrderQuantity in Quarter 3 of 2013) of product sold in London for each Sales type ('Reseller' and 'Internet').
WITH CombinedSales AS
(
    SELECT
        ProductKey
        , OrderQuantity
        , SalesTerritoryKey
        , OrderDate
        , 'Internet' AS SalesType
    FROM FactInternetSales
    UNION ALL
    SELECT
        ProductKey
        , OrderQuantity
        , SalesTerritoryKey
        , OrderDate
        , 'Reseller' AS SalesType
    FROM FactResellerSales
)
, City AS (
    SELECT
    CombinedSales.*
    , DG.City
    , DP.EnglishProductName
    FROM CombinedSales
    JOIN DimGeography AS DG
    ON CombinedSales.SalesTerritoryKey = DG.SalesTerritoryKey
    JOIN DimProduct AS DP
    ON CombinedSales.ProductKey = DP.ProductKey
)
SELECT
    ProductKey
    , EnglishProductName
    , SalesType
    , SUM(OrderQuantity) AS TotalOrderQuantity
FROM City 
WHERE City = 'London'
AND YEAR(OrderDate) = 2013
AND MONTH(OrderDate) IN (7,8,9)
GROUP BY ProductKey, EnglishProductName, SalesType
ORDER BY ProductKey
;
-- From database, retrieve total SalesAmount monthly of internet_sales and reseller_sales.
SELECT
    MONTH(OrderDate) AS Month
    , YEAR(OrderDate) AS Year
    , SUM(CASE WHEN SalesType = 'Internet' THEN SalesAmount ELSE 0 END) AS Internet_SalesAmount
    , SUM(CASE WHEN SalesType = 'Reseller' THEN SalesAmount ELSE 0 END) AS Reseller_SalesAmount
FROM (
    SELECT
        OrderDate
        , 'Internet' AS SalesType
        , SalesAmount
    FROM FactInternetSales
    UNION ALL
    SELECT
        OrderDate
        , 'Reseller' AS SalesType
        , SalesAmount
    FROM FactResellerSales
) AS CombinedSales
GROUP BY
    YEAR(OrderDate)
    , MONTH(OrderDate)
ORDER BY
    Year
    , Month
;
-- Get list of 5 City with highest InternetSalesAmount in each country, each year.
WITH RankedSales AS
(
    SELECT
        DC.CustomerKey
        , DG.EnglishCountryRegionName AS Country
        , DG.City
        , YEAR(FIS.OrderDate) AS Year
        , FIS.SalesAmount AS InternetSalesAmount
        , ROW_NUMBER() OVER (PARTITION BY DG.EnglishCountryRegionName, YEAR(FIS.OrderDate) ORDER BY FIS.SalesAmount DESC) AS SalesAmountRankCountry
    FROM FactInternetSales AS FIS
    JOIN DimCustomer AS DC ON FIS.CustomerKey = DC.CustomerKey
    JOIN DimGeography AS DG ON DC.GeographyKey = DG.GeographyKey
)
SELECT
    Year
    , Country
    , City
    , InternetSalesAmount
    , SalesAmountRankCountry
FROM RankedSales
WHERE SalesAmountRankCountry <= 5
ORDER BY
    Year
    , Country
    , SalesAmountRankCountry;