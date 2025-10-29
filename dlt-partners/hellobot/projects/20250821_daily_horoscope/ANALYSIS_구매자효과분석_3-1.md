# 3.1 구매 횟수 변화 분석 쿼리

## 1. 기존 구매자 식별 및 세그먼트 분류

### 1.1 기존 구매자 리스트 추출
```sql
-- 10월 12일 이전에 구매한 적이 있는 사용자 목록
WITH existing_buyers AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date < '2025-10-12'
    AND event_name LIKE '%pay_for_%'
    AND revenue_krw > 0
),

-- 신규 기능 사용자 식별 (10/12 이후)
feature_users AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date >= '2025-10-12'
    AND viewed_daily_tab = 1
),

-- 사용자 그룹 분류
user_groups AS (
  SELECT
    eb.user_id,
    CASE
      WHEN fu.user_id IS NOT NULL THEN 'Treatment'
      ELSE 'Control'
    END AS user_group
  FROM existing_buyers eb
  LEFT JOIN feature_users fu ON eb.user_id = fu.user_id
)
SELECT * FROM user_groups;
```

## 2. Before Period 구매 패턴 분석 (8/1 ~ 9/30)

```sql
WITH existing_buyers AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date < '2025-10-12'
    AND event_name LIKE '%pay_for_%'
    AND revenue_krw > 0
),

feature_users AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date >= '2025-10-12'
    AND viewed_daily_tab = 1
),

user_groups AS (
  SELECT
    eb.user_id,
    CASE
      WHEN fu.user_id IS NOT NULL THEN 'Treatment'
      ELSE 'Control'
    END AS user_group
  FROM existing_buyers eb
  LEFT JOIN feature_users fu ON eb.user_id = fu.user_id
),

-- Before Period 구매 데이터 (프로모션 전)
before_purchases AS (
  SELECT
    ug.user_id,
    ug.user_group,
    COUNT(DISTINCT t.transaction_id) as purchase_count,
    COUNT(DISTINCT DATE(t.event_date)) as active_days,
    COUNT(DISTINCT t.transaction_id) / NULLIF(COUNT(DISTINCT DATE(t.event_date)), 0) as daily_avg_purchases,
    COUNT(DISTINCT EXTRACT(WEEK FROM t.event_date)) as active_weeks,
    COUNT(DISTINCT t.transaction_id) / NULLIF(COUNT(DISTINCT EXTRACT(WEEK FROM t.event_date)), 0) as weekly_avg_purchases
  FROM user_groups ug
  LEFT JOIN `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029` t
    ON ug.user_id = t.user_id
    AND t.event_date BETWEEN '2025-08-01' AND '2025-09-30'
    AND t.event_name LIKE '%pay_for_%'
    AND t.revenue_krw > 0
  GROUP BY ug.user_id, ug.user_group
)

SELECT
  user_group,
  COUNT(user_id) as user_count,
  AVG(purchase_count) as avg_purchase_count,
  STDDEV(purchase_count) as std_purchase_count,
  APPROX_QUANTILES(purchase_count, 100)[OFFSET(50)] as median_purchase_count,
  AVG(daily_avg_purchases) as avg_daily_purchases,
  AVG(weekly_avg_purchases) as avg_weekly_purchases,
  AVG(active_days) as avg_active_days,
  AVG(active_weeks) as avg_active_weeks
FROM before_purchases
GROUP BY user_group;
```

## 3. After Period 구매 패턴 분석 (10/14 ~ 10/29)

```sql
WITH existing_buyers AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date < '2025-10-12'
    AND event_name LIKE '%pay_for_%'
    AND revenue_krw > 0
),

feature_users AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date >= '2025-10-12'
    AND viewed_daily_tab = 1
),

user_groups AS (
  SELECT
    eb.user_id,
    CASE
      WHEN fu.user_id IS NOT NULL THEN 'Treatment'
      ELSE 'Control'
    END AS user_group
  FROM existing_buyers eb
  LEFT JOIN feature_users fu ON eb.user_id = fu.user_id
),

-- After Period 구매 데이터 (프로모션 후)
after_purchases AS (
  SELECT
    ug.user_id,
    ug.user_group,
    COUNT(DISTINCT t.transaction_id) as purchase_count,
    COUNT(DISTINCT DATE(t.event_date)) as active_days,
    COUNT(DISTINCT t.transaction_id) / NULLIF(COUNT(DISTINCT DATE(t.event_date)), 0) as daily_avg_purchases,
    COUNT(DISTINCT EXTRACT(WEEK FROM t.event_date)) as active_weeks,
    COUNT(DISTINCT t.transaction_id) / NULLIF(COUNT(DISTINCT EXTRACT(WEEK FROM t.event_date)), 0) as weekly_avg_purchases
  FROM user_groups ug
  LEFT JOIN `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029` t
    ON ug.user_id = t.user_id
    AND t.event_date BETWEEN '2025-10-14' AND '2025-10-29'
    AND t.event_name LIKE '%pay_for_%'
    AND t.revenue_krw > 0
  GROUP BY ug.user_id, ug.user_group
)

SELECT
  user_group,
  COUNT(user_id) as user_count,
  AVG(purchase_count) as avg_purchase_count,
  STDDEV(purchase_count) as std_purchase_count,
  APPROX_QUANTILES(purchase_count, 100)[OFFSET(50)] as median_purchase_count,
  AVG(daily_avg_purchases) as avg_daily_purchases,
  AVG(weekly_avg_purchases) as avg_weekly_purchases,
  AVG(active_days) as avg_active_days,
  AVG(active_weeks) as avg_active_weeks
FROM after_purchases
GROUP BY user_group;
```

