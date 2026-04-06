SELECT
  u.traffic_source,
  COUNT(DISTINCT o.order_id) AS total_orders,
  ROUND(SUM(o.sale_price), 2) AS total_revenue -- gross revenue
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS o ON u.id = o.user_id
WHERE u.created_at >= '2025-01-01' -- recent users
  AND o.status NOT IN ('Cancelled', 'Returned') -- actualized revenue
GROUP BY u.traffic_source
ORDER BY total_revenue DESC;