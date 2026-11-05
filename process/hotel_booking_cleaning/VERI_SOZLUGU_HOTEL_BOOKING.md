# Veri Sözlüğü: Otel Rezervasyon Verisi (stg_hotel_bookings ve int_hotel_bookings_flagged)

## Genel bilgi

| Madde | Değer |
|---|---|
| Kaynak | Kaggle "Hotel Booking Demand" (Portekiz'de bir tatil oteli ve bir şehir oteli) |
| Ham dosya | `data/raw/hotel_booking/hotel_bookings.csv` |
| Ham satır sayısı | 119.390 |
| Temizlik sonrası satır sayısı | 119.208 |
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
| Fiyatı 1000'in üzerinde olan uç değerli satır çıkarıldı (`adr` = 5400) | -1 |
| Temizlik sonrası | 119.208 |

Birebir aynı olan satırlar **silinmedi**, `is_duplicate` ile işaretlendi (aşağıya bakın). Diğer uç değerli satırlar da silinmedi, "Uç değerler" bölümünde belgelendi.

## Rezervasyon numarası (`booking_id`)

Ham veride rezervasyon kimliği yok. `booking_id`, **ham CSV dosyasındaki satır numarasıdır** ve satırlar çıkarılmadan önce, temizlikten bağımsız olarak üretilir. Bu yüzden:

- Numaralar 1 ile 119.390 arasındadır ve ardışık değildir: çıkarılan 182 satırın numarası boşta kalır.
- İleride başka satır çıkarılırsa kalan rezervasyonların numarası değişmez.
- Aynı rezervasyon her çalıştırmada aynı numarayı alır (CSV dosyası değişmediği sürece).

## Sütunlar

Boş yüzdeleri, aralıklar ve kategori sayıları dbt ile alınan sorgu çıktılarından yazılmıştır.

### Kimlik ve tarih

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| booking_id | tamsayı | 1 - 119390 | 0 | Ham CSV'deki satır numarası (yukarıya bakın). Benzersizliği `unique` testiyle doğrulanır |
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

### Misafirin geçmişi

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| is_repeated_guest | tamsayı | 0, 1 | 0 | 1 = daha önce konaklamış misafir |
| previous_cancellations | tamsayı | 0 - 26 | 0 | Misafirin önceki iptal sayısı |
| previous_bookings_not_canceled | tamsayı | 0 - 72 | 0 | Misafirin iptal etmediği önceki rezervasyon sayısı |

### Fiyat

| Sütun | Tür | Değer aralığı | Boş % | Açıklama |
|---|---|---|---|---|
| adr | ondalık | 0,0 - 510,0 | 0 | Ortalama günlük oda fiyatı. Para birimi veri setinde belirtilmemiş, Euro olarak varsayıldı (Portekiz). 1000'in üzerindeki tek satır (5400) çıkarıldı |

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
| `adr` değeri 1000'in üzerinde olan 1 satır çıkarıldı (5400, City Hotel, 25 Mart 2016, iptal edilmiş) | Gerçek dışı fiyat. Kaybedilen gelir toplamlarını şişiriyordu |
| `booking_id` ham CSV satır numarasıyla üretildi | Satır çıkarılsa bile numaralar değişmesin diye |
| Birebir aynı satırlar silinmedi, işaretlendi | Kimlik sütunu olmadığı için gerçek kopya oldukları kesin değil |
| Diğer uç değerli satırlar silinmedi, belgelendi | Gerçek dışı olup olmadıkları veriden ayırt edilemiyor, etkileri çok küçük |

## Uç değerler

| Sütun | Satır | Ayrıntı |
|---|---|---|
| adr > 1000 | 0 (1 satır çıkarıldı) | Çıkarılan satır: City Hotel, 25 Mart 2016, adr 5400, iptal edilmiş |
| adr > 400 | 7 | En yüksek 510. Makul aralıkta sayıldı, silinmedi |
| adults > 10 | 12 | Hepsi Resort Hotel ve hepsi iptal edilmiş. Yetişkin sayısı 20 ile 55 arası. Booking numaraları: 1540, 1588, 1644, 1753, 1885, 1918, 1963, 2004, 2165, 2174, 2229, 2419. Birbirine yakın olmaları grup rezervasyonu ya da toplu giriş hatası olabileceğini düşündürüyor, veriden ayırt edilemiyor |
| children > 5 | 1 | Booking 329, 10 çocuk, Resort Hotel, iptal edilmiş |
| babies > 5 | 2 | City Hotel, booking 46620 (10 bebek) ve 78657 (9 bebek), ikisi de iptal edilmemiş |

## Bilinen sorunlar ve dikkat edilecekler

- **Kopya satırlar:** 32.238 satır (yaklaşık %27) başka bir satırla birebir aynı. Tüm satırlarda iptal oranı %37,1, `is_duplicate` olanlar çıkarılınca %27,3.
- **Uç değerler:** Yukarıdaki tabloya bakın.
- **"Undefined" kategorileri:** `meal` (1.169), `market_segment` (2) ve `distribution_channel` (5) sütunlarında "Undefined" değeri var.
- **Anonim kodlar:** `agent`, `company`, `reserved_room_type` ve `assigned_room_type` anonim kodlardır, gerçek karşılıkları bilinmiyor.
- **Para birimi:** `adr` için para birimi veri setinde belirtilmemiş, Euro varsayıldı.
- **`company` sütunu:** %94 boş, model için kullanışlı değil.
- **Kısaltmalar:** BB, HB, FB, SC açıklamaları Kaggle veri tanımından alınmıştır, bu veri setinde ayrıca doğrulanmadı.