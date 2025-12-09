-- Transaction to delete specific tag_seq records and insert new data
BEGIN;

-- Delete all existing records with tag_seq 3002155
DELETE FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
WHERE tag_seq = 3002155;

-- Insert new data for tag_seq 3002155
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",           -- order: 표시 순서
    fixed_menu_seq,    -- fixed_menu_seq: 고정 메뉴 시퀀스 번호
    tag_seq,           -- tag_seq: 태그 시퀀스 번호
    priority           -- priority: 우선순위
) VALUES
    (1, 23878, 3002155, 1),
    (2, 43117, 3002155, 1),
    (3, 24572, 3002155, 1),
    (4, 34575, 3002155, 1),
    (5, 24509, 3002155, 1),
    (6, 47704, 3002155, 1),
    (7, 42952, 3002155, 1),
    (8, 26500, 3002155, 1),
    (9, 27706, 3002155, 1),
    (10, 49255, 3002155, 1),
    (11, 22327, 3002155, 1),
    (12, 21964, 3002155, 1),
    (13, 48332, 3002155, 1),
    (14, 27376, 3002155, 1),
    (15, 19192, 3002155, 1),
    (16, 21799, 3002155, 1),
    (17, 31435, 3002155, 1),
    (18, 48892, 3002155, 1),
    (19, 54503, 3002155, 1),
    (20, 52621, 3002155, 1),
    (21, 54668, 3002155, 1),
    (22, 20347, 3002155, 1),
    (23, 55723, 3002155, 1),
    (24, 22360, 3002155, 1),
    (25, 48463, 3002155, 1),
    (26, 30875, 3002155, 1),
    (27, 41074, 3002155, 1),
    (28, 55789, 3002155, 1),
    (29, 23086, 3002155, 1),
    (30, 2328, 3002155, 1),
    (31, 18142, 3002155, 1),
    (32, 39852, 3002155, 1),
    (33, 56416, 3002155, 1),
    (34, 24008, 3002155, 1),
    (35, 27178, 3002155, 1),
    (36, 13663, 3002155, 1),
    (37, 18105, 3002155, 1),
    (38, 37441, 3002155, 1),
    (39, 19215, 3002155, 1),
    (40, 40749, 3002155, 1);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3002155;

-- Check the inserted data (optional)
-- SELECT * FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3002155
-- ORDER BY "order";

COMMIT;