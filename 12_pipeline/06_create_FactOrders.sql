-- ============================================================
-- Database : WideWorldImportersDW
-- Table    : FactOrders
-- Purpose  : Order fulfilment fact table for OTIF reporting
-- Source   : Sales.Orders, Sales.OrderLines, Sales.Invoices
-- Author   : James Sakanak
-- Date     : May 2026
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
    IsOnTime                BIT             NOT NULL,
    IsOTIF                  BIT             NOT NULL,
    DaysLate                INT             NOT NULL,
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
-- Step 2: Populate FactOrders
-- ============================================================

INSERT INTO FactOrders
SELECT
    ol.OrderLineID,
    ol.OrderID,
    o.CustomerID,
    ol.StockItemID,
    i.DeliveryMethodID,
    o.SalespersonPersonID,
    o.PickedByPersonID,
    CAST(FORMAT(o.OrderDate, 'yyyyMMdd') AS INT)            AS OrderDateKey,
    CAST(FORMAT(o.ExpectedDeliveryDate, 'yyyyMMdd') AS INT) AS ExpectedDeliveryDateKey,
    ol.Quantity,
    ol.PickedQuantity,
    ol.UnitPrice,
    ol.Quantity * ol.UnitPrice                              AS TotalLineValue,

    -- Is In Full
    CASE
        WHEN ol.PickedQuantity >= ol.Quantity THEN 1
        ELSE 0
    END                                                     AS IsInFull,

    -- Is On Time
    CASE
        WHEN i.ConfirmedDeliveryTime <= o.ExpectedDeliveryDate THEN 1
        ELSE 0
    END                                                     AS IsOnTime,

    -- Is OTIF
    CASE
        WHEN ol.PickedQuantity >= ol.Quantity
         AND i.ConfirmedDeliveryTime <= o.ExpectedDeliveryDate THEN 1
        ELSE 0
    END                                                     AS IsOTIF,

    -- Days Late
    CASE
        WHEN i.ConfirmedDeliveryTime > o.ExpectedDeliveryDate
        THEN DATEDIFF(DAY, o.ExpectedDeliveryDate, i.ConfirmedDeliveryTime)
        ELSE 0
    END                                                     AS DaysLate,

    -- Backorder Quantity
    CASE
        WHEN ol.PickedQuantity < ol.Quantity
        THEN ol.Quantity - ol.PickedQuantity
        ELSE 0
    END                                                     AS BackorderQuantity

FROM WideWorldImporters.Sales.OrderLines ol
JOIN WideWorldImporters.Sales.Orders o
    ON ol.OrderID = o.OrderID
JOIN WideWorldImporters.Sales.Invoices i
    ON o.OrderID = i.OrderID;