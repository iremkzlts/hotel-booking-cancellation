-- Iptal orani 0 ile 1 arasinda olmali ve iptal sayisi toplam rezervasyonu gecmemeli.
-- Bu sorgu satir dondururse test BASARISIZ olur.
select *
from {{ ref('mart_monthly_cancellations') }}
where cancel_rate < 0
   or cancel_rate > 1
   or canceled_bookings > total_bookings