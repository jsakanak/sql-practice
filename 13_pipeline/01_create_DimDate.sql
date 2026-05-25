-- ============================================================
-- Database : WideWorldImportersDW
-- Table    : DimDate
-- Purpose  : Generated date dimension covering WWI data range 2013-2016
-- Source   : No source table — generated via WHILE loop
-- Author   : James Sakanak
-- Date     : May 2026
-- ============================================================

CREATE TABLE DimDate (
    DateKey             INT             NOT NULL PRIMARY KEY,  -- YYYYMMDD
    FullDate            DATE            NOT NULL,
    DayOfWeek           TINYINT         NOT NULL,
    DayName             NVARCHAR(10)    NOT NULL,
    DayOfMonth          TINYINT         NOT NULL,
    DayOfYear           SMALLINT        NOT NULL,
    WeekNumber          TINYINT         NOT NULL,
    Month               TINYINT         NOT NULL,
    MonthName           NVARCHAR(10)    NOT NULL,
    Quarter             TINYINT         NOT NULL,
    QuarterName         NVARCHAR(6)     NOT NULL,
    Year                SMALLINT        NOT NULL,
    IsWeekend           BIT             NOT NULL
);

-- ============================================================
-- Populate DimDate 2013-2016
-- ============================================================

DECLARE @StartDate DATE = '2013-01-01';
DECLARE @EndDate   DATE = '2016-12-31';
DECLARE @Date      DATE = @StartDate;

WHILE @Date <= @EndDate
BEGIN
    INSERT INTO DimDate
    VALUES (
        CAST(FORMAT(@Date, 'yyyyMMdd') AS INT),
        @Date,
        DATEPART(WEEKDAY, @Date),
        DATENAME(WEEKDAY, @Date),
        DAY(@Date),
        DATEPART(DAYOFYEAR, @Date),
        DATEPART(WEEK, @Date),
        MONTH(@Date),
        DATENAME(MONTH, @Date),
        DATEPART(QUARTER, @Date),
        'Q' + CAST(DATEPART(QUARTER, @Date) AS NVARCHAR),
        YEAR(@Date),
        CASE WHEN DATEPART(WEEKDAY, @Date) IN (1,7) THEN 1 ELSE 0 END
    );

    SET @Date = DATEADD(DAY, 1, @Date);
END;