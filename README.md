# SQL Load Generator

## Getting started with the script
You can effortlessly create load in your SQL environments by utilizing the Stored Procedures (SPs) and parameters that are actively used in your real-world scenarios. You have the capability to configure the duration for which the load should be generated, specify the parameters to be employed during the execution of the SPs, and determine the number of parallel connections to be established for executing these SPs. Consequently, you can simulate a load identical to that in your production environment, with the options of your choosing.

## Script components
The codebase of the script consists of two files: sql-load-gen.ps1 and functions.psm1. Additionally, for the script to run, config.txt and a file containing your Stored Procedures (SPs) are required.

* **[sql-load-gen.ps1](https://github.com/yigitaktan/SqlLoadGen/blob/main/sql-load-gen.ps1):** The primary script. The execution of the SPs is carried out within this file.
* **[functions.psm1](https://github.com/yigitaktan/SqlLoadGen/blob/main/functions.psm1):** All functions used in the sql-load-gen.ps1 file are stored in this file, and the script cannot run without it.
* **[config.txt](https://github.com/yigitaktan/SqlLoadGen/blob/main/config.txt):** This file defines the SQL Server connection details and the conditions under which the SPs will be executed.
* **[sp.txt](https://github.com/yigitaktan/SqlLoadGen/blob/main/sp.txt):** This file specifies the SPs to be executed, along with their parameters if any. The file can have any name, but the chosen name must be specified in the config.txt file.

