-- ============================================================
-- Database : WideWorldImportersDW
-- Table    : DimCustomer
-- Purpose  : Customer dimension for OTIF reporting
-- Source   : Sales.Customers, Sales.CustomerCategories,
--            Sales.BuyingGroups
-- Author   : James Sakanak
-- Date     : May 2026
-- ============================================================

CREATE TABLE DimCustomer (
    CustomerID              INT             NOT NULL PRIMARY KEY,
    CustomerName            NVARCHAR(100)   NOT NULL,
    CustomerCategory        NVARCHAR(50)    NOT NULL,
    BuyingGroup             NVARCHAR(50)    NOT NULL,
    DeliveryMethodID        INT             NOT NULL,
    CreditLimit             DECIMAL(18,2)   NULL,
    IsOnCreditHold          BIT             NOT NULL,
    PaymentDays             INT             NOT NULL,
    DeliveryPostalCode      NVARCHAR(10)    NOT NULL
);

-- ============================================================
-- Populate DimCustomer
-- ============================================================

INSERT INTO DimCustomer
SELECT
    c.CustomerID,
    c.CustomerName,
    cc.CustomerCategoryName     AS CustomerCategory,
    ISNULL(bg.BuyingGroupName, 'No Buying Group') AS BuyingGroup,
    c.DeliveryMethodID,
    c.CreditLimit,
    c.IsOnCreditHold,
    c.PaymentDays,
    c.DeliveryPostalCode
FROM WideWorldImporters.Sales.Customers c
JOIN WideWorldImporters.Sales.CustomerCategories cc
    ON c.CustomerCategoryID = cc.CustomerCategoryID
LEFT JOIN WideWorldImporters.Sales.BuyingGroups bg
    ON c.BuyingGroupID = bg.BuyingGroupID;