-- ============================================================
-- Database : WideWorldImportersDW
-- Table    : DimStockItem
-- Purpose  : Stock item dimension for OTIF reporting
-- Source   : Warehouse.StockItems
-- Author   : James Sakanak
-- Date     : May 2026
-- ============================================================

CREATE TABLE DimStockItem (
    StockItemID             INT             NOT NULL PRIMARY KEY,
    StockItemName           NVARCHAR(100)   NOT NULL,
    SupplierID              INT             NOT NULL,
    Brand                   NVARCHAR(50)    NULL,
    Size                    NVARCHAR(20)    NULL,
    IsChillerStock          BIT             NOT NULL,
    LeadTimeDays            INT             NOT NULL,
    UnitPrice               DECIMAL(18,2)   NOT NULL,
    TaxRate                 DECIMAL(18,3)   NOT NULL
);

-- ============================================================
-- Populate DimStockItem
-- ============================================================

INSERT INTO DimStockItem
SELECT
    StockItemID,
    StockItemName,
    SupplierID,
    Brand,
    Size,
    IsChillerStock,
    LeadTimeDays,
    UnitPrice,
    TaxRate
FROM WideWorldImporters.Warehouse.StockItems;