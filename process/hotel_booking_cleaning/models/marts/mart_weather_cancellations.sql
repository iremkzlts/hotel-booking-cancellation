{{ config(
    materialized = 'table',
    post_hook = "copy {{ this }} to '../../data/processed/marts/mart_weather_cancellations.csv' (header, delimiter ',')"
) }}

-- mart_weather_cancellations: her satir bir otel + yagis durumu + sicaklik araligi.
-- "Hava durumu iptalleri etkiliyor mu?" sorusu icin dashboard ozeti.

select
    hotel,
    is_rainy_day,
    temp_band,
    count(*)                                            as total_bookings,
    sum(is_canceled)                                    as canceled_bookings,
    round(avg(is_canceled), 4)                          as cancel_rate,
    round(avg(precipitation_mm), 2)                     as avg_precipitation_mm,
    round(avg(temp_mean_c), 1)                          as avg_temp_mean_c
from {{ ref('fct_bookings') }}
where temp_mean_c is not null
group by hotel, is_rainy_day, temp_band
order by hotel, is_rainy_day, temp_band