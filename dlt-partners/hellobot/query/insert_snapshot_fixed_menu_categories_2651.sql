-- PostgreSQL
-- Transaction to delete specific menu_category_seq records and insert new data
BEGIN;

-- Delete existing records with menu_category_seq 2651
DELETE FROM snapshot_fixed_menu_categories_fixed_menu_category
WHERE menu_category_seq = 2651;

-- Insert new data for menu_category_seq 2651
INSERT INTO snapshot_fixed_menu_categories_fixed_menu_category
(menu_category_seq, turn, fixed_menu_seq)
VALUES
    (2651, 1, 55195),
    (2651, 2, 47737),
    (2651, 3, 55360),
    (2651, 4, 56255),
    (2651, 5, 42062),
    (2651, 6, 28729),
    (2651, 7, 30282),
    (2651, 8, 41566),
    (2651, 9, 27326),
    (2651, 10, 40048),
    (2651, 11, 453),
    (2651, 12, 18933),
    (2651, 13, 31336),
    (2651, 14, 18570),
    (2651, 15, 25454),
    (2651, 16, 26182),
    (2651, 17, 25450),
    (2651, 18, 53710),
    (2651, 19, 22195),
    (2651, 20, 28003),
    (2651, 21, 22954),
    (2651, 22, 22690),
    (2651, 23, 18664),
    (2651, 24, 28813),
    (2651, 25, 38138),
    (2651, 26, 30379),
    (2651, 27, 34717),
    (2651, 28, 39553),
    (2651, 29, 16717),
    (2651, 30, 25403),
    (2651, 31, 39850),
    (2651, 32, 25839),
    (2651, 33, 2465),
    (2651, 34, 2428),
    (2651, 35, 18668);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2651;

-- Check the inserted data (optional)
-- SELECT * FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2651
-- ORDER BY turn;

COMMIT;