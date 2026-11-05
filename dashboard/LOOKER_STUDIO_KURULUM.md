# Looker Studio Dashboard Kurulumu

Rapor: [https://datastudio.google.com/reporting/55dc2678-148c-459a-8ec7-e3a4e050e54b]

Rapor sahibi: Elif. Takım üyeleri Editör, bağlantıyı bilen herkes Görüntüleyici.

## 1. Veri kaynakları

`data/processed/marts/` altındaki CSV dosyaları Looker Studio'ya "CSV dosyası yükleme" bağlayıcısıyla yüklendi, her biri ayrı veri kaynağı olarak rapora eklendi.

| Veri kaynağı | Kullanım |
|---|---|
| mart_monthly_cancellations | Genel özet |
| mart_weather_cancellations | Hava durumu sayfası |
| mart_flight_delay_cancellations | Havalimanı gecikmesi sayfası |
| mart_airport_monthly_delay | Havalimanı aylık gecikme trendi |
| fct_bookings | Detay analizler |
| dim_date | Takvim boyutu |

## 2. Hesaplanan alanlar

| Alan | Formül | Tür | Kaynaklar |
|---|---|---|---|
| iptal_orani | `SUM(canceled_bookings) / SUM(total_bookings)` | Yüzde | monthly, weather, flight |
| iptal_orani | `SUM(is_canceled) / COUNT(booking_id)` | Yüzde | fct_bookings |
| ay_baslangici | `PARSE_DATE("%Y-%m-%d", month_start)` | Tarih | monthly, dim_date |
| ay_baslangici | `PARSE_DATE("%Y-%m-%d", arrival_month_start)` | Tarih | fct_bookings |
| ay_baslangici | `PARSE_DATE("%Y-%m-%d", AY_BASLANGICI)` | Tarih | mart_airport_monthly_delay |
| gun | `PARSE_DATE("%Y-%m-%d", date_day)` | Tarih | dim_date |
| gun | `PARSE_DATE("%Y-%m-%d", arrival_date)` | Tarih | fct_bookings |

Önemli: İptal oranı için hazır `cancel_rate` sütununun toplamı veya ortalaması kullanılmaz. Oranların ortalaması yanlış sonuç verir. Her zaman `iptal_orani` kullanılır.

Tarihler CSV'de metin olarak geldiği için `PARSE_DATE` ile Tarih türüne çevrildi.

## 3. Sayfalar ve filtreler

Sayfalar: Genel Özet, Hava Durumu, Havalimanı Gecikmesi.

Her sayfada üç filtre vardır: hotel, tarih aralığı, is_duplicate. Filtreler `mart_monthly_cancellations` kaynağından kuruldu ve diğer kaynaklarla alan adı eşleşmesi (hotel, is_duplicate) üzerinden çalışır. Hava durumu ve havalimanı özet tablolarında tarih sütunu olmadığı için tarih filtresi o sayfalarda etkisizdir.

## 4. Bilinen sınırlar

- Veriler CSV anlık görüntüsüdür. dbt çıktısı yenilenirse CSV'ler Looker Studio'da yeniden yüklenmelidir.
- `mart_airport_monthly_delay` tablosunda hotel ve iptal bilgisi yoktur, yalnızca havalimanı ve ay bazında gecikme vardır. `TOPLAM_UCUS` sütunu ayın gün sayısıdır, uçuş sayısı değildir.
- Hava durumu ve uçuş gecikmesi değerleri rezervasyon anında bilinmez. Bulgular nedensellik değil ilişki gösterir.