--*************************************************************************--
-- Title: Assignment06
-- Author: LThurgood
-- Desc: This file demonstrates how to use Views
-- Change Log: When,Who,What
-- 2026-05-27,LThurgood,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_LThurgood')
	 Begin 
	  Alter Database [Assignment06DB_LThurgood] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_LThurgood;
	 End
	Create Database Assignment06DB_LThurgood;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_LThurgood;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [mOney] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10 -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, UnitsInStock + 20 -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From Categories;
go
Select * From Products;
go
Select * From Employees;
go
Select * From Inventories;
go

/********************************* Questions and Answers *********************************/
print 
'NOTES------------------------------------------------------------------------------------ 
 1) You can use any name you like for you views, but be descriptive and consistent
 2) You can use your working code from assignment 5 for much of this assignment
 3) You must use the BASIC views for each table after they are created in Question 1
------------------------------------------------------------------------------------------'

-- Question 1 (5% pts): How can you create BACIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!

/*
-- One view per table. Spell out the columns instead of using *, and throw SCHEMABINDING on
-- each one so nobody can change the table out from under the view.
*/

GO
CREATE VIEW dbo.vCategories WITH SCHEMABINDING AS
 SELECT CategoryID, CategoryName
  FROM dbo.Categories;
GO

CREATE VIEW dbo.vProducts WITH SCHEMABINDING AS
 SELECT ProductID, ProductName, CategoryID, UnitPrice
  FROM dbo.Products;
GO

CREATE VIEW dbo.vEmployees WITH SCHEMABINDING AS
 SELECT EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID
  FROM dbo.Employees;
GO

CREATE VIEW dbo.vInventories WITH SCHEMABINDING AS
 SELECT InventoryID, InventoryDate, EmployeeID, ProductID, [Count]
  FROM dbo.Inventories;
GO

