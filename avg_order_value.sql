SELECT
  u.traffic_source,
  ROUND(SAFE_DIVIDE(SUM(o.sale_price), COUNT(DISTINCT o.order_id)), 2) AS avg_order_value
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS o ON u.id = o.user_id
WHERE u.created_at >= '2025-01-01' -- recent users
  AND o.status NOT IN ('Cancelled', 'Returned') -- actualized revenue
GROUP BY u.traffic_source
ORDER BY avg_order_value DESC;