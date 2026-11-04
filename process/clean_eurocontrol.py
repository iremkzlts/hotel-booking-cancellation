# ==================================================
# EUROCONTROL VERİ SETİ TEMİZLEME VE ÖN İŞLEME
# ==================================================

# 1. AŞAMA: VERİ SETLERİNİN İNCELENMESİ
# ==================================================

from pathlib import Path
import pandas as pd

# Proje ana klasörü
BASE_DIR = Path(__file__).resolve().parents[1]

# Eurocontrol ham veri klasörü
RAW_DIR = BASE_DIR / "data" / "raw" / "eurocontrol"

csv_files = list(RAW_DIR.glob("*.csv"))

for file in csv_files:
    print("\n" + "=" * 50)
    print(f"İNCELEME: {file.name}")

    df = pd.read_csv(file)

    print("Satır ve sütun sayısı:", df.shape)
    print("\nSütunlar:")
    print(df.columns.tolist())

    print("\nVeri tipleri:")
    print(df.dtypes)

    print("\nEksik değer sayıları:")
    print(df.isnull().sum())

    print("\nİlk 5 satır:")
    print(df.head())
   # ==================================================
# 2. AŞAMA: EKSİK DEĞER ANALİZİ
# ==================================================

for file in csv_files:
    df = pd.read_csv(file)

    print("\n" + "=" * 50)
    print(f"EKSİK DEĞER ANALİZİ: {file.name}")

    missing = pd.DataFrame({
        "Eksik Değer Sayısı": df.isnull().sum(),
        "Eksik Değer Oranı (%)": (df.isnull().mean() * 100).round(2)
    })

    print(missing[missing["Eksik Değer Sayısı"] > 0]) 
    # ==================================================
# 3. AŞAMA: VERİ SETLERİNİN BİRLEŞTİRİLMESİ
# ==================================================

# Üç yıllık veriyi bir listeye aktaralım
dataframes = []

for file in csv_files:
    df = pd.read_csv(file)
    dataframes.append(df)

# Veri setlerini alt alta birleştirelim
eurocontrol_df = pd.concat(dataframes, ignore_index=True)

# Birleştirme sonucunu kontrol edelim
print("\nBİRLEŞTİRİLMİŞ VERİ SETİ")
print("Toplam satır ve sütun sayısı:", eurocontrol_df.shape)

print("\nYıllara göre kayıt sayıları:")
print(eurocontrol_df["YEAR"].value_counts().sort_index())

print("\nİlk 5 satır:")
print(eurocontrol_df.head())

print("\nSon 5 satır:")
print(eurocontrol_df.tail())
# ==================================================
# 4. AŞAMA: BİRLEŞTİRİLMİŞ VERİNİN KAYDEDİLMESİ
# ==================================================

PROCESSED_DIR = BASE_DIR / "data" / "processed"
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

output_file = PROCESSED_DIR / "eurocontrol_combined.csv"

eurocontrol_df.to_csv(output_file, index=False)

print("\nBirleştirilmiş veri başarıyla kaydedildi!")
print("Dosya konumu:", output_file)
# ==================================================
# 5. AŞAMA: TARİH DÜZENLEME VE FİLTRELEME
# ==================================================

# Tarih sütununu datetime formatına dönüştürelim
eurocontrol_df["FLT_DATE"] = pd.to_datetime(eurocontrol_df["FLT_DATE"])

# Belirlenen tarih aralığını filtreleyelim
start_date = "2015-07-01"
end_date = "2017-08-31"

eurocontrol_df = eurocontrol_df[
    (eurocontrol_df["FLT_DATE"] >= start_date) &
    (eurocontrol_df["FLT_DATE"] <= end_date)
]

print("\nTARİH FİLTRELEME SONUCU")
print("Satır ve sütun sayısı:", eurocontrol_df.shape)
print("Başlangıç tarihi:", eurocontrol_df["FLT_DATE"].min())
print("Bitiş tarihi:", eurocontrol_df["FLT_DATE"].max())
# ==================================================
# 6. AŞAMA: HEDEF HAVALİMANLARININ FİLTRELENMESİ
# ==================================================

# Faro ve Lizbon havalimanlarını seçelim
target_airports = ["LPFR", "LPPT"]

eurocontrol_df = eurocontrol_df[
    eurocontrol_df["APT_ICAO"].isin(target_airports)
]

print("\nHAVALİMANI FİLTRELEME SONUCU")
print("Satır ve sütun sayısı:", eurocontrol_df.shape)

print("\nHavalimanlarına göre kayıt sayıları:")
print(eurocontrol_df["APT_ICAO"].value_counts())

