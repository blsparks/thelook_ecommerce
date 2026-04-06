WITH u_orders AS (
  SELECT 
    user_id, 
    COUNT(order_id) AS order_count
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status NOT IN ('Cancelled', 'Returned')
  GROUP BY user_id) -- count total orders in cte
SELECT 
  u.traffic_source,
  COUNT(DISTINCT u.id) AS total_customers,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN uo.order_count > 1 THEN u.id END), 
    COUNT(DISTINCT u.id)) * 100, 2) AS repeat_purchase_rate -- count customers who have ordered > 1 times
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
LEFT JOIN u_orders AS uo ON u.id = uo.user_id -- include everyone, even if they order 0 times
WHERE u.created_at >= '2025-01-01' -- recent users
GROUP BY u.traffic_source
ORDER BY repeat_purchase_rate DESC;