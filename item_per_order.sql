SELECT 
  u.traffic_source,
  ROUND(AVG(item_count), 2) AS avg_items_per_order
FROM (SELECT 
    order_id, 
    user_id, 
    COUNT(id) AS item_count 
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
  GROUP BY 1, 2) AS o -- count items per specific order
JOIN `bigquery-public-data.thelook_ecommerce.users` AS u ON o.user_id = u.id
WHERE u.created_at >= '2025-01-01' -- recent users
GROUP BY u.traffic_source
ORDER BY avg_items_per_order DESC;