-- Transaction to delete specific tag_seq records and insert new data
BEGIN;

-- Delete all existing records with tag_seq 3006545
DELETE FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
WHERE tag_seq = 3006545;

-- Insert new data for tag_seq 3006545
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",           -- order: 표시 순서
    fixed_menu_seq,    -- fixed_menu_seq: 고정 메뉴 시퀀스 번호
    tag_seq,           -- tag_seq: 태그 시퀀스 번호
    priority           -- priority: 우선순위
) VALUES
    (1, 48332, 3006545, 1),
    (2, 47506, 3006545, 1),
    (3, 44899, 3006545, 1),
    (4, 25978, 3006545, 1),
    (5, 56185, 3006545, 1),
    (6, 51301, 3006545, 1),
    (7, 31435, 3006545, 1),
    (8, 49882, 3006545, 1),
    (9, 26214, 3006545, 1),
    (10, 48463, 3006545, 1),
    (11, 39091, 3006545, 1),
    (12, 30940, 3006545, 1),
    (13, 21734, 3006545, 1),
    (14, 18270, 3006545, 1),
    (15, 41074, 3006545, 1),
    (16, 2505, 3006545, 1),
    (17, 16426, 3006545, 1),
    (18, 2141, 3006545, 1),
    (19, 23086, 3006545, 1),
    (20, 400, 3006545, 1),
    (21, 18142, 3006545, 1),
    (22, 40708, 3006545, 1),
    (23, 16377, 3006545, 1),
    (24, 46384, 3006545, 1),
    (25, 16378, 3006545, 1),
    (26, 42754, 3006545, 1),
    (27, 17212, 3006545, 1),
    (28, 19002, 3006545, 1),
    (29, 18639, 3006545, 1),
    (30, 48925, 3006545, 1);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3006545;

-- Check the inserted data (optional)
-- SELECT * FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3006545
-- ORDER BY "order";

COMMIT;