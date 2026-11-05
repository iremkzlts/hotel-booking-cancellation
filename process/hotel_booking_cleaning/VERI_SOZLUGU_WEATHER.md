# Veri Sözlüğü: Hava Durumu Verisi (stg_weather)

## Genel bilgi

| Madde | Değer |
|---|---|
| Kaynak | Open-Meteo Historical Weather API (günlük) |
| Ham dosyalar | `data/raw/open_meteo/weather_faro.csv` ve `data/raw/open_meteo/weather_lisbon.csv` |
| Tarih aralığı | 2015-07-01 ile 2017-08-31 (şehir başına 793 gün) |
| Toplam satır | 1.586 (Faro 793 + Lizbon 793) |
| Oluşturan dbt modeli | `stg_weather` (staging) |
| Birleştirme anahtarı | `hotel` ve `weather_date` (otel rezervasyonlarının varış tarihiyle) |

**Otel eşleştirmesi (varsayım):** Otel veri setinde konum yazmıyor. Faro Resort Hotel'e, Lizbon City Hotel'e bağlandı. Bu eşleştirme kaynak makalelerden alınmış bir varsayımdır, veriden doğrulanmamıştır.

**Veri güncellemesi (5 Kasım 2026):** lk indirilen dosyalarda yağış, yağmur ve rüzgâr sütunları tamamen boştu. Veri, Open-Meteo Historical Weather API'den yeniden indirildi ve artık tüm sütunlar dolu. API, istenen konuma en yakın veri hücresini kullanıyor. Faro için bu hücre 37.01, -7.96 koordinatında ve rakımı 0 m (eski dosyada 37.00, -7.90, 22 m). Bu yüzden sıcaklık değerleri eski dosyadan biraz farklı.

## Sütunlar

| Sütun | Tür | Birim | Açıklama |
|---|---|---|---|
| weather_date | tarih | | Gözlem günü |
| temp_mean_c | ondalık | °C | Günlük ortalama sıcaklık |
| temp_max_c | ondalık | °C | Günlük en yüksek sıcaklık |
| temp_min_c | ondalık | °C | Günlük en düşük sıcaklık |
| precipitation_mm | ondalık | mm | Günlük toplam yağış (yağmur + kar vb.) |
| rain_mm | ondalık | mm | Günlük toplam yağmur |
| precipitation_hours | ondalık | saat | Günlük yağışlı saat sayısı |
| wind_speed_max_kmh | ondalık | km/sa | Günlük en yüksek rüzgâr hızı (10 m yükseklikte) |
| city | metin | | Şehir: Faro veya Lisbon |
| hotel | metin | | Şehre bağlanan otel: Resort Hotel (Faro) veya City Hotel (Lizbon) |

## Temizlik kararları

| Karar | Gerekçe |
|---|---|
| Her dosyanın ilk 4 satırı atlandı (`skip = 4`) | lk iki satır konum bilgisi, üçüncüsü boş, başlık dördüncü satırda |
| `NaN` ve boş hücreler gerçek boş değer (`NULL`) olarak okunuyor | leride boş değer gelirse doğru tanınsın diye |
| Bozuk karakter içeren ham başlıklar (`Â°C`) kullanılmadı, her sütuna okunur bir ad ve tip verildi | Başlıktaki derece işareti kodlama hatasıyla bozulmuş |
| `city` ve `hotel` sütunları eklendi | Otel verisiyle birleştirme anahtarı |
| ki şehir alt alta birleştirildi (`union all`) | Tek tablo |

## Testler

- `weather_date` boş olamaz.
- `city` sadece Faro veya Lisbon olabilir.
- `hotel` sadece Resort Hotel veya City Hotel olabilir.
- `precipitation_mm`, `rain_mm`, `precipitation_hours` ve `wind_speed_max_kmh` boş olamaz (veri yeniden boş gelirse hemen fark edilsin diye).
- Sıcaklık değerleri tutarlı olmalı: en düşük ≤ ortalama ≤ en yüksek (`weather_sicaklik_mantikli`).
- Aynı şehir ve gün için tekrar eden satır olmamalı (`weather_tekrar_eden_gun_yok`).

## Doğrulanan veri durumu

| | Faro | Lizbon |
|---|---|---|
| En düşük sıcaklık | 3,2 °C | 1,2 °C |
| En yüksek sıcaklık | 36,9 °C | 39,1 °C |
| Ocak ortalaması | 13,1 °C | 12,0 °C |
| Temmuz ortalaması | 25,1 °C | 22,0 °C |
| Ağustos ortalaması | 24,8 °C | 22,4 °C |
| Toplam yağış (793 gün) | 1.001,9 mm | 1.106,9 mm |
| Yağışlı gün sayısı | 175 | 241 |
| En yüksek günlük yağış | 67,7 mm | 33,0 mm |
| En yüksek rüzgâr | 53,7 km/sa | 50,8 km/sa |
| Boş değer | Yok | Yok |

Sıcaklıklar mevsim örüntüsüne uyuyor. Lizbon daha sık yağış alıyor, Faro'da ise yağışlı gün daha az ama tek günde düşen en yüksek yağış daha fazla.

## Bilinen sorunlar ve dikkat edilecekler

- **Zamanlama sınırlılığı:** Varış gününün hava durumu rezervasyon yapılırken bilinmiyor. Hava durumu ile iptal arasındaki ilişki nedensel değil, ilişkili bir değişken olarak yorumlanmalı.
- **Otel konumu varsayımı:** Yukarıda belirtildi.
- **Konum farkı:** Faro verisi kıyıdaki bir hücreden geliyor (rakım 0 m), bu da şehir içinden biraz farklı sıcaklık değerleri verebilir.
