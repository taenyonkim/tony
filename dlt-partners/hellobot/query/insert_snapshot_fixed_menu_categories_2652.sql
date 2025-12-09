-- PostgreSQL
-- Transaction to delete specific menu_category_seq records and insert new data
BEGIN;

-- Delete existing records with menu_category_seq 2652
DELETE FROM snapshot_fixed_menu_categories_fixed_menu_category
WHERE menu_category_seq = 2652;

-- Insert new data for menu_category_seq 2652
INSERT INTO snapshot_fixed_menu_categories_fixed_menu_category
(menu_category_seq, turn, fixed_menu_seq)
VALUES
    (2652, 1, 26214),
    (2652, 2, 16378),
    (2652, 3, 18639),
    (2652, 4, 18467),
    (2652, 5, 49552),
    (2652, 6, 2141),
    (2652, 7, 48925),
    (2652, 8, 18641),
    (2652, 9, 18643),
    (2652, 10, 18646),
    (2652, 11, 21734),
    (2652, 12, 36439),
    (2652, 13, 18709),
    (2652, 14, 2429),
    (2652, 15, 18651),
    (2652, 16, 18648),
    (2652, 17, 2449),
    (2652, 18, 19060),
    (2652, 19, 24871),
    (2652, 20, 23186),
    (2652, 21, 19690),
    (2652, 22, 19177),
    (2652, 23, 2429),
    (2652, 24, 53875),
    (2652, 25, 54271),
    (2652, 26, 19176),
    (2652, 27, 19687),
    (2652, 28, 17443),
    (2652, 29, 6315),
    (2652, 30, 17413),
    (2652, 31, 2381),
    (2652, 32, 18433),
    (2652, 33, 25429);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2652;

-- Check the inserted data (optional)
-- SELECT * FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2652
-- ORDER BY turn;

COMMIT;