
--How does sales performance vary across the product categories?
SELECT Prod_Category, Total_order, ROUND(Total_revenue/Total_order, 2) AS Average_order_value, Total_revenue 
FROM (
  SELECT(COUNT(DISTINCT SOH.SalesOrderID)) AS Total_order, SUM(LineTotal) AS Total_revenue,
     PC.Name AS Prod_Category
  FROM Sales.SalesOrderHeader SOH
  INNER JOIN Sales.SalesOrderDetail SOD
  ON SOH.SalesOrderID = SOD.SalesOrderID
  INNER JOIN Production.Product P
  ON P.ProductID = SOD.ProductID
  INNER JOIN Production.ProductSubcategory PSC 
  ON PSC.ProductSubcategoryID = P.ProductSubcategoryID
  INNER JOIN Production.ProductCategory pc 
  ON PC.ProductCategoryID = PSC.ProductCategoryID
  GROUP BY PC.Name) sub
ORDER BY Total_revenue DESC;

-- Are there any seasonal patterns or trends in Sales?
SELECT CONCAT(FORMAT(SOH.OrderDate, 'MMM'), ',', ' ',YEAR(SOH.OrderDate) ) AS Year_month,
       YEAR(SOH.OrderDate) AS OrderYear, 
       MONTH(SOH.OrderDate) AS OrderMonth,
       ROUND(SUM(SOD.LineTotal), 2) AS TotalSales
FROM Sales.SalesOrderHeader SOH
INNER JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY YEAR(SOH.OrderDate), MONTH(SOH.OrderDate), CONCAT(FORMAT(SOH.OrderDate, 'MMM'), ',', ' ',YEAR(OrderDate) )
ORDER BY OrderYear, OrderMonth;

--Which sales representatives have the highest sales performance?
SELECT BusinessEntityID, SalesQuota, 
    ROUND(SUM(SalesYTD),2) AS total_sales, (SUM(SalesYTD)/SalesQuota * 100) AS perc_ratio
FROM Sales.SalesPerson
GROUP BY BusinessEntityID, SalesQuota
ORDER BY total_sales DESC;

--Are there opportunities for cross-selling or upselling?
WITH Cte AS (
  SELECT 
      P.Name AS BaseProduct,
      P2.Name AS AssociatedProduct,
      COUNT(*) AS PurchaseCount,
      RANK() OVER(PARTITION BY COUNT(*) ORDER BY p.Name) AS Rnk1
  FROM Sales.SalesOrderDetail AS SOD
  INNER JOIN
  Production.Product AS P ON SOD.ProductID = P.ProductID
  INNER JOIN
  Sales.SalesOrderDetail AS SOD2 ON SOD.SalesOrderID = SOD2.SalesOrderID
  INNER JOIN
  Production.Product AS P2 ON SOD2.ProductID = P2.ProductID
  WHERE SOD.ProductID <> SOD2.ProductID
  GROUP BY p.Name, p2.Name )
SELECT TOP 10 BaseProduct, AssociatedProduct, PurchaseCount
FROM Cte
WHERE Rnk1 = 1
ORDER BY PurchaseCount DESC;

--Which products have the highest sales volume or units sold
SELECT TOP 10 P.Name, SUM(SOD.Orderqty)Qty_sold_per_product
FROM Production.Product P
INNER JOIN Sales.SalesOrderDetail SOD
ON P.ProductID =SOD.ProductID
GROUP BY P.Name
ORDER BY Qty_sold_per_product DESC;

--Which region generated the highest revenue?
SELECT ST.[Group] AS Region, SUM(SOH.Totaldue) AS Total_sales
FROM Sales.SalesTerritory ST
INNER JOIN Sales.SalesOrderHeader SOH
ON ST.TerritoryID = SOH.TerritoryID
GROUP BY ST.[Group]
ORDER BY total_sales DESC;

--Are there any differences in purchasing behavior between territories
SELECT ST.TerritoryID, CONCAT(ST.Name, ',', ' ', ST.CountryRegionCode) AS Territories,
  (SUM(SOH.TotalDue)/SUM(SOD.OrderQty)) AS AverageOrderValue,
  COUNT( DISTINCT SOH.CustomerID) AS UniqueCust,
  COUNT(DISTINCT SOD.ProductID) AS Uniqueprod,
  COUNT(DISTINCT SOH.SalesOrderID) AS No_oforders,
  SUM(SOH.TotalDue) AS Totalsales
FROM Sales.SalesTerritory ST
INNER JOIN Sales.SalesOrderHeader SOH
ON ST.TerritoryID = SOH.TerritoryID
INNER JOIN Sales.SalesOrderDetail SOD
ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY ST.TerritoryID, CONCAT(ST.Name, ',', ' ', ST.CountryRegionCode)
ORDER BY Totalsales DESC;

--Product popularity across regions
SELECT REGION, PRODUCT, productfreq, Rank1
FROM (
  SELECT ST.Name AS Region, PP.Name AS Product, 
  COUNT(SOD.ProductID) AS Productfreq, 
  RANK() OVER(PARTITION BY ST.Name ORDER BY COUNT(SOD.ProductID) DESC) AS Rank1
  FROM Sales.SalesOrderDetail SOD
  INNER JOIN Production.Product PP
  ON SOD.ProductID = PP.ProductID
  INNER JOIN Sales.SalesOrderHeader SOH
  ON SOD.SalesOrderID = SOH.SalesOrderID
  INNER JOIN sales.SalesTerritory ST
  ON SOH.TerritoryID = st.TerritoryID
  GROUP BY ST.Name, PP.Name ) SUB
WHERE Rank1 = 1

--Who are the top spending Customers?
SELECT TOP 5 CONCAT(PP.Title, ' ', PP.Firstname , ' ', PP.Lastname) AS Cust_Name, 
    CAST(SUM(Totaldue) AS INT) AS Total_sales,
       COUNT(SOH.SalesOrderID) AS Total_quat, COUNT(Productid) AS Total_prod
FROM Sales.SalesOrderHeader SOH
INNER JOIN Sales.SalesOrderDetail SOD
ON SOH.SalesOrderID = SOD.SalesOrderID
INNER JOIN Sales.Customer SC
ON SC.CustomerID =SOH.CustomerID
INNER JOIN Person.Person PP
ON PP.BusinessEntityID = SC.PersonID
GROUP BY SOH.Customerid, CONCAT(PP.Title, ' ', PP.FirstName , ' ', PP.LastName)
ORDER BY  Total_sales DESC;

--Most Common Sales Channel
WITH Channel AS (
   SELECT CASE WHEN OnlineOrderFlag = '0' THEN 'In Person' ELSE 'Online' END AS Sales_channel
   FROM Sales.SalesOrderHeader)
SELECT  Sales_channel, COUNT( SalesOrderID) AS No_of_sales
FROM Channel
GROUP BY Sales_channel

--Most profitable products
SELECT TOP 10 P.Name AS ProductName, 
    SUM(SOD.LineTotal) AS TotalSales, 
    SUM(SOD.LineTotal - (SOD.OrderQty * P.StandardCost)) AS TotalProfit,
    (SUM(SOD.LineTotal - (SOD.OrderQty * P.StandardCost)) / SUM(SOD.LineTotal)) * 100 AS ProfitMargin
FROM Sales.SalesOrderDetail SOD
INNER JOIN Production.Product P ON SOD.ProductID = P.ProductID
GROUP BY P.Name
ORDER BY ProfitMargin DESC

--Overall sales performance through the years
SELECT YEAR(OrderDate) AS Saleyear, SUM(TotalDue) AS Total_sales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY Saleyear