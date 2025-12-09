
WITH base_touch_home_section_item AS
(
  SELECT
        *, (CASE WHEN section_name LIKE '%추천스킬%' THEN '추천스킬' ELSE section_name END) AS section
  FROM `hellobot-f445c.hlb_mart.mart_v2_skill_funnel_fb`
  WHERE platform != 'WEB'
      AND event_name IN ('touch_home_section_item','touch_home_section_more_item')
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
       OR section_name LIKE '%내 운명 어떤 사람일까?%')
  	AND event_date >= CAST(PARSE_DATE('%Y%m%d', @DS_START_DATE) AS DATE) AND event_date <= CAST(PARSE_DATE('%Y%m%d', @DS_END_DATE) AS DATE)
),
base_pay_for_skill AS
(
  SELECT
        event_date,
        user_id,
        event_timestamp,
        CAST(menu_seq AS STRING) AS menu_seq,
        COALESCE(spent_heart_coin, 0) * @KRW_PER_HEART + COALESCE(spent_cash_amount, 0) AS amount_pay_for_skill_krw,
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY event_timestamp ASC) AS purchase_rnum
  FROM
      `hellobot-f445c.hlb_mart.mart_use_skill_se`
  WHERE event_name IN ('pay_for_contents', 'pay_for_coaching_program')
      AND platform != 'WEB'
  	AND event_date >= CAST(PARSE_DATE('%Y%m%d', @DS_START_DATE) AS DATE) AND event_date <= CAST(PARSE_DATE('%Y%m%d', @DS_END_DATE) AS DATE)
),
base_skill_funnel AS
(
  SELECT
        *
  FROM `hellobot-f445c.hlb_mart.mart_v2_skill_funnel_fb`
  WHERE event_name IN ('open_skill_description','enter_skill')
      AND platform != 'WEB'
  	AND event_date >= CAST(PARSE_DATE('%Y%m%d', @DS_START_DATE) AS DATE) AND event_date <= CAST(PARSE_DATE('%Y%m%d', @DS_END_DATE) AS DATE)
),

-- 하루 중 여러 섹션에서 동일한 스킬에 대한 클릭이 발생했을 경우? last_click의 섹션으로 선택해야 함.
touch_home_section_item AS
(
  SELECT
        event_date,
        user_id_processed,
        menu_seq,
        MAX(event_timestamp) AS last_click_time
  FROM base_touch_home_section_item
  GROUP BY
        event_date,
        user_id_processed,
        menu_seq
 -- event_date >= CAST(PARSE_DATE('%Y%m%d', @DS_START_DATE) AS DATE) AND event_date <= CAST(PARSE_DATE('%Y%m%d', @DS_END_DATE) AS DATE)
),
touch_home_section_item_lastclick AS
(
  SELECT
        DISTINCT
        a.event_date,
        a.user_id_processed,
        a.menu_seq,
        a.section,
  FROM base_touch_home_section_item AS a
  INNER JOIN touch_home_section_item AS b
  ON a.event_timestamp = b.last_click_time
  AND a.user_id_processed = b.user_id_processed
  AND a.menu_seq = b.menu_seq
),

enter_skill AS
(
  SELECT
        DISTINCT
        event_date,
        user_id_processed,
        menu_seq
  FROM base_skill_funnel
  WHERE event_name = 'enter_skill' -- event_date >= CAST(PARSE_DATE('%Y%m%d', @DS_START_DATE) AS DATE) AND event_date <= CAST(PARSE_DATE('%Y%m%d', @DS_END_DATE) AS DATE)
),

enter_skill_homesection AS
(
  SELECT
        a.section,
        COUNT(DISTINCT a.user_id_processed) AS num_enter_skill_homesection_users,
  FROM touch_home_section_item_lastclick AS a
  LEFT JOIN enter_skill AS b
  ON a.user_id_processed = b.user_id_processed
   AND a.event_date = b.event_date
   AND a.menu_seq = b.menu_seq
  WHERE b.user_id_processed IS NOT NULL
  GROUP BY a.section

),

# 하루에 동일한 스킬을 여러번 클릭도 하고, 여러번 구매할 수도 있다.
# 구매가 발생한 날에 클릭이 있으면 무조건 포함되도록 한다.
# 그 날에 그 스킬을 클릭한 액션을 유니크하게 만들어 놓은 테이블과 조인을 하면 중복없이 해결?
pay_for_skill_homesection AS
(
  SELECT
        b.section,
        COUNT(DISTINCT a.user_id) AS num_pay_for_contents_search_users,
        COUNT(*) AS num_pay_for_contents_search,
        SUM(a.amount_pay_for_skill_krw) AS total_amount_pay_for_skill_krw
  FROM base_pay_for_skill AS a
  LEFT JOIN touch_home_section_item_lastclick AS b
  ON a.user_id = b.user_id_processed
   AND a.event_date = b.event_date
   AND a.menu_seq = b.menu_seq
  WHERE b.user_id_processed IS NOT NULL
  GROUP BY b.section
),

active_users AS (
    SELECT
        'result' AS result,
        COUNT(DISTINCT user_id_processed) AS num_active_users
    FROM `hellobot-f445c.hlb_mart.mart_home_action_fb`
  	WHERE event_date >= CAST(PARSE_DATE('%Y%m%d', @DS_START_DATE) AS DATE) AND event_date <= CAST(PARSE_DATE('%Y%m%d', @DS_END_DATE) AS DATE) AND event_name = 'view_tab_at_home'
),

result_touch_home_section_item AS
(
  SELECT
        section,
        COUNT(user_id_processed) AS num_touch_home_section_item,
        COUNT(DISTINCT user_id_processed) AS num_touch_home_section_item_users,
  FROM base_touch_home_section_item
  GROUP BY section
 -- event_date >= CAST(PARSE_DATE('%Y%m%d', @DS_START_DATE) AS DATE) AND event_date <= CAST(PARSE_DATE('%Y%m%d', @DS_END_DATE) AS DATE)
)

SELECT
      a.*,
	b.num_enter_skill_homesection_users,
      c.num_touch_home_section_item_users,
      (SELECT num_active_users FROM active_users) AS num_active_users
FROM pay_for_skill_homesection AS a
LEFT JOIN enter_skill_homesection AS b
ON a.section = b.section
LEFT JOIN result_touch_home_section_item AS c
ON a.section = c.section





