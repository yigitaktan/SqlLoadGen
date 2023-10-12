USE [master]
Go

IF DATABASEPROPERTYEX (N'DemoDB', N'Version') > 0
BEGIN
    ALTER DATABASE [DemoDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DemoDB];
END
GO

CREATE DATABASE [DemoDB];
GO

USE [DemoDB];
GO

-- Creating Users Table
CREATE TABLE dbo.Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Age INT
);
GO

-- Creating Addresses Table
CREATE TABLE dbo.Addresses (
    AddressID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT FOREIGN KEY REFERENCES dbo.Users(UserID),
    City NVARCHAR(50),
    PostalCode NVARCHAR(20)
);
GO

-- Creating Orders Table
CREATE TABLE dbo.Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT FOREIGN KEY REFERENCES dbo.Users(UserID),
    OrderDate DATE
);
GO

-- Creating ProductCategories Table
CREATE TABLE dbo.ProductCategories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100)
);
GO

-- Inserting sample data into ProductCategories
INSERT INTO dbo.ProductCategories (CategoryName)
VALUES ('Electronics'), ('Clothing'), ('Home Goods');
GO

-- Creating Products Table
CREATE TABLE dbo.Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100),
    CategoryID INT FOREIGN KEY REFERENCES dbo.ProductCategories(CategoryID),
    Price DECIMAL(10,2)
);
GO

-- Creating OrderDetails Table
CREATE TABLE dbo.OrderDetails (
    OrderDetailID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT FOREIGN KEY REFERENCES dbo.Orders(OrderID),
    ProductName NVARCHAR(100),
    Quantity INT,
    ProductID INT FOREIGN KEY REFERENCES dbo.Products(ProductID)
);
GO

-- Inserting sample data into Products
INSERT INTO dbo.Products (ProductName, CategoryID, Price)
VALUES ('Laptop', 1, 1000.00), ('Shirt', 2, 20.00), ('Toaster', 3, 30.00);

DECLARE @i INT = 1;

-- Inserting sample data into Users
WHILE @i <= 3000
BEGIN;
    INSERT INTO dbo.Users (FirstName, LastName, Age)
    VALUES ('Name' + CAST(@i AS NVARCHAR(50)), 'Surname' + CAST(@i AS NVARCHAR(50)), (RAND() * 40) + 20);

    SET @i = @i + 1;
END;

SET @i = 1;

-- Inserting sample data into Addresses
WHILE @i <= 3000
BEGIN;
    INSERT INTO dbo.Addresses (UserID, City, PostalCode)
    VALUES (@i, 'City' + CAST(@i AS NVARCHAR(50)), CAST((RAND() * 89999) + 10000 AS NVARCHAR(20)));

    SET @i = @i + 1;
END;

SET @i = 1;

-- Inserting sample data into Orders
WHILE @i <= 3000
BEGIN;
    INSERT INTO dbo.Orders (UserID, OrderDate)
    VALUES (@i, DATEADD(DAY, (RAND() * 365), '2022-01-01'));

    SET @i = @i + 1;
END;

SET @i = 1;

-- Inserting sample data into ProductCategories
INSERT INTO dbo.ProductCategories (CategoryName)
VALUES ('Electronics'), ('Clothing'), ('Home Goods');

-- Inserting sample data into Products
INSERT INTO dbo.Products (ProductName, CategoryID, Price) 
VALUES ('Laptop', 1, 1700.00), ('Shirt', 2, 20.00), ('Toaster', 3, 30.00);

SET @i = 1;

-- Inserting sample data into OrderDetails
WHILE @i <= 1000
BEGIN;
    DECLARE @ProductID INT;
    DECLARE @ProductName NVARCHAR(100);
    
    SELECT TOP 1 @ProductID = ProductID, @ProductName = ProductName
    FROM dbo.Products
    ORDER BY NEWID();
    
    INSERT INTO dbo.OrderDetails (OrderID, ProductID, ProductName, Quantity)
    VALUES (@i, @ProductID, @ProductName, CAST((RAND() * 100) + 1 AS INT));

    SET @i = @i + 1;
END;
GO

-- Adds a new user along with their address information into the Users and Addresses tables respectively.
CREATE PROCEDURE dbo.sp_AddUserAndAddress
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Age INT,
    @City NVARCHAR(50),
    @PostalCode NVARCHAR(20)
AS
BEGIN;  
    DECLARE @UserID INT;

    INSERT INTO dbo.Users (FirstName, LastName, Age)
    VALUES (@FirstName, @LastName, @Age);

    SET @UserID = SCOPE_IDENTITY(); 

    INSERT INTO dbo.Addresses (UserID, City, PostalCode)
    VALUES (@UserID, @City, @PostalCode);
END;
GO

-- Updates the information of an existing user in the Users table.
CREATE PROCEDURE dbo.sp_UpdateUser
    @UserID INT,
    @NewFirstName NVARCHAR(50),
    @NewLastName NVARCHAR(50),
    @NewAge INT
AS
BEGIN;  
    UPDATE dbo.Users
    SET 
        FirstName = @NewFirstName,
        LastName = @NewLastName,
        Age = @NewAge
    WHERE UserID = @UserID;
END;
GO

-- Deletes a user and their related address information from the Users and Addresses tables respectively.
CREATE PROCEDURE sp_DeleteUser
    @UserID INT
