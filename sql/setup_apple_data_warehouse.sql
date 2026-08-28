/*=============================================================================
  Apple Data Warehouse Setup
  File: setup_apple_data_warehouse.sql

  Purpose:
    - Create the APPLE_DB database if it does not exist
    - Enable Change Data Capture (CDC) at database level
    - Create staging, current-source, dimension, fact, and output tables
    - Enable CDC on the required source tables

  Platform:
    Microsoft SQL Server / T-SQL

  Notes:
    - SQL Server Agent must be running for CDC capture/cleanup jobs.
    - The script is designed to be safely rerun where practical.
=============================================================================*/

/*=============================================================================
  1. CREATE DATABASE
=============================================================================*/

IF DB_ID(N'APPLE_DB') IS NULL
BEGIN
    CREATE DATABASE [APPLE_DB];
    PRINT N'Database APPLE_DB created successfully.';
END
ELSE
BEGIN
    PRINT N'Database APPLE_DB already exists.';
END;
GO

USE [APPLE_DB];
GO

/*=============================================================================
  2. ENABLE DATABASE-LEVEL CDC
=============================================================================*/

IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = N'APPLE_DB'
      AND is_cdc_enabled = 1
)
BEGIN
    PRINT N'CDC is already enabled for APPLE_DB.';
END
ELSE
BEGIN
    EXEC sys.sp_cdc_enable_db;
    PRINT N'CDC enabled successfully for APPLE_DB.';
END;
GO

/*=============================================================================
  3. CDC STATE CONTROL TABLE
=============================================================================*/