## 4. Before/After 통합 비교 분석

```sql
WITH existing_buyers AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date < '2025-10-12'
    AND event_name LIKE '%pay_for_%'
    AND revenue_krw > 0
),

feature_users AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date >= '2025-10-12'
    AND viewed_daily_tab = 1
),

user_groups AS (
  SELECT
    eb.user_id,
    CASE
      WHEN fu.user_id IS NOT NULL THEN 'Treatment'
      ELSE 'Control'
    END AS user_group
  FROM existing_buyers eb
  LEFT JOIN feature_users fu ON eb.user_id = fu.user_id
),

-- Before Period
before_purchases AS (
  SELECT
    ug.user_id,
    ug.user_group,
    'Before' as period,
    COUNT(DISTINCT t.transaction_id) as purchase_count,
    COUNT(DISTINCT DATE(t.event_date)) as active_days,
    SUM(t.revenue_krw) as total_revenue
  FROM user_groups ug
  LEFT JOIN `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029` t
    ON ug.user_id = t.user_id
    AND t.event_date BETWEEN '2025-08-01' AND '2025-09-30'
    AND t.event_name LIKE '%pay_for_%'
    AND t.revenue_krw > 0
  GROUP BY ug.user_id, ug.user_group
),

-- After Period
after_purchases AS (
  SELECT
    ug.user_id,
    ug.user_group,
    'After' as period,
    COUNT(DISTINCT t.transaction_id) as purchase_count,
    COUNT(DISTINCT DATE(t.event_date)) as active_days,
    SUM(t.revenue_krw) as total_revenue
  FROM user_groups ug
  LEFT JOIN `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029` t
    ON ug.user_id = t.user_id
    AND t.event_date BETWEEN '2025-10-14' AND '2025-10-29'
    AND t.event_name LIKE '%pay_for_%'
    AND t.revenue_krw > 0
  GROUP BY ug.user_id, ug.user_group
),

-- 통합 데이터
combined_data AS (
  SELECT * FROM before_purchases
  UNION ALL
  SELECT * FROM after_purchases
)

-- 그룹별, 기간별 통계
SELECT
  user_group,
  period,
  COUNT(user_id) as user_count,
  AVG(purchase_count) as avg_purchase_count,
  STDDEV(purchase_count) as std_purchase_count,
  APPROX_QUANTILES(purchase_count, 100)[OFFSET(50)] as median_purchase_count,
  AVG(purchase_count / NULLIF(active_days, 0)) as avg_daily_purchase_rate,
  SUM(purchase_count) as total_purchases,
  AVG(total_revenue) as avg_revenue,
  SUM(total_revenue) as total_revenue
FROM combined_data
GROUP BY user_group, period
ORDER BY user_group, period;
```

## 5. DID (Difference-in-Differences) 분석용 데이터

```sql
WITH existing_buyers AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date < '2025-10-12'
    AND event_name LIKE '%pay_for_%'
    AND revenue_krw > 0
),

feature_users AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date >= '2025-10-12'
    AND viewed_daily_tab = 1
),

user_groups AS (
  SELECT
    eb.user_id,
    CASE
      WHEN fu.user_id IS NOT NULL THEN 'Treatment'
      ELSE 'Control'
    END AS user_group
  FROM existing_buyers eb
  LEFT JOIN feature_users fu ON eb.user_id = fu.user_id
),

user_metrics AS (
  SELECT
    ug.user_id,
    ug.user_group,

    -- Before Period (8/1 ~ 9/30)
    COUNT(DISTINCT CASE
      WHEN t.event_date BETWEEN '2025-08-01' AND '2025-09-30'
      THEN t.transaction_id
    END) as before_purchase_count,

    COUNT(DISTINCT CASE
      WHEN t.event_date BETWEEN '2025-08-01' AND '2025-09-30'
      THEN DATE(t.event_date)
    END) as before_active_days,

    -- After Period (10/14 ~ 10/29)
    COUNT(DISTINCT CASE
      WHEN t.event_date BETWEEN '2025-10-14' AND '2025-10-29'
      THEN t.transaction_id
    END) as after_purchase_count,

    COUNT(DISTINCT CASE
      WHEN t.event_date BETWEEN '2025-10-14' AND '2025-10-29'
      THEN DATE(t.event_date)
    END) as after_active_days

  FROM user_groups ug
  LEFT JOIN `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029` t
    ON ug.user_id = t.user_id
    AND t.event_name LIKE '%pay_for_%'
    AND t.revenue_krw > 0
    AND (
      t.event_date BETWEEN '2025-08-01' AND '2025-09-30'
      OR t.event_date BETWEEN '2025-10-14' AND '2025-10-29'
    )
  GROUP BY ug.user_id, ug.user_group
)

SELECT
  user_group,

  -- Before Period 지표
  AVG(before_purchase_count) as avg_before_purchases,
  AVG(before_purchase_count / NULLIF(before_active_days, 0)) as avg_before_daily_rate,

  -- After Period 지표
  AVG(after_purchase_count) as avg_after_purchases,
  AVG(after_purchase_count / NULLIF(after_active_days, 0)) as avg_after_daily_rate,

  -- 변화량
  AVG(after_purchase_count - before_purchase_count) as avg_purchase_change,
  AVG((after_purchase_count / NULLIF(after_active_days, 0)) -
      (before_purchase_count / NULLIF(before_active_days, 0))) as avg_daily_rate_change,

  -- 변화율 (%)
  AVG(SAFE_DIVIDE(after_purchase_count - before_purchase_count,
                  NULLIF(before_purchase_count, 0)) * 100) as avg_purchase_change_rate,

  COUNT(user_id) as user_count
FROM user_metrics
WHERE before_purchase_count > 0  -- Before 기간에 구매가 있었던 사용자만
GROUP BY user_group;
```

