-- Transaction to delete specific tag_seq records and insert new data
BEGIN;

-- Delete all existing records with tag_seq 3006513
DELETE FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
WHERE tag_seq = 3006513;

-- Insert new data for tag_seq 3006513
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",           -- order: 표시 순서
    fixed_menu_seq,    -- fixed_menu_seq: 고정 메뉴 시퀀스 번호
    tag_seq,           -- tag_seq: 태그 시퀀스 번호
    priority           -- priority: 우선순위
) VALUES
    (1, 55360, 3006513, 1),
    (2, 55723, 3006513, 1),
    (3, 42952, 3006513, 1),
    (4, 26805, 3006513, 1),
    (5, 49816, 3006513, 1),
    (6, 56614, 3006513, 1),
    (7, 47704, 3006513, 1),
    (8, 49255, 3006513, 1),
    (9, 43117, 3006513, 1),
    (10, 21964, 3006513, 1),
    (11, 47935, 3006513, 1),
    (12, 28894, 3006513, 1),
    (13, 49519, 3006513, 1),
    (14, 48892, 3006513, 1),
    (15, 45097, 3006513, 1),
    (16, 25297, 3006513, 1),
    (17, 52621, 3006513, 1),
    (18, 55195, 3006513, 1),
    (19, 56255, 3006513, 1),
    (20, 2166, 3006513, 1),
    (21, 27376, 3006513, 1),
    (22, 21799, 3006513, 1),
    (23, 23878, 3006513, 1),
    (24, 19192, 3006513, 1),
    (25, 54668, 3006513, 1),
    (26, 24572, 3006513, 1),
    (27, 26502, 3006513, 1),
    (28, 45658, 3006513, 1),
    (29, 22360, 3006513, 1),
    (30, 53974, 3006513, 1),
    (31, 42660, 3006513, 1),
    (32, 37705, 3006513, 1),
    (33, 30875, 3006513, 1),
    (34, 34075, 3006513, 1),
    (35, 34575, 3006513, 1),
    (36, 55789, 3006513, 1),
    (37, 28729, 3006513, 1),
    (38, 23089, 3006513, 1),
    (39, 35527, 3006513, 1),
    (40, 18570, 3006513, 1);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3006513;

-- Check the inserted data (optional)
-- SELECT * FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3006513
-- ORDER BY "order";

COMMIT;