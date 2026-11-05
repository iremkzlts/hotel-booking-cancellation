# Veri Sözlüğü: Mart Tabloları (fct_bookings, dim_date ve özet tablolar)

## Genel bilgi

| Madde | Değer |
|---|---|
| Katman | Mart (dashboard ve modelin kullandığı iş tabloları) |
| Hazırlayan | Elif Uyar |
| dbt klasörü | `process/hotel_booking_cleaning/models/marts/` |
| CSV çıktıları | `data/processed/marts/` (her `dbt build` sonrası otomatik güncellenir) |
| Kaynak modeller | `int_hotel_bookings_flagged` (Esma), `stg_weather` (Zehra), `stg_eurocontrol` (İrem) |
| Birleştirme anahtarı | Otel + varış tarihi (`hotel`, `arrival_date`) |
| Tarih aralığı | 2015-07-01 ile 2017-08-31 (793 gün) |
| Testler | `_marts.yml`, `_marts_ozet.yml`, `_marts_ucus.yml` ve `tests/` klasöründeki 2 özel test |

## Tablolar

| Tablo | Bir satır = | Satır sayısı | Ne için |
|---|---|---|---|
| `fct_bookings` | Bir rezervasyon | 119.208 | Ana tablo. Dashboard detayları ve Bölüm 2 modeli |
| `dim_date` | Bir takvim günü | 793 | Dashboard tarih filtreleri |
| `mart_monthly_cancellations` | Otel + ay + kopya işareti | 104 | KPI kartları ve aylık trend |
| `mart_weather_cancellations` | Otel + yağış + sıcaklık aralığı + kopya işareti | 28 | Hava durumu analizi |
| `mart_flight_delay_cancellations` | Otel + gecikmeli gün + kopya işareti | 8 | Uçuş gecikmesi analizi |



## Tabloların ilişkisi

```
int_hotel_bookings_flagged ─┐
stg_weather ────────────────┼──► fct_bookings ──► mart_monthly_cancellations
stg_eurocontrol ────────────┘         │        ──► mart_weather_cancellations
                                      │        ──► mart_flight_delay_cancellations
                       dim_date ◄─────┘  (arrival_date = date_day)
```

## fct_bookings

Her satır bir rezervasyon. Esma'nın `int_hotel_bookings_flagged` tablosu, Zehra'nın `stg_weather` tablosu ve İrem'in `stg_eurocontrol` tablosu varış günü ve otele göre birleştirilir. Temizlik burada yapılmaz, staging'de yapılır. `left join` kullanıldığı için hava ya da uçuş verisi eksik olsa bile rezervasyon tablodan düşmez.

### Kimlik, tarih ve hedef

| Sütun | Tür | Açıklama |
|---|---|---|
| `booking_id` | BIGINT | Rezervasyon kimliği. Ham CSV'deki satır numarası, temizlikten sonra değişmez (benzersiz) |
| `hotel` | VARCHAR | Resort Hotel veya City Hotel |
| `city` | VARCHAR | Hava eşleşmesi için şehir: Resort Hotel → Faro, City Hotel → Lisbon |
| `arrival_date` | DATE | Planlanan varış tarihi. `dim_date.date_day` ile bağlanır |
| `arrival_year`, `arrival_month` | BIGINT | Varış yılı ve ay numarası |
| `arrival_month_start` | DATE | Varış ayının ilk günü (aylık gruplamalar için) |
| `is_canceled` | BIGINT | **Hedef değişken.** 1 = iptal edildi, 0 = edilmedi |
| `is_duplicate` | BOOLEAN | Kopya işareti (Esma). Aynı bilgilere sahip 2. ve sonraki satırlar true |

### Hesaplanan rezervasyon sütunları

| Sütun | Tür | Hesaplama |
|---|---|---|
| `total_nights` | BIGINT | `stays_in_weekend_nights` + `stays_in_week_nights` |
| `total_guests` | BIGINT | `adults` + `children` + `babies` |
| `is_room_changed` | BOOLEAN | Verilen oda tipi (`assigned_room_type`), rezerve edilenden (`reserved_room_type`) farklı mı |
| `booking_revenue` | DOUBLE | `adr` × `total_nights` (rezervasyonun toplam tutarı) |
| `realized_revenue` | DOUBLE | İptal edilmediyse `booking_revenue`, iptal edildiyse 0 |
| `lost_revenue` | DOUBLE | İptal edildiyse `booking_revenue`, edilmediyse 0 |

