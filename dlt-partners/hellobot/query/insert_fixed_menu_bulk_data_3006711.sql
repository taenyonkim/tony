-- Transaction to delete specific tag_seq records and insert new data
BEGIN;

-- Delete all existing records with tag_seq 3006711
DELETE FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
WHERE tag_seq = 3006711;

-- Insert new data for tag_seq 3006711
INSERT INTO fixed_menu_fixed_menu_tags_fixed_menu_tag (
    "order",           -- order: 표시 순서
    fixed_menu_seq,    -- fixed_menu_seq: 고정 메뉴 시퀀스 번호
    tag_seq,           -- tag_seq: 태그 시퀀스 번호
    priority           -- priority: 우선순위
) VALUES
    (1, 54668, 3006711, 1),
    (2, 55789, 3006711, 1),
    (3, 56254, 3006711, 1),
    (4, 55492, 3006711, 1),
    (5, 56648, 3006711, 1),
    (6, 55030, 3006711, 1),
    (7, 54503, 3006711, 1),
    (8, 56185, 3006711, 1),
    (9, 54007, 3006711, 1),
    (10, 49552, 3006711, 1);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3006711;

-- Check the inserted data (optional)
-- SELECT * FROM fixed_menu_fixed_menu_tags_fixed_menu_tag
-- WHERE tag_seq = 3006711
-- ORDER BY "order";

COMMIT;