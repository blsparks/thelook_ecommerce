SELECT
  u.traffic_source,
  COUNT(DISTINCT o.order_id) AS total_orders,
  COUNT(DISTINCT CASE WHEN o.status IN ('Cancelled', 'Returned') THEN o.order_id END) AS order_issues, -- order not fulfilled
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN o.status IN ('Cancelled', 'Returned') THEN o.order_id END), 
    COUNT(DISTINCT o.order_id)) * 100, 2) AS order_issue_rate -- order issue / total orders
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS o ON u.id = o.user_id
WHERE u.created_at >= '2025-01-01'
GROUP BY u.traffic_source
ORDER BY order_issue_rate DESC;