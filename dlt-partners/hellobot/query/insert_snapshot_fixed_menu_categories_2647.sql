-- PostgreSQL
-- Transaction to delete specific menu_category_seq records and insert new data
BEGIN;

-- Delete existing records with menu_category_seq 2647
DELETE FROM snapshot_fixed_menu_categories_fixed_menu_category
WHERE menu_category_seq = 2647;

-- Insert new data for menu_category_seq 2647
INSERT INTO snapshot_fixed_menu_categories_fixed_menu_category
(menu_category_seq, turn, fixed_menu_seq)
VALUES
    (2647, 1, 47704),
    (2647, 2, 54668),
    (2647, 3, 52621),
    (2647, 4, 19192),
    (2647, 5, 42952),
    (2647, 6, 43117),
    (2647, 7, 50312),
    (2647, 8, 21799),
    (2647, 9, 48892),
    (2647, 10, 50542),
    (2647, 11, 48463),
    (2647, 12, 26502),
    (2647, 13, 2141),
    (2647, 14, 22360),
    (2647, 15, 34575),
    (2647, 16, 30875),
    (2647, 17, 24008),
    (2647, 18, 45625),
    (2647, 19, 47407),
    (2647, 20, 54503),
    (2647, 21, 33654),
    (2647, 22, 27178),
    (2647, 23, 24175),
    (2647, 24, 34952),
    (2647, 25, 55426),
    (2647, 26, 56581),
    (2647, 27, 25651),
    (2647, 28, 37441),
    (2647, 29, 20347),
    (2647, 30, 36508),
    (2647, 31, 39421),
    (2647, 32, 29193),
    (2647, 33, 2418),
    (2647, 34, 53644),
    (2647, 35, 40749),
    (2647, 36, 18705);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2647;

-- Check the inserted data (optional)
-- SELECT * FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2647
-- ORDER BY turn;

COMMIT;