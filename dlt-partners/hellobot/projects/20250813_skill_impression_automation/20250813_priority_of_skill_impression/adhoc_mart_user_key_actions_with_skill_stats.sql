    -- DECLARE START_DATE DATE;
    -- DECLARE END_DATE DATE;
    DECLARE KRW_PER_HEART, KRW_PER_USD INT64;
    -- SET START_DATE = '2022-01-01';
    -- SET END_DATE = '2024-12-31';
    SET KRW_PER_HEART = 150;
    SET KRW_PER_USD = 1250;

    CREATE OR REPLACE TABLE `hellobot-f445c.hlb_mart_adhoc.adhoc_mart_user_key_actions_with_skill_stats` PARTITION BY event_date AS

    -- 1. user_daily + use_skill_se union - 필요한 필드만 골라서 넣기
    -- 일별 방문시 1회 남기는 이벤트 형식으로 union
    WITH
    -- enter_skill, consume_skill, pay_for_* events
    base_use_skill_se AS (
        SELECT
            event_date,
            event_timestamp,
            event_month,
            event_week,
            start_of_week,
            end_of_week,
            event_name,
            user_id,
            user_country,
            -- user_language,
            platform,
            user_gender,
            user_birth_year,
            user_age,
            user_type,
            user_created_at,
            user_is_new_month,
            user_is_new_week,
            chatbot_seq,
            chatbot_name,
            chatbot_original_type,
            menu_seq,
            menu_name,
            -- block_seq,
            -- block_name,
            current_heart_price,
            heart_price,
            current_price,
            price,
            -- package_seq,
            -- package_title,
            -- unlock_price,
            -- current_unlock_price,
            -- current_procedure,
            -- collection_name,
            -- collection_seq,
            -- product_category,
            spent_heart_coin,
            spent_bonus_heart_coin,
            spent_cash_amount,
            -- spent_cash_currency,
            spent_cash_amount_krw,
            spent_total_amount_krw,
            revenue_krw,
            CAST(NULL AS STRING) AS currency,
            NULL AS event_value_in_currency,
            NULL AS event_value_in_usd,
            CAST(NULL AS STRING) AS product_id,
            CAST(NULL AS STRING) AS product_name,
            CAST(NULL AS STRING) AS product_type,
            CAST(NULL AS STRING) AS transaction_id,
        FROM
            `hellobot-f445c.hlb_mart.mart_use_skill_se`
    ),
    -- open_skill_description events
    -- base_mart_v2_skill_funnel_fb_open_skill_description AS (
    --     SELECT
    --         event_date,
    --         event_timestamp,
    --         event_month,
    --         event_week,
    --         start_of_week,
    --         end_of_week,
    --         event_name,
    --         user_id,
    --         country AS user_country,
    --         -- -- language AS user_language,
    --         platform,
    --         user_gender,
    --         user_birth_year,
    --         user_age,
    --         user_type,
    --         user_created_at,
    --         user_is_new_month,
    --         user_is_new_week,
    --         chatbot_seq,
    --         chatbot_name,
    --         chatbot_original_type,
    --         menu_seq,
    --         menu_name,
    --         -- CAST(NULL AS STRING) AS block_seq,
    --         -- CAST(NULL AS STRING) AS block_name,
    --         -- NULL AS current_heart_price,
    --         -- NULL AS heart_price,
    --         -- NULL AS current_price,
    --         -- NULL AS price,
    --         -- NULL AS package_seq,
    --         -- CAST(NULL AS STRING)  AS package_title,
    --         -- NULL AS unlock_price,
    --         -- NULL AS current_unlock_price,
    --         -- NULL AS current_procedure,
    --         -- CAST(NULL AS STRING) AS collection_name,
    --         -- CAST(NULL AS STRING) AS collection_seq,
    --         -- NULL AS product_category,
    --         NULL AS spent_heart_coin,
    --         NULL AS spent_bonus_heart_coin,
    --         NULL AS spent_cash_amount,
    --         -- CAST(NULL AS STRING) AS spent_cash_currency,
    --         NULL AS spent_cash_amount_krw,
    --         NULL AS spent_total_amount_krw,
    --         NULL AS revenue_krw,
    -- CAST(NULL AS STRING) AS currency,
    -- NULL AS event_value_in_currency,
    -- NULL AS event_value_in_usd,
    --         CAST(NULL AS STRING) AS product_id,
    --         CAST(NULL AS STRING) AS product_name,
    --         CAST(NULL AS STRING) AS product_type,
    --         CAST(NULL AS STRING) AS transaction_id,
    --     FROM `hellobot-f445c.hlb_mart.mart_v2_skill_funnel_fb`
    --         WHERE event_name = 'open_skill_description'
    --             -- AND event_date >= START_DATE AND event_date <= END_DATE
    -- ),
    union_user_actions AS (
        (
            SELECT
                *
            FROM
                base_use_skill_se
        )
        -- UNION ALL
        -- (SELECT * FROM base_mart_v2_skill_funnel_fb_open_skill_description)
    ),
    -- 2. content info
    skill_meta_info AS (
        SELECT
            menu_seq,
            menu_name,
            targets[SAFE_OFFSET(0)] AS target,
            subjects[SAFE_OFFSET(0)] AS subject,
            content_types[SAFE_OFFSET(0)] AS chatbot_content_type
        FROM
            `hellobot-f445c.hlb_mart.mart_fixed_menu_server`
        WHERE
            menu_seq IS NOT NULL
            AND targets IS NOT NULL
            AND subjects IS NOT NULL
            AND content_types IS NOT NULL
    ),
    skill_open_date_se AS (
        SELECT
            menu_seq,
            event_date AS open_date,
        FROM
            `hellobot-f445c.hlb_mart.mart_skill_open_date_se`
    ),
    union_use_skill_with_skill_info AS (
        SELECT
            u.*,
            -- (IFNULL (u.spent_heart_coin, 0) * KRW_PER_HEART) + (IFNULL (u.spent_bonus_heart_coin, 0) * KRW_PER_HEART) + IFNULL (u.spent_cash_amount_krw, 0) AS spent_total_amount_krw,
            tags.target,
            open_date.open_date,
        FROM
            union_user_actions u
            LEFT JOIN skill_meta_info tags ON u.menu_seq = tags.menu_seq
            LEFT JOIN skill_open_date_se open_date ON u.menu_seq = open_date.menu_seq
    ),
    -- 3. + user info
    user_property_info_monthly_avg AS (
        WITH
            monthly AS (
                SELECT
                    user_id,
                    event_month,
                    SUM(
                        IFNULL (spent_heart_coin, 0) * KRW_PER_HEART + IFNULL (spent_cash_amount_krw, 0)
                    ) AS total_revenue_krw,
                    COUNT(DISTINCT event_date) AS total_day_visited,
                FROM
                    union_user_actions
                GROUP BY
                    user_id,
                    event_month
            )
        SELECT
            user_id,
            AVG(total_revenue_krw) AS monthly_avg_revenue_krw,
            AVG(total_day_visited) AS monthly_avg_day_visited,
        FROM
            monthly
        GROUP BY
            user_id
    ),
    pay_for_skill_with_type AS (
        SELECT
            ROW_NUMBER() OVER (
                PARTITION BY
                    a.user_id
                ORDER BY
                    a.event_timestamp
            ) as pay_for_skill_order,
            b.chatbot_content_type,
            a.*
        FROM
            `hellobot-f445c.hlb_mart.mart_use_skill_se` a
            LEFT JOIN skill_meta_info b ON a.menu_seq = b.menu_seq
        WHERE
            event_name LIKE '%pay_for_%'
    ),
    user_first_paid_skill AS (
        SELECT
            user_id,
            chatbot_seq,
            menu_seq,
            menu_name,
            chatbot_content_type
        FROM
            pay_for_skill_with_type
        WHERE
            pay_for_skill_order = 1
    ),
    user_total_paid_by_skill_type AS (
        SELECT
            user_id,
            SUM(IF (chatbot_content_type = '사주', revenue_krw, 0)) AS total_revenue_krw_saju,
            SUM(IF (chatbot_content_type = '타로', revenue_krw, 0)) AS total_revenue_krw_tarot,
            SUM(
                IF (
                    chatbot_content_type NOT IN ('타로', '사주'),
                    revenue_krw,
                    0
                )
            ) AS total_revenue_krw_else,
            SUM(revenue_krw) AS total_revenue_krw
        FROM
            pay_for_skill_with_type
        GROUP BY
            user_id
    ),
    user_properties AS (
        WITH
            user_property_total AS (
                SELECT
                    user_id,
                    COUNT(
                        DISTINCT CASE
                            WHEN event_name LIKE '%pay_for_%' THEN event_date
                            ELSE NULL
                        END
                    ) AS number_of_paid_date,
                    -- total revenue in KRW
                    SUM(
                        IFNULL (spent_heart_coin, 0) * KRW_PER_HEART + IFNULL (spent_cash_amount_krw, 0)
                    ) AS total_revenue_krw,
                    -- total number of visit
                    COUNT(DISTINCT event_date) AS total_day_visited,
                    COUNT(DISTINCT event_week) AS total_week_visited,
                    COUNT(DISTINCT event_month) AS total_month_visited,
                    -- first paid date
                    MIN(
                        IF (
                            IFNULL (spent_heart_coin, 0) * KRW_PER_HEART + IFNULL (spent_cash_amount_krw, 0) > 0,
                            event_date,
                            NULL
                        )
                    ) AS first_paid_date,
                    -- last paid date
                    MAX(
                        IF (
                            IFNULL (spent_heart_coin, 0) * KRW_PER_HEART + IFNULL (spent_cash_amount_krw, 0) > 0,
                            event_date,
                            NULL
                        )
                    ) AS last_paid_date,
                    -- last visit date
                    MAX(event_date) AS last_visit_date,
                FROM
                    union_user_actions
                GROUP BY
                    user_id
            )
        SELECT
            a.*,
            b.monthly_avg_revenue_krw AS total_revenue_krw_monthly_avg,
            b.monthly_avg_day_visited AS total_day_visited_monthly_avg,
            c.menu_seq AS first_paid_menu_seq,
            c.menu_name AS first_paid_menu_name,
            c.chatbot_content_type AS first_paid_menu_content_type,
            d.total_revenue_krw_saju AS total_revenue_krw_saju,
            d.total_revenue_krw_tarot AS total_revenue_krw_tarot,
            d.total_revenue_krw_else AS total_revenue_krw_else,
        FROM
            user_property_total a
            LEFT JOIN user_property_info_monthly_avg b ON a.user_id = b.user_id
            LEFT JOIN user_first_paid_skill c ON a.user_id = c.user_id
            LEFT JOIN user_total_paid_by_skill_type d ON a.user_id = d.user_id
    ),
    -- 4. + user action event for funnel tagging - 특정 퍼널 성과 분석용
    -- home banner
    base_touch_featured_banner AS (
        SELECT
            event_date,
            event_name,
            platform,
            user_id,
            menu_seq,
            COALESCE(menu_name, banner_title) AS menu_name,
        FROM
            `hellobot-f445c.hlb_mart.mart_home_action_fb`
        WHERE
            event_name = 'touch_featured_banner'
    ),
    distinct_touch_featured_banner AS (
        SELECT DISTINCT
            event_date,
            user_id,
            menu_seq,
            true AS from_home_banner
        FROM
            base_touch_featured_banner
    ),
    -- base_v2_skill_funnel_fb
    base_v2_skill_funnel_fb AS (
        SELECT
            event_date,
            event_name,
            user_id_processed AS user_id,
            menu_seq,
            section_name
        FROM
            `hellobot-f445c.hlb_mart.mart_v2_skill_funnel_fb`
        WHERE
            event_name IN (
                'touch_home_section_item',
                'touch_home_section_more_item',
                'touch_skill_item_in_category',
                'view_search_main',
                'touch_search_result'
            )
    ),
    -- home section
    base_touch_home_section_item AS (
        SELECT
            event_date,
            user_id,
            menu_seq,
            (
                CASE
                    WHEN section_name LIKE '%추천스킬%' THEN '추천스킬'
                    ELSE section_name
                END
            ) AS section
        FROM
            base_v2_skill_funnel_fb
        WHERE
            event_name IN (
                'touch_home_section_item',
                'touch_home_section_more_item'
            )
            --   AND tab_name = '추천'
            AND section_name != '인기 TOP 10'
            AND (
                section_name LIKE '%TOP 10%'
                OR section_name LIKE '%추천스킬%'
                OR section_name = '인기 관계도'
                OR section_name = '⚡ 실시간 인기'
                OR section_name = '새로 나온 스킬'
                OR section_name LIKE '%이 주의 추천%'
                OR section_name LIKE '%7일간의 값진 혜택%'
                OR section_name LIKE '%퇴사를 꿈꾸며%'
                OR section_name LIKE '%썸일까? 착각일까?%'
                OR section_name LIKE '%결혼을 꿈꾸며%'
                OR section_name LIKE '%학생이라면?%'
                OR section_name LIKE '%내 사주엔 어떤 살이?%'
                OR section_name LIKE '%인기 AI 궁합도%'
                OR section_name LIKE '%신규 스킬 추천%'
                OR section_name LIKE '%사주 BEST%'
                OR section_name LIKE '%타로 BEST%'
                OR section_name LIKE '%언제 연애할 수 있을까?%'
                OR section_name LIKE '%어떤 사람과 만나게 될까%'
                OR section_name LIKE '%우리 다시 만날 수 있을까%'
                OR section_name LIKE '%결혼해도 괜찮을까%'
                OR section_name LIKE '%언제 결혼할 수 있을까%'
                OR section_name LIKE '%사주로 보는 나의 재물운%'
                OR section_name LIKE '%그 사람과 나 잘 맞을까%'
                OR section_name LIKE '%그 사람과 잘될 수 있을까%'
                OR section_name LIKE '%신규 스킬 추천%'
                OR section_name LIKE '%내 운명 어떤 사람일까?%'
            )
    ),
    distinct_touch_home_section_item AS (
        SELECT DISTINCT
            event_date,
            user_id,
            menu_seq,
            true AS from_home_section
        FROM
            base_touch_home_section_item
    ),
    -- home category
    base_touch_skill_item_in_category AS (
        SELECT
            event_date,
            user_id,
            menu_seq
        FROM
            base_v2_skill_funnel_fb
        WHERE
            event_name = 'touch_skill_item_in_category'
    ),
    distinct_touch_skill_item_in_category AS (
        SELECT DISTINCT
            event_date,
            user_id,
            menu_seq,
            true AS from_home_category
        FROM
            base_touch_skill_item_in_category
    ),
    -- search result
    base_touch_search_result AS (
        SELECT
            event_date,
            user_id,
            menu_seq
        FROM
            base_v2_skill_funnel_fb
        WHERE
            event_name = "touch_search_result"
    ),
    distinct_touch_search_result AS (
        SELECT DISTINCT
            event_date,
            user_id,
            menu_seq,
            true AS from_search_result
        FROM
            base_touch_search_result
    ),
    -- 스킬별 통계 데이터 추가
    -- 스킬 총 매출(revenue_krw) 추가
    -- 스킬 총 구매자수(pay_for_* 이벤트 user_id 중복 제거) 추가
    -- 스킬 일 평균 매출(revenue_krw) 추가 (일 = COUNT(DISTINCT event_date))
    -- 스킬 일 평균 구매자수(pay_for_* 이벤트 user_id 중복 제거) 추가 (일 = COUNT(DISTINCT event_date))
    -- 스킬 일 최고 매출(revenue_krw) 추가
    -- 스킬 일 최고 구매자수(pay_for_* 이벤트 user_id 중복 제거) 추가
    skill_stats_info AS (
        WITH skill_daily_stats AS (
            SELECT
                menu_seq,
                event_date,
                -- 일별 매출
                SUM(CASE WHEN event_name LIKE '%pay_for_%' THEN revenue_krw ELSE 0 END) AS daily_revenue_krw,
                -- 일별 구매자 수 (중복 제거)
                COUNT(DISTINCT CASE WHEN event_name LIKE '%pay_for_%' THEN user_id ELSE NULL END) AS daily_buyers_count
            FROM
                base_use_skill_se
            WHERE
                menu_seq IS NOT NULL
                AND platform != 'WEB'
            GROUP BY
                menu_seq, event_date
        )
        SELECT
            s.menu_seq,
            -- 스킬 총 매출
            SUM(s.daily_revenue_krw) AS total_revenue_krw,
            -- 스킬 총 구매자수 (전체 기간 user_id 중복 제거)
            (SELECT COUNT(DISTINCT user_id)
            FROM base_use_skill_se
            WHERE menu_seq = s.menu_seq
            AND event_name LIKE '%pay_for_%'
            AND platform != 'WEB') AS total_unique_buyers,
            -- 스킬 일 평균 매출
            CASE
                WHEN COUNT(DISTINCT s.event_date) > 0
                THEN SUM(s.daily_revenue_krw) / COUNT(DISTINCT s.event_date)
                ELSE 0
            END AS daily_avg_revenue_krw,
            -- 스킬 일 평균 구매자수
            CASE
                WHEN COUNT(DISTINCT s.event_date) > 0
                THEN AVG(s.daily_buyers_count)
                ELSE 0
            END AS daily_avg_buyers_count,
            -- 스킬 일 최고 매출
            MAX(s.daily_revenue_krw) AS daily_max_revenue_krw,
            -- 스킬 일 최고 구매자수
            MAX(s.daily_buyers_count) AS daily_max_buyers_count,
            -- 스킬 최근 30일의 일 평균 매출
            CASE
                WHEN COUNT(DISTINCT CASE WHEN s.event_date >= CURRENT_DATE() - 30 THEN s.event_date ELSE NULL END) > 0
                THEN SUM(CASE WHEN s.event_date >= CURRENT_DATE() - 30 THEN s.daily_revenue_krw ELSE 0 END) / COUNT(DISTINCT CASE WHEN s.event_date >= CURRENT_DATE() - 30 THEN s.event_date ELSE NULL END)
                ELSE 0
            END AS daily_avg_revenue_krw_30d,
            -- 스킬 최근 30일의 일 평균 구매자수
            CASE
                WHEN COUNT(DISTINCT CASE WHEN s.event_date >= CURRENT_DATE() - 30 THEN s.event_date ELSE NULL END) > 0
                THEN AVG(CASE WHEN s.event_date >= CURRENT_DATE() - 30 THEN s.daily_buyers_count ELSE NULL END)
                ELSE 0
            END AS daily_avg_buyers_count_30d,
            -- 스킬 최근 30일의 일 최고 매출
            MAX(CASE WHEN s.event_date >= CURRENT_DATE() - 30 THEN s.daily_revenue_krw ELSE NULL END) AS daily_max_revenue_krw_30d,
            -- 스킬 최근 30일의 일 최고 구매자수
            MAX(CASE WHEN s.event_date >= CURRENT_DATE() - 30 THEN s.daily_buyers_count ELSE NULL END) AS daily_max_buyers_count_30d,
            -- 활성 일수 (매출이 있는 일의 수)
            COUNT(DISTINCT CASE WHEN s.daily_revenue_krw > 0 THEN s.event_date ELSE NULL END) AS active_days_count
        FROM
            skill_daily_stats s
        GROUP BY
            s.menu_seq
    )
    -- 5. + addtional info - 대시보드용 데이터 변형 태그 정보
    SELECT
        a.*,
        h.chatbot_content_type,
        h.target AS skill_target_segment,
        h.subject AS skill_subject,
        b.first_paid_menu_seq AS user_first_paid_menu_seq,
        b.first_paid_menu_name AS user_first_paid_menu_name,
        b.first_paid_menu_content_type AS user_first_paid_menu_content_type,
        b.number_of_paid_date AS user_number_of_paid_date,
        b.total_revenue_krw AS user_total_revenue_krw,
        b.total_revenue_krw_monthly_avg AS user_total_revenue_krw_monthly_avg,
        b.total_day_visited AS user_total_day_visited,
        b.total_day_visited_monthly_avg AS user_total_day_visited_monthly_avg,
        b.total_week_visited AS user_total_week_visited,
        b.total_month_visited AS user_total_month_visited,
        b.first_paid_date AS user_first_paid_date,
        b.last_paid_date AS user_last_paid_date,
        b.last_visit_date AS user_last_visit_date,
        b.total_revenue_krw_saju AS user_total_revenue_krw_saju,
        b.total_revenue_krw_tarot AS user_total_revenue_krw_tarot,
        b.total_revenue_krw_else AS user_total_revenue_krw_else,
        -- IFNULL (spent_heart_coin, 0) * KRW_PER_HEART + IFNULL (spent_cash_amount_krw, 0) AS revenue_krw,
        j.total_revenue_krw AS skill_total_revenue_krw,
        j.total_unique_buyers AS skill_total_unique_buyers,
        j.daily_avg_revenue_krw AS skill_daily_avg_revenue_krw,
        j.daily_avg_buyers_count AS skill_daily_avg_buyers_count,
        j.daily_max_revenue_krw AS skill_daily_max_revenue_krw,
        j.daily_max_buyers_count AS skill_daily_max_buyers_count,
        j.daily_avg_revenue_krw_30d AS skill_daily_avg_revenue_krw_30d,
        j.daily_avg_buyers_count_30d AS skill_daily_avg_buyers_count_30d,
        j.daily_max_revenue_krw_30d AS skill_daily_max_revenue_krw_30d,
        j.daily_max_buyers_count_30d AS skill_daily_max_buyers_count_30d,
        j.active_days_count AS skill_active_days_count,
        CASE
            WHEN a.platform IN ('IOS', 'ANDROID') THEN 'APP'
            WHEN a.platform = 'WEB' THEN 'WEB'
            ELSE 'UNKNOWN'
        END AS platform_appweb,
        CASE
            WHEN a.user_created_at IS NULL THEN '생성일 없음'
            WHEN a.event_date = a.user_created_at THEN '신규'
            WHEN a.event_date != a.user_created_at THEN '기존'
            ELSE '오류'
        END user_new_type,
        FORMAT_DATE ("%Y-%Ww", a.user_created_at) AS cohort_week,
        DATE_TRUNC (a.user_created_at, WEEK (MONDAY)) AS cohort_start_of_week,
        DATE_ADD (
            DATE_TRUNC (a.user_created_at, WEEK (MONDAY)),
            INTERVAL 6 DAY
        ) AS cohort_end_of_week,
        FORMAT_DATE ("%Y-%m", a.user_created_at) AS cohort_month,
        CASE
            WHEN a.user_age >= 13
            AND a.user_age <= 17 THEN '13-17'
            WHEN a.user_age >= 18
            AND a.user_age <= 24 THEN '18-24'
            WHEN a.user_age >= 25
            AND a.user_age <= 34 THEN '25-34'
            WHEN a.user_age >= 35
            AND a.user_age <= 44 THEN '35-44'
            WHEN a.user_age >= 45
            AND a.user_age <= 54 THEN '45-54'
            WHEN a.user_age >= 55
            AND a.user_age <= 64 THEN '55-64'
            WHEN a.user_age >= 65
            AND a.user_age <= 99 THEN '65+'
            ELSE '정보없음'
        END AS age_group,
        CASE
            WHEN a.user_age >= 10
            AND a.user_age <= 19 THEN '10대'
            WHEN a.user_age >= 20
            AND a.user_age <= 29 THEN '20대'
            WHEN a.user_age >= 30
            AND a.user_age <= 39 THEN '30대'
            WHEN a.user_age >= 40
            AND a.user_age <= 49 THEN '40대'
            WHEN a.user_age >= 50
            AND a.user_age <= 59 THEN '50대'
            WHEN a.user_age >= 60
            AND a.user_age <= 69 THEN '60대'
            WHEN a.user_age >= 70
            AND a.user_age <= 99 THEN '70대 이상'
            ELSE '정보없음'
        END AS age_generation,
        CASE
            WHEN a.user_type = 'anonymous' THEN '미가입 사용자'
            ELSE '가입 사용자'
        END acc_type,
        -- 방문 당일: 방문(익명계정 생성) 당일, 그 외: 재방문
        CASE
            WHEN a.event_date = a.user_created_at THEN '방문 당일'
            ELSE '재방문'
        END pay_type,
        -- 방문일 대비 액션일 차이
        DATE_DIFF (a.event_date, a.user_created_at, DAY) AS event_date_diff,
        -- 사용자 액션 퍼널 태깅
        d.from_home_banner AS funnel_from_home_banner,
        e.from_home_section AS funnel_from_home_section,
        f.from_home_category AS funnel_from_home_category,
        g.from_search_result AS funnel_from_search_result,
        -- 액션 수행일 요일
        UPPER(FORMAT_DATE("%a", a.event_date)) AS event_weekday,
        -- RFM 정보 추가
        i.last_pay_date AS rfm_last_pay_date,
        i.last_engage_date AS rfm_last_engage_date,
        i.R_pay AS rfm_R_pay,
        i.F_pay AS rfm_F_pay,
        i.F_pay_freq AS rfm_F_pay_freq,
        i.M AS rfm_M,
        i.R_engage AS rfm_R_engage,
        i.F_engage AS rfm_F_engage,
        i.F_engage_freq AS rfm_F_engage_freq,
        i.R_pay_score AS rfm_R_pay_score,
        i.F_pay_score AS rfm_F_pay_score,
        i.M_score AS rfm_M_score,
        i.R_engage_score AS rfm_R_engage_score,
        i.F_engage_score AS rfm_F_engage_score,
        i.payment_rfm_score AS rfm_payment_rfm_score,
        i.engagement_rf_score AS rfm_engagement_rf_score,
        i.payment_segment AS rfm_payment_segment,
    FROM
        union_use_skill_with_skill_info a
        LEFT JOIN user_properties b ON a.user_id = b.user_id
        -- LEFT JOIN chatbot_info c ON a.chatbot_seq = c.chatbot_seq
        LEFT JOIN skill_meta_info h ON a.menu_seq = h.menu_seq
        LEFT JOIN distinct_touch_featured_banner d ON a.event_date = d.event_date
        AND a.user_id = d.user_id
        AND a.menu_seq = d.menu_seq
        AND a.event_name LIKE '%pay_for_%'
        LEFT JOIN distinct_touch_home_section_item e ON a.event_date = e.event_date
        AND a.user_id = e.user_id
        AND a.menu_seq = e.menu_seq
        AND a.event_name LIKE '%pay_for_%'
        LEFT JOIN distinct_touch_skill_item_in_category f ON a.event_date = f.event_date
        AND a.user_id = f.user_id
        AND a.menu_seq = f.menu_seq
        AND a.event_name LIKE '%pay_for_%'
        LEFT JOIN distinct_touch_search_result g ON a.event_date = g.event_date
        AND a.user_id = g.user_id
        AND a.menu_seq = g.menu_seq
        AND a.event_name LIKE '%pay_for_%'
        -- RFM 정보 조인 (어제자 데이터)
        LEFT JOIN (
            SELECT *
            FROM `hellobot-f445c.hlb_mart_adhoc.adhoc_mart_user_rfm_info_daily`
            WHERE event_date = CURRENT_DATE() - 1
        ) i ON a.user_id = i.user_id
        LEFT JOIN skill_stats_info j ON a.menu_seq = j.menu_seq
