-- Ham dosyalar _sources.yml içinde tanımlı (raw.weather_faro, raw.weather_lisbon).
-- Okuma ayarları (ilk 4 satırı atlama, NaN = boş, sütun adları) orada, tipler burada verilir.

with faro as (
    select *, 'Faro' as city, 'Resort Hotel' as hotel
    from {{ source('raw', 'weather_faro') }}
),

lisbon as (
    select *, 'Lisbon' as city, 'City Hotel' as hotel
    from {{ source('raw', 'weather_lisbon') }}
),

birlesik as (
    select * from faro
    union all
    select * from lisbon
)

select
    cast(weather_date as date) as weather_date,
    cast(temp_mean_c as double) as temp_mean_c,
    cast(temp_max_c as double) as temp_max_c,
    cast(temp_min_c as double) as temp_min_c,
    cast(precipitation_mm as double) as precipitation_mm,
    cast(rain_mm as double) as rain_mm,
    cast(precipitation_hours as double) as precipitation_hours,
    cast(wind_speed_max_kmh as double) as wind_speed_max_kmh,
    city,
    hotel
from birlesik