IF OBJECT_ID(N'dbo.cdc_states', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.cdc_states
    (
        [name]  NVARCHAR(256) NOT NULL,
        [state] NVARCHAR(256) NOT NULL
    );

    PRINT N'Table dbo.cdc_states created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.cdc_states already exists.';
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID(N'dbo.cdc_states')
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'dbo',
        @source_name   = N'cdc_states',
        @role_name     = NULL;

    PRINT N'CDC enabled on dbo.cdc_states.';
END
ELSE
BEGIN
    PRINT N'CDC is already enabled on dbo.cdc_states.';
END;
GO

/*=============================================================================
  4. PRODUCT TABLES
=============================================================================*/

IF OBJECT_ID(N'dbo.staging_product', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.staging_product
    (
        Product_ID   NVARCHAR(50) NULL,
        Product_Name NVARCHAR(50) NULL,
        Category_ID  NVARCHAR(50) NULL,
        Launch_Date  DATE NULL,
        Price        NUMERIC(18,0) NULL
    );

    PRINT N'Table dbo.staging_product created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.staging_product already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Current_Product_Source', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Current_Product_Source
    (
        Product_ID   NVARCHAR(50) NULL,
        Product_Name NVARCHAR(50) NULL,
        Category_ID  NVARCHAR(50) NULL,
        Launch_Date  DATE NULL,
        Price        NUMERIC(18,0) NULL
    );

    PRINT N'Table dbo.Current_Product_Source created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Current_Product_Source already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Staging_Product_2', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Staging_Product_2
    (
        Product_ID            NVARCHAR(50) NULL,
        Product_Name          NVARCHAR(50) NULL,
        Category_ID           NVARCHAR(50) NULL,
        Launch_Date           NVARCHAR(10) NULL,
        Price                 NUMERIC(18,0) NULL,
        Operation             NVARCHAR(50) NULL,
        Modified_Date         DATETIME NULL,
        SurrogateKey_Category NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.Staging_Product_2 created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Staging_Product_2 already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Dimension_Product', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dimension_Product
    (
        SurrogateKey_Product  INT IDENTITY(1,1) NOT NULL,
        Product_ID            NVARCHAR(50) NULL,
        Product_Name          NVARCHAR(50) NULL,
        Category_ID           NVARCHAR(50) NULL,
        Launch_Date           DATE NULL,
        Price                 NUMERIC(18,0) NULL,
        Operation             NVARCHAR(50) NULL,
        Modified_Date         DATETIME NULL,
        SurrogateKey_Category INT NULL,
        CONSTRAINT PK_Dim_Product PRIMARY KEY (SurrogateKey_Product)
    );

    PRINT N'Table dbo.Dimension_Product created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Dimension_Product already exists.';
END;
GO

-- Enable CDC on the current product source.
IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID(N'dbo.Current_Product_Source')
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema         = N'dbo',
        @source_name           = N'Current_Product_Source',
        @role_name             = NULL,
        @capture_instance      = N'current_product',
        @captured_column_list  = NULL;

    PRINT N'CDC enabled on dbo.Current_Product_Source.';
END
ELSE
BEGIN
    PRINT N'CDC is already enabled on dbo.Current_Product_Source.';
END;
GO

/*
To disable CDC on Current_Product_Source when changing its keys or capture setup:

EXEC sys.sp_cdc_disable_table
    @source_schema    = N'dbo',
    @source_name      = N'Current_Product_Source',
    @capture_instance = N'current_product';
*/

/*=============================================================================
  5. CATEGORY TABLES
=============================================================================*/

IF OBJECT_ID(N'dbo.staging_category', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.staging_category
    (
        Category_ID   NVARCHAR(50) NULL,
        Category_Name NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.staging_category created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.staging_category already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Current_Category_Source', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Current_Category_Source
    (
        Category_ID   NVARCHAR(50) NULL,
        Category_Name NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.Current_Category_Source created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Current_Category_Source already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Dimension_Category', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dimension_Category
    (
        SurrogateKey  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Category_ID   NVARCHAR(50) NULL,
        Category_Name NVARCHAR(50) NULL,
        Modified_Date DATETIME NULL,
        Operation     NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.Dimension_Category created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Dimension_Category already exists.';
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID(N'dbo.Current_Category_Source')
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema        = N'dbo',
        @source_name          = N'Current_Category_Source',
        @role_name            = NULL,
        @capture_instance     = N'current_category',
        @captured_column_list = NULL;

    PRINT N'CDC enabled on dbo.Current_Category_Source.';
END
ELSE
BEGIN
    PRINT N'CDC is already enabled on dbo.Current_Category_Source.';
END;
GO

/*=============================================================================
  6. STORE TABLES
=============================================================================*/

IF OBJECT_ID(N'dbo.staging_store', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.staging_store
    (
        Store_ID   NVARCHAR(50) NOT NULL PRIMARY KEY,
        Store_Name NVARCHAR(50) NULL,
        City       NVARCHAR(50) NULL,
        Country    NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.staging_store created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.staging_store already exists.';
END;
GO

IF OBJECT_ID(N'dbo.current_store_source', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.current_store_source
    (
        Store_ID   NVARCHAR(50) NOT NULL PRIMARY KEY,
        Store_Name NVARCHAR(50) NULL,
        City       NVARCHAR(50) NULL,
        Country    NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.current_store_source created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.current_store_source already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Dimension_Store', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dimension_Store
    (
        Store_ID      NVARCHAR(50) NULL,
        Store_Name    NVARCHAR(50) NULL,
        City          NVARCHAR(50) NULL,
        Country       NVARCHAR(50) NULL,
        Operation     NVARCHAR(50) NULL,
        Modified_Date DATETIME NULL,
        SurrogateKey  INT IDENTITY(1,1) NOT NULL PRIMARY KEY
    );

    PRINT N'Table dbo.Dimension_Store created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Dimension_Store already exists.';
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID(N'dbo.current_store_source')
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema        = N'dbo',
        @source_name          = N'current_store_source',
        @role_name            = NULL,
        @capture_instance     = N'current_Store',
        @captured_column_list = NULL;

    PRINT N'CDC enabled on dbo.current_store_source.';
END
ELSE
BEGIN
    PRINT N'CDC is already enabled on dbo.current_store_source.';
END;
GO

/*=============================================================================
  7. WARRANTY TABLES
=============================================================================*/

IF OBJECT_ID(N'dbo.Staging_Warranty', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Staging_Warranty
    (
        Claim_ID      NVARCHAR(50) NULL,
        Claim_Date    DATE NULL,
        Sale_ID       NVARCHAR(50) NULL,
        Repair_Status NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.Staging_Warranty created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Staging_Warranty already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Staging_Warranty_2', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Staging_Warranty_2
    (
        SurrogateKey_Sale INT NULL,
        Modified_Date     DATETIME NULL,
        Operation         NVARCHAR(50) NULL,
        Claim_ID          NVARCHAR(50) NULL,
        Claim_Date        DATE NULL,
        Sale_ID           NVARCHAR(50) NULL,
        Repair_Status     NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.Staging_Warranty_2 created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Staging_Warranty_2 already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Current_Warranty_Source', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Current_Warranty_Source
    (
        Claim_ID      NVARCHAR(50) NULL,
        Claim_Date    DATE NULL,
        Sale_ID       NVARCHAR(50) NULL,
        Repair_Status NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.Current_Warranty_Source created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Current_Warranty_Source already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Fact_Warranty', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Warranty
    (
        SurrogateKey      INT IDENTITY(1,1) NOT NULL,
        Sale_ID           NVARCHAR(50) NULL,
        SurrogateKey_Sale INT NULL,
        Modified_Date     DATETIME NULL,
        Operation         NVARCHAR(50) NULL,
        Claim_ID          NVARCHAR(50) NULL,
        Claim_Date        NVARCHAR(10) NULL,
        Repair_Status     NVARCHAR(50) NULL,
        Quantity          INT NULL,
        Sale_Date         NVARCHAR(10) NULL,
        Store_Name        NVARCHAR(50) NULL,
        City              NVARCHAR(50) NULL,
        Country           NVARCHAR(50) NULL,
        Product_Name      NVARCHAR(50) NULL,
        Price             NUMERIC(18,0) NULL,
        Category_Name     NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.Fact_Warranty created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Fact_Warranty already exists.';
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID(N'dbo.Current_Warranty_Source')
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema        = N'dbo',
        @source_name          = N'Current_Warranty_Source',
        @role_name            = NULL,
        @capture_instance     = N'current_warranty',
        @captured_column_list = NULL;

    PRINT N'CDC enabled on dbo.Current_Warranty_Source.';
END
ELSE
BEGIN
    PRINT N'CDC is already enabled on dbo.Current_Warranty_Source.';
END;
GO

/*=============================================================================
  8. SALES TABLES
=============================================================================*/

IF OBJECT_ID(N'dbo.Staging_Sale', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Staging_Sale
    (
        Sale_ID     NVARCHAR(50) NULL,
        Sale_Date   NVARCHAR(50) NULL,
        Store_ID    NVARCHAR(50) NULL,
        Product_ID  NVARCHAR(50) NULL,
        Quantity    INT NULL,
        Edited_Date DATE NULL
    );

    PRINT N'Table dbo.Staging_Sale created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Staging_Sale already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Staging_Sale_2', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Staging_Sale_2
    (
        SurrogateKey_Product INT NULL,
        Quantity             INT NULL,
        Sale_Date            DATE NULL,
        Active               INT NULL,
        Update_Date          DATETIME NULL,
        Sale_ID              NVARCHAR(50) NULL,
        Store_ID             NVARCHAR(50) NULL,
        Product_ID           NVARCHAR(50) NULL,
        Operation            NVARCHAR(50) NULL
    );

    PRINT N'Table dbo.Staging_Sale_2 created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Staging_Sale_2 already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Fact_Sale', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Sale
    (
        SurrogateKey         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Sale_ID              NVARCHAR(50) NULL,
        Store_ID             NVARCHAR(50) NULL,
        Product_ID           NVARCHAR(50) NULL,
        Quantity             INT NULL,
        Sale_Date            DATE NULL,
        Update_Date          DATE NULL,
        Active               NVARCHAR(50) NULL,
        Operation            NVARCHAR(50) NULL,
        SurrogateKey_Product INT NULL
    );

    PRINT N'Table dbo.Fact_Sale created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Fact_Sale already exists.';
END;
GO

IF OBJECT_ID(N'dbo.Final_Sale', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Final_Sale
    (
        SurrogateKey         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Sale_ID              NVARCHAR(50) NULL,
        Sale_Date            NVARCHAR(10) NULL,
        Store_ID             NVARCHAR(50) NULL,
        Product_ID           NVARCHAR(50) NULL,
        Quantity             INT NULL,
        Update_Date          NVARCHAR(10) NULL,
        Active               NVARCHAR(50) NULL,
        Operation            NVARCHAR(50) NULL,
        SurrogateKey_Product INT NULL,
        Store_Name           NVARCHAR(50) NULL,
        City                 NVARCHAR(50) NULL,
        Country              NVARCHAR(50) NULL,
        Product_Name         NVARCHAR(50) NULL,
        Price                NUMERIC(18,0) NULL,
        Category_Name        NVARCHAR(50) NULL,
        SurrogateKey_FactSale INT NULL
    );

    PRINT N'Table dbo.Final_Sale created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.Final_Sale already exists.';
END;
GO

IF OBJECT_ID(N'dbo.sales_transactions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.sales_transactions
    (
        Sale_ID       VARCHAR(50) NOT NULL,
        Sale_Date     VARCHAR(50) NULL,
        Store_ID      VARCHAR(50) NULL,
        Product_ID    VARCHAR(50) NULL,
        Quantity      INT NULL,
        City          VARCHAR(50) NULL,
        Country       VARCHAR(50) NULL,
        Category_Name VARCHAR(50) NULL,
        Product_Name  VARCHAR(50) NULL,
        Launch_Date   DATE NULL,
        Price         DECIMAL(10,0) NULL,
        Edited_Date   DATE NULL,
        CONSTRAINT PK_SALES PRIMARY KEY (Sale_ID)
    );

    PRINT N'Table dbo.sales_transactions created successfully.';
END
ELSE
BEGIN
    PRINT N'Table dbo.sales_transactions already exists.';
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID(N'dbo.sales_transactions')
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema        = N'dbo',
        @source_name          = N'sales_transactions',
        @role_name            = NULL,
        @capture_instance     = N'sale_cdc',
        @index_name           = NULL,
        @captured_column_list = NULL;

    PRINT N'CDC enabled on dbo.sales_transactions.';
END
ELSE
BEGIN
    PRINT N'CDC is already enabled on dbo.sales_transactions.';
END;
GO

/*=============================================================================
  9. VALIDATION
=============================================================================*/

PRINT N'Apple data warehouse setup completed.';

SELECT
    DB_NAME() AS Current_Database,
    is_cdc_enabled AS CDC_Enabled
FROM sys.databases
WHERE name = DB_NAME();

SELECT
    s.name AS Schema_Name,
    t.name AS Table_Name
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;

SELECT
    OBJECT_SCHEMA_NAME(source_object_id) AS Source_Schema,
    OBJECT_NAME(source_object_id) AS Source_Table,
    capture_instance AS Capture_Instance
FROM cdc.change_tables
ORDER BY Source_Table;
GO
