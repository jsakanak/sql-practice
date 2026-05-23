# SQL Practice & WideWorldImporters OTIF Pipeline

SQL development and data warehouse pipeline project using **WideWorldImporters** on SQL Server Express.  
Built as part of a structured progression toward PL-300 and DP-600 certification, and to support a transition into data analyst roles in supply chain and logistics.

---

## Project Overview

This repository contains two streams of work:

**Stream 1 — SQL Practice**  
Structured query practice covering core T-SQL concepts, using WideWorldImporters as the source database. Exercises progress from basics through to window functions, CTEs, and stored procedures.

**Stream 2 — OTIF Pipeline**  
An end-to-end data warehouse pipeline built from scratch. Extracts data from the WideWorldImporters OLTP database, transforms it into a star schema, and loads it into a custom data warehouse — ready for Power BI reporting.

---

## Database

**WideWorldImporters** — Microsoft's sample OLTP database for a fictional novelty goods importer/exporter.  
Key schemas used:

| Schema | Contents |
|---|---|
| `Sales` | Customer orders, invoices, transactions |
| `Warehouse` | Stock items, inventory, movements |
| `Purchasing` | Supplier orders, deliveries |
| `Application` | Reference data — people, cities, delivery methods |

Download: [Microsoft SQL Server Samples](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0)

---

## OTIF Pipeline

### What is OTIF?
**On Time In Full (OTIF)** is the gold standard supply chain KPI — measuring whether customer orders were delivered on time and with the correct quantity fulfilled.

| Component | Definition |
|---|---|
| **On Time** | `ConfirmedDeliveryTime` ≤ `ExpectedDeliveryDate` |
| **In Full** | `PickedQuantity` ≥ `Quantity` |
| **OTIF** | Both conditions met |

### Pipeline Architecture
```
WideWorldImporters (OLTP)
        │
        │  T-SQL Pipeline
        ▼
WideWorldImportersDW (Star Schema)
        │
        │  Power BI
        ▼
    OTIF Dashboard
```

### Star Schema Design

```
                    DimDate
                       │
DimCustomer ──── FactOrders ──── DimStockItem
                       │
              DimDeliveryMethod
                       │
                   DimPeople
```

**FactOrders** (grain: one row per order line)

| Column | Description |
|---|---|
| OrderLineID | Primary key |
| OrderID | Order reference |
| CustomerID | FK → DimCustomer |
| StockItemID | FK → DimStockItem |
| DeliveryMethodID | FK → DimDeliveryMethod |
| OrderDateKey | FK → DimDate |
| ExpectedDeliveryDateKey | FK → DimDate |
| Quantity | Quantity ordered |
| PickedQuantity | Quantity fulfilled |
| UnitPrice | Line unit price |
| TotalLineValue | Quantity × UnitPrice |
| IsInFull | 1 if PickedQuantity >= Quantity |
| IsOnTime | 1 if delivered by expected date |
| IsOTIF | 1 if both conditions met |
| DaysLate | Days beyond expected delivery |
| BackorderQuantity | Quantity - PickedQuantity |

---

## Folder Structure

```
sql-practice/
│
├── 01_exploration/          # Schema and column profiling queries
├── 02_wwi_dimensions/       # Dimension design and profiling
├── 03_basics/               # SELECT, FROM, WHERE, aliases
├── 04_filtering_sorting/    # WHERE, ORDER BY, TOP, DISTINCT
├── 05_joins/                # INNER, LEFT, RIGHT, FULL
├── 06_aggregation/          # GROUP BY, HAVING, aggregate functions
├── 07_subqueries/           # Correlated, scalar, EXISTS, IN
├── 08_window_functions/     # ROW_NUMBER, RANK, LAG, LEAD
├── 09_case_when/            # Conditional logic and bucketing
├── 10_ctes/                 # Common Table Expressions
├── 11_stored_procedures/    # Parameters, error handling
├── 12_pipeline/             # DW build scripts and ETL pipeline
├── notebooks/               # Jupyter notebooks for Python analysis
│
├── .gitignore
└── README.md
```

---

## Progress

### SQL Practice
| Topic | Status |
|---|---|
| 01 — Exploration & Profiling | 🟡 In progress |
| 02 — WWI Dimension Design | 🟡 In progress |
| 03 — Basics | 🔲 Not started |
| 04 — Filtering & Sorting | 🔲 Not started |
| 05 — Joins | 🔲 Not started |
| 06 — Aggregation | 🔲 Not started |
| 07 — Subqueries | 🔲 Not started |
| 08 — Window Functions | 🔲 Not started |
| 09 — CASE WHEN | 🔲 Not started |
| 10 — CTEs | 🔲 Not started |
| 11 — Stored Procedures | 🔲 Not started |

### OTIF Pipeline
| Phase | Status |
|---|---|
| Schema exploration | ✅ Complete |
| Star schema design | 🟡 In progress |
| DW database build | 🔲 Not started |
| Dimension pipeline | 🔲 Not started |
| Fact pipeline | 🔲 Not started |
| Power BI connection | 🔲 Not started |
| OTIF dashboard | 🔲 Not started |

---

## Commit Convention

```
[folder] Short description

Examples:
[01_exploration] Schema and column profiling queries for WWI
[12_pipeline] Create DimCustomer table and INSERT pipeline
[08_window_functions] Running OTIF % by customer using window functions
```

---

## Certification Roadmap

| Cert | Target |
|---|---|
| PL-300 Power BI Data Analyst | June 2026 |
| DP-600 Fabric Analytics Engineer | September 2026 |
| Databricks Certified Data Analyst Associate | December 2026 |
