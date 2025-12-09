-- PostgreSQL용 fixed_menu_fixed_menu_tags_fixed_menu_tag 테이블에 데이터 삽입
-- PostgreSQL에서는 "order"를 큰따옴표로 감싸서 예약어 충돌을 방지

-- 단일 행 삽입
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",
    fixed_menu_seq,
    tag_seq,
    priority
) VALUES (
    23,         -- order: 표시 순서
    56614,      -- fixed_menu_seq: 고정 메뉴 시퀀스 번호
    3006513,    -- tag_seq: 태그 시퀀스 번호
    1           -- priority: 우선순위
);

-- 여러 행 한번에 삽입
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",
    fixed_menu_seq,
    tag_seq,
    priority
) VALUES
    (23, 56614, 3006513, 1),
    (24, 56614, 3006514, 2),
    (25, 56615, 3006515, 1),
    (26, 56615, 3006516, 2);

-- RETURNING 절을 사용하여 삽입된 데이터 확인 (PostgreSQL 특징)
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",
    fixed_menu_seq,
    tag_seq,
    priority
) VALUES (
    27,
    56616,
    3006517,
    1
)
RETURNING *;

-- ON CONFLICT를 사용한 UPSERT (PostgreSQL 9.5+)
-- fixed_menu_seq와 tag_seq 조합이 유니크 제약조건이 있다고 가정
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",
    fixed_menu_seq,
    tag_seq,
    priority
) VALUES (
    28,
    56617,
    3006518,
    1
)
ON CONFLICT (fixed_menu_seq, tag_seq)
DO UPDATE SET
    "order" = EXCLUDED."order",
    priority = EXCLUDED.priority;

-- 조건부 삽입 (중복 방지)
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",
    fixed_menu_seq,
    tag_seq,
    priority
)
SELECT
    29,
    56618,
    3006519,
    1
WHERE NOT EXISTS (
    SELECT 1
    FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
    WHERE fixed_menu_seq = 56618
      AND tag_seq = 3006519
);

-- CTE를 사용한 복잡한 삽입 (PostgreSQL 특징)
WITH new_tags AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY tag_seq) + 29 AS "order",
        56619 AS fixed_menu_seq,
        tag_seq,
        1 AS priority
    FROM (
        VALUES
            (3006520),
            (3006521),
            (3006522)
    ) AS t(tag_seq)
)
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",
    fixed_menu_seq,
    tag_seq,
    priority
)
SELECT * FROM new_tags;

-- 트랜잭션 내에서 안전하게 삽입
BEGIN;
    INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
        "order",
        fixed_menu_seq,
        tag_seq,
        priority
    ) VALUES (
        33,
        56620,
        3006523,
        1
    );

    -- 삽입 확인
    -- SELECT * FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
    -- WHERE fixed_menu_seq = 56620 AND tag_seq = 3006523;
COMMIT;