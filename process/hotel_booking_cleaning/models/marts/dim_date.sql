{{ config(
    materialized = 'table',
    post_hook = "copy {{ this }} to '../../data/processed/marts/dim_date.csv' (header, delimiter ',')"
) }}

-- dim_date: her satir bir takvim gunu.
-- Rezervasyonlardaki en erken ve en gec varis tarihi arasindaki her gunu uretir.

with sinirlar as (

    select
        min(arrival_date) as ilk_gun,
        max(arrival_date) as son_gun
    from {{ ref('int_hotel_bookings_flagged') }}

),

gunler as (

    select unnest(generate_series(ilk_gun, son_gun, interval 1 day))::date as date_day
    from sinirlar

)

select
    date_day,
    year(date_day)                                      as year,
    quarter(date_day)                                   as quarter,
    month(date_day)                                     as month,
    case month(date_day)
        when 1 then 'Ocak'    when 2 then 'Şubat'   when 3 then 'Mart'
        when 4 then 'Nisan'   when 5 then 'Mayıs'   when 6 then 'Haziran'
        when 7 then 'Temmuz'  when 8 then 'Ağustos' when 9 then 'Eylül'
        when 10 then 'Ekim'   when 11 then 'Kasım'  when 12 then 'Aralık'
    end                                                 as month_name_tr,
    date_trunc('month', date_day)::date                 as month_start,
    weekofyear(date_day)                                as iso_week,
    isodow(date_day)                                    as weekday_no,   -- 1 = Pazartesi, 7 = Pazar
    case isodow(date_day)
        when 1 then 'Pazartesi' when 2 then 'Salı'  when 3 then 'Çarşamba'
        when 4 then 'Perşembe'  when 5 then 'Cuma'  when 6 then 'Cumartesi'
        when 7 then 'Pazar'
    end                                                 as weekday_tr,
    isodow(date_day) in (6, 7)                          as is_weekend,
    case
        when month(date_day) in (12, 1, 2) then 'Kış'
        when month(date_day) in (3, 4, 5)  then 'İlkbahar'
        when month(date_day) in (6, 7, 8)  then 'Yaz'
        else 'Sonbahar'
    end                                                 as season
from gunler
order by date_day