-- Transaction to delete specific tag_seq records and insert new data
BEGIN;

-- Delete all existing records with tag_seq 3002158
DELETE FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
WHERE tag_seq = 3002158;

-- Insert new data for tag_seq 3002158
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",           -- order: 표시 순서
    fixed_menu_seq,    -- fixed_menu_seq: 고정 메뉴 시퀀스 번호
    tag_seq,           -- tag_seq: 태그 시퀀스 번호
    priority           -- priority: 우선순위
) VALUES
    (1, 48892, 3002158, 1),
    (2, 52621, 3002158, 1),
    (3, 19192, 3002158, 1),
    (4, 54668, 3002158, 1),
    (5, 26502, 3002158, 1),
    (6, 45658, 3002158, 1),
    (7, 22360, 3002158, 1),
    (8, 34575, 3002158, 1),
    (9, 24008, 3002158, 1),
    (10, 45625, 3002158, 1),
    (11, 18705, 3002158, 1),
    (12, 39421, 3002158, 1),
    (13, 33654, 3002158, 1),
    (14, 36224, 3002158, 1),
    (15, 25651, 3002158, 1),
    (16, 523, 3002158, 1),
    (17, 2418, 3002158, 1),
    (18, 54503, 3002158, 1),
    (19, 40749, 3002158, 1),
    (20, 56086, 3002158, 1);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3002158;

-- Check the inserted data (optional)
-- SELECT * FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3002158
-- ORDER BY "order";

COMMIT;