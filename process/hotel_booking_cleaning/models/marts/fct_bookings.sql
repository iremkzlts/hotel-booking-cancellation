{{ config(
    materialized = 'table',
    post_hook = "copy {{ this }} to '../../data/processed/marts/fct_bookings.csv' (header, delimiter ',')"
) }}

-- fct_bookings: her satir bir rezervasyon.
-- Esma'nin isaretlenmis rezervasyon tablosunu okur, Zehra'nin hava durumu
-- tablosuyla varis gunu ve otele gore birlestirir, is hesaplarini ekler.
-- Temizlik burada YAPILMAZ; bozuk deger gorulurse staging'de duzeltilir.

with bookings as (

    select * from {{ ref('int_hotel_bookings_flagged') }}

),

weather as (

    select * from {{ ref('stg_weather') }}

),

birlesik as (

    select
        b.*,
        b.stays_in_weekend_nights + b.stays_in_week_nights  as total_nights,
        b.adults + b.children + b.babies                    as total_guests,
        case when b.hotel = 'Resort Hotel' then 'Faro'
             when b.hotel = 'City Hotel'   then 'Lisbon'
        end                                                 as city,
        w.temp_mean_c,
        w.temp_max_c,
        w.temp_min_c,
        w.precipitation_mm,
        w.rain_mm,
        w.precipitation_hours,
        w.wind_speed_max_kmh
    from bookings as b
    left join weather as w
        on  w.hotel        = b.hotel
        and w.weather_date = b.arrival_date

)

select
    -- kimlik ve tarih
    booking_id,
    hotel,
    city,
    arrival_date,
    year(arrival_date)                                  as arrival_year,
    month(arrival_date)                                 as arrival_month,
    date_trunc('month', arrival_date)::date             as arrival_month_start,

    -- hedef degisken
    is_canceled,

    -- kopya isareti (Esma'nin ara katmanindan)
    is_duplicate,

    -- rezervasyon bilgileri
    lead_time,
    stays_in_weekend_nights,
    stays_in_week_nights,
    total_nights,
    adults,
    children,
    babies,
    total_guests,
    meal,
    country,
    market_segment,
    distribution_channel,
    customer_type,
    deposit_type,
    reserved_room_type,
    assigned_room_type,
    reserved_room_type <> assigned_room_type            as is_room_changed,
    booking_changes,
    days_in_waiting_list,
    required_car_parking_spaces,
    total_of_special_requests,
    agent,
    company,

    -- gecmis davranis
    is_repeated_guest,
    previous_cancellations,
    previous_bookings_not_canceled,

    -- para
    adr,
    round(adr * total_nights, 2)                        as booking_revenue,
    case when is_canceled = 0 then round(adr * total_nights, 2) else 0 end
                                                        as realized_revenue,
    case when is_canceled = 1 then round(adr * total_nights, 2) else 0 end
                                                        as lost_revenue,

    -- varis gunundeki hava durumu (Zehra'nin stg_weather tablosundan)
    temp_mean_c,
    temp_max_c,
    temp_min_c,
    precipitation_mm,
    rain_mm,
    precipitation_hours,
    wind_speed_max_kmh,
    precipitation_mm >= 1.0                             as is_rainy_day,
    case
        when temp_mean_c is null then null
        when temp_mean_c < 15    then '15 alti'
        when temp_mean_c < 20    then '15-20'
        when temp_mean_c < 25    then '20-25'
        else '25 ve ustu'
    end                                                 as temp_band,

    -- DIKKAT: sonucu dogrudan soyleyen sutunlar (sadece dashboard icin).
    -- Modelde girdi olarak KULLANILMAZ (veri sizintisi).
    reservation_status,
    reservation_status_date

from birlesik