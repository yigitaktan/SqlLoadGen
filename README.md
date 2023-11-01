# SQL Load Generator

* **[Getting started with the script](#getting-started-with-the-script)**
* **[Script components](#script-components)**
* **[Preparing the config.txt file](#preparing-the-configtxt-file)**
* **[Preparing the SP file](#preparing-the-sp-file)**
* **[Random value generations](#random-value-generations)**
* **[Running the script](#running-the-script)**
* **[Encoding requirement](#encoding-requirement)**
* **[Creating the test environment](#creating-the-test-environment)**


## Getting started with the script
You can effortlessly create load in your SQL environments by utilizing the Stored Procedures (SPs) and parameters that are actively used in your real-world scenarios. You have the capability to configure the duration for which the load should be generated, specify the parameters to be employed during the execution of the SPs, and determine the number of parallel connections to be established for executing these SPs. Consequently, you can simulate a load identical to that in your production environment, with the options of your choosing.

## Script components
The codebase of the script consists of two files: `sql-load-gen.ps1` and `functions.psm1`. Additionally, for the script to run, `config.txt` and a file containing your Stored Procedures (SPs) are required.

* **[sql-load-gen.ps1](https://github.com/yigitaktan/SqlLoadGen/blob/main/sql-load-gen.ps1):** The primary script. The execution of the SPs is carried out within this file.
* **[functions.psm1](https://github.com/yigitaktan/SqlLoadGen/blob/main/functions.psm1):** All functions used in the `sql-load-gen.ps1` file are stored in this file, and the script cannot run without it.
* **[config.txt](https://github.com/yigitaktan/SqlLoadGen/blob/main/config.txt):** This file defines the SQL Server connection details and the conditions under which the SPs will be executed.
* **[sp.txt](https://github.com/yigitaktan/SqlLoadGen/blob/main/sp.txt):** This file specifies the SPs to be executed, along with their parameters if any. The file can have any name, but the chosen name must be specified in the `config.txt` file.

All four of the files mentioned above should be located within the same folder.

## Preparing the config.txt file
The **`config.txt`** file consists of 9 parameters: `AuthenticationType`, `ServerName`, `DatabaseName`, `UserName`, `Password`, `ParallelConnections`, `ExecutionTimeLimit`, `SpFile`, and `RandomExecute`.

* **[AuthenticationType]**: Specifies the type of authentication you will use to connect to the SQL Server. Only two values should be entered: either "**WIN**" or "**SQL**". If "**WIN**" is entered, it indicates connecting with Windows Authentication; if "**SQL**" is entered, it indicates connecting with SQL Server Authentication.
  
* **[ServerName]**: Define the instance you will connect to here. If it's the default instance, enter in the form of **SERVERNAME**; if it's a named instance, enter as **SERVERNAME/INSTANCENAME**.
  
* **[DatabaseName]**: Enter the name of the database where you will generate the load.
  
* **[UserName]**: If "**SQL**" is entered for the `AuthenticationType` parameter, the `UserName` parameter must definitely be filled out. The user with which the connection will be established is determined in this parameter.
  
* **[Password]**: Similar to the `UserName` parameter, if your `AuthenticationType` is "**SQL**", define the password for the entered username in this parameter.
  
* **[ParallelConnections]**: Determines how many different parallel connections will be used to execute the SPs. Only a number should be entered for this parameter.
  
* **[ExecutionTimeLimit]**: Define in this parameter how long the load you will create, measured in seconds, should last.
  
* **[SpFile]**: Write the name of the file, which contains the SPs to be executed, in this parameter.
  
* **[RandomExecute]**: Specify in this parameter whether you want the SPs to be executed in the order written in the file or executed randomly. If you want them to be executed in the same order, write "**0**"; if you want them to be executed randomly, write "**1**". Values other than 0 or 1 are not accepted.


If `AuthenticationType` is specified as "**SQL**", all the parameters mentioned above must be written in the `config.txt` file. If it is specified as "**WIN**", the `UserName` and `Password` parameters are not required. If `AuthenticationType` is specified as "**WIN**" and the `UserName` and `Password` parameters are still set to specific values in the file, these two parameters will be skipped, and whether or not they have any values will not affect the operation of the script.


The name of the configuration file must be **`config.txt`**. The previously mentioned 9 parameters should be written inside square brackets and then assigned their respective values. Below is an example of how a config.txt file should be written.

<pre>
[AuthenticationType]=SQL
[ServerName]=DBPROD01\SQL2019
[DatabaseName]=DemoDB
[UserName]=MyDemoUser
[Password]=Password.1
[ParallelConnections]=20
[ExecutionTimeLimit]=300
[SpFile]=sp.txt
[RandomExecute]=1
</pre>

## Preparing the SP file
In its current version, SQL Load Generator only executes Stored Procedures (SPs). Support for executing Ad-Hoc queries will be provided in upcoming versions.

The SP file must be prepared in a specific format. Each SP should be written one per line. The most crucial writing style to pay attention to is the format for SPs with parameters. If there is a parametric SP, parameter names should be separated from other parameters and the SP name with a semicolon "**;**". The writing format for a parametric SP should be as follows.

<pre>Schema_Name.Sp_Name;@Parameter1=ParameterValue;@Parameter2=ParameterValue</pre>

To better understand the above example, let's examine the sp_UpdateProduct SP.

<pre>
CREATE PROCEDURE sp_UpdateProduct
    @ProductID INT,
    @NewProductName NVARCHAR(100),
    @NewCategoryID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN  
    UPDATE Products
    SET 
        ProductName = @NewProductName,
        CategoryID = @NewCategoryID,
        Price = @NewPrice
    WHERE ProductID = @ProductID;
END;
</pre>

The above SP takes 4 different parameters: ProductID, NewProductName, NewCategoryID, and NewPrice. To execute this SP in SSMS, you would do it as follows.

<pre>EXEC dbo.sp_UpdateProduct @ProductID = 2, @NewProductName = 'Winter Jacket', @NewCategoryID = 2, @NewPrice = 120.00</pre>

Adapting the above usage to the SP file is as follows.

<pre>dbo.sp_UpdateProduct;@ProductID=2;@NewProductName=Winter Jacket;@NewCategoryID=2;@NewPrice=120.00</pre>

For SPs that do not take parameters, the usage should be in the form of Schema_Name.Sp_Name. The sp_GetProductCategories SP can be examined below.

<pre>
CREATE PROCEDURE sp_GetProductCategories
AS
BEGIN
    SELECT CategoryName FROM ProductCategories WITH(NOLOCK);
END;
</pre>

The usage of the sp_GetProductCategories SP within the SP file should be as follows.

<pre>dbo.sp_GetProductCategories</pre>

You can create an SP file by writing the above 2 examples one under the other.

<pre>
dbo.sp_UpdateProduct;@ProductID=2;@NewProductName=Winter Jacket;@NewCategoryID=2;@NewPrice=120.00
dbo.sp_GetProductCategories
</pre>

## Random value generations
You might want to generate random parameter values for SPs that take parameters. There are 3 different usage types for this, and you can examine the usages below.

* **rnd-number**: This function is used to generate a random number. Its usage is `{rnd-number:How_Many_Digits_Long,Which_Numbers_to_Choose_From}`. In the example below, there is a usage form to generate a 3-digit number from among the numbers 0123456789.
  <pre>{rnd-number:3,0123456789}</pre>

* **rnd-text**: This function is used to generate letters of the specified character length. Its usage is `{rnd-text:How_Many_Characters_Long,Which_Letters_to_Choose_From}`. In the example below, there is an example of generating random text from among the letters abcdefghijklmo, 7 characters in length.
  <pre>{rnd-text:7,abcdefghijklmo}</pre>

* **rnd-date**: This function generates data in the "**yyyy-MM-dd**" format. It has 2 parameters, both are year parameters. The start and end year are written, and the desired date is generated from among the specified years. Its usage is `{rnd-date:Start_Year-End_Year}`. In the example below, a date is being generated between the years 2013 and 2023.
  <pre>{rnd-date:2013-2023}</pre>

To give examples of the usage of these 3 functions, an example can be created as follows.

<pre>
dbo.sp_DeleteUser;@UserID={rnd-number:3,123456789}
dbo.sp_AddOrder;@UserID={rnd-number:5,12345};@OrderDate={rnd-date:2013-2023}
dbo.sp_AddProduct;@ProductName={rnd-text:10,abcdefghijklmnopqrstuvwxyz};@CategoryID=2;@Price={rnd-number:3,123456789}
</pre>

## Running the script
The script can be easily run by opening a command prompt. There is no need to open the console with a user that has administrator privileges. All you need to do is place the necessary files mentioned above into a single folder and run the following command.

<pre>powershell.exe -File .\sql-load-gen.ps1</pre>

![console-run2](https://github.com/yigitaktan/SqlLoadGen/assets/51110247/65b7d3ad-5c00-4921-9b47-2df4e285299f)

If the parameters in the `config.txt` file are not written as they should be, it will generate a detailed, informative error message.

![console-error2](https://github.com/yigitaktan/SqlLoadGen/assets/51110247/e8e1a59b-66c5-492f-adec-f7a87e5ae594)

As the script starts running and executing the SPs, you can track the elapsed time through the countdown and progress bar on the console screen.

![console-progress2](https://github.com/yigitaktan/SqlLoadGen/assets/51110247/aea791de-0b2f-4f65-9c0f-4b07e01405c9)

When the script completes the duration specified in `config.txt`, the word "**Completed**" appears on the screen. Additionally, it reports how many of the executed SPs were successful and how many failed.

![console-completed2](https://github.com/yigitaktan/SqlLoadGen/assets/51110247/ebc9b877-7735-474b-8be6-25469a84bca4)

If there are any errors encountered during the execution of the SPs, it logs the details of each error by creating an error log file named `errlog.txt`. This log file is created in the same folder as the script files.

![console-errlog3](https://github.com/yigitaktan/SqlLoadGen/assets/51110247/59e5cedd-8b28-47cf-af87-deee656a0df9)

## Encoding requirement
Both `sql-load-gen.ps1` and `functions.psm1` files must be set with a character encoding of **UTF-16LE** or **UTF-16BE**. If either of these files has a different encoding standard than specified, the following error message will appear.

![console-encoding2](https://github.com/yigitaktan/SqlLoadGen/assets/51110247/4f4d7c2e-a516-4479-888d-44dc9e582826)

If you get an encoding error, you should open the files in a text editor like Notepad++ and save them as **UTF-16LE** or **UTF-16BE**. How to do this with Notepad++ is shown below.

![console-notepadpp](https://github.com/yigitaktan/SqlLoadGen/assets/51110247/bc89e9a5-d098-455a-aa21-f9c85c703405)

When you download from GitHub, the encoding of all files within the ZIP may be **UTF-8**. Please check. If different, make the change as described above.

## Creating the test environment
You might want to try the script on a test database first. For this, please run the [demo-setup.sql](https://github.com/yigitaktan/SqlLoadGen/blob/main/demo-setup.sql) file in the instance where you want to perform the test. When the specified file is executed, a new database named DemoDB will be created. This database will create 6 tables and 13 Stored Procedures (SPs), and a user named **MyDemoUser**.

Tables to be created:

<pre>
dbo.Addresses
dbo.OrderDetails
dbo.Orders
dbo.ProductCategories
dbo.Products
dbo.Users
</pre>

SPs to be created:

<pre>
dbo.sp_AddOrder
dbo.sp_AddOrderDetail
dbo.sp_AddProduct
dbo.sp_AddUserAndAddress
dbo.sp_DeleteProduct
dbo.sp_DeleteUser
dbo.sp_GetAllUsers
dbo.sp_GetOrderDetails
dbo.sp_GetOrdersByUser
dbo.sp_GetProductCategories
dbo.sp_GetProductsByCategory
dbo.sp_UpdateProduct
dbo.UpdateUser
</pre>

If you want to create a sample SP file using these SPs, you can prepare a file as below using the **rnd-text**, **rnd-date**, and **rnd-number** functions described above.

<pre>
dbo.sp_DeleteUser;@UserID={rnd-number:4,0123456789}
dbo.sp_AddOrder;@UserID={rnd-number:3,123456789};@OrderDate={rnd-date:2013-2023}
dbo.sp_UpdateUser;@UserID={rnd-number:3,123456789};@NewFirstName={rnd-text:10,abcdefghijklmnopqrstuvwxyz};@NewLastName={rnd-text:6,abcdefghijklmnopqrstuvwxyz};@NewAge={rnd-number:2,123456}
dbo.sp_GetOrderDetails;@OrderID={rnd-number:3,123456789}
dbo.sp_AddProduct;@ProductName={rnd-text:7,abcdefghijklmo};@CategoryID=2;@Price={rnd-number:3,123456789}
dbo.sp_UpdateProduct;@ProductID={rnd-number:3,123456789};@NewProductName={rnd-text:7,abcdefghijklmnopqrstuvwxyz};@NewCategoryID=3;@NewPrice={rnd-number:3,123456}
dbo.sp_GetProductsByCategory;@CategoryID={rnd-number:1,123456}
dbo.sp_GetProductCategories
dbo.sp_AddOrderDetail;@OrderID={rnd-number:3,123456789};@ProductID={rnd-number:1,123456};@Quantity={rnd-number:2,12345689}
dbo.sp_GetOrdersByUser;@UserID={rnd-number:3,123456789}
dbo.sp_DeleteProduct;@ProductID={rnd-number:3,123456789}
</pre>
