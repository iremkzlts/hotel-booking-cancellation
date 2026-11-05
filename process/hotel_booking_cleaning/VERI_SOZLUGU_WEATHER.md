# Veri Sözlüğü: stg_hotel_bookings ve int_hotel_bookings_flagged

Kaynak: Kaggle "Hotel Booking Demand" (119.390 ham satır). Temizlik sonrası 119.209 satır.

| Sütun | Tür | Açıklama |
|---|---|---|
| booking_id | sayı | Satır numarasından üretilen kimlik (ham veride kimlik sütunu yok) |
| hotel | metin | Resort Hotel (Algarve, Faro varsayımı) veya City Hotel (Lizbon) |
| is_canceled | 0/1 | Hedef değişken: 1 = iptal edildi |
| lead_time | sayı | Rezervasyon ile varış tarihi arasındaki gün sayısı |
| arrival_date | tarih | Varış tarihi (yıl, ay ve günden üretildi) |
| stays_in_weekend_nights | sayı | Hafta sonu gecesi sayısı |
| stays_in_week_nights | sayı | Hafta içi gece sayısı |
| adults | sayı | Yetişkin sayısı |
| children | sayı | Çocuk sayısı (4 boş değer 0 yapıldı) |
| babies | sayı | Bebek sayısı |
| meal | metin | Yemek planı: BB (kahvaltı), HB (yarım pansiyon), FB (tam pansiyon), SC (yemek yok) |
| country | metin | Misafirin ülkesi (3 harfli kod) |
| market_segment | metin | Pazar segmenti (ör. çevrimiçi acente, tur operatörü, doğrudan) |
| distribution_channel | metin | Rezervasyon kanalı |
| is_repeated_guest | 0/1 | 1 = daha önce konaklamış misafir |
| previous_cancellations | sayı | Misafirin önceki iptal sayısı |
| previous_bookings_not_canceled | sayı | Misafirin iptal etmediği önceki rezervasyon sayısı |
| reserved_room_type | metin | Rezerve edilen oda tipi (anonim kod) |
| assigned_room_type | metin | Atanan oda tipi (anonim kod) |
| booking_changes | sayı | Rezervasyonda yapılan değişiklik sayısı |
| deposit_type | metin | No Deposit, Non Refund veya Refundable |
| agent | sayı | Seyahat acentesi kimliği (anonim, boş olabilir) |
| company | sayı | Şirket kimliği (anonim, çoğunlukla boş) |
| days_in_waiting_list | sayı | Onaylanmadan önce bekleme listesinde geçen gün |
| customer_type | metin | Contract, Group, Transient veya Transient-Party |
| adr | sayı | Ortalama günlük oda fiyatı (para birimi belirtilmemiş) |
| required_car_parking_spaces | sayı | İstenen otopark yeri sayısı |
| total_of_special_requests | sayı | Özel istek sayısı |
| reservation_status | metin | Canceled, Check-Out veya No-Show. **İptal sonucunu ele verir (veri sızıntısı), modelde kullanılmaz** |
| reservation_status_date | tarih | Son durumun belirlendiği tarih. **Aynı sızıntı uyarısı geçerli** |
| duplicate_rank | sayı | Birebir aynı satır grubunda sıra numarası (sadece int_hotel_bookings_flagged) |
| is_duplicate | doğru/yanlış | Aynı satırın 2. ve sonraki tekrarıysa doğru (sadece int_hotel_bookings_flagged) |

**Modele alınmayan ham sütunlar:** `arrival_date_year`, `arrival_date_month` ve `arrival_date_day_of_month` tek `arrival_date` sütununa dönüştü. `arrival_date_week_number` staging'e alınmadı.