select
    'Faro'                              as sehir,
    time::date                            as tarih,
    "temperature_2m_mean (°C)"::double    as sicaklik_ort,
    "temperature_2m_max (°C)"::double     as sicaklik_max,
    "temperature_2m_min (°C)"::double     as sicaklik_min,
    "precipitation_sum (mm)"::double      as yagis_mm,
    "rain_sum (mm)"::double               as yagmur_mm,
    "precipitation_hours (h)"::double     as yagis_saat,
    "wind_speed_10m_max (km/h)"::double   as ruzgar_max_kmh
from read_csv('../../data/raw/open_meteo/weather_faro.csv', skip=3, header=true, nullstr='NaN')
