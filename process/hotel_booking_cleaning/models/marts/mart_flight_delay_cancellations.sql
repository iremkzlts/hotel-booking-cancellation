{{ config(
    materialized = 'table',
    post_hook = "copy {{ this }} to '../../data/processed/marts/mart_flight_delay_cancellations.csv' (header, delimiter ',')"
) }}

-- mart_flight_delay_cancellations: her satir bir otel + gecikme gunu mu + kopya isareti.
-- "Varis gunu havalimani gecikmeleri iptalleri etkiliyor mu?" sorusu icin dashboard ozeti.

select
    hotel,
    airport_icao,
    is_atfm_delay_day,
    is_duplicate,
    count(*)                                            as total_bookings,
    sum(is_canceled)                                    as canceled_bookings,
    round(avg(is_canceled), 4)                          as cancel_rate,
    round(avg(atfm_delay_per_arrival_min), 2)           as avg_delay_per_arrival_min,
    round(avg(airport_arrivals), 1)                     as avg_airport_arrivals
from {{ ref('fct_bookings') }}
where is_atfm_delay_day is not null
group by hotel, airport_icao, is_atfm_delay_day, is_duplicate
order by hotel, is_atfm_delay_day, is_duplicate