## 6. 일별 구매 추이 분석

```sql
WITH existing_buyers AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date < '2025-10-12'
    AND event_name LIKE '%pay_for_%'
    AND revenue_krw > 0
),

feature_users AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date >= '2025-10-12'
    AND viewed_daily_tab = 1
),

user_groups AS (
  SELECT
    eb.user_id,
    CASE
      WHEN fu.user_id IS NOT NULL THEN 'Treatment'
      ELSE 'Control'
    END AS user_group
  FROM existing_buyers eb
  LEFT JOIN feature_users fu ON eb.user_id = fu.user_id
)

SELECT
  DATE(t.event_date) as purchase_date,
  ug.user_group,
  COUNT(DISTINCT t.transaction_id) as daily_purchases,
  COUNT(DISTINCT t.user_id) as daily_purchasers,
  AVG(t.revenue_krw) as avg_order_value,
  SUM(t.revenue_krw) as daily_revenue
FROM user_groups ug
INNER JOIN `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029` t
  ON ug.user_id = t.user_id
WHERE t.event_name LIKE '%pay_for_%'
  AND t.revenue_krw > 0
  AND (
    t.event_date BETWEEN '2025-08-01' AND '2025-09-30'  -- Before
    OR t.event_date BETWEEN '2025-10-14' AND '2025-10-29'  -- After
  )
GROUP BY DATE(t.event_date), ug.user_group
ORDER BY purchase_date, user_group;
```

## 7. 통계 검정을 위한 개별 사용자 데이터 추출

```sql
-- Mann-Whitney U test를 위한 사용자별 변화량 데이터
WITH existing_buyers AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date < '2025-10-12'
    AND event_name LIKE '%pay_for_%'
    AND revenue_krw > 0
),

feature_users AS (
  SELECT DISTINCT user_id
  FROM `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029`
  WHERE event_date >= '2025-10-12'
    AND viewed_daily_tab = 1
),

user_groups AS (
  SELECT
    eb.user_id,
    CASE
      WHEN fu.user_id IS NOT NULL THEN 'Treatment'
      ELSE 'Control'
    END AS user_group
  FROM existing_buyers eb
  LEFT JOIN feature_users fu ON eb.user_id = fu.user_id
)

SELECT
  ug.user_id,
  ug.user_group,

  -- Before Period
  COUNT(DISTINCT CASE
    WHEN t.event_date BETWEEN '2025-08-01' AND '2025-09-30'
    THEN t.transaction_id
  END) as before_purchases,

  -- After Period
  COUNT(DISTINCT CASE
    WHEN t.event_date BETWEEN '2025-10-14' AND '2025-10-29'
    THEN t.transaction_id
  END) as after_purchases,

  -- 변화량
  COUNT(DISTINCT CASE
    WHEN t.event_date BETWEEN '2025-10-14' AND '2025-10-29'
    THEN t.transaction_id
  END) -
  COUNT(DISTINCT CASE
    WHEN t.event_date BETWEEN '2025-08-01' AND '2025-09-30'
    THEN t.transaction_id
  END) as purchase_change

FROM user_groups ug
LEFT JOIN `hellobot-f445c.temporary.tony_analysis_daily_fortune_20251029` t
  ON ug.user_id = t.user_id
  AND t.event_name LIKE '%pay_for_%'
  AND t.revenue_krw > 0
  AND (
    t.event_date BETWEEN '2025-08-01' AND '2025-09-30'
    OR t.event_date BETWEEN '2025-10-14' AND '2025-10-29'
  )
GROUP BY ug.user_id, ug.user_group
HAVING before_purchases > 0  -- Before 기간에 구매 이력이 있는 사용자만
ORDER BY user_group, user_id;
```