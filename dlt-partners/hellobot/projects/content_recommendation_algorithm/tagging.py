import pandas as pd

# 1. Load Data
try:
    df = pd.read_csv("20261209_skill_tagging.csv")
    df_1000 = df.iloc[:1000].copy()
except:
    df_1000 = pd.DataFrame(columns=["스킬ID", "스킬"])

# 2. Scenario-Based Intent Analysis Logic
def analyze_user_persona(title):
    title = str(title).strip()
    
    # --- Step 1: Define User Intent Scenarios ---
    
    # Scenario A: "I am alone and want to change it" (Strict Single)
    # Keywords imply absence of a current partner or desire to return to a past one.
    is_strict_single = any(k in title for k in [
        "재회", "전 연인", "전 남친", "전 여친", "전연인", "헤어진", "다시 만날", "연락", # Past
        "솔로", "탈출", "새로운", "나타날", "생길까", "안생겨요", "고백", "소개팅" # Absence
    ])
    
    # Scenario B: "I am in a relationship and have specific issues" (Strict Couple)
    # Keywords imply the existence of a partner and relationship-specific contexts.
    is_strict_couple = any(k in title for k in [
        "부부", "이혼", "임신", "자녀", "출산", "권태기", "바람기", "외도", "불륜", 
        "우리", "속궁합", "잠자리", "가정", "시댁", "처가"
    ])
    
    # Scenario C: "Checking Destiny/Person" (Dual Target)
    # Marriage, Compatibility, Mind Reading, Charm - Valid for both.
    # Note: "짝사랑" is tricky. Usually Single, but technically "Checking". 
    # But usually 짝사랑 implies unrequited, so implies Single status mostly. Let's keep 짝사랑 in Single for safety, or Dual?
    # User feedback: "Marriage Partner" -> Dual.
    # "Saju/Tarot" -> Dual.
    
    # --- Step 2: Determine Scope (Status) ---
    scope = set()
    
    if is_strict_single:
        scope.add("LOVE_SINGLE")
        # Conflict check: If title has "Strict Couple" words (rare e.g., "Divorced Single"), priority to context.
        # But usually these don't overlap much.
    elif is_strict_couple:
        scope.add("LOVE_COUPLE")
    else:
        # Default for Marriage, Compatibility, Destiny, Luck, Career, Wealth -> Open to ALL or Both Love Statuses
        # If it is Love content, it's Both. If it's Wealth, it's All.
        scope.add("LOVE_SINGLE")
        scope.add("LOVE_COUPLE")
        
        # Check if non-love content (Wealth/Career only)
        # If strictly Wealth/Career/General without Love nuances, make it ALL (which includes Single/Couple implicitly in system, or explicit ALL)
        # But per system spec, ALL is for metadata. 
        # Let's keep it "LOVE_SINGLE, LOVE_COUPLE" for Love contents, and "ALL" for pure General.
        
    # --- Step 3: Determine Tags (Interest) based on Intent ---
    tags = set()
    
    # [FAMILY]
    if any(k in title for k in ["임신", "자녀", "아기", "출산", "가족"]): tags.add("FAMILY")
    
    # [WEALTH / CAREER / NEW_YEAR]
    if any(k in title for k in ["재물", "금전", "돈", "부자", "로또", "대박", "적금"]): tags.add("WEALTH")
    if any(k in title for k in ["직업", "취업", "합격", "승진", "사업", "이직", "사장"]): tags.add("CAREER")
    if any(k in title for k in ["신년", "202", "토정비결", "년 운세", "새해"]): tags.add("NEW_YEAR")

    # [LOVE SPECIFIC]
    
    # REUNION (Strict Single Context)
    if is_strict_single and any(k in title for k in ["재회", "전 ", "헤어진", "미련", "돌아", "이별", "연락"]):
        tags.add("LOVE_REUNION")
    
    # CRISIS (Strict Couple Context)
    if is_strict_couple and any(k in title for k in ["권태기", "갈등", "위기", "이별수", "바람", "이혼"]):
        tags.add("LOVE_CRISIS")
        
    # MARRIAGE (The specific feedback case)
    if any(k in title for k in ["결혼", "배우자", "혼인", "웨딩", "남편", "아내", "시집", "장가"]):
        tags.add("LOVE_MARRIAGE")
        # If I am single -> finding (NEW). If I am couple -> checking (MATCH).
        # Since we set scope to Both, we can add both tags or just MARRIAGE?
        # System spec allows multiple tags.
        # Let's add context tags if words are present.
        if "언제" in title or "누구" in title or "미래" in title: tags.add("LOVE_NEW")
        if "궁합" in title or "잘" in title: tags.add("LOVE_MATCH")

    # NEW (Finding/Destiny)
    # Applies to Singles (finding) AND Couples (checking if 'destiny' matches current)
    # But usually 'NEW' tag is for 'Solos'. 
    # Let's stick to system spec: LOVE_NEW = "Solos/Crush". 
    # If the title is "My future spouse", for a Couple, it's MARRIAGE/MATCH intent, not NEW intent.
    # So add LOVE_NEW only if Scope includes Single AND keyword implies 'New/Finding'.
    if "LOVE_SINGLE" in scope and any(k in title for k in ["솔로", "새로운", "도화", "짝사랑", "나타날", "탈출", "썸", "누구", "언제", "생길까", "고백"]):
        tags.add("LOVE_NEW")
        
    # MATCH (Compatibility/Mind)
    if any(k in title for k in ["궁합", "속마음", "진심", "좋아할까", "관계", "애정", "케미"]):
        tags.add("LOVE_MATCH")
        
    # GENERAL
    if "연애" in title or "사랑" in title or "운명" in title:
        # Add General if no specific Love tag yet
        if not (tags & {"LOVE_NEW", "LOVE_REUNION", "LOVE_MATCH", "LOVE_CRISIS", "LOVE_MARRIAGE"}):
            tags.add("LOVE_GENERAL")
            
    # OVERALL
    if not tags or any(k in title for k in ["총운", "운세", "사주", "통합", "인생", "보고서"]):
         # Refine: Don't add OVERALL if specific tags exist, unless it's a 'Report'
         if not tags or "보고서" in title or "통합" in title:
             tags.add("OVERALL")

    # --- Step 4: Final Scope Cleanup ---
    # If Scope is ALL (default from else), but tags are strictly Love -> Set to Single+Couple
    is_love_tag = any(t.startswith("LOVE_") for t in tags) or "FAMILY" in tags
    if "ALL" in scope and is_love_tag:
        scope.remove("ALL")
        scope.add("LOVE_SINGLE")
        scope.add("LOVE_COUPLE")
        
    if not scope: # Fallback
        scope.add("ALL")

    return ", ".join(sorted(list(scope))), ", ".join(sorted(list(tags)))

# Apply Logic
df_1000['Target Scope'], df_1000['Target Tags'] = zip(*df_1000['스킬'].apply(analyze_user_persona))

# Save
output_filename = "20261209_skill_tagging_persona_v1.csv"
df_1000.to_csv(output_filename, index=False, encoding='utf-8-sig')

# Verification display
check_list = ["사주로 보는 내 결혼 상대는?", "재회 사주", "2024년 솔로 탈출", "우리 부부", "그 사람의 속마음"]
# Retrieve rows that resemble these titles
pd.set_option('display.max_colwidth', None)
sample_rows = pd.DataFrame()
for k in ["결혼 상대", "재회", "솔로", "부부", "속마음", "연애 상대"]:
    sample_rows = pd.concat([sample_rows, df_1000[df_1000['스킬'].str.contains(k)].head(1)])
    
print(sample_rows[['스킬', 'Target Scope', 'Target Tags']].to_markdown(index=False))
