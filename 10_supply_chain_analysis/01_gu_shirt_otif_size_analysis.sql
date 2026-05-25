-- ============================================================
-- Database : WideWorldImporters / WideWorldImportersDW
-- Analysis : OTIF Investigation — "The Gu" Red Shirt XL & 4XL
-- Purpose  : Root cause analysis of poor OTIF performance on
--            specific shirt sizes identified via Power BI dashboard
-- Finding  : Newly listed product (May 2016) with no formal
--            replenishment process — stock depleted with no PO
--            raised until end of dataset period
-- Author   : James Sakanak
-- Date     : May 2026
-- ============================================================

-- ============================================================
-- SUMMARY OF FINDINGS
-- ============================================================
-- Step 1: Power BI OTIF dashboard identified XL and 4XL sizes
--         of "The Gu" red shirt performing at 17% and 24% OTIF
--         respectively, vs 99%+ for all other sizes
--
-- Step 2: SQL analysis confirmed lower order volumes for XL/4XL
--         vs other sizes — ruling out high demand as the cause
--
-- Step 3: Purchase order investigation revealed only ONE PO
--         ever raised for each size, on 31st May 2016, with
--         zero units received — confirming no replenishment
--
-- Step 4: Stock item master data revealed ValidFrom = 2016-05-31
--         for ALL shirt sizes — product range only formally
--         added to system on that date despite orders going
--         back to 2013
--
-- ROOT CAUSE: Brand new product line added to system May 2016.
--             XL and 4XL had insufficient opening stock.
--             No reorder process in place before system setup.
--             Stock depleted with no replenishment — every
--             customer order fulfilled from residual stock only.
-- ============================================================


-- ============================================================
-- Step 1: OTIF performance by shirt size
-- Identifies XL and 4XL as significant outliers
-- ============================================================

SELECT
    si.StockItemName,
    si.LeadTimeDays,
    COUNT(f.OrderLineID)                            AS TotalOrders,
    SUM(f.Quantity)                                 AS TotalQuantity,
    SUM(CASE WHEN f.IsOTIF = 0 
        THEN f.Quantity ELSE 0 END)                 AS QuantityOnLateOrders,
    ROUND(100.0 * SUM(CAST(f.IsOTIF AS INT)) 
        / COUNT(f.OrderLineID), 2)                  AS OTIF_Pct
FROM WideWorldImportersDW.dbo.FactOrders f
JOIN WideWorldImportersDW.dbo.DimStockItem si 
    ON f.StockItemID = si.StockItemID
WHERE si.StockItemName LIKE '%Gu%red shirt%Black%'
GROUP BY si.StockItemName, si.LeadTimeDays
ORDER BY OTIF_Pct ASC;


-- ============================================================
-- Step 2: Purchase order history for XL and 4XL
-- Confirms only one PO ever raised, never fulfilled
-- ============================================================

SELECT
    si.StockItemName,
    COUNT(pol.PurchaseOrderLineID)                  AS TotalPOLines,
    COUNT(DISTINCT po.PurchaseOrderID)              AS TotalPOs,
    SUM(pol.OrderedOuters)                          AS TotalOrdered,
    SUM(pol.ReceivedOuters)                         AS TotalReceived,
    SUM(pol.OrderedOuters - pol.ReceivedOuters)     AS TotalMissed,
    MIN(po.OrderDate)                               AS FirstPO,
    MAX(po.OrderDate)                               AS LastPO,
    MAX(CAST(pol.IsOrderLineFinalized AS INT))      AS IsFinalized
FROM WideWorldImporters.Purchasing.PurchaseOrderLines pol
JOIN WideWorldImporters.Purchasing.PurchaseOrders po
    ON pol.PurchaseOrderID = po.PurchaseOrderID
JOIN WideWorldImporters.Warehouse.StockItems si
    ON pol.StockItemID = si.StockItemID
WHERE si.StockItemName LIKE '%Gu%red shirt%Black%'
  AND si.StockItemName LIKE '%XL%'
  AND (pol.OrderedOuters - pol.ReceivedOuters) > 1
GROUP BY si.StockItemName
ORDER BY si.StockItemName;




-- ============================================================
-- Step 3: Stock item master — ValidFrom date investigation
-- Reveals entire product range added to system May 2016
-- ============================================================

SELECT
    StockItemID,
    StockItemName,
    Size,
    LeadTimeDays,
    QuantityPerOuter,
    UnitPrice,
    ValidFrom,
    ValidTo,
    JSON_VALUE(CustomFields, '$.Range')             AS ProductRange
FROM WideWorldImporters.Warehouse.StockItems
WHERE StockItemName LIKE '%Gu%red shirt%Black%'
ORDER BY StockItemName;


-- ============================================================
-- Step 4: Full purchase order detail for XL and 4XL
-- Shows outstanding unfulfilled orders at dataset end
-- ============================================================

SELECT
    si.StockItemName,
    po.OrderDate,
    po.ExpectedDeliveryDate,
    pol.OrderedOuters,
    pol.ReceivedOuters,
    pol.OrderedOuters - pol.ReceivedOuters          AS MissedQuantity,
    pol.LastReceiptDate,
    pol.IsOrderLineFinalized,
    v.SupplierName
FROM WideWorldImporters.Purchasing.PurchaseOrderLines pol
JOIN WideWorldImporters.Purchasing.PurchaseOrders po
    ON pol.PurchaseOrderID = po.PurchaseOrderID
JOIN WideWorldImporters.Warehouse.StockItems si
    ON pol.StockItemID = si.StockItemID
JOIN WideWorldImporters.Purchasing.Suppliers v
    ON po.SupplierID = v.SupplierID
WHERE si.StockItemName LIKE '%Gu%red shirt%Black%'
  AND si.StockItemName LIKE '%XL%'
  AND (pol.OrderedOuters - pol.ReceivedOuters) > 1
ORDER BY si.StockItemName, po.OrderDate;