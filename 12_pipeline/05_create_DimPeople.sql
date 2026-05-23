-- ============================================================
-- Database : WideWorldImportersDW
-- Table    : DimPeople
-- Purpose  : People dimension for OTIF reporting
--            Covers salesperson and picker context
-- Source   : Application.People
-- Author   : James Sakanak
-- Date     : May 2026
-- ============================================================

CREATE TABLE DimPeople (
    PersonID        INT             NOT NULL PRIMARY KEY,
    FullName        NVARCHAR(50)    NOT NULL,
    IsEmployee      BIT             NOT NULL,
    IsSalesperson   BIT             NOT NULL,
    EmailAddress    NVARCHAR(256)   NULL
);

-- ============================================================
-- Populate DimPeople
-- ============================================================

INSERT INTO DimPeople
SELECT
    PersonID,
    FullName,
    IsEmployee,
    IsSalesperson,
    EmailAddress
FROM WideWorldImporters.Application.People;