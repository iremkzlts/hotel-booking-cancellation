select
    *,
    row_number() over (
        partition by
            hotel, is_canceled, lead_time, arrival_date,
            stays_in_weekend_nights, stays_in_week_nights,
            adults, children, babies, meal, country,
            market_segment, distribution_channel, is_repeated_guest,
            previous_cancellations, previous_bookings_not_canceled,
            reserved_room_type, assigned_room_type, booking_changes,
            deposit_type, agent, company, days_in_waiting_list,
            customer_type, adr, required_car_parking_spaces,
            total_of_special_requests
        order by booking_id
    ) as duplicate_rank,
    duplicate_rank > 1 as is_duplicate
from {{ ref('stg_hotel_bookings') }}