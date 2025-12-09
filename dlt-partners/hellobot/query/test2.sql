with main_category as (
    select sfmc.*
    from snapshot_fixed_menu_category sfmc
    where sfmc.parent_category_seq is null
        and is_open = true
        and sfmc.country_code = 'KR'
        and sfmc.language_code = 'ko'
    order by parent_category_seq, turn
)
select
      mc.seq as main_category_seq,
      mc.title as main_category_title,
      mc.turn as main_category_turn,
      sfmc.seq as sub_category_seq,
      sfmc.title as sub_category_title,
      sfmc.turn as sub_category_turn
from snapshot_fixed_menu_category sfmc
left join main_category mc on mc.seq = sfmc.parent_category_seq
order by mc.turn, sfmc.turn