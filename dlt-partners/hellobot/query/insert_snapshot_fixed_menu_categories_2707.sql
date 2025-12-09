-- PostgreSQL
-- Transaction to delete specific menu_category_seq records and insert new data
BEGIN;

-- Delete existing records with menu_category_seq 2707
DELETE FROM snapshot_fixed_menu_categories_fixed_menu_category
WHERE menu_category_seq = 2707;

-- Insert new data for menu_category_seq 2707
INSERT INTO snapshot_fixed_menu_categories_fixed_menu_category
(menu_category_seq, turn, fixed_menu_seq)
VALUES
    (2707, 1, 26214),
    (2707, 2, 18639),
    (2707, 3, 18467),
    (2707, 4, 49552),
    (2707, 5, 2141),
    (2707, 6, 21734),
    (2707, 7, 48925),
    (2707, 8, 18641),
    (2707, 9, 18646),
    (2707, 10, 18647),
    (2707, 11, 16379),
    (2707, 12, 23088),
    (2707, 13, 18709),
    (2707, 14, 22564),
    (2707, 15, 18648),
    (2707, 16, 2449),
    (2707, 17, 18532),
    (2707, 18, 24871),
    (2707, 19, 23186),
    (2707, 20, 19690),
    (2707, 21, 2429),
    (2707, 22, 53875),
    (2707, 23, 23883),
    (2707, 24, 54271),
    (2707, 25, 16450),
    (2707, 26, 19176),
    (2707, 27, 19687),
    (2707, 28, 30217),
    (2707, 29, 17443),
    (2707, 30, 2445),
    (2707, 31, 2381),
    (2707, 32, 18433),
    (2707, 33, 19206),
    (2707, 34, 19984);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2707;

-- Check the inserted data (optional)
-- SELECT * FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2707
-- ORDER BY turn;

COMMIT;