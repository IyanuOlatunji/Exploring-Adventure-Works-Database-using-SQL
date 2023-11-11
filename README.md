# Exploring-Adventure-Works-Database-using-SQL

### Project Overview
In a bid to hone my SQL skills and addressing business challenges, I embarked on an exploration of the Adventure Works database. The AdventureWorks database, created by Microsoft revolves around a fictional company called Adventureworks Cycle, which represents a multinational manufacturing company on a large scale. The Adventure Works database encompasses approximately 71 tables, along with various views, stored procedures, User-Defined Functions, and a diverse range of data types and it is being updated as new versions are released.
The aim of this project is to discover valuable insights regarding sales patterns, factors influencing sales performance, and customer purchasing behavior across diverse regions. These insights will serve as a foundation for enhancing sales strategies and driving improvements in overall sales performance.
SQL was used in the cleaning and analysis. 
You can access the full documentation here

### SQL Queries
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
