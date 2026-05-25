
-- ============================================================
-- Database : WideWorldImportersDW / WideWorldImporters
-- Query    : OTIF analysis for The Gu red shirt product range
-- Purpose  : Investigate poor OTIF performance on XL and 4XL sizes
-- Finding  : XL (17% OTIF) and 4XL (24% OTIF) significantly
--            underperform vs other sizes (99%+)
--            Lower order volumes suggest chronic stock availability
--            issue — demand signal distortion likely cause
-- Author   : James Sakanak
-- Date     : May 2026
-- ============================================================

-- Compare lead times and performance across shirt sizes
SELECT
    si.StockItemName,
    si.LeadTimeDays,
    COUNT(f.OrderLineID)                    AS TotalOrders,
    SUM(f.Quantity)                         AS TotalQuantity,
    SUM(CASE WHEN f.IsOTIF = 0 
        THEN f.Quantity ELSE 0 END)         AS QuantityOnLateOrders,
    ROUND(100.0 * SUM(CAST(f.IsOTIF AS INT)) 
        / COUNT(f.OrderLineID), 2)          AS OTIF_Pct
FROM FactOrders f
JOIN DimStockItem si ON f.StockItemID = si.StockItemID
WHERE si.StockItemName LIKE '%Gu%red shirt%Black%'
GROUP BY si.StockItemName, si.LeadTimeDays
ORDER BY OTIF_Pct ASC;

SELECT
    si.StockItemName,
    COUNT(f.OrderLineID)        AS TotalOrders,
    SUM(f.Quantity)             AS TotalQuantity,
    AVG(f.Quantity)             AS AvgOrderQty,
    ROUND(100.0 * SUM(CAST(f.IsOTIF AS INT)) 
        / COUNT(f.OrderLineID), 2) AS OTIF_Pct
FROM FactOrders f
JOIN DimStockItem si ON f.StockItemID = si.StockItemID
WHERE si.StockItemName LIKE '%Gu%red shirt%Black%'
GROUP BY si.StockItemName
ORDER BY TotalQuantity DESC;