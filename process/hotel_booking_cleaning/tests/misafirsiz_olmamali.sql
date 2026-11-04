select booking_id
from {{ ref('stg_hotel_bookings') }}
where adults + children + babies = 0