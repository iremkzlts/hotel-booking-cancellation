select *
from {{ ref('stg_weather') }}
where temp_min_c > temp_max_c
   or temp_mean_c not between temp_min_c and temp_max_c