Diğer rezervasyon sütunları (`lead_time`, `adults`, `meal`, `country`, `market_segment`, `deposit_type`, `agent`, `company`, `adr` vb.) staging'den değişmeden gelir. Anlamları için `VERI_SOZLUGU_HOTEL_BOOKING.md` dosyasına bakın. `adr` para birimi Euro kabul edilmiştir (veri setinde belirtilmemiş).

### Hava durumu sütunları (Zehra'nın `stg_weather` tablosundan)

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

### Havalimanı gecikmesi sütunları (İrem'in `stg_eurocontrol` tablosundan)

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

### Modelde kullanılmaması gereken sütunlar (veri sızıntısı)

| Sütun | Neden |
|---|---|
| `reservation_status` | Canceled / No-Show / Check-Out. Sonucu doğrudan söylüyor |
| `reservation_status_date` | Son durumun tarihi. Aynı sebep |

Bu iki sütun sadece dashboard için tabloda tutulur. Bölüm 2'deki modelde girdi olarak kullanılırsa model "kopya çeker".

## dim_date

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

## Özet tablolar

Üç özet tablo da `fct_bookings` tablosundan hesaplanır ve aynı ölçüleri içerir:

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

## Önemli kararlar

| Karar | Gerekçe |
|---|---|
| Kopya satırlar silinmedi, `is_duplicate` ile işaretlendi | Veri setinde rezervasyon numarası yok, aynı görünen satırlar gerçekte ayrı rezervasyonlar (ör. grup rezervasyonları) olabilir. Dashboard'da `is_duplicate` için filtre konur |
| `left join` kullanıldı | Hava ya da uçuş verisi eksik olan gün olsa bile hiçbir rezervasyon kaybolmaz |
| `fct_bookings` sonunda `order by booking_id` var | CSV her çalıştırmada aynı sırada çıkar, Git'te gereksiz değişiklik görünmez |
| Havalimanı tarihi `at time zone 'UTC'` ile çevrildi | Saat dilimi farkı yüzünden bir gün kayma olmaz |

## Ana sayılar (son `dbt build` sonrası)

| Ölçü | Değer |
|---|---|
| Rezervasyon | 119.208 |
| Kopya işaretli | 32.238 |
| İptal oranı (tümü) | %37,1 |
| İptal oranı (kopyalar hariç) | %27,3 |
| Gerçekleşen gelir | 25.986.976 € |
| İptallerle kaybedilen gelir | 16.721.837 € |
| Hava ve uçuş verisiyle eşleşen rezervasyon | 119.208 (tamamı) |

## Bulgular

- **Uçuş gecikmesi:** Varış günü havalimanı gecikmesiyle iptal arasında belirgin bir ilişki yok. City Hotel'de gecikmeli günlerde iptal oranı yaklaşık %42, gecikmesiz günlerde %41. Resort Hotel'de gecikmeli gün çok az (yaklaşık 390 rezervasyon), karşılaştırma güvenilir değil.
- **Yağış:** Varış günü yağışıyla iptal arasında da belirgin bir ilişki yok. City Hotel'de yağışlı günlerde iptal oranı %40,7, yağışsız günlerde %42,0. Resort Hotel'de %28,2 ve %27,7. Rezervasyonların yaklaşık %17'sinin varış günü yağışlı (≥ 1 mm).
- **Yorum:** Müşteriler iptal kararını genellikle varıştan haftalar önce veriyor. Varış günündeki hava ve gecikme o anda bilinmiyor. Bu yüzden bu analizler **sebep-sonuç** değil, **ilişki** gösterir. İki dış etkenin de belirgin etkisi olmaması, iptali asıl belirleyenin rezervasyonun kendi özellikleri olduğunu düşündürüyor.

## Bilinen sorunlar

| Sorun | Etkisi | Durum |
|---|---|---|
| Ham Open-Meteo dosyalarında yağış, yağmur ve rüzgâr `NaN` idi | Yağış analizi yapılamıyordu | ✅ Çözüldü: Zehra veriyi Historical Weather API'den yeniden indirdi. `precipitation_mm` için uyarı testi var |
| `meal` sütununda "Undefined" değerleri | Dashboard'da ayrı dilim olarak görünür | Staging kararı (Esma) |

## Bölüm 2 (model) için notlar

- Hedef değişken: `is_canceled`
- Kullanılmamalı: `reservation_status`, `reservation_status_date` (veri sızıntısı)
- Hava ve uçuş sütunları rezervasyon anında bilinmez. Modelde kullanılırsa bu sınırlılık model kartında belirtilmeli.
- Kopya satırlar eğitim ve test setine ayrı ayrı düşerse doğruluk olduğundan yüksek çıkabilir. `is_duplicate` ile kopyalı ve kopyasız iki sürüm karşılaştırılmalı.