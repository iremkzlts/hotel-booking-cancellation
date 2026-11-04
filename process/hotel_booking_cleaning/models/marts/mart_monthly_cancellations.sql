{{ config(
    materialized = 'table',
    post_hook = "copy {{ this }} to '../../data/processed/marts/mart_monthly_cancellations.csv' (header, delimiter ',')"
) }}

-- mart_monthly_cancellations: her satir bir otel + bir varis ayi + kopya isareti.
-- is_duplicate ayri tutulur ki dashboard'daki kopya dilimleyicisi bu tabloyu da suzebilsin.
-- Dashboard'daki KPI kartlari ve aylik trend grafigi icin hazir ozet.

select
    hotel,
    arrival_month_start                                 as month_start,
    is_duplicate,
    count(*)                                            as total_bookings,
    sum(is_canceled)                                    as canceled_bookings,
    round(avg(is_canceled), 4)                          as cancel_rate,
    round(avg(adr), 2)                                  as avg_adr,
    round(avg(lead_time), 1)                            as avg_lead_time,
    round(sum(realized_revenue), 2)                     as realized_revenue,
    round(sum(lost_revenue), 2)                         as lost_revenue
from {{ ref('fct_bookings') }}
group by hotel, arrival_month_start, is_duplicate
order by hotel, month_start, is_duplicate