print("\nHavalimanı isimleri:")
print(eurocontrol_df[["APT_ICAO", "APT_NAME"]].drop_duplicates())
# ==================================================
# 7. AŞAMA: YİNELENEN KAYITLARIN KONTROLÜ
# ==================================================

# Tamamen aynı olan satırları kontrol edelim
duplicate_count = eurocontrol_df.duplicated().sum()

print("\nYİNELENEN KAYIT ANALİZİ")
print("Yinelenen kayıt sayısı:", duplicate_count)

# Yinelenen kayıtları görüntüleyelim
if duplicate_count > 0:
    print("\nYinelenen kayıtlar:")
    print(eurocontrol_df[eurocontrol_df.duplicated(keep=False)])
else:
    print("Veri setinde yinelenen kayıt bulunmamaktadır.")
    # ==================================================
# 8. AŞAMA: FİLTRELEME SONRASI EKSİK DEĞER ANALİZİ
# ==================================================

missing_analysis = pd.DataFrame({
    "Eksik Değer Sayısı": eurocontrol_df.isnull().sum(),
    "Eksik Değer Oranı (%)": (
        eurocontrol_df.isnull().mean() * 100
    ).round(2)
})

print("\nFİLTRELEME SONRASI EKSİK DEĞER ANALİZİ")
print(missing_analysis[missing_analysis["Eksik Değer Sayısı"] > 0])
# ==================================================
# 9. AŞAMA: EKSİK KAYITLARIN DAĞILIMI
# ==================================================

# Gecikme verisi eksik olan kayıtları belirleyelim
missing_rows = eurocontrol_df[
    eurocontrol_df["DLY_APT_ARR_1"].isnull()
]

print("\nEKSİK KAYITLARIN HAVALİMANLARINA GÖRE DAĞILIMI")
print(missing_rows["APT_ICAO"].value_counts())

print("\nEKSİK KAYITLARIN YILLARA GÖRE DAĞILIMI")
print(missing_rows["YEAR"].value_counts().sort_index())

print("\nHavalimanı ve yıl bazında eksik kayıtlar:")
print(
    missing_rows.groupby(["APT_ICAO", "YEAR"]).size()
)
# ==================================================
# 10. AŞAMA: EKSİK VE DOLU KAYITLARIN KARŞILAŞTIRILMASI
# ==================================================
# Gecikme verisi bulunan ve bulunmayan kayıtları belirleyelim
eurocontrol_df["GECIKME_DURUMU"] = eurocontrol_df[
    "DLY_APT_ARR_1"
].notnull().map({
    True: "Gecikme verisi mevcut",
    False: "Gecikme verisi eksik"
})

print("\nGECİKME VERİSİNE GÖRE KAYIT SAYILARI")
print(eurocontrol_df["GECIKME_DURUMU"].value_counts())

print("\nGECİKME DURUMUNA GÖRE UÇUŞ SAYILARI")
print(
    eurocontrol_df.groupby("GECIKME_DURUMU")["FLT_ARR_1"]
    .agg(["count", "sum", "mean"])
)
# ==================================================
# 11. AŞAMA: GECİKME VERİLERİNİN İSTATİSTİKSEL İNCELENMESİ
# ==================================================

delay_columns = [
    "DLY_APT_ARR_1",
    "FLT_ARR_1_DLY",
    "FLT_ARR_1_DLY_15"
]

print("\nGECİKME VERİLERİNİN TANIMLAYICI İSTATİSTİKLERİ")

print(
    eurocontrol_df[delay_columns].describe().round(2)
)
# ==================================================
# 12. AŞAMA: HAVALİMANLARINA GÖRE GECİKME ANALİZİ
# ==================================================

print("\nHAVALİMANLARINA GÖRE GECİKME İSTATİSTİKLERİ")

print(
    eurocontrol_df.groupby("APT_ICAO")["DLY_APT_ARR_1"]
    .agg(["count", "mean", "median", "min", "max"])
    .round(2)
)
# ==================================================
# 13. AŞAMA: YILLARA VE HAVALİMANLARINA GÖRE
# GECİKME VERİSİ DAĞILIMI
# ==================================================

print("\nYIL VE HAVALİMANINA GÖRE GECİKME VERİSİ")

delay_distribution = eurocontrol_df.pivot_table(
    index="YEAR",
    columns="APT_ICAO",
    values="DLY_APT_ARR_1",
    aggfunc="count",
    fill_value=0
)

print(delay_distribution)

