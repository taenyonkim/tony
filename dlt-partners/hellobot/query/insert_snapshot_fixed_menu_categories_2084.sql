-- PostgreSQL
-- Transaction to delete specific menu_category_seq records and insert new data
BEGIN;

-- Delete existing records with menu_category_seq 2084
DELETE FROM snapshot_fixed_menu_categories_fixed_menu_category
WHERE menu_category_seq = 2084;

-- Insert new data for menu_category_seq 2084
INSERT INTO snapshot_fixed_menu_categories_fixed_menu_category
(menu_category_seq, turn, fixed_menu_seq)
VALUES
    (2084, 1, 55360),
    (2084, 2, 55723),
    (2084, 3, 55789),
    (2084, 4, 56614),
    (2084, 5, 56185),
    (2084, 6, 56255),
    (2084, 7, 55195),
    (2084, 8, 56383),
    (2084, 9, 56416),
    (2084, 10, 56516),
    (2084, 11, 56515),
    (2084, 12, 51565),
    (2084, 13, 50312),
    (2084, 14, 51499),
    (2084, 15, 50014),
    (2084, 16, 50773),
    (2084, 17, 50774),
    (2084, 18, 52852),
    (2084, 19, 41170),
    (2084, 20, 41171),
    (2084, 21, 41566),
    (2084, 22, 43447);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2084;

-- Check the inserted data (optional)
-- SELECT * FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2084
-- ORDER BY turn;

COMMIT;