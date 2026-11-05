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
| fct_bookings |