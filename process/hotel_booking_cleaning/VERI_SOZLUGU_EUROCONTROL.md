
# Eurocontrol Veri Sözlüğü

## 1. Veri Setinin Tanıtımı

Bu veri seti, Eurocontrol tarafından sağlanan havalimanı uçuş ve gecikme verilerini içermektedir. Proje kapsamında Faro (LPFR) ve Lisbon (LPPT) havalimanlarına ait veriler incelenmiştir.

Veri seti, havalimanlarındaki uçuş sayılarını ve uçuş gecikmelerini analiz etmek amacıyla kullanılmıştır.

**Kapsanan tarih aralığı:** 01.07.2015 – 31.08.2017  
**Havalimanları:** LPFR ve LPPT

## 2. Veri Setindeki Sütunlar

| Sütun Adı | Veri Tipi | Açıklama |
|---|---|---|
| YEAR | INTEGER | Uçuşun gerçekleştiği yıl. |
| MONTH_NUM | INTEGER | Uçuşun gerçekleştiği ayın sayısal değeri. |
| MONTH_MON | VARCHAR | Ayın kısaltılmış adı. |
| FLT_DATE | TIMESTAMP | Uçuşun gerçekleştiği tarih. |
| APT_ICAO | VARCHAR | Havalimanının ICAO kodu. |
| APT_NAME | VARCHAR | Havalimanının adı. |
| STATE_NAME | VARCHAR | Havalimanının bulunduğu ülke adı. |
| FLT_ARR_1 | DOUBLE | Gerçekleşen varış uçuşlarının sayısı. |
| DLY_APT_ARR_1 | DOUBLE | Havalimanı varış uçuşlarına ilişkin toplam gecikme değeri. |
| DLY_APT_ARR_A_1 | DOUBLE | A kategorisindeki gecikme değeri. |
| DLY_APT_ARR_C_1 | DOUBLE | C kategorisindeki gecikme değeri. |
| DLY_APT_ARR_D_1 | DOUBLE | D kategorisindeki gecikme değeri. |
| DLY_APT_ARR_E_1 | DOUBLE | E kategorisindeki gecikme değeri. |
| DLY_APT_ARR_G_1 | DOUBLE | G kategorisindeki gecikme değeri. |
| DLY_APT_ARR_I_1 | DOUBLE | I kategorisindeki gecikme değeri. |
| DLY_APT_ARR_M_1 | DOUBLE | M kategorisindeki gecikme değeri. |
| DLY_APT_ARR_N_1 | DOUBLE | N kategorisindeki gecikme değeri. |
| DLY_APT_ARR_O_1 | DOUBLE | O kategorisindeki gecikme değeri. |
| DLY_APT_ARR_P_1 | DOUBLE | P kategorisindeki gecikme değeri. |
| DLY_APT_ARR_R_1 | DOUBLE | R kategorisindeki gecikme değeri. |
| DLY_APT_ARR_S_1 | DOUBLE | S kategorisindeki gecikme değeri. |
| DLY_APT_ARR_T_1 | DOUBLE | T kategorisindeki gecikme değeri. |
| DLY_APT_ARR_V_1 | DOUBLE | V kategorisindeki gecikme değeri. |
| DLY_APT_ARR_W_1 | DOUBLE | W kategorisindeki gecikme değeri. |
| DLY_APT_ARR_NA_1 | DOUBLE | NA kategorisindeki gecikme değeri. |
| FLT_ARR_1_DLY | DOUBLE | Gecikmeli gerçekleşen varış uçuşlarına ilişkin değer. |
| FLT_ARR_1_DLY_15 | DOUBLE | 15 dakika ve üzeri gecikmeyle gerçekleşen varış uçuşlarına ilişkin değer. |
| ATFM_VERSION | VARCHAR | ATFM veri sürüm bilgisi. |

*Not: Gecikme kategorilerinin harf kodları kaynak verideki biçimiyle korunmuştur.*

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

Analiz kapsamında aşağıdaki koşullar uygulanmıştır:

**Havalimanı filtresi:**
- LPFR
- LPPT

**Tarih filtresi:**
- Başlangıç: 01.07.2015
- Bitiş: 31.08.2017

Bu filtreler sayesinde analiz için belirlenen iki havalimanına ve tarih aralığına ait kayıtlar kullanılmıştır.

## 5. Türetilen Değişken

### GECIKME_DURUMU

Veri setine analiz amacıyla yeni bir değişken eklenmiştir.

| Koşul | Değer |
|---|---|
| DLY_APT_ARR_1 NULL ise | Gecikme verisi eksik |
| DLY_APT_ARR_1 NULL değilse | Gecikme verisi mevcut |

Bu değişken, gecikme verisinin bulunup bulunmadığını sınıflandırmak amacıyla oluşturulmuştur.

## 6. Kullanılan Teknolojiler

- Python: Veri işleme ve birleştirme.
- SQL: Veri dönüştürme ve sorgulama.
- dbt: Veri modellerinin oluşturulması ve test edilmesi.
- DuckDB: Veri tabanı yönetimi ve sorgulama.
- Git ve GitHub: Sürüm kontrolü ve ekip çalışması.