print("\nYILLARA GÖRE TOPLAM GECİKME VERİSİ BULUNAN KAYITLAR")
print(delay_distribution.sum(axis=1))
# ==================================================
# 14. AŞAMA: EKSİK DEĞERLERİN GÖRSELLEŞTİRİLMESİ
# ==================================================

import matplotlib.pyplot as plt
import seaborn as sns

missing_by_airport = eurocontrol_df.groupby("APT_ICAO")[
    "DLY_APT_ARR_1"
].apply(lambda x: x.isnull().sum())

plt.figure(figsize=(8, 5))

sns.barplot(
    x=missing_by_airport.index,
    y=missing_by_airport.values
)

plt.title("Havalimanlarına Göre Eksik Gecikme Kayıtları")
plt.xlabel("Havalimanı")
plt.ylabel("Eksik Kayıt Sayısı")

plt.tight_layout()
plt.show()
# ==================================================
# 14. AŞAMA: AYKIRI DEĞER ANALİZİ
# ==================================================

delay_columns = [
    "DLY_APT_ARR_1",
    "FLT_ARR_1_DLY",
    "FLT_ARR_1_DLY_15"
]

print("\nAYKIRI DEĞER ANALİZİ (IQR YÖNTEMİ)")

for column in delay_columns:

    data = eurocontrol_df[column].dropna()

    Q1 = data.quantile(0.25)
    Q3 = data.quantile(0.75)

    IQR = Q3 - Q1

    lower_limit = Q1 - 1.5 * IQR
    upper_limit = Q3 + 1.5 * IQR

    outliers = data[
        (data < lower_limit) |
        (data > upper_limit)
    ]

    print(f"\nSütun: {column}")
    print("Alt sınır:", round(lower_limit, 2))
    print("Üst sınır:", round(upper_limit, 2))
    print("Aykırı değer sayısı:", len(outliers))
    # ==================================================
# 15. AŞAMA: AYKIRI DEĞERLERİN GÖRSELLEŞTİRİLMESİ
# ==================================================

plt.figure(figsize=(12, 5))

sns.boxplot(
    x=eurocontrol_df["DLY_APT_ARR_1"].dropna()
)

plt.title("Toplam Varış Gecikmesi - Aykırı Değer Analizi")
plt.xlabel("Gecikme Değeri")

plt.tight_layout()
plt.show()
# ==================================================
# 16. AŞAMA: TEMEL VERİ TEMİZLEME VE DÖNÜŞTÜRME
# ==================================================

# Metin sütunlarındaki gereksiz boşlukları temizleyelim
text_columns = eurocontrol_df.select_dtypes(
    include=["object"]
).columns

for column in text_columns:
    eurocontrol_df[column] = eurocontrol_df[column].str.strip()

# Sayısal sütunların veri tiplerini kontrol edelim
numeric_columns = eurocontrol_df.select_dtypes(
    include=["number"]
).columns

for column in numeric_columns:
    eurocontrol_df[column] = pd.to_numeric(
        eurocontrol_df[column],
        errors="coerce"
    )

# Tarih sütununu kontrol edelim
eurocontrol_df["FLT_DATE"] = pd.to_datetime(
    eurocontrol_df["FLT_DATE"],
    utc=True
)

# Veriyi tarihe ve havalimanına göre sıralayalım
eurocontrol_df = eurocontrol_df.sort_values(
    by=["FLT_DATE", "APT_ICAO"]
).reset_index(drop=True)

print("\nTEMEL VERİ TEMİZLEME SONUCU")
print("Satır ve sütun sayısı:", eurocontrol_df.shape)

print("\nVeri tipleri:")
print(eurocontrol_df.dtypes)

print("\nEksik değer kontrolü:")
print(eurocontrol_df.isnull().sum().sum())

print("\nİlk 5 kayıt:")
print(eurocontrol_df.head())
# ==================================================
# 16. AŞAMA: VERİ TUTARLILIĞI KONTROLÜ
# ==================================================

print("\nVERİ TUTARLILIĞI KONTROLÜ")

# Sayısal sütunlarda negatif değer kontrolü
numeric_columns = eurocontrol_df.select_dtypes(
    include=["number"]
).columns

for column in numeric_columns:
    negative_count = (eurocontrol_df[column] < 0).sum()
    if negative_count > 0:
        print(f"{column}: {negative_count} negatif değer")

# Havalimanı kontrolü
print("\nHavalimanları:")
print(eurocontrol_df["APT_ICAO"].value_counts())

# Tarih kontrolü
print("\nTarih aralığı:")
print(eurocontrol_df["FLT_DATE"].min())
print(eurocontrol_df["FLT_DATE"].max())

# Son boyut
print("\nGüncel veri boyutu:", eurocontrol_df.shape)