AS
BEGIN;
    DELETE FROM OrderDetails
    WHERE OrderID IN (SELECT OrderID FROM Orders WHERE UserID = @UserID);

    DELETE FROM Orders
    WHERE UserID = @UserID;

    DELETE FROM Addresses
    WHERE UserID = @UserID;

    DELETE FROM Users
    WHERE UserID = @UserID;
END;
GO

-- Adds a new order for a user into the Orders table.
CREATE PROCEDURE dbo.sp_AddOrder
    @UserID INT,
    @OrderDate DATE
AS
BEGIN;   
    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @UserID)
    BEGIN;
        THROW 50000, 'UserID does not exist in the Users table.', 1;
        RETURN;
    END;
    
    INSERT INTO dbo.Orders (UserID, OrderDate)
    VALUES (@UserID, @OrderDate);
END;
GO

-- Adds a new order detail into the OrderDetails table.
CREATE PROCEDURE dbo.sp_AddOrderDetail
    @OrderID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN;
    IF NOT EXISTS (SELECT 1 FROM dbo.Orders WHERE OrderID = @OrderID)
    BEGIN;
        THROW 50000, 'OrderID does not exist in the Orders table.', 1;
        RETURN;
    END;
    
    IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = @ProductID)
    BEGIN;
        THROW 50000, 'ProductID does not exist in the Products table.', 1;
        RETURN;
    END;
    
    INSERT INTO dbo.OrderDetails (OrderID, ProductID, Quantity)
    VALUES (@OrderID, @ProductID, @Quantity);
END;
GO

-- Retrieves all users from the Users table.
CREATE PROCEDURE dbo.sp_GetAllUsers
AS
BEGIN;
    SELECT FirstName, LastName, Age
    FROM dbo.Users WITH(NOLOCK);
END;
GO

-- Retrieves all orders for a specific user from the Orders table.
CREATE PROCEDURE dbo.sp_GetOrdersByUser
    @UserID INT
AS
BEGIN;
    SELECT OrderID, UserID, OrderDate
    FROM dbo.Orders WITH(NOLOCK)
    WHERE UserID = @UserID;
END;
GO

-- Retrieves all order details for a specific order from the OrderDetails table.
CREATE PROCEDURE dbo.sp_GetOrderDetails
    @OrderID INT
AS
BEGIN;
    SELECT OrderID, ProductName, Quantity
    FROM dbo.OrderDetails 
    WHERE OrderID = @OrderID;
END;
GO

-- Adds a new product into the Products table.
CREATE PROCEDURE sp_AddProduct
    @ProductName NVARCHAR(100),
    @CategoryID INT,
    @Price DECIMAL(10,2)
AS
BEGIN;
    IF NOT EXISTS (SELECT 1 FROM ProductCategories WHERE CategoryID = @CategoryID)
    BEGIN;
        THROW 50000, 'CategoryID does not exist in the ProductCategories table.', 1;
        RETURN;
    END;
    
    INSERT INTO Products (ProductName, CategoryID, Price)
    VALUES (@ProductName, @CategoryID, @Price);
END;
GO

-- Updates the information of an existing product in the Products table.
CREATE PROCEDURE sp_UpdateProduct
    @ProductID INT,
    @NewProductName NVARCHAR(100),
    @NewCategoryID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN;  
    UPDATE Products
    SET 
        ProductName = @NewProductName,
        CategoryID = @NewCategoryID,
        Price = @NewPrice
    WHERE ProductID = @ProductID;
END;
GO

-- Deletes a product from the Products table.
CREATE PROCEDURE sp_DeleteProduct
    @ProductID INT
AS
BEGIN;
    IF EXISTS (SELECT 1 FROM dbo.OrderDetails WHERE ProductID = @ProductID)
    BEGIN;
        DELETE FROM dbo.OrderDetails 
        WHERE ProductID = @ProductID;
    END;
    
    DELETE FROM dbo.Products 
    WHERE ProductID = @ProductID;
END;
GO

-- Retrieves all products from a specific category from the Products table.
CREATE PROCEDURE sp_GetProductsByCategory
    @CategoryID INT
AS
BEGIN;
    SELECT ProductName, Price
    FROM Products
    WHERE CategoryID = @CategoryID;
END;
GO

-- Retrieves all product categories.
CREATE PROCEDURE sp_GetProductCategories
AS
BEGIN;
    SELECT CategoryName 
    FROM ProductCategories WITH(NOLOCK);
END;
GO

USE [master]
GO

-- Check if the login already exists
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'MyDemoUser')
BEGIN;
    -- Drop the login if it exists
    DROP LOGIN MyDemoUser;
END;

-- Create the login
CREATE LOGIN MyDemoUser WITH PASSWORD = 'Password.1';
GO

USE [DemoDB]
GO

-- Check if the user already exists
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'MyDemoUser')
BEGIN;
    -- Drop the user if it exists
    DROP USER MyDemoUser;
END;

-- Create the user
CREATE USER MyDemoUser FOR LOGIN MyDemoUser;
GO

-- Granting execute permissions on stored procedures to the user
GRANT EXECUTE ON dbo.sp_AddUserAndAddress TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_UpdateUser TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_DeleteUser TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_AddOrder TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_AddOrderDetail TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_GetAllUsers TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_GetOrdersByUser TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_GetOrderDetails TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_AddProduct TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_UpdateProduct TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_DeleteProduct TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_GetProductsByCategory TO MyDemoUser;
GRANT EXECUTE ON dbo.sp_GetProductCategories TO MyDemoUser;
GO
