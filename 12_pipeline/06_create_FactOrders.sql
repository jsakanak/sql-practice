-- ============================================================
-- Database : WideWorldImportersDW
-- Table    : FactOrders
-- Purpose  : Order fulfilment fact table for OTIF reporting
-- Source   : Sales.Orders, Sales.OrderLines, Sales.Invoices
-- Author   : James Sakanak
-- Date     : May 2026
-- ============================================================
-- DATA NOTE: 3,147 order lines excluded from this table
-- Reason   : No matching invoice found in Sales.Invoices
-- These represent open/unfulfilled orders at time of extract
-- OTIF cannot be calculated without a confirmed delivery time
-- Impact   : 228,265 of 231,412 source rows loaded (98.6%)
-- ============================================================
-- AMENDMENT LOG
-- Date     : May 2026
-- Change   : Fixed IsOnTime calculation
-- Reason   : ConfirmedDeliveryTime includes time component
--            causing correct-date deliveries to fail the
--            <= comparison against date-only ExpectedDeliveryDate
-- Fix      : CAST(ConfirmedDeliveryTime AS DATE) before comparing
-- ============================================================
-- Date     : May 2026
-- Change   : Handle NULL ConfirmedDeliveryTime
-- Reason   : 84 orders (284 lines) have no confirmed delivery
--            Previously marked IsOnTime = 0 incorrectly
-- Fix      : Return NULL for IsOnTime, IsOTIF, DaysLate
--            where ConfirmedDeliveryTime IS NULL
-- Action   : ALTER COLUMN on IsOnTime, IsOTIF, DaysLate to allow NULL
-- ============================================================

-- Step 1: Create table
CREATE TABLE FactOrders (
    OrderLineID             INT             NOT NULL PRIMARY KEY,
    OrderID                 INT             NOT NULL,
    CustomerID              INT             NOT NULL,
    StockItemID             INT             NOT NULL,
    DeliveryMethodID        INT             NOT NULL,
    SalespersonPersonID     INT             NOT NULL,
    PickedByPersonID        INT             NULL,
    OrderDateKey            INT             NOT NULL,
    ExpectedDeliveryDateKey INT             NOT NULL,
    Quantity                INT             NOT NULL,
    PickedQuantity          INT             NOT NULL,
    UnitPrice               DECIMAL(18,2)   NOT NULL,
    TotalLineValue          DECIMAL(18,2)   NOT NULL,
    IsInFull                BIT             NOT NULL,
    IsOnTime                BIT             NULL,
    IsOTIF                  BIT             NULL,
    DaysLate                INT             NULL,
    BackorderQuantity       INT             NOT NULL,

    CONSTRAINT FK_FactOrders_DimCustomer
        FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID),
    CONSTRAINT FK_FactOrders_DimStockItem
        FOREIGN KEY (StockItemID) REFERENCES DimStockItem(StockItemID),
    CONSTRAINT FK_FactOrders_DimDeliveryMethod
        FOREIGN KEY (DeliveryMethodID) REFERENCES DimDeliveryMethod(DeliveryMethodID),
    CONSTRAINT FK_FactOrders_OrderDate
        FOREIGN KEY (OrderDateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT FK_FactOrders_ExpectedDeliveryDate
        FOREIGN KEY (ExpectedDeliveryDateKey) REFERENCES DimDate(DateKey)
);

-- ============================================================
-- Populate FactOrders
-- ============================================================


-- Step 2: Reload with corrected IsOnTime logic
INSERT INTO FactOrders
SELECT
    ol.OrderLineID,
    ol.OrderID,
    o.CustomerID,
    ol.StockItemID,
    i.DeliveryMethodID,
    o.SalespersonPersonID,
    o.PickedByPersonID,
    CAST(FORMAT(o.OrderDate, 'yyyyMMdd') AS INT),
    CAST(FORMAT(o.ExpectedDeliveryDate, 'yyyyMMdd') AS INT),
    ol.Quantity,
    ol.PickedQuantity,
    ol.UnitPrice,
    ol.Quantity * ol.UnitPrice,

    -- Is In Full
    CASE WHEN ol.PickedQuantity >= ol.Quantity THEN 1 ELSE 0 END,

    -- Is On Time (handle NULL ConfirmedDeliveryTime)
    CASE 
        WHEN i.ConfirmedDeliveryTime IS NULL THEN NULL
        WHEN CAST(i.ConfirmedDeliveryTime AS DATE) <= o.ExpectedDeliveryDate 
        THEN 1 ELSE 0
    END,

    -- Is OTIF
    CASE 
        WHEN i.ConfirmedDeliveryTime IS NULL THEN NULL
        WHEN ol.PickedQuantity >= ol.Quantity
         AND CAST(i.ConfirmedDeliveryTime AS DATE) <= o.ExpectedDeliveryDate THEN 1
    ELSE 0
    END,

    -- Days Late
    CASE 
        WHEN i.ConfirmedDeliveryTime IS NULL THEN NULL
        WHEN CAST(i.ConfirmedDeliveryTime AS DATE) > o.ExpectedDeliveryDate
        THEN DATEDIFF(DAY, o.ExpectedDeliveryDate, CAST(i.ConfirmedDeliveryTime AS DATE))
    ELSE 0
    END,

    -- Backorder Quantity
    CASE 
        WHEN ol.PickedQuantity < ol.Quantity 
        THEN ol.Quantity - ol.PickedQuantity 
        ELSE 0 
    END

FROM WideWorldImporters.Sales.OrderLines ol
JOIN WideWorldImporters.Sales.Orders o ON ol.OrderID = o.OrderID
JOIN WideWorldImporters.Sales.Invoices i ON o.OrderID = i.OrderID;