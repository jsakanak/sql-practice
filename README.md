# Supply Chain Analytics — WideWorldImporters

An end-to-end supply chain analytics project using **WideWorldImporters** on SQL Server Express.  
Built as part of a structured progression toward PL-300 and DP-600 certification, and to support a transition into data analyst roles in supply chain and logistics.

---

## Project Overview

This project covers the full analytics stack — from raw OLTP data through to interactive Power BI reporting:

- **SQL pipeline** — data warehouse built from scratch using T-SQL
- **Power BI dashboard** — OTIF reporting built on the warehouse
- **Supply chain analysis** — applied investigations into operational issues
- **Python automation** — pipeline scheduling and orchestration (planned)

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
| **On Time** | `CAST(ConfirmedDeliveryTime AS DATE)` ≤ `ExpectedDeliveryDate` |
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
                   DimPeople
```

**FactOrders** (grain: one row per order line)

| Column | Description |
|---|---|
| OrderLineID | Primary key |
| OrderID | Order reference |
| CustomerID | FK → DimCustomer |
| StockItemID | FK → DimStockItem |
| OrderDateKey | FK → DimDate |
| ExpectedDeliveryDateKey | FK → DimDate |
| SalespersonPersonID | FK → DimPeople |
| PickedByPersonID | FK → DimPeople (nullable) |
| Quantity | Quantity ordered |
| PickedQuantity | Quantity fulfilled |
| UnitPrice | Line unit price |
| TotalLineValue | Quantity × UnitPrice |
| IsInFull | 1 if PickedQuantity >= Quantity |
| IsOnTime | 1 if delivered by expected date, NULL if unconfirmed |
| IsOTIF | 1 if both conditions met, NULL if unconfirmed |
| DaysLate | Days beyond expected delivery, NULL if unconfirmed |
| BackorderQuantity | Quantity - PickedQuantity |

**Data Notes:**
- 3,147 order lines excluded — no matching invoice (open orders)
- 284 order lines (84 orders) have NULL OTIF flags — no confirmed delivery time
- DeliveryMethodID removed — all orders use Delivery Van (ID 3)

---

## Folder Structure

```
supply-chain-analytics-wwi/
│
├── sql/
│   ├── pipeline/            # DW build scripts and ETL pipeline
│   ├── analysis/            # Applied supply chain investigations
│   └── exploration/         # Schema profiling and dimension design
│
├── powerbi/
│   └── screenshots/         # Dashboard screenshots
│
├── python/                  # Automation scripts (planned)
├── notebooks/               # Jupyter notebooks (planned)
│
├── .gitignore
└── README.md
```

---

## Progress

### OTIF Pipeline
| Phase | Status |
|---|---|
| Schema exploration | ✅ Complete |
| Star schema design | ✅ Complete |
| DW database build | ✅ Complete |
| Dimension pipeline | ✅ Complete |
| Fact pipeline | ✅ Complete |
| Power BI connection | ✅ Complete |
| OTIF dashboard | 🟡 In progress |

### Supply Chain Analysis
| Investigation | Status |
|---|---|
| Gu shirt XL/4XL OTIF root cause | ✅ Complete |

### Automation (Planned)
| Task | Status |
|---|---|
| Wrap pipeline into stored procedure | 🔲 Not started |
| SQL Server Agent Job nightly refresh | 🔲 Not started |
| Python pipeline scheduling | 🔲 Not started |

---

## Key Findings

**Gu Shirt OTIF Investigation (May 2026)**  
OTIF dashboard identified XL (17%) and 4XL (24%) as significant outliers vs 99%+ for all other sizes. SQL investigation across sales, purchasing, and stock holdings confirmed near-zero stock on hand at dataset end (XL = 48 units, 4XL = 25 units vs 51,000–525,000 for other sizes). Purchasing data quality limitations prevented full replenishment analysis. Documented in `sql/analysis/01_gu_shirt_otif_size_analysis.sql`.

---

## Commit Convention

```
[folder] Short description

Examples:
[sql/pipeline] Create and populate DimCustomer
[sql/analysis] OTIF root cause analysis for Gu shirt range
[powerbi] Add OTIF Overview dashboard screenshots
[python] Add pipeline scheduling script
```

---

## Certification Roadmap

| Cert | Target |
|---|---|
| PL-300 Power BI Data Analyst | June 2026 |
| DP-600 Fabric Analytics Engineer | September 2026 |
| Databricks Certified Data Analyst Associate | December 2026 |
