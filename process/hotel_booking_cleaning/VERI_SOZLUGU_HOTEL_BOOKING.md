# Veri Sözlüğü: Otel Rezervasyon Verisi (stg_hotel_bookings ve int_hotel_bookings_flagged)

## Genel bilgi

| Madde | Değer |
|---|---|
| Kaynak | Kaggle "Hotel Booking Demand" (Portekiz'de bir tatil oteli ve bir şehir oteli) |
| Ham dosya | `data/raw/hotel_booking/hotel_bookings.csv` |
| Ham satır sayısı | 119.390 |
| Temizlik sonrası satır sayısı | 119.209 |
| Varış tarihi aralığı | 2015-07-01 ile 2017-08-31 |
| Hedef değişken | `is_canceled` (1 = iptal edildi) |
| Oluşturan dbt modelleri | `stg_hotel_bookings` (staging), `int_hotel_bookings_flagged` (intermediate) |
| Birleştirme anahtarları | `hotel` ve `arrival_date` (hava durumu ve havalimanı verisiyle) |

**Otel konumu varsayımı:** Veri setinde otelin konumu yazmıyor. Resort Hotel'in Algarve'de (Faro), City Hotel'in Lizbon'da olduğu kabul edildi.

## Temizlik sonrası değişen satırlar

| İşlem | Satır |
|---|---|
| Ham veri | 119.390 |
| Negatif fiyatlı (`adr` < 0) satır çıkarıldı | -1 |
| Yetişkin, çocuk ve bebek toplamı 0 olan satırlar çıkarıldı | -180 |
| Temizlik sonrası | 119.209 |

Birebir aynı olan satırlar **silinmedi**, `is_duplicate` ile işaretlendi (aşağıya bakın).

## Sütunlar

Boş yüzdeleri ve aralıklar `summarize` çıktısından alınmıştır.

### Kimlik ve tarih

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| booking_id | tamsayı | 1 - 119209 | 0 | Satır numarasından üretilen kimlik. Ham veride kimlik sütunu yok. Benzersizliği `unique` testiyle doğrulanır |
| hotel | metin | City Hotel, Resort Hotel | 0 | Otel tipi |
| arrival_date | tarih | 2015-07-01 - 2017-08-31 | 0 | Varış tarihi. Ham veride yıl, ay adı ve gün ayrı sütunlardaydı, birleştirilerek üretildi |

### Hedef değişken

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| is_canceled | tamsayı | 0, 1 | 0 | 1 = rezervasyon iptal edildi, 0 = edilmedi |

### Rezervasyon bilgileri

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| lead_time | tamsayı | 0 - 737 | 0 | Rezervasyon ile varış tarihi arasındaki gün sayısı |
| stays_in_weekend_nights | tamsayı | 0 - 19 | 0 | Hafta sonu gecesi sayısı |
| stays_in_week_nights | tamsayı | 0 - 50 | 0 | Hafta içi gece sayısı |
| adults | tamsayı | 0 - 55 | 0 | Yetişkin sayısı. Üst değer (55) uç değerdir |
| children | tamsayı | 0 - 10 | 0 | Çocuk sayısı. Ham veride 4 boş değer vardı, 0 yapıldı |
| babies | tamsayı | 0 - 10 | 0 | Bebek sayısı. Üst değer (10) uç değerdir |
| meal | metin | 5 kategori | 0 | Yemek planı. BB: kahvaltı, HB: yarım pansiyon, FB: tam pansiyon, SC: yemek yok, Undefined: belirtilmemiş* |
| country | metin | 180 farklı değer | 0,40 | Misafirin ülkesi (üç harfli kod) |
| market_segment | metin | 8 kategori | 0 | Pazar segmenti (ör. Online TA, Offline TA/TO, Direct, Corporate, Groups). "Undefined" kategorisi içerir* |
| distribution_channel | metin | 5 kategori | 0 | Rezervasyon kanalı (ör. TA/TO, Direct, Corporate, GDS). "Undefined" kategorisi içerir* |
| customer_type | metin | 4 kategori | 0 | Contract, Group, Transient, Transient-Party* |
| deposit_type | metin | 3 kategori | 0 | No Deposit (104.460 satır), Non Refund (14.587), Refundable (162) |
| reserved_room_type | metin | A - L (9 farklı) | 0 | Rezerve edilen oda tipi. Anonim kod, anlamı bilinmiyor |
| assigned_room_type | metin | A - L (11 farklı) | 0 | Atanan oda tipi. Anonim kod |
| booking_changes | tamsayı | 0 - 18 | 0 | Rezervasyonda yapılan değişiklik sayısı |
| agent | tamsayı | 1 - 535 | 13,66 | Seyahat acentesi kimliği. Anonim. Boş değer, acentesiz rezervasyon anlamına gelebilir (doğrulanmadı) |
| company | tamsayı | 6 - 543 | 94,32 | Şirket kimliği. Anonim, büyük oranda boş |
| days_in_waiting_list | tamsayı | 0 - 391 | 0 | Onaylanmadan önce bekleme listesinde geçen gün |
| required_car_parking_spaces | tamsayı | 0 - 8 | 0 | İstenen otopark yeri sayısı |
| total_of_special_requests | tamsayı | 0 - 5 | 0 | Özel istek sayısı |

### Misafirin geçmişi

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| is_repeated_guest | tamsayı | 0, 1 | 0 | 1 = daha önce konaklamış misafir |
| previous_cancellations | tamsayı | 0 - 26 | 0 | Misafirin önceki iptal sayısı |
| previous_bookings_not_canceled | tamsayı | 0 - 72 | 0 | Misafirin iptal etmediği önceki rezervasyon sayısı |

### Fiyat

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| adr | ondalık | 0,0 - 5400,0 | 0 | Ortalama günlük oda fiyatı. Para birimi veri setinde belirtilmemiş. Üst değer (5400) uç değerdir |

### Sonucu ele veren sütunlar (veri sızıntısı)

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| reservation_status | metin | Canceled, Check-Out, No-Show | 0 | Rezervasyonun son durumu. İptal sonucunu doğrudan söyler, **modelde kullanılmaz** |
| reservation_status_date | tarih | 2014-10-17 - 2017-09-14 | 0 | Son durumun belirlendiği tarih. Aynı sızıntı sebebiyle **modelde kullanılmaz**. Tarih aralığı varış tarihinden öncesine uzanıyor |

### Ek sütunlar (sadece int_hotel_bookings_flagged)

| Sütun | Tür | Açıklama |
|---|---|---|
| duplicate_rank | tamsayı | Birebir aynı satır grubunda sıra numarası (1 = ilk) |
| is_duplicate | doğru/yanlış | Aynı satırın 2. ve sonraki tekrarıysa doğru |

## Modele alınmayan ham sütunlar

| Ham sütun | Ne yapıldı |
|---|---|
| arrival_date_year, arrival_date_month, arrival_date_day_of_month | Tek `arrival_date` sütununa birleştirildi |
| arrival_date_week_number | Staging'e alınmadı |

## Temizlik kararları

| Karar | Gerekçe |
|---|---|
| `NULL` yazan hücreler gerçek boş değere çevrildi | Ham dosyada boş değerler metin olarak yazılmış |
| Boş `children` değerleri 0 yapıldı | 4 satırda boş, çocuk yok kabul edildi |
| `adr` negatif olan 1 satır çıkarıldı | Negatif günlük fiyat anlamsız |
| Misafir sayısı 0 olan 180 satır çıkarıldı | Misafirsiz rezervasyon anlamsız |
| Birebir aynı satırlar silinmedi, işaretlendi | Kimlik sütunu olmadığı için gerçek kopya oldukları kesin değil |

## Bilinen sorunlar ve dikkat edilecekler

- **Kopya satırlar:** Birebir aynı satırlar iptal oranını yükseltiyor. Tüm satırlarda iptal oranı %37,1, `is_duplicate` olanlar çıkarılınca %27,3.
- **Uç değerler:** `adr` (en yüksek 5400), `adults` (en yüksek 55), `babies` ve `children` (en yüksek 10) için uç değerler var. Silinmedi.
- **"Undefined" kategorileri:** `meal`, `market_segment` ve `distribution_channel` sütunlarında "Undefined" değeri var.
- **Anonim kodlar:** `agent`, `company`, `reserved_room_type` ve `assigned_room_type` anonim kodlardır, gerçek karşılıkları bilinmiyor.
- **Para birimi:** `adr` için para birimi belirtilmemiş.
- **`company` sütunu:** %94 boş, model için kullanışlı değil.

\* Kategori adları Kaggle veri tanımından alınmıştır, bu veri setinde tam listeyi görmek için `dbt show` ile `group by` sorgusu çalıştırılabilir.