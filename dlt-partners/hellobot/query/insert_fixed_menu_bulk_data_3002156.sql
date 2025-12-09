-- Transaction to delete specific tag_seq records and insert new data
BEGIN;

-- Delete all existing records with tag_seq 3002156
DELETE FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
WHERE tag_seq = 3002156;

-- Insert new data for tag_seq 3002156
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",           -- order: 표시 순서
    fixed_menu_seq,    -- fixed_menu_seq: 고정 메뉴 시퀀스 번호
    tag_seq,           -- tag_seq: 태그 시퀀스 번호
    priority           -- priority: 우선순위
) VALUES
    (1, 49816, 3002156, 1),
    (2, 47935, 3002156, 1),
    (3, 28894, 3002156, 1),
    (4, 45097, 3002156, 1),
    (5, 47506, 3002156, 1),
    (6, 25978, 3002156, 1),
    (7, 2141, 3002156, 1),
    (8, 37705, 3002156, 1),
    (9, 39091, 3002156, 1),
    (10, 18270, 3002156, 1),
    (11, 400, 3002156, 1),
    (12, 40708, 3002156, 1),
    (13, 16377, 3002156, 1),
    (14, 42754, 3002156, 1),
    (15, 19002, 3002156, 1),
    (16, 2142, 3002156, 1),
    (17, 2236, 3002156, 1),
    (18, 55492, 3002156, 1),
    (19, 56648, 3002156, 1),
    (20, 23705, 3002156, 1),
    (21, 24779, 3002156, 1),
    (22, 18104, 3002156, 1),
    (23, 29423, 3002156, 1),
    (24, 28378, 3002156, 1),
    (25, 28380, 3002156, 1),
    (26, 2217, 3002156, 1),
    (27, 2170, 3002156, 1),
    (28, 18637, 3002156, 1),
    (29, 28379, 3002156, 1),
    (30, 2196, 3002156, 1),
    (31, 19218, 3002156, 1),
    (32, 2151, 3002156, 1),
    (33, 28381, 3002156, 1);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3002156;

-- Check the inserted data (optional)
-- SELECT * FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3002156
-- ORDER BY "order";

COMMIT;