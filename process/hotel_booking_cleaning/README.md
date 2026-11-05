# Otel İptal Projesi: dbt Veri Temizleme ve Modelleme

Bu proje, Kaggle Hotel Booking Demand veri setini temizlemek; hava durumu ve EUROCONTROL havalimanı gecikme verileriyle birleştirerek analiz ve raporlamaya uygun hale getirmek amacıyla geliştirilmiştir.

Proje kapsamında dbt ve DuckDB kullanılarak staging, intermediate ve mart katmanlarından oluşan bir veri modelleme süreci oluşturulmuştur.

## Veri Kaynakları

| Kaynak | Dosya / Konum |
|---|---|
| Kaggle Hotel Booking Demand (119.390 rezervasyon, 2015-2017) | `data/raw/hotel_booking/hotel_bookings.csv` |
| Open-Meteo günlük hava durumu (Faro, Lizbon) | `data/raw/open_meteo/` |
| EUROCONTROL havalimanı gecikmeleri (2015-2017) | `data/raw/eurocontrol/` |

**Varsayım:** Ham otel veri setinde otellerin konum bilgisi bulunmamaktadır. Bu nedenle Resort Hotel'in Algarve/Faro, City Hotel'in ise Lizbon'da bulunduğu varsayılmıştır. Hava durumu ve havalimanı gecikme verileri bu eşleştirmeye göre birleştirilmiştir.

## Veri Modeli ve Katmanlar

| Katman | Model | Açıklama |
|---|---|---|
| staging | `stg_hotel_bookings` | Ham otel CSV dosyasını okur, temizler, tarih ve `booking_id` alanlarını oluşturur. |
| staging | `stg_weather` | Faro ve Lizbon günlük hava durumu verilerini okur ve otellerle eşleştirir. |
| staging | `stg_eurocontrol` | Faro (LPFR) ve Lizbon (LPPT) havalimanlarına ait gecikme verilerini işler. |
| intermediate | `int_hotel_bookings_flagged` | Birebir aynı kayıtları silmeden `is_duplicate` alanıyla işaretler. |
| marts | `dim_date` | Tarih boyut tablosudur. |
| marts | `fct_bookings` | Rezervasyon, hava durumu ve havalimanı verilerini birleştiren ana analiz tablosudur. |
| marts | `mart_monthly_cancellations` | Aylık iptal istatistiklerini özetler. |
| marts | `mart_weather_cancellations` | Hava durumu koşullarına göre iptal istatistiklerini özetler. |
| marts | `mart_flight_delay_cancellations` | Havalimanı gecikme günleri ile rezervasyon iptalleri arasındaki ilişkiyi özetler. |
| marts | `mart_airport_delays` | Havalimanı bazında gecikme istatistiklerini gösterir. |
| marts | `mart_yearly_delays` | Yıllık havalimanı gecikme istatistiklerini gösterir. |
| marts | `mart_airport_monthly_delay` | Havalimanı bazında aylık gecikme istatistiklerini gösterir. |

Model katmanları ayrı klasörlerde tutulmaktadır:

- `models/staging`
- `models/intermediate`
- `models/marts`

## Kurulum ve Çalıştırma

Gerekli paketlerin kurulması:

```bash
pip install dbt-duckdb
## Kurulum

Gerekli paketlerin kurulmasi:
``bash
pip install dbt-duckdb
``
