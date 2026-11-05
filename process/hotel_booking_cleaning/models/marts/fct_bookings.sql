{{ config(
    materialized = 'table',
    post_hook = "copy {{ this }} to '../../data/processed/marts/fct_bookings.csv' (header, delimiter ',')"
) }}

-- fct_bookings: her satir bir rezervasyon.
-- Esma'nin isaretlenmis rezervasyon tablosunu okur; Zehra'nin hava durumu ve
-- Irem'in Eurocontrol tablolariyla varis gunu ve otele gore birlestirir, is hesaplarini ekler.
-- Temizlik burada YAPILMAZ; bozuk deger gorulurse staging'de duzeltilir.

with bookings as (

    select * from {{ ref('int_hotel_bookings_flagged') }}

),

weather as (

    select * from {{ ref('stg_weather') }}

),

flights as (

    -- FLT_DATE UTC saatiyle tutuluyor (ornek: 2016-01-01T00:00:00Z).
    -- 'at time zone UTC' ile tarihe cevrilir; boylece bilgisayarin saat
    -- diliminden bagimsiz olarak dogru gun elde edilir.
    select
        APT_ICAO                                as airport_icao,
        (FLT_DATE at time zone 'UTC')::date     as flight_date,
        FLT_ARR_1,
        DLY_APT_ARR_1,
        DLY_APT_ARR_W_1,
        FLT_ARR_1_DLY,
        FLT_ARR_1_DLY_15
    from {{ ref('stg_eurocontrol') }}

),

birlesik as (

    select
        b.*,
        b.stays_in_weekend_nights + b.stays_in_week_nights  as total_nights,
        b.adults + b.children + b.babies                    as total_guests,
        case when b.hotel = 'Resort Hotel' then 'Faro'
             when b.hotel = 'City Hotel'   then 'Lisbon'
        end                                                 as city,
        case when b.hotel = 'Resort Hotel' then 'LPFR'
             when b.hotel = 'City Hotel'   then 'LPPT'
        end                                                 as airport_icao,
        w.temp_mean_c,
        w.temp_max_c,
        w.temp_min_c,
        w.precipitation_mm,
        w.rain_mm,
        w.precipitation_hours,
        w.wind_speed_max_kmh,
        f.flight_date                                       as flight_match_date,
        f.FLT_ARR_1,
        f.DLY_APT_ARR_1,
        f.DLY_APT_ARR_W_1,
        f.FLT_ARR_1_DLY,
        f.FLT_ARR_1_DLY_15
    from bookings as b
    left join weather as w
        on  w.hotel        = b.hotel
        and w.weather_date = b.arrival_date
    left join flights as f
        on  f.airport_icao = case when b.hotel = 'Resort Hotel' then 'LPFR'
                                  when b.hotel = 'City Hotel'   then 'LPPT' end
        and f.flight_date  = b.arrival_date

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

    -- varis gunu havalimani gecikmeleri (Irem'in stg_eurocontrol tablosundan)
    -- Eurocontrol'de bos gecikme degeri o gun ATFM gecikmesi kaydedilmedigi anlamina gelir.
    airport_icao,
    FLT_ARR_1                                           as airport_arrivals,
    DLY_APT_ARR_1                                       as atfm_arrival_delay_min,
    DLY_APT_ARR_W_1                                     as atfm_weather_delay_min,
    FLT_ARR_1_DLY                                       as atfm_delayed_arrivals,
    FLT_ARR_1_DLY_15                                    as atfm_delayed_arrivals_15,
    case
        when flight_match_date is null then null
        else round(coalesce(DLY_APT_ARR_1, 0) / nullif(FLT_ARR_1, 0), 2)
    end                                                 as atfm_delay_per_arrival_min,
    case
        when flight_match_date is null then null
        else coalesce(DLY_APT_ARR_1, 0) > 0
    end                                                 as is_atfm_delay_day,

    -- DIKKAT: sonucu dogrudan soyleyen sutunlar (sadece dashboard icin).
    -- Modelde girdi olarak KULLANILMAZ (veri sizintisi).
    reservation_status,
    reservation_status_date

from birlesik
order by booking_id