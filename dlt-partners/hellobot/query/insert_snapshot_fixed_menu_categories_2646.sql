-- PostgreSQL
-- Transaction to delete specific menu_category_seq records and insert new data
BEGIN;

-- Delete existing records with menu_category_seq 2646
DELETE FROM snapshot_fixed_menu_categories_fixed_menu_category
WHERE menu_category_seq = 2646;

-- Insert new data for menu_category_seq 2646
INSERT INTO snapshot_fixed_menu_categories_fixed_menu_category
(menu_category_seq, turn, fixed_menu_seq)
VALUES
    (2646, 1, 54668),
    (2646, 2, 52621),
    (2646, 3, 2166),
    (2646, 4, 43117),
    (2646, 5, 50312),
    (2646, 6, 48892),
    (2646, 7, 56254),
    (2646, 8, 26805),
    (2646, 9, 25297),
    (2646, 10, 27376),
    (2646, 11, 26502),
    (2646, 12, 2141),
    (2646, 13, 45658),
    (2646, 14, 34075),
    (2646, 15, 21734),
    (2646, 16, 42660),
    (2646, 17, 26374),
    (2646, 18, 16426),
    (2646, 19, 49882),
    (2646, 20, 36042),
    (2646, 21, 35527),
    (2646, 22, 45625),
    (2646, 23, 47407),
    (2646, 24, 21766),
    (2646, 25, 33654),
    (2646, 26, 2326),
    (2646, 27, 34952),
    (2646, 28, 25651),
    (2646, 29, 38993),
    (2646, 30, 17212),
    (2646, 31, 19010),
    (2646, 32, 29192),
    (2646, 33, 41171),
    (2646, 34, 40180),
    (2646, 35, 22792),
    (2646, 36, 24176),
    (2646, 37, 2418),
    (2646, 38, 1210),
    (2646, 39, 19206),
    (2646, 40, 53644),
    (2646, 41, 35220),
    (2646, 42, 16396);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2646;

-- Check the inserted data (optional)
-- SELECT * FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2646
-- ORDER BY turn;

COMMIT;