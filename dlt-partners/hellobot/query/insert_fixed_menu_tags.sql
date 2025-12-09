-- fixed_menu_fixed_menu_tags_fixed_menu_tag 테이블에 데이터 삽입
-- 테이블 컬럼: fixed_menu_name, id, order, fixed_menu_seq, tag_seq, priority

-- 단일 행 삽입 예제
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    fixed_menu_name,
    id,
    `order`,
    fixed_menu_seq,
    tag_seq,
    priority
) VALUES (
    '메뉴명',      -- fixed_menu_name: 고정 메뉴 이름
    1,            -- id: 레코드 고유 ID
    1,            -- order: 표시 순서
    101,          -- fixed_menu_seq: 고정 메뉴 시퀀스 번호
    201,          -- tag_seq: 태그 시퀀스 번호
    1             -- priority: 우선순위
);

-- 여러 행 한번에 삽입 예제
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    fixed_menu_name,
    id,
    `order`,
    fixed_menu_seq,
    tag_seq,
    priority
) VALUES
    ('인기 메뉴', 1, 1, 101, 201, 1),
    ('인기 메뉴', 2, 2, 101, 202, 2),
    ('추천 메뉴', 3, 1, 102, 203, 1),
    ('추천 메뉴', 4, 2, 102, 204, 2),
    ('신규 메뉴', 5, 1, 103, 205, 1);

-- 조건부 삽입 (중복 방지)
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    fixed_menu_name,
    id,
    `order`,
    fixed_menu_seq,
    tag_seq,
    priority
)
SELECT
    '특별 메뉴',
    6,
    1,
    104,
    206,
    1
WHERE NOT EXISTS (
    SELECT 1
    FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
    WHERE id = 6
       OR (fixed_menu_seq = 104 AND tag_seq = 206)
);

-- INSERT ... ON DUPLICATE KEY UPDATE 예제 (ID가 기본키인 경우)
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    fixed_menu_name,
    id,
    `order`,
    fixed_menu_seq,
    tag_seq,
    priority
) VALUES (
    '업데이트 메뉴',
    7,
    1,
    105,
    207,
    1
)
ON DUPLICATE KEY UPDATE
    fixed_menu_name = VALUES(fixed_menu_name),
    `order` = VALUES(`order`),
    priority = VALUES(priority);

-- 다른 테이블에서 데이터 가져와서 삽입하는 예제
/*
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    fixed_menu_name,
    id,
    `order`,
    fixed_menu_seq,
    tag_seq,
    priority
)
SELECT
    fm.menu_name,
    ROW_NUMBER() OVER (ORDER BY fm.seq, t.seq),
    ROW_NUMBER() OVER (PARTITION BY fm.seq ORDER BY t.seq),
    fm.seq,
    t.seq,
    1
FROM fixed_menu fm
CROSS JOIN tags t
WHERE fm.is_active = 1
  AND t.is_active = 1;
*/