# Apple Sales Data Warehouse – SQL Server & SSIS

This repository contains a small data warehouse / ETL project built with **Microsoft SQL Server** and **SQL Server Integration Services (SSIS)**.

The project creates an `APPLE_DB` database, prepares the source/staging and analytical tables, enables Change Data Capture (CDC), and uses SSIS packages to load product, category, store, warranty, and sales data.

---

## Dataset Source

The source data used in this project comes from the **Apple Retail Sales Dataset** available on Kaggle:

**Apple Retail Sales Dataset:**  
https://www.kaggle.com/datasets/amangarg08/apple-retail-sales-dataset

The dataset provides the Apple retail sales data used as the source for the SQL Server and SSIS ETL workflow in this project.

---

## Project Structure

The recommended repository structure is:

```text
apple-data-warehouse/
│
├── README.md
├── .gitignore
│
├── sql/
│   └── setup_apple_data_warehouse.sql
│
├── ssis/
│   └── SALES/
│       ├── SALES.dtproj
│       ├── Project.params
│       │
│       └── Packages/
│           ├── CDCInitialLoad.dtsx
│           ├── CategoryLoad.dtsx
│           ├── ProductLoad.dtsx
│           ├── StoreLoad.dtsx
│           ├── WarrantyLoad.dtsx
│           └── SalesLoad.dtsx
│
├── analysis-services/
│   └── SALES.database
│
└── data/
    └── raw/
        ├── category.csv
        ├── products.csv
        ├── sales.csv
        ├── stores.csv
        └── warranty.csv
```

### Files that should normally NOT be committed

The following file is specific to an individual Visual Studio user/environment:

```text
SALES.dtproj.user
```

It is better to exclude it from Git.

Other generated Visual Studio / SSIS files should also normally be ignored.

A suggested `.gitignore` is:

```gitignore
# Visual Studio
.vs/
*.user
*.suo

# SSIS / build output
bin/
obj/
*.ispac

# User-specific SSIS project settings
*.dtproj.user

# Temporary files
*.tmp
*.bak

# Optional: local datasets
# data/raw/
```

If the dataset is small and intended to be part of the repository, keep `data/raw/`.
If the source data is large, private, or licensed separately, ignore it and document where users should obtain it.

---

# 1. Project Overview

The project follows this general ETL architecture:

```text
CSV Source Files
       |
       v
SSIS Packages
       |
       v
SQL Server Source / Staging Tables
       |
       v
Transformation & Lookup Logic
       |
       v
Dimension Tables + Fact Table
       |
       v
Change Data Capture (CDC)
```

The SQL setup script should be executed before running the SSIS packages.

---

# 2. Main Technologies

- Microsoft SQL Server
- SQL Server Integration Services (SSIS)
- SQL Server Change Data Capture (CDC)
- T-SQL
- Visual Studio / SQL Server Data Tools
- Git and GitHub

---

# 3. Prerequisites

Before using the project, install and configure:

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- Visual Studio with SQL Server Integration Services support
- SQL Server Integration Services Projects extension / SSDT components compatible with the project
- Git, if cloning the repository

The SSIS packages were created using SSIS project format version 8.

---

# 4. Clone the Repository

Clone the repository and open the project directory.

Example:

```bash
git clone <YOUR_REPOSITORY_URL>
cd apple-data-warehouse
```

---

# 5. Prepare the SQL Server Database

The database should be prepared before executing the SSIS packages.

Open:

```text
sql/setup_apple_data_warehouse.sql
```

in SQL Server Management Studio.

Run the script using an account with sufficient permissions to:

- create a database;
- create tables;
- create schemas if required;
- enable Change Data Capture;
- enable CDC on tables.

The setup script prepares:

```text
APPLE_DB
```

and the database objects required by the SSIS packages.

It also configures Change Data Capture for the tables used by the CDC workflow.

---

# 6. Verify the Database

After executing the SQL script, verify that the database exists:

```sql
SELECT name
FROM sys.databases
WHERE name = 'APPLE_DB';
```

Then switch to the database:

```sql
USE APPLE_DB;
GO
```

You can inspect the tables with:

```sql
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA, TABLE_NAME;
```

To verify whether CDC is enabled for the database:

```sql
SELECT
    name,
    is_cdc_enabled
FROM sys.databases
WHERE name = 'APPLE_DB';
```

---

# 7. Source Data

The SSIS packages use CSV source files.

Recommended location inside the repository:

```text
data/raw/
```

Expected source files include:

