select DISTINCT
    user_id,
    acc_type,
    user_gender,
    age_group,
    age_generation,
    user_created_at,
    user_last_paid_date,
    user_last_visit_date,
    user_total_revenue_krw,
    user_total_revenue_krw_saju,
    user_total_revenue_krw_tarot,
    user_total_revenue_krw_else,
    user_total_day_visited,
    user_total_week_visited,
    user_total_month_visited,
     CASE
        WHEN user_total_revenue_krw = 0 THEN '0원'
        WHEN user_total_revenue_krw > 0 AND user_total_revenue_krw < 17000 THEN '1. 17,000원 미만'
        WHEN user_total_revenue_krw >= 17000 AND user_total_revenue_krw < 34000 THEN '2. 17,000원 이상'
        WHEN user_total_revenue_krw >= 34000 AND user_total_revenue_krw < 68000 THEN '3. 34,000원 이상'
        WHEN user_total_revenue_krw >= 68000 AND user_total_revenue_krw < 136000 THEN '4. 68,000원 이상'
        WHEN user_total_revenue_krw >= 136000 AND user_total_revenue_krw < 323000 THEN '5. 136,000원 이상'
        WHEN user_total_revenue_krw >= 323000 THEN '6. 323,000원 이상'
        ELSE '7. 0원'
    END AS user_revenue_range_total,
    -- 사주 콘텐츠 가격 구간 설정
    CASE
        WHEN user_total_revenue_krw_saju = 0 THEN '0원'
        WHEN user_total_revenue_krw_saju > 0 AND user_total_revenue_krw_saju < 17000 THEN '1. 17,000원 미만'
        WHEN user_total_revenue_krw_saju >= 17000 AND user_total_revenue_krw_saju < 34000 THEN '2. 17,000원 이상'
        WHEN user_total_revenue_krw_saju >= 34000 AND user_total_revenue_krw_saju < 68000 THEN '3. 34,000원 이상'
        WHEN user_total_revenue_krw_saju >= 68000 AND user_total_revenue_krw_saju < 136000 THEN '4. 68,000원 이상'
        WHEN user_total_revenue_krw_saju >= 136000 AND user_total_revenue_krw_saju < 323000 THEN '5. 136,000원 이상'
        WHEN user_total_revenue_krw_saju >= 323000 THEN '6. 323,000원 이상'
        ELSE '7. 0원'
    END AS user_revenue_range_saju,
    -- 타로 콘텐츠 가격 구간 설정
    CASE
        WHEN user_total_revenue_krw_tarot = 0 THEN '0원'
        WHEN user_total_revenue_krw_tarot > 0 AND user_total_revenue_krw_tarot < 17000 THEN '1. 17,000원 미만'
        WHEN user_total_revenue_krw_tarot >= 17000 AND user_total_revenue_krw_tarot < 34000 THEN '2. 17,000원 이상'
        WHEN user_total_revenue_krw_tarot >= 34000 AND user_total_revenue_krw_tarot < 68000 THEN '3. 34,000원 이상'
        WHEN user_total_revenue_krw_tarot >= 68000 AND user_total_revenue_krw_tarot < 136000 THEN '4. 68,000원 이상'
        WHEN user_total_revenue_krw_tarot >= 136000 AND user_total_revenue_krw_tarot < 323000 THEN '5. 136,000원 이상'
        WHEN user_total_revenue_krw_tarot >= 323000 THEN '6. 323,000원 이상'
        ELSE '7. 0원'
    END AS user_revenue_range_tarot,
    -- 기타 콘텐츠 가격 구간 설정
    CASE
        WHEN user_total_revenue_krw_else = 0 THEN '0원'
        WHEN user_total_revenue_krw_else > 0 AND user_total_revenue_krw_else < 17000 THEN '1. 17,000원 미만'
        WHEN user_total_revenue_krw_else >= 17000 AND user_total_revenue_krw_else < 34000 THEN '2. 17,000원 이상'
        WHEN user_total_revenue_krw_else >= 34000 AND user_total_revenue_krw_else < 68000 THEN '3. 34,000원 이상'
        WHEN user_total_revenue_krw_else >= 68000 AND user_total_revenue_krw_else < 136000 THEN '4. 68,000원 이상'
        WHEN user_total_revenue_krw_else >= 136000 AND user_total_revenue_krw_else < 323000 THEN '5. 136,000원 이상'
        WHEN user_total_revenue_krw_else >= 323000 THEN '6. 323,000원 이상'
        ELSE '7. 0원'
    END AS user_revenue_range_else
FROM `hellobot-f445c.hlb_mart_integrated.union_mart_user_key_actions`
WHERE event_name LIKE '%pay_for_%'
ORDER BY user_total_revenue_krw DESC