# SQL Load Generator

* **[Getting started with the script](#Getting-started-with-the-script)**
* **[Script components](#Script-components)**
* **[Preparing the config.txt file](#preparing-the-configtxt-file)**
* **[Preparing the SP file](#preparing-the-sp-file)**
* **[Random value generations](#random-value-generations)**


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

* **AuthenticationType**: Specifies the type of authentication you will use to connect to the SQL Server. Only two values should be entered: either "**WIN**" or "**SQL**". If "**WIN**" is entered, it indicates connecting with Windows Authentication; if "**SQL**" is entered, it indicates connecting with SQL Server Authentication.
  
* **ServerName**: Define the instance you will connect to here. If it's the default instance, enter in the form of **SERVERNAME**; if it's a named instance, enter as **SERVERNAME/INSTANCENAME**.
  
* **DatabaseName**: Enter the name of the database where you will generate the load.
  
* **UserName**: If "**SQL**" is entered for the `AuthenticationType` parameter, the `UserName` parameter must definitely be filled out. The user with which the connection will be established is determined in this parameter.
  
* **Password**: Similar to the `UserName` parameter, if your `AuthenticationType` is "**SQL**", define the password for the entered username in this parameter.
  
* **ParallelConnections**: Determines how many different parallel connections will be used to execute the SPs. Only a number should be entered for this parameter.
  
* **ExecutionTimeLimit**: Define in this parameter how long the load you will create, measured in seconds, should last.
  
* **SpFile**: Write the name of the file, which contains the SPs to be executed, in this parameter.
  
* **RandomExecute**: Specify in this parameter whether you want the SPs to be executed in the order written in the file or executed randomly. If you want them to be executed in the same order, write "**0**"; if you want them to be executed randomly, write "**1**". Values other than 0 or 1 are not accepted.


If `AuthenticationType` is specified as "**WIN**", all the parameters mentioned above must be written in the `config.txt` file. If it is specified as "**SQL**", the `UserName` and `Password` parameters are not required. If `AuthenticationType` is specified as "**WIN**" and the `UserName` and `Password` parameters are still set to specific values in the file, these two parameters will be skipped, and whether or not they have any values will not affect the operation of the script.


The name of the configuration file must be **`config.txt`**. The previously mentioned 9 parameters should be written inside square brackets and then assigned their respective values. Below is an example of how a config.txt file should be written.

```
[AuthenticationType]=SQL
[ServerName]=DBPROD01\SQL2019
[DatabaseName]=DemoDB
[UserName]=MyDemoUser
[Password]=Password.1
[ParallelConnections]=20
[ExecutionTimeLimit]=300
[SpFile]=sp.txt
[RandomExecute]=1
```

## Preparing the SP file
In its current version, SQL Load Generator only executes Stored Procedures (SPs). Support for executing Ad-Hoc queries will be provided in upcoming versions.

The SP file must be prepared in a specific format. Each SP should be written one per line. The most crucial writing style to pay attention to is the format for SPs with parameters. If there is a parametric SP, parameter names should be separated from other parameters and the SP name with a semicolon "**;**". The writing format for a parametric SP should be as follows.

<pre>Schema_Name.Sp_Name;@Parameter1=ParameterValue;@Parameter2=ParameterValue</pre>

To better understand the above example, let's examine the sp_UpdateProduct SP.

```
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
```

The above SP takes 4 different parameters: ProductID, NewProductName, NewCategoryID, and NewPrice. To execute this SP in SSMS, you would do it as follows.

<pre>EXEC dbo.sp_UpdateProduct @ProductID = 2, @NewProductName = 'Winter Jacket', @NewCategoryID = 2, @NewPrice = 120.00</pre>

Adapting the above usage to the SP file is as follows.

<pre>dbo.sp_UpdateProduct;@ProductID=2;@NewProductName=Winter Jacket;@NewCategoryID=2;@NewPrice=120.00</pre>

For SPs that do not take parameters, the usage should be in the form of Schema_Name.Sp_Name. The sp_GetProductCategories SP can be examined below.

```
CREATE PROCEDURE sp_GetProductCategories
AS
BEGIN
    SELECT CategoryName FROM ProductCategories WITH(NOLOCK);
END;
```

The usage of the sp_GetProductCategories SP within the SP file should be as follows.

<pre>dbo.sp_GetProductCategories</pre>

You can create an SP file by writing the above 2 examples one under the other.

```
dbo.sp_UpdateProduct;@ProductID=2;@NewProductName=Winter Jacket;@NewCategoryID=2;@NewPrice=120.00
dbo.sp_GetProductCategories
```

## Random value generations
You might want to generate random parameter values for SPs that take parameters. There are 3 different usage types for this, and you can examine the usages below.

* **rnd-number**: This function is used to generate a random number. Its usage is `{rnd-number:How_Many_Digits_Long,Which_Numbers_to_Choose_From}`. In the example below, there is a usage form to generate a 3-digit number from among the numbers 0123456789.
  <pre>{rnd-number:3,0123456789}</pre>

* **rnd-text**: This function is used to generate letters of the specified character length. Its usage is `{rnd-text:How_Many_Characters_Long,Which_Letters_to_Choose_From}`. In the example below, there is an example of generating random text from among the letters abcdefghijklmo, 7 characters in length.
  <pre>{rnd-text:7,abcdefghijklmo}</pre>

* **rnd-date**: This function generates data in the "**yyyy-MM-dd**" format. It has 2 parameters, both are year parameters. The start and end year are written, and the desired date is generated from among the specified years. Its usage is `{rnd-date:Start_Year-End_Year}`. In the example below, a date is being generated between the years 2013 and 2023.
  <pre>{rnd-date:2013-2023}</pre>

To give examples of the usage of these 3 functions, an example can be created as follows.

```
dbo.sp_DeleteUser;@UserID={rnd-number:3,123456789}
dbo.sp_AddOrder;@UserID={rnd-number:5,12345};@OrderDate={rnd-date:2013-2023}
dbo.sp_AddProduct;@ProductName={rnd-text:10,abcdefghijklmnopqrstuvwxyz};@CategoryID=2;@Price={rnd-number:3,123456789}
```

