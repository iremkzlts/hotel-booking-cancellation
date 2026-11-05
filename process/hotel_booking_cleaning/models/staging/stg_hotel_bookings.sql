with kaynak as (
    select
        row_number() over () as booking_id,
        *
    from read_csv_auto(
        '../../data/raw/hotel_booking/hotel_bookings.csv',
        header = true,
        nullstr = ['NULL', 'NA']
    )
)
select
    booking_id,
    hotel,
    is_canceled,
    lead_time,
    make_date(
        arrival_date_year,
        case arrival_date_month
            when 'January' then 1 when 'February' then 2
            when 'March' then 3 when 'April' then 4
            when 'May' then 5 when 'June' then 6
            when 'July' then 7 when 'August' then 8
            when 'September' then 9 when 'October' then 10
            when 'November' then 11 when 'December' then 12
        end,
        arrival_date_day_of_month
    ) as arrival_date,
    stays_in_weekend_nights,
    stays_in_week_nights,
    adults,
    coalesce(children, 0) as children,
    babies,
    meal,
    country,
    market_segment,
    distribution_channel,
    is_repeated_guest,
    previous_cancellations,
    previous_bookings_not_canceled,
    reserved_room_type,
    assigned_room_type,
    booking_changes,
    deposit_type,
    agent,
    company,
    days_in_waiting_list,
    customer_type,
    adr,
    required_car_parking_spaces,
    total_of_special_requests,
    reservation_status,
    reservation_status_date
from kaynak
where (adr is null or adr >= 0)
  and adults + coalesce(children, 0) + babies > 0
  and (adr is null or adr <= 1000)