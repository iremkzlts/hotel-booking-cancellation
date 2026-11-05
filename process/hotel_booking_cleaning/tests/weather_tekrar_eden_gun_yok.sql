select city, weather_date, count(*) as adet
from {{ ref('stg_weather') }}
group by city, weather_date
having count(*) > 1
