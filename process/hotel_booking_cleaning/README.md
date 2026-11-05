# Otel İptal Projesi: dbt Projesi

Kaggle "Hotel Booking Demand" verisini temizleyen, hava durumu ve havalimanı gecikme verisiyle birleştirip analize hazırlayan dbt (DuckDB) projesi.

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
| staging | `stg_hotel_bookings` | Ham otel CSV'sini okur, temizler, tarih ve `booking_id` üretir |
| staging | `stg_weather` | Faro ve Lizbon günlük hava durumunu okur, otel ile eşleştirir |
| staging | `stg_eurocontrol` | Faro (LPFR) ve Lizbon (LPPT) havalimanı gecikmelerini okur |
| intermediate | `int_hotel_bookings_flagged` | Birebir aynı satırları `is_duplicate` ile işaretler |
| marts | `dim_date` | Tarih boyut tablosu |
| marts | `fct_bookings` | Rezervasyon, hava durumu ve havalimanı verisini birleştiren ana tablo |
| marts | `mart_monthly_cancellations` | Aylık iptal özeti |
| marts | `mart_weather_cancellations` | Hava durumuna göre iptal özeti |
| marts | `mart_flight_delay_cancellations` | Havalimanı gecikmesine göre iptal özeti |
| marts | `mart_airport_delays` | Havalimanı gecikme özeti |
| marts | `mart_yearly_delays` | Yıllık gecikme özeti |

Staging, intermediate ve mart katmanları ayrı klasörlerdedir: `models/staging`, `models/intermediate`, `models/marts`.

## Çalıştırma

```
pip install dbt-duckdb
cd process/hotel_booking_cleaning
dbt run
dbt test
dbt docs generate
dbt docs serve
```

## Temizlik kararları (otel verisi)

| Karar | Gerekçe |
|---|---|
| `NULL` yazan hücreler gerçek boş değere çevrildi | Ham dosyada boş değerler metin olarak yazılmış |
| Yıl, ay adı ve günden `arrival_date` üretildi | Ham veride tarih üç ayrı sütunda |
| `booking_id` ham CSV'deki satır numarasıyla üretildi | Ham veride kimlik yok. Satır çıkarılsa bile numaralar değişmez |
| Boş `children` değerleri 0 yapıldı | 4 satırda boş, çocuk yok kabul edildi |
| `adr` negatif olan 1 satır çıkarıldı (rezervasyon 14970, -6,38) | Negatif günlük fiyat anlamsız |
| Yetişkin, çocuk ve bebek toplamı 0 olan 180 satır çıkarıldı | Misafirsiz rezervasyon anlamsız |
| `adr` değeri 1000'in üzerinde olan 1 satır çıkarıldı (5400) | Gerçek dışı fiyat, kaybedilen gelir toplamlarını şişiriyordu |
| Birebir aynı 32.238 satır silinmedi, `is_duplicate` ile işaretlendi | Kimlik sütunu olmadığı için gerçek kopya oldukları kesin değil |
| `reservation_status` ve `reservation_status_date` modelde kullanılmayacak | İptal sonucunu doğrudan ele verir (veri sızıntısı) |

Satır sayısı: 119.390 ham satırdan 1 negatif fiyatlı, 180 misafirsiz ve 1 uç fiyatlı satır çıkarılınca **119.208** satır kalır. İptal oranı tüm satırlarda %37,1, kopya işaretli satırlar çıkarılınca %27,3.

## Testler

`dbt test` ile çalışır. Otel verisi için başlıca testler: `booking_id` benzersiz ve dolu, `hotel` iki değerden biri, `is_canceled` 0 veya 1 ve dolu, `arrival_date` dolu, negatif fiyat yok, misafirsiz rezervasyon yok. Hava durumu, Eurocontrol ve mart modellerinin testleri kendi şema dosyalarındadır.

## Belgeler

| Belge | Kapsam | Hazırlayan |
|---|---|---|
| [VERI_SOZLUGU_HOTEL_BOOKING.md](VERI_SOZLUGU_HOTEL_BOOKING.md) | Otel rezervasyon verisi | Esma |
| `VERI_SOZLUGU_WEATHER.md` | Hava durumu verisi | Zehra |
| `VERI_SOZLUGU_EUROCONTROL.md` | Havalimanı gecikme verisi | İrem |
| `VERI_SOZLUGU_MART.md` | Mart katmanı | Elif |

Model ve sütun açıklamaları `dbt docs generate` ile de görülebilir.

## Sınırlılıklar

- Kopya satırların gerçek kopya olup olmadığı veriden anlaşılamıyor.
- Otel konumu varsayıma dayanıyor (Resort Hotel = Faro, City Hotel = Lizbon).
- `adr` için para birimi veri setinde belirtilmemiş, Euro varsayıldı.
- Hava durumu ve havalimanı gecikmesi varış gününe ait. Rezervasyon yapılırken bilinmiyor, bu yüzden iptal ile ilişkisi nedensel değil, ilişki olarak yorumlanmalı.
- Faro havalimanı için gecikme kayıtları seyrek.
- `reservation_status`, `reservation_status_date` ve onlardan türeyen gelir sütunları (`realized_revenue`, `lost_revenue`) iptal sonucunu ele verir. İkinci aşamadaki tahmin modelinde kullanılmamalı.