SELECT 
  u.traffic_source,
  ROUND(AVG(TIMESTAMP_DIFF(o.created_at, u.created_at, DAY)), 1) AS avg_days_convert, --order creation vs account creation
  COUNT(DISTINCT u.id) AS total_users
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o ON u.id = o.user_id
WHERE u.created_at >= '2025-01-01'  
  AND o.created_at = (SELECT MIN(created_at) 
    FROM `bigquery-public-data.thelook_ecommerce.orders` 
    WHERE user_id = u.id)
GROUP BY u.traffic_source
ORDER BY avg_days_convert ASC;