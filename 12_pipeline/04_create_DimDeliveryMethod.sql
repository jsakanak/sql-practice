-- ============================================================
-- Database : WideWorldImportersDW
-- Table    : DimDeliveryMethod
-- Purpose  : Delivery method dimension for OTIF reporting
-- Source   : Application.DeliveryMethods
-- Author   : James Sakanak
-- Date     : May 2026
-- ============================================================

CREATE TABLE DimDeliveryMethod (
    DeliveryMethodID        INT             NOT NULL PRIMARY KEY,
    DeliveryMethodName      NVARCHAR(50)    NOT NULL
);

-- ============================================================
-- Populate DimDeliveryMethod
-- ============================================================

INSERT INTO DimDeliveryMethod
SELECT
    DeliveryMethodID,
    DeliveryMethodName
FROM WideWorldImporters.Application.DeliveryMethods;