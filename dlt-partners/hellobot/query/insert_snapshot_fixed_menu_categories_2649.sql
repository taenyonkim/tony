-- PostgreSQL
-- Transaction to delete specific menu_category_seq records and insert new data
BEGIN;

-- Delete existing records with menu_category_seq 2649
DELETE FROM snapshot_fixed_menu_categories_fixed_menu_category
WHERE menu_category_seq = 2649;

-- Insert new data for menu_category_seq 2649
INSERT INTO snapshot_fixed_menu_categories_fixed_menu_category
(menu_category_seq, turn, fixed_menu_seq)
VALUES
    (2649, 1, 25978),
    (2649, 2, 56648),
    (2649, 3, 49816),
    (2649, 4, 28894),
    (2649, 5, 47935),
    (2649, 6, 47506),
    (2649, 7, 2141),
    (2649, 8, 45097),
    (2649, 9, 37705),
    (2649, 10, 55492),
    (2649, 11, 39091),
    (2649, 12, 18270),
    (2649, 13, 400),
    (2649, 14, 40708),
    (2649, 15, 16377),
    (2649, 16, 42754),
    (2649, 17, 19002),
    (2649, 18, 2142),
    (2649, 19, 2236),
    (2649, 20, 24779),
    (2649, 21, 23705),
    (2649, 22, 19218),
    (2649, 23, 18104),
    (2649, 24, 38332),
    (2649, 25, 37872),
    (2649, 26, 2366),
    (2649, 27, 18637),
    (2649, 28, 2170),
    (2649, 29, 2217),
    (2649, 30, 2196),
    (2649, 31, 2151);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2649;

-- Check the inserted data (optional)
-- SELECT * FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2649
-- ORDER BY turn;

COMMIT;