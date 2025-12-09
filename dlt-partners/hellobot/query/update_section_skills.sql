with fixed_menu_with_tags as (
    select
        ttst.turn AS turn,
        fmt.seq, -- fixed_menu_tag.seq
        fmt.name,
        fmt.expose,
        fmt.is_opt_in,
        ttst.seq AS admin_tag_seq -- today_tag_skills_tag.seq
    from fixed_menu_tag fmt
        left join today_tag_skills_tag ttst on ttst.tag = fmt.name
    where ttst.country_code = 'KR' -- 국내 콘텐츠 노출
        and ttst.language_code = 'ko'
        and ttst."section" = 'recommend'
    order by ttst.turn
)
select
from fixed_menu_fixed_menu_tags_fixed_menu_tag fftft
left join fixed_menu_with_tags tags on tags.seq = fftft.tag_seq
where  tags.admin_tag_seq = 364
order by fftft.priority



select
    ttst.turn AS turn,
    fmt.seq, -- fixed_menu_tag.seq
    fmt.name,
    fmt.expose,
    fmt.is_opt_in,
    ttst.seq AS admin_tag_seq -- today_tag_skills_tag.seq
from fixed_menu_tag fmt
    left join today_tag_skills_tag ttst on ttst.tag = fmt.name
where ttst.country_code = 'KR' -- 국내 콘텐츠 노출
	and ttst.language_code = 'ko'
	and ttst."section" = 'recommend'
order by ttst.turn