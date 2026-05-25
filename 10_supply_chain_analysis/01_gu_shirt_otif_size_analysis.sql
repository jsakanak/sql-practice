-- ============================================================
-- Database : WideWorldImporters / WideWorldImportersDW
-- Analysis : OTIF Investigation — "The Gu" Red Shirt XL & 4XL
-- Purpose  : Root cause analysis of poor OTIF performance on
--            specific shirt sizes identified via Power BI dashboard
-- Author   : James Sakanak
-- Date     : May 2026
-- ============================================================

-- ============================================================
-- SUMMARY OF FINDINGS
-- ============================================================
-- ISSUE IDENTIFIED:
-- Power BI OTIF dashboard flagged XL (17% OTIF) and 4XL (24%)
-- as significant outliers vs 99%+ for all other shirt sizes.
--
-- INVESTIGATION STEPS:
-- Step 1: OTIF by size — confirmed XL/4XL as outliers
-- Step 2: PO history — initial filter showed 1 unfulfilled PO
--         but this was misleading (filter excluded fulfilled POs)
-- Step 3: System migration check — ALL 227 stock items share
--         ValidFrom = 2016-05-31, confirming a data migration.
--         ValidFrom cannot be used to determine product history.
-- Step 4: Full replenishment vs sales analysis — purchasing data
--         for StockItemID 95 (XL) and 98 (4XL) shows anomalous
--         PO counts (963 and 954) vs 1 PO for all other sizes,
--         with replenishment volumes (9.2M and 18.8M units) far
--         exceeding total sales. This is inconsistent with the
--         rest of the range and suggests a data quality issue
--         in the WideWorldImporters sample database.
--
-- DATA QUALITY LIMITATION:
-- Purchasing data for XL and 4XL StockItemIDs appears to contain
-- records that do not belong to these items — likely a data
-- generation artefact in the WWI sample database. Replenishment
-- analysis cannot be completed reliably for these sizes.
--
-- CONCLUSION:
-- The purchasing schema does not provide sufficient data quality
-- to definitively determine root cause. Based on OTIF and sales
-- data alone, the most likely operational explanations are:
--   A) Insufficient opening stock for XL/4XL at migration
--   B) Replenishment frequency not keeping pace with demand
--   C) Demand signal distortion — poor service reducing orders
--      which further reduces perceived demand
--
-- RECOMMENDATION:
-- In a real environment, cross-reference with:
--   1. Stock on hand at time of each failed order
--   2. Reorder point and safety stock settings per SKU
--   3. Supplier lead time variability for these sizes
--   4. Historical demand forecasts vs actuals
--
-- FINAL CONFIRMATION:
-- StockItemHoldings confirms stock depletion at dataset end:
--   XL  = 48 units remaining
--   4XL = 25 units remaining
--   All other sizes = 51,000 to 525,000 units
-- Stock depletion is confirmed as the primary operational cause.
-- No time-series stock data available in WWI to trace the
-- depletion trajectory over the 2013-2016 period.
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
-- Step 2: Purchase order history — undelivered POs only
-- NOTE: This query only returns unfulfilled POs
--       Full PO history exists for XL/4XL — see Step 4
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
-- Step 3: System migration check
-- All 227 stock items share ValidFrom = 2016-05-31
-- Confirms data migration — ValidFrom not reliable for analysis
-- ============================================================

SELECT 
    CAST(ValidFrom AS DATE)                         AS ValidFromDate,
    COUNT(*)                                        AS ItemCount
FROM WideWorldImporters.Warehouse.StockItems
GROUP BY CAST(ValidFrom AS DATE)
ORDER BY ItemCount DESC;


-- ============================================================
-- Step 4: Replenishment vs sales analysis
-- Uses temp tables to avoid cartesian product between
-- sales and purchasing data sources
-- NOTE: XL and 4XL show anomalous PO counts — see data
--       quality note in summary above
-- ============================================================

-- Clean up temp tables if they exist
IF OBJECT_ID('tempdb..#Sales') IS NOT NULL DROP TABLE #Sales;
IF OBJECT_ID('tempdb..#Purchasing') IS NOT NULL DROP TABLE #Purchasing;

-- Sales side
SELECT
    si.StockItemName,
    COUNT(DISTINCT f.OrderLineID)                   AS TotalSalesOrders,
    SUM(f.Quantity)                                 AS TotalUnitsSold
INTO #Sales
FROM WideWorldImportersDW.dbo.FactOrders f
JOIN WideWorldImportersDW.dbo.DimStockItem si 
    ON f.StockItemID = si.StockItemID
WHERE si.StockItemName LIKE '%Gu%red shirt%Black%'
GROUP BY si.StockItemName;

-- Purchasing side
SELECT
    si.StockItemName,
    COUNT(DISTINCT po.PurchaseOrderID)              AS TotalPOs,
    SUM(pol.ReceivedOuters)                         AS TotalOutersReceived,
    AVG(pol.OrderedOuters)                          AS AvgOutersPerPO
INTO #Purchasing
FROM WideWorldImporters.Purchasing.PurchaseOrderLines pol
JOIN WideWorldImporters.Purchasing.PurchaseOrders po
    ON pol.PurchaseOrderID = po.PurchaseOrderID
JOIN WideWorldImporters.Warehouse.StockItems si
    ON pol.StockItemID = si.StockItemID
WHERE si.StockItemName LIKE '%Gu%red shirt%Black%'
GROUP BY si.StockItemName;

-- Combine with unit conversion (QuantityPerOuter = 12 for all shirts)
SELECT
    s.StockItemName,
    s.TotalSalesOrders,
    s.TotalUnitsSold,
    p.TotalPOs,
    p.TotalOutersReceived,
    p.TotalOutersReceived * 12                      AS TotalUnitsReplenished,
    p.AvgOutersPerPO * 12                           AS AvgUnitsPerDelivery,
    s.TotalUnitsSold - 
        (p.TotalOutersReceived * 12)                AS ReplenishmentGap
FROM #Sales s
LEFT JOIN #Purchasing p 
    ON s.StockItemName COLLATE Latin1_General_CI_AS = 
       p.StockItemName COLLATE Latin1_General_CI_AS
ORDER BY ReplenishmentGap DESC;

-- Clean up
DROP TABLE #Sales;
DROP TABLE #Purchasing;

-- ============================================================
-- Step 5: Current stock on hand confirmation
-- Confirms near-zero stock for XL and 4XL at dataset end
-- Source : Warehouse.StockItemHoldings (point-in-time only)
-- ============================================================

SELECT
    si.StockItemName,
    sh.QuantityOnHand,
    sh.BinLocation,
    sh.LastStocktakeQuantity,
    sh.LastEditedWhen
FROM WideWorldImporters.Warehouse.StockItemHoldings sh
JOIN WideWorldImporters.Warehouse.StockItems si
    ON sh.StockItemID = si.StockItemID
WHERE si.StockItemName LIKE '%Gu%red shirt%Black%'
ORDER BY si.StockItemName;