```text
category.csv
products.csv
sales.csv
stores.csv
warranty.csv
```

The original SSIS packages contain local file paths such as:

```text
D:\BI-SQL\AppleDataSet\category.csv
D:\BI-SQL\AppleDataSet\products.csv
D:\BI-SQL\AppleDataSet\sales.csv
D:\BI-SQL\AppleDataSet\stores.csv
D:\BI-SQL\AppleDataSet\warranty.csv
```

These paths are machine-specific.

Therefore, after downloading the project, users must update the SSIS Flat File Connection Managers to point to the location of the CSV files on their own computer.

For example:

```text
C:\Projects\apple-data-warehouse\data\raw\category.csv
```

A better long-term improvement is to replace hard-coded file paths with SSIS project parameters.

---

# 8. Open the SSIS Project

Open Visual Studio.

Then open:

```text
ssis/SALES/SALES.dtproj
```

The main SSIS project contains the ETL packages used to load the warehouse.

The packages should be stored under:

```text
ssis/SALES/Packages/
```

---

# 9. Configure Database Connections

The packages currently reference the SQL Server database:

```text
APPLE_DB
```

Some package connection managers use local SQL Server instances such as:

```text
Data Source=.
```

or machine-specific server names.

Before running the packages:

1. Open the SSIS project in Visual Studio.
2. Open each required Connection Manager.
3. Set the SQL Server instance to your SQL Server.
4. Set the database to:

```text
APPLE_DB
```

5. Test the connection.
6. Save the project.

If Windows Authentication is used, make sure your Windows account has permission to access the database.

---

# 10. SSIS Packages

## `CategoryLoad.dtsx`

Loads category source data into the database.

Run this before processes that depend on category information.

---

## `ProductLoad.dtsx`

Loads and transforms product data.

Product processing may depend on category data, so category data should normally be available first.

---

## `StoreLoad.dtsx`

Loads store-related source data into the corresponding warehouse structures.

---

## `WarrantyLoad.dtsx`

Loads warranty information used by the warehouse.

---

## `SalesLoad.dtsx`

Loads sales transaction data.

Because sales data commonly references products and stores, dimension/master-data packages should normally be completed before the sales package.

---

## `CDCInitialLoad.dtsx`

Initializes the CDC-related loading workflow.

This package connects to:

```text
APPLE_DB
```

and is used as part of the Change Data Capture process.

The SQL database setup script must be executed first so that CDC is configured before running the CDC workflow.

---

# 11. Recommended Package Execution Order

For an initial load, use the following order:

```text
1. setup_apple_data_warehouse.sql
        |
        v
2. CategoryLoad.dtsx
        |
        v
3. ProductLoad.dtsx
        |
        v
4. StoreLoad.dtsx
        |
        v
5. WarrantyLoad.dtsx
        |
        v
6. SalesLoad.dtsx
        |
        v
7. CDCInitialLoad.dtsx
```

Depending on changes made to package dependencies in Visual Studio, the exact execution sequence can also be controlled through an SSIS master package or SQL Server Agent job.

---

# 12. Running an SSIS Package

In Visual Studio:

1. Open `SALES.dtproj`.
2. Open the desired `.dtsx` package.
3. Verify the Flat File Connection Managers.
4. Verify the SQL Server Connection Managers.
5. Right-click the package.
6. Select **Execute Package**.

Watch the **Progress** or **Execution Results** tab for errors.

A successful execution should show the relevant SSIS tasks and data flows as completed successfully.

---

# 13. Validate the Loaded Data

After running the SSIS packages, use SSMS to inspect the destination tables.

For example:

```sql
USE APPLE_DB;
GO

SELECT TOP (10) *
FROM <schema>.<table>;
```

You can also compare row counts between the source/staging and final tables:

```sql
SELECT COUNT(*)
FROM <schema>.<table>;
```

Use the table names created by `setup_apple_data_warehouse.sql` for the exact validation queries.

---

# 14. Change Data Capture

The project uses SQL Server Change Data Capture to identify inserts, updates, and deletes after the initial load.

Conceptually:

```text
Source Table
     |
     | INSERT / UPDATE / DELETE
     v
SQL Server CDC
     |
     v
CDC Change Tables
     |
     v
SSIS CDC Processing
     |
     v
Warehouse Tables
```

Before using the CDC package, confirm that CDC is enabled.

Database-level check:

```sql
SELECT
    name,
    is_cdc_enabled
FROM sys.databases
WHERE name = 'APPLE_DB';
```

CDC-enabled tables can be inspected with:

```sql
USE APPLE_DB;
GO

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.is_tracked_by_cdc
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE t.is_tracked_by_cdc = 1
ORDER BY s.name, t.name;
```

---

# 15. Project Parameters

The SSIS project contains:

```text
Project.params
```

This file is intended for project-level SSIS parameters.

The current file does not define project parameters.

A recommended future improvement is to create parameters such as:

```text
SourceDataPath
ServerName
DatabaseName
```

This would allow package connections to be configured without editing every package individually.

For example:

```text
SourceDataPath = C:\Projects\apple-data-warehouse\data\raw
DatabaseName   = APPLE_DB
```

---

# 16. `SALES.database`

The repository also contains:

```text
SALES.database
```

A `.database` file is associated with SQL Server Analysis Services project metadata rather than being a normal SSIS package.

For clarity, it is recommended to store it separately:

```text
analysis-services/SALES.database
```

If Analysis Services is not part of the final project, review whether this file is actually required before keeping it in the repository.

---

# 17. Files to Commit to Git

Recommended files to commit:

```text
README.md

sql/
    setup_apple_data_warehouse.sql

ssis/SALES/
    SALES.dtproj
    Project.params
    Packages/
        CategoryLoad.dtsx
        ProductLoad.dtsx
        StoreLoad.dtsx
        WarrantyLoad.dtsx
        SalesLoad.dtsx
        CDCInitialLoad.dtsx

analysis-services/
    SALES.database
```

Optional:

```text
data/raw/*.csv
```

Do not normally commit:

```text
SALES.dtproj.user
.vs/
bin/
obj/
*.ispac
```

---

# 18. Recommended Improvements

The current project works as a learning / portfolio ETL project, but the following improvements would make it more portable and production-friendly:

1. Replace hard-coded CSV paths with SSIS project parameters.
2. Replace machine-specific SQL Server names with parameters or environments.
3. Create project-level Connection Managers when multiple packages use the same connection.
4. Add a master SSIS package that executes the load packages in dependency order.
5. Add error-handling and reject-row outputs for invalid source records.
6. Add row-count validation after each load.
7. Configure logging for package executions.
8. Deploy the SSIS project to the SSIS Catalog (`SSISDB`) for controlled execution.
9. Use SQL Server Agent for scheduled production runs.
10. Keep credentials and environment-specific settings out of Git.

---

# 19. Suggested Repository Workflow

The complete setup process is:

```text
Clone Repository
      |
      v
Install / Configure SQL Server
      |
      v
Run sql/setup_apple_data_warehouse.sql
      |
      v
Prepare CSV Source Files
      |
      v
Open ssis/SALES/SALES.dtproj
      |
      v
Update Flat File Paths
      |
      v
Update SQL Server Connections
      |
      v
Run Dimension / Master Data Packages
      |
      v
Run SalesLoad.dtsx
      |
      v
Run / Initialize CDC Workflow
      |
      v
Validate SQL Server Tables
```

---

# 20. Troubleshooting

## Flat file cannot be found

If SSIS reports that a CSV file cannot be found, update the corresponding Flat File Connection Manager.

The original packages were created with local paths under:

```text
D:\BI-SQL\AppleDataSet\
```

Those paths will not automatically exist on another user's computer.

---

## Cannot connect to `APPLE_DB`

Check:

- SQL Server service is running;
- the server/instance name is correct;
- `APPLE_DB` has been created;
- Windows Authentication or SQL Authentication is configured correctly;
- your account has database permissions.

---

## CDC package fails

Confirm that:

1. `setup_apple_data_warehouse.sql` completed successfully.
2. CDC is enabled on `APPLE_DB`.
3. The required source tables are tracked by CDC.
4. SQL Server Agent is available/running where required by your SQL Server configuration.
5. The SSIS connection points to the correct SQL Server instance.

---

## Package opens with compatibility warnings

The project was saved with a modern SSIS project/package format.

Make sure Visual Studio has a compatible version of the **SQL Server Integration Services Projects** extension installed.

---

# Summary

This project demonstrates an end-to-end SQL Server ETL workflow:

```text
CSV Files
   |
   v
SSIS
   |
   v
APPLE_DB
   |
   +--> Source / Staging Data
   |
   +--> Dimension Tables
   |
   +--> Fact / Sales Data
   |
   +--> Change Data Capture
```

Start with the database setup script, configure the SSIS connection managers for your machine, execute the load packages in dependency order, and then validate the loaded data in SQL Server Management Studio.
