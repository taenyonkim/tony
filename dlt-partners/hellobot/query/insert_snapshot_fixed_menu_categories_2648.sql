-- PostgreSQL
-- Transaction to delete specific menu_category_seq records and insert new data
BEGIN;

-- Delete existing records with menu_category_seq 2648
DELETE FROM snapshot_fixed_menu_categories_fixed_menu_category
WHERE menu_category_seq = 2648;

-- Insert new data for menu_category_seq 2648
INSERT INTO snapshot_fixed_menu_categories_fixed_menu_category
(menu_category_seq, turn, fixed_menu_seq)
VALUES
    (2648, 1, 55723),
    (2648, 2, 56416),
    (2648, 3, 48332),
    (2648, 4, 49255),
    (2648, 5, 31435),
    (2648, 6, 51565),
    (2648, 7, 54668),
    (2648, 8, 52621),
    (2648, 9, 42952),
    (2648, 10, 43117),
    (2648, 11, 21799),
    (2648, 12, 48463),
    (2648, 13, 2505),
    (2648, 14, 43683),
    (2648, 15, 44108),
    (2648, 16, 51499),
    (2648, 17, 16426),
    (2648, 18, 23878),
    (2648, 19, 50542),
    (2648, 20, 19192),
    (2648, 21, 21964),
    (2648, 22, 39852),
    (2648, 23, 49917),
    (2648, 24, 49920),
    (2648, 25, 49919),
    (2648, 26, 49916),
    (2648, 27, 41170),
    (2648, 28, 26502),
    (2648, 29, 24572),
    (2648, 30, 25204),
    (2648, 31, 52891),
    (2648, 32, 22360),
    (2648, 33, 34575),
    (2648, 34, 30875),
    (2648, 35, 24008),
    (2648, 36, 26500),
    (2648, 37, 2328),
    (2648, 38, 44371),
    (2648, 39, 18962),
    (2648, 40, 18105),
    (2648, 41, 44866),
    (2648, 42, 24509),
    (2648, 43, 36224),
    (2648, 44, 24870),
    (2648, 45, 27178),
    (2648, 46, 24175),
    (2648, 47, 25651),
    (2648, 48, 20347),
    (2648, 49, 36508),
    (2648, 50, 29757),
    (2648, 51, 39421),
    (2648, 52, 29193),
    (2648, 53, 2418),
    (2648, 54, 47968),
    (2648, 55, 35826),
    (2648, 56, 22162),
    (2648, 57, 18705),
    (2648, 58, 18970);

-- Verify the insertion (optional)
-- SELECT COUNT(*) AS total_inserted
-- FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2648;

-- Check the inserted data (optional)
-- SELECT * FROM snapshot_fixed_menu_categories_fixed_menu_category
-- WHERE menu_category_seq = 2648
-- ORDER BY turn;

COMMIT;