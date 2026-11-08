# Hotel Booking Cancellation Prediction and Analysis System
Hotel Booking Cancellation Prediction and Analysis System YBS305 term project, Part 1 (data pipeline, dbt models and dashboard). The project studies cancellations of two Portuguese hotels (a city hotel in Lisbon and a resort hotel in the Algarve) and enriches the Kaggle Hotel Booking Demand data with daily weather and airport delay data.

**Dashboard (Looker Studio):** [https://datastudio.google.com/reporting/55dc2678-148c-459a-8ec7-e3a4e050e54b](https://datastudio.google.com/reporting/55dc2678-148c-459a-8ec7-e3a4e050e54b)

---

## Project Goal Part 1

Clean and combine three data sources with dbt (staging, intermediate, marts), test them, document them, and present the results in a dashboard.

## Project Goal Part 2 (Planned)

Predict whether a booking will be cancelled (is_canceled) and serve the model in a Streamlit app.

---

## Data Sources

| Source | Content | Location |
| --- | --- | --- |
| **Kaggle Hotel Booking Demand** | 119,390 bookings, 2015-2017 | `data/raw/hotel_booking/` |
| **Open-Meteo** | Daily weather for Faro and Lisbon (temperature, precipitation, wind) | `data/raw/open_meteo/` |
| **EUROCONTROL** | Daily airport arrival delays for Faro (LPFR) and Lisbon (LPPT), 2015-2017 | `data/raw/eurocontrol/` |

> **Assumption:** The booking data does not state where the hotels are. Resort Hotel is assumed to be in the Algarve (Faro) and City Hotel in Lisbon. Weather and airport data are joined to bookings using this mapping.

---

## Repository Structure

```text
.
├── data/
│   ├── raw/                  # original source files
│   └── processed/            # cleaned data and mart tables (CSV)
├── process/
│   ├── clean_eurocontrol.py  # EUROCONTROL cleaning script
│   └── hotel_booking_cleaning/ # dbt project (DuckDB)
│       ├── models/staging/
│       ├── models/intermediate/
│       ├── models/marts/
│       ├── tests/
│       └── VERI_SOZLUGU.md  # data dictionaries
├── dashboard/                # dashboard screenshots and dbt lineage graph
├── requirements.txt
└── README.md

```

---

## dbt Project

The project has 12 models and 71 data tests (all passing).

| Layer | Models |
| --- | --- |
| **Staging** | `stg_hotel_bookings`, `stg_weather`, `stg_eurocontrol` |
| **Intermediate** | `int_hotel_bookings_flagged` (marks exact duplicate rows with `is_duplicate`) |
| **Marts** | `dim_date`, `fct_bookings`, `mart_monthly_cancellations`, `mart_weather_cancellations`, `mart_flight_delay_cancellations`, `mart_airport_delays`, `mart_yearly_delays`, `mart_airport_monthly_delay` |

### Key Cleaning Decisions:

* 1 row with a negative adr and 1 row with adr above 1000 were removed.
* 180 rows with zero guests were removed (119,208 bookings remain).
* 32,238 exact duplicate rows were kept but flagged with `is_duplicate`.
* Details are in the dbt README.

---

## How to Run

```bash
pip install -r requirements.txt
cd process/hotel_booking_cleaning
dbt run
dbt test
dbt docs generate
dbt docs serve

```

*(Note: `dbt run` also rewrites the mart CSV files in `data/processed/marts/`.)*

### Data Preparation Notebook (Google Colab)

The data quality checks behind the dbt cleaning decisions (missing values, duplicates, invalid values, outliers) are documented in a Google Colab notebook. It reads the raw CSV directly from this repository and ends with a check that the cleaned row count matches the dbt staging model (119,208 rows).

- Notebook (Google Drive folder): https://drive.google.com/drive/folders/11qfyyOaEf_oipgr1Sr7U9jE-gKVuZ7yC
- To run: open `otel_rezervasyon_projesi.ipynb` in Colab and choose *Runtime → Restart and run all*.

---

## Dashboard

The Looker Studio report has three pages: General Overview, Weather and Cancellation, and Airport Delay Analysis. Screenshots are in the `dashboard/` folder and are shown in the dbt README.

---

## Main Figures (Verified against dbt queries)

* Total Bookings: **119,208**
* Overall Cancellation Rate: **37.1%** (City Hotel 41.8%, Resort Hotel 27.8%)
* Average Daily Rate: **101.93 EUR**

---

## Data Dictionaries

* Hotel bookings
* Weather
* EUROCONTROL
* Mart layer

---

## Limitations & Findings

* Findings describe associations, not causes.
* Weather and airport delays are not known at booking time.
* Rain has almost no effect on cancellation rates (City Hotel 42.0% on rainy vs 40.7% on dry days; Resort Hotel 27.7% vs 28.2%).
* Days with an airport delay record are almost all City Hotel bookings, so comparisons without the hotel split are misleading.
* "No delay record" means no EUROCONTROL data exists for that day, not that there was no delay.
* Faro (LPFR) delay data is sparse.
* Cancellation rates depend on duplicates: 37.1% with all rows, about 27.3% when duplicates are removed.
* For the Part 2 model, `reservation_status`, `reservation_status_date`, `realized_revenue` and `lost_revenue` must be excluded because they reveal the outcome (data leakage).

---

## Team Member Contribution

* **Esma:** Hotel booking data: dbt staging and intermediate layers, cleaning decisions, tests, dbt README, dashboard page 1.
* **Zehra:** Weather data: `stg_weather`, tests, data dictionary, dashboard page 2.
* **İrem:** EUROCONTROL data: `stg_eurocontrol`, airport marts, data dictionary, repository management, dashboard page 3.
* **Elif:** Mart layer (`dim_date`, `fct_bookings`, summary marts), mart data dictionary, Looker Studio report setup.