-- Question 2 (5% pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?

/*
-- Lock public out of the tables with DENY, then GRANT them access to the views.
-- DENY beats GRANT, so the tables stay locked no matter what.
*/

GO
DENY  SELECT ON dbo.Categories  TO Public;
DENY  SELECT ON dbo.Products    TO Public;
DENY  SELECT ON dbo.Employees   TO Public;
DENY  SELECT ON dbo.Inventories TO Public;

GRANT SELECT ON dbo.vCategories  TO Public;
GRANT SELECT ON dbo.vProducts    TO Public;
GRANT SELECT ON dbo.vEmployees   TO Public;
GRANT SELECT ON dbo.vInventories TO Public;
GO

-- Question 3 (10% pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!

/*
-- Same join from Module 5 Q1, just pointing at the BASIC views this time.
SELECT C.CategoryName, P.ProductName, P.UnitPrice
 FROM dbo.vCategories AS C
 JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
 ORDER BY C.CategoryName, P.ProductName;
-- Wrap it up as a view. TOP is in there because ORDER BY isn't allowed in a view without it.
*/

GO
CREATE VIEW dbo.vProductsByCategories WITH SCHEMABINDING AS
 SELECT TOP (1000000)
   C.CategoryName,
   P.ProductName,
   P.UnitPrice
  FROM dbo.vCategories AS C
  JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
  ORDER BY C.CategoryName, P.ProductName;
GO

-- Question 4 (10% pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!

/*
-- Module 5 Q2, swapped to BASIC views.
SELECT P.ProductName, I.InventoryDate, I.[Count]
 FROM dbo.vProducts AS P
 JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
 ORDER BY P.ProductName, I.InventoryDate, I.[Count];
-- Wrap as a view.
*/

GO
CREATE VIEW dbo.vInventoriesByProductsByDates WITH SCHEMABINDING AS
 SELECT TOP (1000000)
   P.ProductName,
   I.InventoryDate,
   I.[Count]
  FROM dbo.vProducts AS P
  JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
  ORDER BY P.ProductName, I.InventoryDate, I.[Count];
GO

-- Question 5 (10% pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!

-- Here is are the rows selected from the view:

-- InventoryDate	EmployeeName
-- 2017-01-01	    Steven Buchanan
-- 2017-02-01	    Robert King
-- 2017-03-01	    Anne Dodsworth

/*
-- Module 5 Q3 but using DISTINCT this time (M5 grading note mentioned to try DISTINCT).
-- Names get concatenated into one EmployeeName column to match the result table above.
SELECT DISTINCT I.InventoryDate,
       [EmployeeName] = E.EmployeeFirstName + ' ' + E.EmployeeLastName
 FROM dbo.vInventories AS I
 JOIN dbo.vEmployees AS E ON I.EmployeeID = E.EmployeeID
 ORDER BY I.InventoryDate;
-- Wrap as a view.
*/

GO
CREATE VIEW dbo.vInventoriesByEmployeesByDates WITH SCHEMABINDING AS
 SELECT DISTINCT TOP (1000000)
   I.InventoryDate,
   [EmployeeName] = E.EmployeeFirstName + ' ' + E.EmployeeLastName
  FROM dbo.vInventories AS I
  JOIN dbo.vEmployees AS E ON I.EmployeeID = E.EmployeeID
  ORDER BY I.InventoryDate;
GO

-- Question 6 (10% pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!

/*
-- Module 5 Q4, swapped to BASIC views. Three-way join across Categories, Products, Inventories.
SELECT C.CategoryName, P.ProductName, I.InventoryDate, I.[Count]
 FROM dbo.vCategories AS C
 JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
 JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
 ORDER BY C.CategoryName, P.ProductName, I.InventoryDate, I.[Count];
-- Wrap as a view.
*/

GO
CREATE VIEW dbo.vInventoriesByProductsByCategories WITH SCHEMABINDING AS
 SELECT TOP (1000000)
   C.CategoryName,
   P.ProductName,
   I.InventoryDate,
   I.[Count]
  FROM dbo.vCategories AS C
  JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
  JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
  ORDER BY C.CategoryName, P.ProductName, I.InventoryDate, I.[Count];
GO

-- Question 7 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!

/*
-- Module 5 Q5 on BASIC views. Adds the Employees view and keeps EmployeeName concatenated.
SELECT C.CategoryName, P.ProductName, I.InventoryDate, I.[Count],
       [EmployeeName] = E.EmployeeFirstName + ' ' + E.EmployeeLastName
 FROM dbo.vCategories AS C
 JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
 JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
 JOIN dbo.vEmployees AS E ON I.EmployeeID = E.EmployeeID
 ORDER BY I.InventoryDate, C.CategoryName, P.ProductName, EmployeeName;
-- Wrap as a view.
*/

GO
CREATE VIEW dbo.vInventoriesByProductsByEmployees WITH SCHEMABINDING AS
 SELECT TOP (1000000)
   C.CategoryName,
   P.ProductName,
   I.InventoryDate,
   I.[Count],
   [EmployeeName] = E.EmployeeFirstName + ' ' + E.EmployeeLastName
  FROM dbo.vCategories AS C
  JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
  JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
  JOIN dbo.vEmployees AS E ON I.EmployeeID = E.EmployeeID
  ORDER BY I.InventoryDate, C.CategoryName, P.ProductName, [EmployeeName];
GO

-- Question 8 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 

/*
-- Same as Q7 but filter down to just Chai and Chang. Module 5 used a subquery to look up
-- the ProductIDs by name, doing the same thing here.
SELECT C.CategoryName, P.ProductName, I.InventoryDate, I.[Count],
       [EmployeeName] = E.EmployeeFirstName + ' ' + E.EmployeeLastName
 FROM dbo.vCategories AS C
 JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
 JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
 JOIN dbo.vEmployees AS E ON I.EmployeeID = E.EmployeeID
 WHERE P.ProductID IN (SELECT ProductID FROM dbo.vProducts WHERE ProductName IN ('Chai', 'Chang'))
 ORDER BY I.InventoryDate, C.CategoryName, P.ProductName;
-- Wrap as a view.
*/

GO
CREATE VIEW dbo.vInventoriesForChaiAndChangByEmployees WITH SCHEMABINDING AS
 SELECT TOP (1000000)
   C.CategoryName,
   P.ProductName,
   I.InventoryDate,
   I.[Count],
   [EmployeeName] = E.EmployeeFirstName + ' ' + E.EmployeeLastName
  FROM dbo.vCategories AS C
  JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
  JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
  JOIN dbo.vEmployees AS E ON I.EmployeeID = E.EmployeeID
  WHERE P.ProductID IN (SELECT ProductID FROM dbo.vProducts WHERE ProductName IN ('Chai', 'Chang'))
  ORDER BY I.InventoryDate, C.CategoryName, P.ProductName;
GO

-- Question 9 (10% pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!

/*
-- Module 5 Q7 self-join, now on the BASIC vEmployees view.
-- Two aliases (Emp and Mgr) so we can join the same view to itself.
SELECT [Manager]  = Mgr.EmployeeFirstName + ' ' + Mgr.EmployeeLastName,
       [Employee] = Emp.EmployeeFirstName + ' ' + Emp.EmployeeLastName
 FROM dbo.vEmployees AS Emp
 JOIN dbo.vEmployees AS Mgr ON Emp.ManagerID = Mgr.EmployeeID
 ORDER BY Manager, Employee;
-- Wrap as a view.
*/

GO
CREATE VIEW dbo.vEmployeesByManager WITH SCHEMABINDING AS
 SELECT TOP (1000000)
   [Manager]  = Mgr.EmployeeFirstName + ' ' + Mgr.EmployeeLastName,
   [Employee] = Emp.EmployeeFirstName + ' ' + Emp.EmployeeLastName
  FROM dbo.vEmployees AS Emp
  JOIN dbo.vEmployees AS Mgr ON Emp.ManagerID = Mgr.EmployeeID
  ORDER BY [Manager], [Employee];
GO

-- Question 10 (20% pts): How can you create one view to show all the data from all four 
-- BASIC Views? Also show the Employee's Manager Name and order the data by 
-- Category, Product, InventoryID, and Employee.

/*
-- The big one :p. Pull everything from all four BASIC views, then self-join vEmployees one more
-- time to grab the manager's name on top.
*/

GO
CREATE VIEW dbo.vInventoriesByProductsByCategoriesByEmployees WITH SCHEMABINDING AS
 SELECT TOP (1000000)
   C.CategoryID,
   C.CategoryName,
   P.ProductID,
   P.ProductName,
   P.UnitPrice,
   I.InventoryID,
   I.InventoryDate,
   I.[Count],
   Emp.EmployeeID,
   [EmployeeName] = Emp.EmployeeFirstName + ' ' + Emp.EmployeeLastName,
   [ManagerName]  = Mgr.EmployeeFirstName + ' ' + Mgr.EmployeeLastName
  FROM dbo.vCategories AS C
  JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
  JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
  JOIN dbo.vEmployees AS Emp ON I.EmployeeID = Emp.EmployeeID
  JOIN dbo.vEmployees AS Mgr ON Emp.ManagerID = Mgr.EmployeeID
  ORDER BY C.CategoryName, P.ProductName, I.InventoryID, [EmployeeName];
GO

/***************************************************************************************/

-- Test your Views (NOTE: You must change the your view names to match what I have below!)
Print 'Note: You will get an error until the views are created!'
Select * From [dbo].[vCategories]
Select * From [dbo].[vProducts]
Select * From [dbo].[vInventories]
Select * From [dbo].[vEmployees]

Select * From [dbo].[vProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByDates]
Select * From [dbo].[vInventoriesByEmployeesByDates]
Select * From [dbo].[vInventoriesByProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByEmployees]
Select * From [dbo].[vInventoriesForChaiAndChangByEmployees]
Select * From [dbo].[vEmployeesByManager]
Select * From [dbo].[vInventoriesByProductsByCategoriesByEmployees]

/***************************************************************************************/