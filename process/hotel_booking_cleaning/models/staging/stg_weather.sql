with faro as (
    select *, 'Faro' as city, 'Resort Hotel' as hotel
    from read_csv(
        '../../data/raw/open_meteo/weather_faro.csv',
        skip = 4,
        header = false,
        nullstr = ['NaN', ''],
        columns = {
            'weather_date': 'DATE',
            'temp_mean_c': 'DOUBLE',
            'temp_max_c': 'DOUBLE',
            'temp_min_c': 'DOUBLE',
            'precipitation_mm': 'DOUBLE',
            'rain_mm': 'DOUBLE',
            'precipitation_hours': 'DOUBLE',
            'wind_speed_max_kmh': 'DOUBLE'
        }
    )
),

lisbon as (
    select *, 'Lisbon' as city, 'City Hotel' as hotel
    from read_csv(
        '../../data/raw/open_meteo/weather_lisbon.csv',
        skip = 4,
        header = false,
        nullstr = ['NaN', ''],
        columns = {
            'weather_date': 'DATE',
            'temp_mean_c': 'DOUBLE',
            'temp_max_c': 'DOUBLE',
            'temp_min_c': 'DOUBLE',
            'precipitation_mm': 'DOUBLE',
            'rain_mm': 'DOUBLE',
            'precipitation_hours': 'DOUBLE',
            'wind_speed_max_kmh': 'DOUBLE'
        }
    )
)

select * from faro
union all
select * from lisbon