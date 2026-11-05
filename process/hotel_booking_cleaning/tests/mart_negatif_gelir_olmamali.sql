-- Negatif gelir olmamali. Negatif adr satirlari staging'de (Esma) cikarildigi icin
-- bu test her zaman 0 satir dondurmeli. Satir donerse test BASARISIZ olur.
select booking_id, adr, total_nights, booking_revenue
from {{ ref('fct_bookings') }}
where booking_revenue < 0