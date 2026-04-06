SELECT 
  u.traffic_source,
  COUNT(DISTINCT u.id) AS total_users,
  COUNT(DISTINCT CASE WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), (SELECT MAX(created_at) 
  FROM `bigquery-public-data.thelook_ecommerce.orders` 
  WHERE user_id = u.id), DAY) > 60 THEN u.id END) AS inactive_users_60d, -- check if customer has purchased in last 60 days
  ROUND(SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), (SELECT MAX(created_at) 
    FROM `bigquery-public-data.thelook_ecommerce.orders` WHERE user_id = u.id), DAY) > 60 THEN u.id END),
    COUNT(DISTINCT u.id)) * 100, 2) AS churn_risk -- find at risk users and divide by all users for churn risk
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
WHERE u.created_at >= '2025-01-01' -- recent users
GROUP BY u.traffic_source
ORDER BY churn_risk DESC;