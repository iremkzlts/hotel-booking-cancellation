# Eurocontrol Veri Sözlüğü

## 1. Veri Setinin Tanıtımı

Bu veri seti, Eurocontrol tarafından sağlanan havalimanı uçuş ve gecikme verilerini içermektedir. Proje kapsamında Portekiz'de bulunan Faro (LPFR) ve Lisbon (LPPT) havalimanlarına ait veriler incelenmiştir.

Veri seti, havalimanlarındaki gerçekleşen varış uçuşlarını ve havalimanı kaynaklı varış gecikmelerini analiz etmek amacıyla kullanılmıştır.

**Kapsanan tarih aralığı:** 01.07.2015 – 31.08.2017  
**Havalimanları:** LPFR (Faro) ve LPPT (Lisbon)

## 2. Veri Setindeki Sütunlar

| Sütun Adı | Veri Tipi | Açıklama |
|---|---|---|
| YEAR | INTEGER | Uçuş kaydının ait olduğu yıl. |
| MONTH_NUM | INTEGER | Uçuş kaydının ait olduğu ayın sayısal değeri. |
| MONTH_MON | VARCHAR | Ayın kısaltılmış adı. |
| FLT_DATE | TIMESTAMP | Uçuş kaydının ait olduğu tarih. |
| APT_ICAO | VARCHAR | Havalimanının ICAO kodu. |
| APT_NAME | VARCHAR | Havalimanının adı. |
| STATE_NAME | VARCHAR | Havalimanının bulunduğu ülke adı. |
| FLT_ARR_1 | DOUBLE | Gerçekleşen varış uçuşlarının sayısı. |
| DLY_APT_ARR_1 | DOUBLE | Havalimanı kaynaklı toplam varış gecikmesi değeri. |
| DLY_APT_ARR_A_1 | DOUBLE | A kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_C_1 | DOUBLE | C kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_D_1 | DOUBLE | D kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_E_1 | DOUBLE | E kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_G_1 | DOUBLE | G kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_I_1 | DOUBLE | I kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_M_1 | DOUBLE | M kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_N_1 | DOUBLE | N kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_O_1 | DOUBLE | O kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_P_1 | DOUBLE | P kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_R_1 | DOUBLE | R kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_S_1 | DOUBLE | S kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_T_1 | DOUBLE | T kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_V_1 | DOUBLE | V kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_W_1 | DOUBLE | W kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| DLY_APT_ARR_NA_1 | DOUBLE | NA kategorisindeki havalimanı kaynaklı varış gecikmesi değeri. |
| FLT_ARR_1_DLY | DOUBLE | Gecikmeli gerçekleşen varış uçuşlarına ilişkin değer. |
| FLT_ARR_1_DLY_15 | DOUBLE | 15 dakika ve üzeri gecikmeyle gerçekleşen varış uçuşlarına ilişkin değer. |
| ATFM_VERSION | VARCHAR | ATFM veri sürüm bilgisi. |

**Not:** Gecikme kategorilerinin harf kodları kaynak verideki biçimiyle korunmuştur. Gecikme değerlerinin ölçü birimi kaynak veri dokümantasyonuna göre değerlendirilmelidir.

## 3. Veri Temizleme İşlemleri

Eurocontrol veri setinde analiz öncesinde aşağıdaki veri temizleme işlemleri uygulanmıştır:

- Boş veya yalnızca boşluk içeren metin değerleri NULL olarak düzenlenmiştir.
- Sayısal olması gereken gecikme ve uçuş alanları TRY_CAST kullanılarak DOUBLE veri tipine dönüştürülmüştür.
- ATFM_VERSION alanındaki gereksiz boşluklar TRIM ile temizlenmiş, boş değerler NULL olarak düzenlenmiştir.
- Tarih alanı uygun zaman damgası veri tipine dönüştürülmüştür.
- Analiz kapsamı dışında kalan havalimanları filtrelenmiştir.
- Yalnızca LPFR ve LPPT havalimanlarına ait kayıtlar bırakılmıştır.
- Tarih aralığı 1 Temmuz 2015 ile 31 Ağustos 2017 arasında sınırlandırılmıştır.

## 4. Uygulanan Filtreleme İşlemleri

**Havalimanı filtresi:**
- LPFR
- LPPT

**Tarih filtresi:**
- Başlangıç: 01.07.2015
- Bitiş: 31.08.2017

Bu filtreler sayesinde analiz için belirlenen iki havalimanına ve tarih aralığına ait kayıtlar kullanılmıştır.

## 5. Türetilen Değişkenler ve Model Alanları

### 5.1. GECIKME_DURUMU

Veri setine analiz amacıyla yeni bir değişken eklenmiştir.

| Koşul | Değer |
|---|---|
| DLY_APT_ARR_1 NULL ise | Gecikme verisi eksik |
| DLY_APT_ARR_1 NULL değilse | Gecikme verisi mevcut |

Bu değişken, gecikme verisinin bulunup bulunmadığını sınıflandırmak amacıyla oluşturulmuştur.

### 5.2. TOPLAM_UCUS

Aylık havalimanı gecikme modelinde oluşturulan bu alan, ilgili havalimanı ve ay için kaynak veri setinde bulunan günlük kayıtların sayısını ifade eder. Gerçekleşen uçuş sayısını ifade etmez.

### 5.3. GECIKME_VERISI_BULUNAN_UCUS

İlgili havalimanı ve ay için gecikme verisi bulunan kayıtların sayısını ifade eder. Gerçek uçuş sayısı olarak yorumlanmamalıdır.

### 5.4. ORTALAMA_GECIKME

İlgili havalimanı ve ay için hesaplanan ortalama gecikme değerini ifade eder. Gecikme verisi bulunan gözlemler üzerinden değerlendirilmelidir.

### 5.5. MAKSIMUM_GECIKME ve MINIMUM_GECIKME

İlgili havalimanı ve ay için hesaplanan en yüksek ve en düşük gecikme değerlerini ifade eder.

## 6. Veri Kısıtları ve Bilinen Sınırlılıklar

- Analiz yalnızca LPFR (Faro) ve LPPT (Lisbon) havalimanlarını kapsamaktadır.
- Veri seti 01.07.2015 – 31.08.2017 tarih aralığıyla sınırlandırılmıştır.
- Faro (LPFR) havalimanına ait bazı dönemlerde gecikme gözlemleri sınırlıdır.
- Gecikme verisi bulunmayan kayıtlar, ortalama gecikme hesaplamalarını etkileyebileceğinden sonuçlar mevcut gözlem sayısı dikkate alınarak yorumlanmalıdır.
- TOPLAM_UCUS ve GECIKME_VERISI_BULUNAN_UCUS alanları günlük kayıt sayılarını ifade eder; gerçek uçuş sayılarıyla karıştırılmamalıdır.

## 7. Kullanılan Teknolojiler

- **Python:** Veri işleme ve birleştirme.
- **SQL:** Veri dönüştürme ve sorgulama.
- **dbt:** Veri modellerinin oluşturulması, belgelenmesi ve test edilmesi.
- **DuckDB:** Veri tabanı yönetimi ve sorgulama.
- **Git ve GitHub:** Sürüm kontrolü ve ekip çalışması.
- **Looker Studio:** Verilerin görselleştirilmesi ve dashboard hazırlanması.