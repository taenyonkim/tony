-- PostgreSQL
-- Transaction to delete specific menu_category_seq records and insert new data
BEGIN;

-- Delete existing records with menu_category_seq 2650
DELETE FROM snapshot_fixed_menu_categories_fixed_menu_category
WHERE menu_category_seq = 2650;

-- Insert new data for menu_category_seq 2650
INSERT INTO snapshot_fixed_menu_categories_fixed_menu_category
(menu_category_seq, turn, fixed_menu_seq)
VALUES
    (2650, 1, 56515),
    (2650, 2, 56255),
    (2650, 3, 20974),
    (2650, 4, 55360),
    (2650, 5, 56516),
    (2650, 6, 47737),
    (2650, 7, 25454),
    (2650, 8, 41566),
    (2650, 9, 45526),
    (2650, 10, 22195),
    (2650, 11, 53974),
    (2650, 12, 23089),
    (2650, 13, 50774),
    (2650, 14, 43249),
    (2650, 15, 50773),
    (2650, 16, 44668),
    (2650, 17, 22525),
    (2650, 18, 18664),
    (2650, 19, 22164),
    (2650, 20, 38138),
    (2650, 21, 18400),
    (2650, 22, 26009),
    (2650, 23, 35626),
    (2650, 24, 24472),
    (2650, 25, 23885),
    (2650, 26, 39553),
    (2650, 27, 46483),
    (2650, 28, 25403),
    (2650, 29, 47638),
    (2650, 30, 26257),
    (2650, 31, 25133),
    (2650, 32, 25839),
    (2650, 33, 16443),
    (2650, 34, 26212),
    (2650, 35, 21667),
    (2650, 36, 2165),
    (2650, 37, 18635),
    (2650, 38, 18701),
    (2650, 39, 2223);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2650;

-- Check the inserted data (optional)
-- SELECT * FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2650
-- ORDER BY turn;

COMMIT;