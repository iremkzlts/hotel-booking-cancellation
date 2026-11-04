# Otel İptal Projesi: dbt Projesi

Kaggle "Hotel Booking Demand" verisini temizleyen ve analize hazırlayan dbt (DuckDB) projesi.

## Veri kaynakları

| Kaynak | Dosya |
|---|---|
| Kaggle Hotel Booking Demand (119.390 rezervasyon, 2015-2017) | `data/raw/hotel_booking/hotel_bookings.csv` |
| Open-Meteo günlük hava durumu (Faro, Lizbon) | `data/raw/open_meteo/` |
| EUROCONTROL havalimanı gecikmeleri (2015-2017) | `data/raw/eurocontrol/` |

**Varsayım:** Veri setinde otel konumu yazmıyor. Resort Hotel'in Algarve'de (Faro), City Hotel'in Lizbon'da olduğu kabul edildi. Hava ve havalimanı verisi bu eşleştirmeyle bağlanıyor.

## Model katmanları

| Katman | Model | Ne yapar |
|---|---|---|
| staging | `stg_hotel_bookings` | Ham CSV'yi okur, temizler, tarih üretir |
| intermediate | `int_hotel_bookings_flagged` | Birebir aynı satırları `is_duplicate` ile işaretler |

Hava, Eurocontrol ve mart modelleri eklenecek.

## Çalıştırma

```
pip install dbt-duckdb
cd process/hotel_booking_cleaning
dbt run
dbt test
dbt docs generate
dbt docs serve
```

## Temizlik kararları

| Karar | Gerekçe |
|---|---|
| `NULL` yazan hücreler gerçek boş değere çevrildi | Ham dosyada boş değerler metin olarak yazılmış |
| Yıl, ay adı ve günden `arrival_date` üretildi | Ham veride tarih üç ayrı sütunda |
| Boş `children` değerleri 0 yapıldı | 4 satırda boş, çocuk yok kabul edildi |
| `adr` negatif olan 1 satır çıkarıldı (rezervasyon 14970, -6,38) | Negatif günlük fiyat anlamsız |
| Yetişkin, çocuk ve bebek toplamı 0 olan 180 satır çıkarıldı | Misafirsiz rezervasyon anlamsız |
| Birebir aynı 32238 satır silinmedi, `is_duplicate` ile işaretlendi | Kimlik sütunu olmadığı için gerçek kopya oldukları kesin değil |
| `reservation_status` ve `reservation_status_date` modelde kullanılmayacak | İptal sonucunu doğrudan ele verir (veri sızıntısı) |

Temizlik sonrası 119.209 satır kalır. İptal oranı tüm satırlarda %37.1, kopya işaretli satırlar çıkarılınca %27.3.

## Testler

8 test: `booking_id` benzersiz ve dolu, `hotel` iki değerden biri, `is_canceled` 0 veya 1 ve dolu, `arrival_date` dolu, negatif fiyat yok, misafirsiz rezervasyon yok.

## Sınırlılıklar

- Kopya satırların gerçek kopya olup olmadığı veriden anlaşılamıyor.
- Otel konumu varsayıma dayanıyor.
- `adr` için para birimi veri setinde belirtilmemiş.