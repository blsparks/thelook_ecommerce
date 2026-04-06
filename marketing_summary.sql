CREATE OR REPLACE VIEW `project-name.dataset-name.marketing_summary` AS

-- 1. Revenue & Orders
WITH revenue AS (
  SELECT
    u.traffic_source,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sale_price), 2) AS total_revenue
  FROM `bigquery-public-data.thelook_ecommerce.users` AS u
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS o ON u.id = o.user_id
  WHERE u.created_at >= '2025-01-01' 
    AND o.status NOT IN ('Cancelled', 'Returned') 
  GROUP BY u.traffic_source),

-- 2. Average Order Value
aov AS (
  SELECT
    u.traffic_source,
    ROUND(SAFE_DIVIDE(SUM(o.sale_price), COUNT(DISTINCT o.order_id)), 2) AS avg_order_value
  FROM `bigquery-public-data.thelook_ecommerce.users` AS u
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS o ON u.id = o.user_id
  WHERE u.created_at >= '2025-01-01' 
    AND o.status NOT IN ('Cancelled', 'Returned')
  GROUP BY u.traffic_source),

-- 3. Conversion Speed
conv_speed AS (
  SELECT 
    u.traffic_source,
    ROUND(AVG(TIMESTAMP_DIFF(o.created_at, u.created_at, DAY)), 1) AS avg_days_convert
  FROM `bigquery-public-data.thelook_ecommerce.users` AS u
  JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o ON u.id = o.user_id
  WHERE u.created_at >= '2025-01-01'  
    AND o.created_at = (SELECT MIN(created_at) FROM `bigquery-public-data.thelook_ecommerce.orders` WHERE user_id = u.id)
  GROUP BY u.traffic_source),

-- 4. Order Issue Rate
issues AS (
  SELECT
    u.traffic_source,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN o.status IN ('Cancelled', 'Returned') THEN o.order_id END), 
      COUNT(DISTINCT o.order_id)) * 100, 2) AS order_issue_rate
  FROM `bigquery-public-data.thelook_ecommerce.users` AS u
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS o ON u.id = o.user_id
  WHERE u.created_at >= '2025-01-01'
  GROUP BY u.traffic_source),

-- 5. Repeat Purchase Rate
repeat_rate AS (
  WITH u_orders AS (
    SELECT user_id, COUNT(order_id) AS order_count
    FROM `bigquery-public-data.thelook_ecommerce.orders`
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY user_id)
  SELECT 
    u.traffic_source,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN uo.order_count > 1 THEN u.id END), 
      COUNT(DISTINCT u.id)) * 100, 2) AS repeat_purchase_rate
  FROM `bigquery-public-data.thelook_ecommerce.users` AS u
  LEFT JOIN u_orders AS uo ON u.id = uo.user_id
  WHERE u.created_at >= '2025-01-01'
  GROUP BY u.traffic_source),

-- 6. Basket Depth
basket AS (
  SELECT 
    u.traffic_source,
    ROUND(AVG(item_count), 2) AS avg_items_per_order
  FROM (SELECT order_id, user_id, COUNT(id) AS item_count 
    FROM `bigquery-public-data.thelook_ecommerce.order_items`
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY 1, 2) AS o
  JOIN `bigquery-public-data.thelook_ecommerce.users` AS u ON o.user_id = u.id
  WHERE u.created_at >= '2025-01-01'
  GROUP BY u.traffic_source),

-- 7. Churn Risk
churn AS (
  SELECT 
    u.traffic_source,
    ROUND(SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), (SELECT MAX(created_at) FROM `bigquery-public-data.thelook_ecommerce.orders` WHERE user_id = u.id), DAY) > 60 THEN u.id END),
      COUNT(DISTINCT u.id)) * 100, 2) AS churn_risk
  FROM `bigquery-public-data.thelook_ecommerce.users` AS u
  WHERE u.created_at >= '2025-01-01'
  GROUP BY u.traffic_source)


SELECT 
  rev.traffic_source,
  rev.total_orders,
  rev.total_revenue,
  aov.avg_order_value,
  cs.avg_days_convert,
  iss.order_issue_rate,
  rep.repeat_purchase_rate,
  bas.avg_items_per_order,
  chu.churn_risk
FROM revenue rev
LEFT JOIN aov ON rev.traffic_source = aov.traffic_source
LEFT JOIN conv_speed cs ON rev.traffic_source = cs.traffic_source
LEFT JOIN issues iss ON rev.traffic_source = iss.traffic_source
LEFT JOIN repeat_rate rep ON rev.traffic_source = rep.traffic_source
LEFT JOIN basket bas ON rev.traffic_source = bas.traffic_source
LEFT JOIN churn chu ON rev.traffic_source = chu.traffic_source
ORDER BY total_revenue DESC;