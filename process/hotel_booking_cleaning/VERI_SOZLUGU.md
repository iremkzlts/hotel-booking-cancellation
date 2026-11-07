# Veri Sözlüğü: Otel Rezervasyon İptali Tahmini ve Analiz Sistemi

Bu belge projedeki tüm veri kaynaklarını ve dbt modellerini tek yerde açıklar. Önceden dört ayrı dosyada (otel, hava durumu, Eurocontrol, mart) duran bilgiler burada birleştirilmiştir.

## İçindekiler

1. [Genel bakış](#1-genel-bakış)
2. [Otel rezervasyon verisi](#2-otel-rezervasyon-verisi-stg_hotel_bookings-ve-int_hotel_bookings_flagged)
3. [Hava durumu verisi](#3-hava-durumu-verisi-stg_weather)
4. [Havalimanı gecikme verisi](#4-havalimanı-gecikme-verisi-stg_eurocontrol)
5. [Mart tabloları](#5-mart-tabloları)
6. [Bölüm 2 (model) için notlar](#6-bölüm-2-model-için-notlar)
7. [Hazırlayanlar ve kullanılan teknolojiler](#7-hazırlayanlar-ve-kullanılan-teknolojiler)

---

## 1. Genel bakış

### Veri kaynakları

| Kaynak | Ham dosya | dbt modeli | Satır (temizlik sonrası) |
|---|---|---|---|
| Kaggle "Hotel Booking Demand" | `data/raw/hotel_booking/hotel_bookings.csv` | `stg_hotel_bookings`, `int_hotel_bookings_flagged` | 119.208 |
| Open-Meteo Historical Weather API (günlük) | `data/raw/open_meteo/weather_faro.csv`, `weather_lisbon.csv` | `stg_weather` | 1.586 (2 şehir × 793 gün) |
| Eurocontrol havalimanı gecikme verisi | `data/raw/eurocontrol/apt_dly_*.csv` | `stg_eurocontrol` | LPFR ve LPPT, günlük |

**Ortak tarih aralığı:** 2015-07-01 ile 2017-08-31 (793 gün). Üç kaynak da bu aralığa göre filtrelenir.

### Katmanlar ve veri akışı

```
Ham veri (data/raw)        Staging                     Intermediate                  Mart
─────────────────────      ─────────────────────       ──────────────────────────    ─────────────────────────────────
hotel_bookings.csv   ──►   stg_hotel_bookings    ──►   int_hotel_bookings_flagged ─┐
weather_*.csv        ──►   stg_weather           ──────────────────────────────────┼──► fct_bookings ──► mart_monthly_cancellations
apt_dly_*.csv        ──►   stg_eurocontrol       ──┬───────────────────────────────┘        │        ──► mart_weather_cancellations
                                                   │                                        │        ──► mart_flight_delay_cancellations
                                                   │                                        └──► dim_date (arrival_date = date_day)
                                                   └──► mart_airport_delays, mart_airport_monthly_delay, mart_yearly_delays
```

- **Staging:** Ham veriyi okur, tipleri düzeltir, hatalı satırları temizler.
- **Intermediate:** Kopya satırları işaretler.
- **Mart:** Dashboard ve modelin kullandığı iş tabloları. CSV çıktıları `data/processed/marts/` klasörüne yazılır.

### Ortak varsayım: otel konumu

Otel veri setinde otellerin konumu yazmıyor. Kaynak makalelere dayanarak şu eşleştirme yapıldı (veriden doğrulanmadı):

| Otel | Şehir | Havalimanı |
|---|---|---|
| Resort Hotel | Faro (Algarve) | LPFR |
| City Hotel | Lizbon | LPPT |

Üç kaynak, **otel + varış tarihi** (`hotel`, `arrival_date`) anahtarıyla birleştirilir.

---

## 2. Otel rezervasyon verisi (stg_hotel_bookings ve int_hotel_bookings_flagged)

### Genel bilgi

| Madde | Değer |
|---|---|
| Kaynak | Kaggle "Hotel Booking Demand" (Portekiz'de bir tatil oteli ve bir şehir oteli) |
| Ham dosya | `data/raw/hotel_booking/hotel_bookings.csv` |
| Ham satır sayısı | 119.390 |
| Temizlik sonrası satır sayısı | 119.208 |
| Varış tarihi aralığı | 2015-07-01 ile 2017-08-31 |
| Hedef değişken | `is_canceled` (1 = iptal edildi) |
| Oluşturan dbt modelleri | `stg_hotel_bookings` (staging), `int_hotel_bookings_flagged` (intermediate) |

### Temizlik sonrası değişen satırlar

| İşlem | Satır |
|---|---|
| Ham veri | 119.390 |
| Negatif fiyatlı (`adr` < 0) satır çıkarıldı | -1 |
| Yetişkin, çocuk ve bebek toplamı 0 olan satırlar çıkarıldı | -180 |
| Fiyatı 1000'in üzerinde olan uç değerli satır çıkarıldı (`adr` = 5400) | -1 |
| Temizlik sonrası | 119.208 |

Birebir aynı olan satırlar **silinmedi**, `is_duplicate` ile işaretlendi. Diğer uç değerli satırlar da silinmedi, "Uç değerler" bölümünde belgelendi.

### Rezervasyon numarası (`booking_id`)

Ham veride rezervasyon kimliği yok. `booking_id`, **ham CSV dosyasındaki satır numarasıdır** ve satırlar çıkarılmadan önce, temizlikten bağımsız olarak üretilir. Bu yüzden:

- Numaralar 1 ile 119.390 arasındadır ve ardışık değildir: çıkarılan 182 satırın numarası boşta kalır.
- İleride başka satır çıkarılırsa kalan rezervasyonların numarası değişmez.
- Aynı rezervasyon her çalıştırmada aynı numarayı alır (CSV dosyası değişmediği sürece).

### Sütunlar

Boş yüzdeleri, aralıklar ve kategori sayıları dbt ile alınan sorgu çıktılarından yazılmıştır.

#### Kimlik ve tarih

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| booking_id | tamsayı | 1 - 119390 | 0 | Ham CSV'deki satır numarası (yukarıya bakın). Benzersizliği `unique` testiyle doğrulanır |
| hotel | metin | City Hotel, Resort Hotel | 0 | Otel tipi |
| arrival_date | tarih | 2015-07-01 - 2017-08-31 | 0 | Varış tarihi. Ham veride yıl, ay adı ve gün ayrı sütunlardaydı, birleştirilerek üretildi |

#### Hedef değişken

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| is_canceled | tamsayı | 0, 1 | 0 | 1 = rezervasyon iptal edildi, 0 = edilmedi |

#### Rezervasyon bilgileri

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| lead_time | tamsayı | 0 - 737 | 0 | Rezervasyon ile varış tarihi arasındaki gün sayısı |
| stays_in_weekend_nights | tamsayı | 0 - 19 | 0 | Hafta sonu gecesi sayısı |
| stays_in_week_nights | tamsayı | 0 - 50 | 0 | Hafta içi gece sayısı |
| adults | tamsayı | 0 - 55 | 0 | Yetişkin sayısı. 12 satırda 10'dan büyük (uç değer, bkz. aşağıda) |
| children | tamsayı | 0 - 10 | 0 | Çocuk sayısı. Ham veride 4 boş değer vardı, 0 yapıldı. 1 satırda 5'ten büyük |
| babies | tamsayı | 0 - 10 | 0 | Bebek sayısı. 2 satırda 5'ten büyük |
| meal | metin | 5 kategori | 0 | Yemek planı. BB: kahvaltı (92.234), HB: yarım pansiyon (14.458), SC: yemek yok (10.549), FB: tam pansiyon (798), Undefined: belirtilmemiş (1.169) |
| country | metin | 180 farklı değer | 0,40 | Misafirin ülkesi (üç harfli kod) |
| market_segment | metin | 8 kategori | 0 | Pazar segmenti. Online TA (56.408), Offline TA/TO (24.181), Groups (19.790), Direct (12.582), Corporate (5.282), Complementary (728), Aviation (235), Undefined (2) |
| distribution_channel | metin | 5 kategori | 0 | Rezervasyon kanalı. TA/TO (97.749), Direct (14.610), Corporate (6.651), GDS (193), Undefined (5) |
| customer_type | metin | 4 kategori | 0 | Transient (89.475), Transient-Party (25.087), Contract (4.072), Group (574) |
| deposit_type | metin | 3 kategori | 0 | No Deposit (104.460), Non Refund (14.586), Refundable (162) |
| reserved_room_type | metin | A - L (9 farklı) | 0 | Rezerve edilen oda tipi. Anonim kod, anlamı bilinmiyor |
| assigned_room_type | metin | A - L (11 farklı) | 0 | Atanan oda tipi. Anonim kod |
| booking_changes | tamsayı | 0 - 18 | 0 | Rezervasyonda yapılan değişiklik sayısı |
| agent | tamsayı | 1 - 535 | 13,66 | Seyahat acentesi kimliği. Anonim. Boş değer, acentesiz rezervasyon anlamına gelebilir (doğrulanmadı) |
| company | tamsayı | 6 - 543 | 94,32 | Şirket kimliği. Anonim, büyük oranda boş |
| days_in_waiting_list | tamsayı | 0 - 391 | 0 | Onaylanmadan önce bekleme listesinde geçen gün |
| required_car_parking_spaces | tamsayı | 0 - 8 | 0 | İstenen otopark yeri sayısı |
| total_of_special_requests | tamsayı | 0 - 5 | 0 | Özel istek sayısı |

#### Misafirin geçmişi

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| is_repeated_guest | tamsayı | 0, 1 | 0 | 1 = daha önce konaklamış misafir |
| previous_cancellations | tamsayı | 0 - 26 | 0 | Misafirin önceki iptal sayısı |
| previous_bookings_not_canceled | tamsayı | 0 - 72 | 0 | Misafirin iptal etmediği önceki rezervasyon sayısı |

#### Fiyat

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| adr | ondalık | 0,0 - 510,0 | 0 | Ortalama günlük oda fiyatı. Para birimi veri setinde belirtilmemiş, Euro olarak varsayıldı (Portekiz). 1000'in üzerindeki tek satır (5400) çıkarıldı |

#### Sonucu ele veren sütunlar (veri sızıntısı)

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| reservation_status | metin | Canceled, Check-Out, No-Show | 0 | Rezervasyonun son durumu. İptal sonucunu doğrudan söyler, **modelde kullanılmaz** |
| reservation_status_date | tarih | 2014-10-17 - 2017-09-14 | 0 | Son durumun belirlendiği tarih. Aynı sızıntı sebebiyle **modelde kullanılmaz**. Tarih aralığı varış tarihinden öncesine uzanıyor |

#### Ek sütunlar (sadece int_hotel_bookings_flagged)

| Sütun | Tür | Açıklama |
|---|---|---|
| duplicate_rank | tamsayı | Birebir aynı satır grubunda sıra numarası (1 = ilk) |
| is_duplicate | doğru/yanlış | Aynı satırın 2. ve sonraki tekrarıysa doğru |

### Modele alınmayan ham sütunlar

| Ham sütun | Ne yapıldı |
|---|---|
| arrival_date_year, arrival_date_month, arrival_date_day_of_month | Tek `arrival_date` sütununa birleştirildi |
| arrival_date_week_number | Staging'e alınmadı |

### Temizlik kararları

| Karar | Gerekçe |
|---|---|
| `NULL` yazan hücreler gerçek boş değere çevrildi | Ham dosyada boş değerler metin olarak yazılmış |
| Boş `children` değerleri 0 yapıldı | 4 satırda boş, çocuk yok kabul edildi |
| `adr` negatif olan 1 satır çıkarıldı | Negatif günlük fiyat anlamsız |
| Misafir sayısı 0 olan 180 satır çıkarıldı | Misafirsiz rezervasyon anlamsız |
| `adr` değeri 1000'in üzerinde olan 1 satır çıkarıldı (5400, City Hotel, 25 Mart 2016, iptal edilmiş) | Gerçek dışı fiyat. Kaybedilen gelir toplamlarını şişiriyordu |
| `booking_id` ham CSV satır numarasıyla üretildi | Satır çıkarılsa bile numaralar değişmesin diye |
| Birebir aynı satırlar silinmedi, işaretlendi | Kimlik sütunu olmadığı için gerçek kopya oldukları kesin değil |
| Diğer uç değerli satırlar silinmedi, belgelendi | Gerçek dışı olup olmadıkları veriden ayırt edilemiyor, etkileri çok küçük |

### Uç değerler

| Sütun | Satır | Ayrıntı |
|---|---|---|
| adr > 1000 | 0 (1 satır çıkarıldı) | Çıkarılan satır: City Hotel, 25 Mart 2016, adr 5400, iptal edilmiş |
| adr > 400 | 7 | En yüksek 510. Makul aralıkta sayıldı, silinmedi |
| adults > 10 | 12 | Hepsi Resort Hotel ve hepsi iptal edilmiş. Yetişkin sayısı 20 ile 55 arası. Booking numaraları: 1540, 1588, 1644, 1753, 1885, 1918, 1963, 2004, 2165, 2174, 2229, 2419. Birbirine yakın olmaları grup rezervasyonu ya da toplu giriş hatası olabileceğini düşündürüyor, veriden ayırt edilemiyor |
| children > 5 | 1 | Booking 329, 10 çocuk, Resort Hotel, iptal edilmiş |
| babies > 5 | 2 | City Hotel, booking 46620 (10 bebek) ve 78657 (9 bebek), ikisi de iptal edilmemiş |

### Bilinen sorunlar ve dikkat edilecekler

- **Kopya satırlar:** 32.238 satır (yaklaşık %27) başka bir satırla birebir aynı. Tüm satırlarda iptal oranı %37,1, `is_duplicate` olanlar çıkarılınca %27,3.
- **"Undefined" kategorileri:** `meal` (1.169), `market_segment` (2) ve `distribution_channel` (5) sütunlarında "Undefined" değeri var. Dashboard'da ayrı dilim olarak görünür.
- **Anonim kodlar:** `agent`, `company`, `reserved_room_type` ve `assigned_room_type` anonim kodlardır, gerçek karşılıkları bilinmiyor.
- **Para birimi:** `adr` için para birimi veri setinde belirtilmemiş, Euro varsayıldı.
- **`company` sütunu:** %94 boş, model için kullanışlı değil.
- **Kısaltmalar:** BB, HB, FB, SC açıklamaları Kaggle veri tanımından alınmıştır, bu veri setinde ayrıca doğrulanmadı.

---

## 3. Hava durumu verisi (stg_weather)

### Genel bilgi

| Madde | Değer |
|---|---|
| Kaynak | Open-Meteo Historical Weather API (günlük) |
| Ham dosyalar | `data/raw/open_meteo/weather_faro.csv` ve `data/raw/open_meteo/weather_lisbon.csv` |
| Tarih aralığı | 2015-07-01 ile 2017-08-31 (şehir başına 793 gün) |
| Toplam satır | 1.586 (Faro 793 + Lizbon 793) |
| Oluşturan dbt modeli | `stg_weather` (staging) |
| Birleştirme anahtarı | `hotel` ve `weather_date` (otel rezervasyonlarının varış tarihiyle) |

**Veri güncellemesi (5 Kasım 2026):** İlk indirilen dosyalarda yağış, yağmur ve rüzgâr sütunları tamamen boştu. Veri, Open-Meteo Historical Weather API'den yeniden indirildi ve artık tüm sütunlar dolu. API, istenen konuma en yakın veri hücresini kullanıyor. Faro için bu hücre 37.01, -7.96 koordinatında ve rakımı 0 m (eski dosyada 37.00, -7.90, 22 m). Bu yüzden sıcaklık değerleri eski dosyadan biraz farklı.

### Sütunlar

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

### Temizlik kararları

| Karar | Gerekçe |
|---|---|
| Her dosyanın ilk 4 satırı atlandı (`skip = 4`) | İlk iki satır konum bilgisi, üçüncüsü boş, başlık dördüncü satırda |
| `NaN` ve boş hücreler gerçek boş değer (`NULL`) olarak okunuyor | İleride boş değer gelirse doğru tanınsın diye |
| Bozuk karakter içeren ham başlıklar (`Â°C`) kullanılmadı, her sütuna okunur bir ad ve tip verildi | Başlıktaki derece işareti kodlama hatasıyla bozulmuş |
| `city` ve `hotel` sütunları eklendi | Otel verisiyle birleştirme anahtarı |
| İki şehir alt alta birleştirildi (`union all`) | Tek tablo |

### Testler

- `weather_date` boş olamaz.
- `city` sadece Faro veya Lisbon olabilir.
- `hotel` sadece Resort Hotel veya City Hotel olabilir.
- `precipitation_mm`, `rain_mm`, `precipitation_hours` ve `wind_speed_max_kmh` boş olamaz (veri yeniden boş gelirse hemen fark edilsin diye).
- Sıcaklık değerleri tutarlı olmalı: en düşük ≤ ortalama ≤ en yüksek (`weather_sicaklik_mantikli`).
- Aynı şehir ve gün için tekrar eden satır olmamalı (`weather_tekrar_eden_gun_yok`).

### Doğrulanan veri durumu

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

### Bilinen sorunlar ve dikkat edilecekler

- **Zamanlama sınırlılığı:** Varış gününün hava durumu rezervasyon yapılırken bilinmiyor. Hava durumu ile iptal arasındaki ilişki nedensel değil, ilişkili bir değişken olarak yorumlanmalı.
- **Konum farkı:** Faro verisi kıyıdaki bir hücreden geliyor (rakım 0 m), bu da şehir içinden biraz farklı sıcaklık değerleri verebilir.

---

## 4. Havalimanı gecikme verisi (stg_eurocontrol)

### Genel bilgi

| Madde | Değer |
|---|---|
| Kaynak | Eurocontrol havalimanı varış uçuşu ve ATFM gecikme verisi |
| Ham dosyalar | `data/raw/eurocontrol/apt_dly_*.csv` (yıllık dosyalar, `union_by_name` ile birleştirilir) |
| Havalimanları | LPFR (Faro) ve LPPT (Lizbon) |
| Tarih aralığı | 01.07.2015 – 31.08.2017 |
| Bir satır = | Bir havalimanı, bir gün |
| Oluşturan dbt modeli | `stg_eurocontrol` (staging) |
| Python ile ön inceleme | `process/clean_eurocontrol.py` (eksik değer analizi ve inceleme; dbt modeli ham CSV'leri doğrudan okur) |

Veri seti, havalimanlarında gerçekleşen varış uçuşlarını ve havalimanı kaynaklı varış gecikmelerini analiz etmek amacıyla kullanılmıştır.

### Sütunlar

Sütun adları kaynak verideki biçimiyle (büyük harf) korunmuştur.

| Sütun Adı | Veri Tipi | Açıklama |
|---|---|---|
| YEAR | INTEGER | Uçuş kaydının ait olduğu yıl |
| MONTH_NUM | INTEGER | Ayın sayısal değeri |
| MONTH_MON | VARCHAR | Ayın kısaltılmış adı |
| FLT_DATE | TIMESTAMPTZ | Uçuş kaydının ait olduğu tarih (UTC) |
| APT_ICAO | VARCHAR | Havalimanının ICAO kodu (LPFR veya LPPT) |
| APT_NAME | VARCHAR | Havalimanının adı |
| STATE_NAME | VARCHAR | Havalimanının bulunduğu ülke adı |
| FLT_ARR_1 | BIGINT | Gerçekleşen varış uçuşlarının sayısı |
| DLY_APT_ARR_1 | DOUBLE | Havalimanı kaynaklı toplam varış gecikmesi |
| DLY_APT_ARR_A_1 … DLY_APT_ARR_NA_1 | DOUBLE | Gecikmenin neden kategorisine göre dağılımı. Kategoriler: A, C, D, E, G, I, M, N, O, P, R, S, T, V, W, NA. **W = hava durumu** kaynaklı gecikme (`fct_bookings` içindeki `atfm_weather_delay_min` bu sütundan gelir) |
| FLT_ARR_1_DLY | DOUBLE | Gecikmeli gerçekleşen varış uçuşlarına ilişkin değer |
| FLT_ARR_1_DLY_15 | DOUBLE | 15 dakika ve üzeri gecikmeyle gerçekleşen varış uçuşlarına ilişkin değer |
| ATFM_VERSION | VARCHAR | ATFM veri sürüm bilgisi |
| GECIKME_DURUMU | VARCHAR | Türetilmiş alan. `DLY_APT_ARR_1` boşsa "Gecikme verisi eksik", doluysa "Gecikme verisi mevcut" |

**Not:** Gecikme kategorilerinin harf kodları kaynak verideki biçimiyle korunmuştur. Gecikme değerlerinin ölçü birimi kaynak veri dokümantasyonuna göre değerlendirilmelidir.

### Temizlik işlemleri

- Boş veya yalnızca boşluk içeren metin değerleri NULL olarak düzenlenmiştir (`NULLIF(TRIM(...), '')`).
- `APT_ICAO` büyük harfe çevrilmiştir.
- Sayısal olması gereken uçuş ve gecikme alanları `TRY_CAST` ile dönüştürülmüştür (uçuş sayısı BIGINT, gecikmeler DOUBLE).
- Tarih alanı zaman damgası tipine (`TIMESTAMPTZ`) dönüştürülmüştür.
- Yalnızca LPFR ve LPPT havalimanlarına ait kayıtlar bırakılmıştır.
- Tarih aralığı 1 Temmuz 2015 ile 31 Ağustos 2017 arasında sınırlandırılmıştır.

### Bilinen sınırlılıklar

- Faro (LPFR) havalimanına ait bazı dönemlerde gecikme gözlemleri sınırlıdır.
- Gecikme verisi bulunmayan kayıtlar ortalama gecikme hesaplamalarını etkileyebileceğinden, sonuçlar mevcut gözlem sayısı dikkate alınarak yorumlanmalıdır.

---

## 5. Mart tabloları

### Genel bilgi

| Madde | Değer |
|---|---|
| Katman | Mart (dashboard ve modelin kullandığı iş tabloları) |
| dbt klasörü | `process/hotel_booking_cleaning/models/marts/` |
| CSV çıktıları | `data/processed/marts/` (her `dbt build` sonrası otomatik güncellenir) |
| Kaynak modeller | `int_hotel_bookings_flagged`, `stg_weather`, `stg_eurocontrol` |
| Birleştirme anahtarı | Otel + varış tarihi (`hotel`, `arrival_date`) |
| Tarih aralığı | 2015-07-01 ile 2017-08-31 (793 gün) |
| Testler | `_marts.yml`, `_marts_ozet.yml`, `_marts_ucus.yml` ve `tests/` klasöründeki 2 özel test |

### Tablolar

| Tablo | Bir satır = | Satır sayısı | Ne için |
|---|---|---|---|
| `fct_bookings` | Bir rezervasyon | 119.208 | Ana tablo. Dashboard detayları ve Bölüm 2 modeli |
| `dim_date` | Bir takvim günü | 793 | Dashboard tarih filtreleri |
| `mart_monthly_cancellations` | Otel + ay + kopya işareti | 104 | KPI kartları ve aylık trend |
| `mart_weather_cancellations` | Otel + yağış + sıcaklık aralığı + kopya işareti | 28 | Hava durumu analizi |
| `mart_flight_delay_cancellations` | Otel + gecikmeli gün + kopya işareti | 8 | Uçuş gecikmesi analizi |
| `mart_airport_delays` | Bir havalimanı | 2 | Havalimanı gecikme özeti |
| `mart_airport_monthly_delay` | Havalimanı + ay | 52 (2 havalimanı × 26 ay) | Aylık havalimanı gecikme trendi |
| `mart_yearly_delays` | Bir yıl | 3 | Yıllık gecikme özeti |

### fct_bookings

Her satır bir rezervasyon. `int_hotel_bookings_flagged`, `stg_weather` ve `stg_eurocontrol` tabloları varış günü ve otele göre birleştirilir. Temizlik burada yapılmaz, staging'de yapılır. `left join` kullanıldığı için hava ya da uçuş verisi eksik olsa bile rezervasyon tablodan düşmez.

#### Kimlik, tarih ve hedef

| Sütun | Tür | Açıklama |
|---|---|---|
| `booking_id` | BIGINT | Rezervasyon kimliği. Ham CSV'deki satır numarası, temizlikten sonra değişmez (benzersiz) |
| `hotel` | VARCHAR | Resort Hotel veya City Hotel |
| `city` | VARCHAR | Hava eşleşmesi için şehir: Resort Hotel → Faro, City Hotel → Lisbon |
| `arrival_date` | DATE | Planlanan varış tarihi. `dim_date.date_day` ile bağlanır |
| `arrival_year`, `arrival_month` | BIGINT | Varış yılı ve ay numarası |
| `arrival_month_start` | DATE | Varış ayının ilk günü (aylık gruplamalar için) |
| `is_canceled` | BIGINT | **Hedef değişken.** 1 = iptal edildi, 0 = edilmedi |
| `is_duplicate` | BOOLEAN | Kopya işareti. Aynı bilgilere sahip 2. ve sonraki satırlar true |

#### Hesaplanan rezervasyon sütunları

| Sütun | Tür | Hesaplama |
|---|---|---|
| `total_nights` | BIGINT | `stays_in_weekend_nights` + `stays_in_week_nights` |
| `total_guests` | BIGINT | `adults` + `children` + `babies` |
| `is_room_changed` | BOOLEAN | Verilen oda tipi (`assigned_room_type`), rezerve edilenden (`reserved_room_type`) farklı mı |
| `booking_revenue` | DOUBLE | `adr` × `total_nights` (rezervasyonun toplam tutarı) |
| `realized_revenue` | DOUBLE | İptal edilmediyse `booking_revenue`, iptal edildiyse 0 |
| `lost_revenue` | DOUBLE | İptal edildiyse `booking_revenue`, edilmediyse 0 |

Diğer rezervasyon sütunları (`lead_time`, `adults`, `meal`, `country`, `market_segment`, `deposit_type`, `agent`, `company`, `adr` vb.) staging'den değişmeden gelir. Anlamları için [Bölüm 2](#2-otel-rezervasyon-verisi-stg_hotel_bookings-ve-int_hotel_bookings_flagged)'ye bakın.

#### Hava durumu sütunları (`stg_weather` tablosundan)

Eşleşme: `hotel` + `arrival_date` = `stg_weather.hotel` + `weather_date`. Değerler varış günü içindir.

| Sütun | Tür | Açıklama |
|---|---|---|
| `temp_mean_c`, `temp_max_c`, `temp_min_c` | DOUBLE | Varış günü ortalama, en yüksek ve en düşük sıcaklık (°C) |
| `precipitation_mm` | DOUBLE | Varış günü toplam yağış (mm) |
| `rain_mm` | DOUBLE | Varış günü yağmur (mm) |
| `precipitation_hours` | DOUBLE | Varış günü yağışlı saat sayısı |
| `wind_speed_max_kmh` | DOUBLE | Varış günü en yüksek rüzgâr hızı (km/sa) |
| `is_rainy_day` | BOOLEAN | `precipitation_mm` ≥ 1 ise true (meteorolojide yağışlı gün eşiği) |
| `temp_band` | VARCHAR | Sıcaklık aralığı: 15 alti, 15-20, 20-25, 25 ve ustu |

#### Havalimanı gecikmesi sütunları (`stg_eurocontrol` tablosundan)

Eşleşme: Resort Hotel → LPFR (Faro), City Hotel → LPPT (Lizbon), varış günü. `FLT_DATE` UTC saatiyle tutulduğu için `at time zone 'UTC'` ile tarihe çevrilir. Böylece hangi saat dilimindeki bilgisayarda çalışırsa çalışsın doğru gün eşleşir.

| Sütun | Tür | Açıklama |
|---|---|---|
| `airport_icao` | VARCHAR | Otelin havalimanı kodu (LPFR veya LPPT) |
| `airport_arrivals` | BIGINT | Varış günü havalimanına inen IFR uçuş sayısı |
| `atfm_arrival_delay_min` | DOUBLE | Varış günü toplam ATFM varış gecikmesi (dakika). Boşsa o gün gecikme kaydı yok |
| `atfm_weather_delay_min` | DOUBLE | Bu gecikmenin hava durumu (W kodu) kaynaklı kısmı (dakika) |
| `atfm_delayed_arrivals` | DOUBLE | Gecikmeli inen uçuş sayısı |
| `atfm_delayed_arrivals_15` | DOUBLE | 15 dakikadan fazla gecikmeli inen uçuş sayısı |
| `atfm_delay_per_arrival_min` | DOUBLE | Uçuş başına ortalama gecikme (dakika). Boş gecikme 0 kabul edilir |
| `is_atfm_delay_day` | BOOLEAN | Varış günü havalimanında ATFM gecikmesi var mı |

#### Veri sızıntısı sütunları

`reservation_status` ve `reservation_status_date` sonucu doğrudan söylediği için sadece dashboard için tabloda tutulur. Bölüm 2'deki modelde girdi olarak kullanılırsa model "kopya çeker" (bkz. [Bölüm 6](#6-bölüm-2-model-için-notlar)).

### dim_date

Her satır bir takvim günü. Rezervasyonlardaki en erken ve en geç varış tarihi arasındaki **her gün** üretilir, rezervasyon olmayan günler de takvimde yer alır.

| Sütun | Tür | Açıklama |
|---|---|---|
| `date_day` | DATE | Takvim günü (anahtar, benzersiz) |
| `year`, `quarter`, `month` | BIGINT | Yıl, çeyrek (1-4), ay (1-12) |
| `month_name_tr` | VARCHAR | Türkçe ay adı (Ocak … Aralık) |
| `month_start` | DATE | Ayın ilk günü |
| `iso_week` | BIGINT | ISO hafta numarası |
| `weekday_no` | BIGINT | Haftanın günü (1 = Pazartesi, 7 = Pazar) |
| `weekday_tr` | VARCHAR | Türkçe gün adı |
| `is_weekend` | BOOLEAN | Cumartesi veya Pazar ise true |
| `season` | VARCHAR | Kış (Ara-Şub), İlkbahar (Mar-May), Yaz (Haz-Ağu), Sonbahar (Eyl-Kas) |

### İptal özet tabloları

Üç tablo da `fct_bookings` tablosundan hesaplanır ve aynı ölçüleri içerir:

| Sütun | Açıklama |
|---|---|
| `total_bookings` | Gruptaki rezervasyon sayısı |
| `canceled_bookings` | Bunlardan iptal edilenler |
| `cancel_rate` | `canceled_bookings` / `total_bookings` (0-1 arası) |

| Tablo | Gruplama | Ek sütunlar |
|---|---|---|
| `mart_monthly_cancellations` | `hotel`, `month_start`, `is_duplicate` | `avg_adr`, `avg_lead_time`, `realized_revenue`, `lost_revenue` |
| `mart_weather_cancellations` | `hotel`, `is_rainy_day`, `temp_band`, `is_duplicate` | `avg_precipitation_mm`, `avg_temp_mean_c` |
| `mart_flight_delay_cancellations` | `hotel`, `airport_icao`, `is_atfm_delay_day`, `is_duplicate` | `avg_delay_per_arrival_min`, `avg_airport_arrivals` |

`avg_adr` ortalamasına iptal edilenler ve fiyatı 0 € olanlar da dahildir.

**Önemli:** Özet tablolarda her grup kopya olan ve olmayan diye ikiye ayrıldığı için dashboard'da iptal oranı `cancel_rate` sütununun **ortalaması alınarak hesaplanmamalı**. Doğrusu: toplam `canceled_bookings` / toplam `total_bookings`.

### Havalimanı gecikme özet tabloları

Üç tablo da doğrudan `stg_eurocontrol` tablosundan hesaplanır.

| Tablo | Gruplama | Sütunlar |
|---|---|---|
| `mart_airport_delays` | `AIRPORT` | `TOPLAM_KAYIT`, `GECIKME_VERISI_BULUNAN_KAYIT`, `ORTALAMA_GECIKME`, `MAKSIMUM_GECIKME`, `MINIMUM_GECIKME` |
| `mart_airport_monthly_delay` | `AIRPORT`, `AY_BASLANGICI` | `TOPLAM_UCUS`, `GECIKME_VERISI_BULUNAN_UCUS`, `ORTALAMA_GECIKME`, `MAKSIMUM_GECIKME`, `MINIMUM_GECIKME` |
| `mart_yearly_delays` | `YEAR` | `TOPLAM_KAYIT`, `GECIKME_VERISI_BULUNAN_KAYIT`, `ORTALAMA_GECIKME`, `MAKSIMUM_GECIKME` |

| Sütun | Açıklama |
|---|---|
| `TOPLAM_KAYIT` / `TOPLAM_UCUS` | Gruptaki **günlük kayıt** sayısı. Adı "uçuş" olsa da gerçekleşen uçuş sayısını ifade etmez |
| `GECIKME_VERISI_BULUNAN_KAYIT` / `GECIKME_VERISI_BULUNAN_UCUS` | Gecikme verisi dolu olan günlük kayıt sayısı. Gerçek uçuş sayısı olarak yorumlanmamalı |
| `ORTALAMA_GECIKME` | `DLY_APT_ARR_1` ortalaması (sadece gecikme verisi dolu günler üzerinden) |
| `MAKSIMUM_GECIKME`, `MINIMUM_GECIKME` | `DLY_APT_ARR_1` en yüksek ve en düşük değeri |

### Önemli kararlar

| Karar | Gerekçe |
|---|---|
| Kopya satırlar silinmedi, `is_duplicate` ile işaretlendi | Veri setinde rezervasyon numarası yok, aynı görünen satırlar gerçekte ayrı rezervasyonlar (ör. grup rezervasyonları) olabilir. Dashboard'da `is_duplicate` için filtre konur |
| `left join` kullanıldı | Hava ya da uçuş verisi eksik olan gün olsa bile hiçbir rezervasyon kaybolmaz |
| `fct_bookings` sonunda `order by booking_id` var | CSV her çalıştırmada aynı sırada çıkar, Git'te gereksiz değişiklik görünmez |
| Havalimanı tarihi `at time zone 'UTC'` ile çevrildi | Saat dilimi farkı yüzünden bir gün kayma olmaz |

### Ana sayılar (son `dbt build` sonrası)

| Ölçü | Değer |
|---|---|
| Rezervasyon | 119.208 |
| Kopya işaretli | 32.238 |
| İptal oranı (tümü) | %37,1 |
| İptal oranı (kopyalar hariç) | %27,3 |
| Gerçekleşen gelir | 25.986.976 € |
| İptallerle kaybedilen gelir | 16.721.837 € |
| Hava ve uçuş verisiyle eşleşen rezervasyon | 119.208 (tamamı) |

### Bulgular

- **Uçuş gecikmesi:** Varış günü havalimanı gecikmesiyle iptal arasında belirgin bir ilişki yok. City Hotel'de gecikmeli günlerde iptal oranı yaklaşık %42, gecikmesiz günlerde %41. Resort Hotel'de gecikmeli gün çok az (yaklaşık 390 rezervasyon), karşılaştırma güvenilir değil.
- **Yağış:** Varış günü yağışıyla iptal arasında da belirgin bir ilişki yok. City Hotel'de yağışlı günlerde iptal oranı %40,7, yağışsız günlerde %42,0. Resort Hotel'de %28,2 ve %27,7. Rezervasyonların yaklaşık %17'sinin varış günü yağışlı (≥ 1 mm).
- **Yorum:** Müşteriler iptal kararını genellikle varıştan haftalar önce veriyor. Varış günündeki hava ve gecikme o anda bilinmiyor. Bu yüzden bu analizler **sebep-sonuç** değil, **ilişki** gösterir. İki dış etkenin de belirgin etkisi olmaması, iptali asıl belirleyenin rezervasyonun kendi özellikleri olduğunu düşündürüyor.

### Çözülen sorunlar

| Sorun | Etkisi | Durum |
|---|---|---|
| Ham Open-Meteo dosyalarında yağış, yağmur ve rüzgâr `NaN` idi | Yağış analizi yapılamıyordu | ✅ Çözüldü: veri Historical Weather API'den yeniden indirildi. `precipitation_mm` için uyarı testi var |

---

## 6. Bölüm 2 (model) için notlar

- **Hedef değişken:** `is_canceled`
- **Kullanılmamalı:** `reservation_status`, `reservation_status_date` (veri sızıntısı, sonucu doğrudan söylüyor).
- **Zamanlama:** Hava ve uçuş sütunları rezervasyon anında bilinmez. Modelde kullanılırsa bu sınırlılık model kartında belirtilmeli.
- **Kopyalar:** Kopya satırlar eğitim ve test setine ayrı ayrı düşerse doğruluk olduğundan yüksek çıkabilir. `is_duplicate` ile kopyalı ve kopyasız iki sürüm karşılaştırılmalı.

---

## 7. Hazırlayanlar ve kullanılan teknolojiler

| Bölüm | Hazırlayan |
|---|---|
| Otel rezervasyon verisi (staging, intermediate) | Esma Gül Polat |
| Hava durumu verisi | Zehra Aktaş |
| Havalimanı gecikme verisi | İrem Kızıltaş |
| Mart katmanı | Elif Uyar |

- **Python:** Veri işleme ve birleştirme.
- **SQL:** Veri dönüştürme ve sorgulama.
- **dbt:** Veri modellerinin oluşturulması, belgelenmesi ve test edilmesi.
- **DuckDB:** Veri tabanı yönetimi ve sorgulama.
- **Git ve GitHub:** Sürüm kontrolü ve ekip çalışması.
- **Looker Studio:** Verilerin görselleştirilmesi ve dashboard hazırlanması.
