{{ config(severity = 'warn') }}

select booking_id, adr
from {{ ref('stg_hotel_bookings') }}
where adr < 0