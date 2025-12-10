import pandas as pd
import sys
import os

# 2. Scenario-Based Intent Analysis Logic
def analyze_user_persona(title):
    title = str(title).strip()
    
    # --- Step 1: 소거법(Elimination Method) 적용 ---
    # 프롬프트 명세에 따라 기본값은 ["LOVE_SINGLE", "LOVE_COUPLE"]에서 시작
    scope = set(["LOVE_SINGLE", "LOVE_COUPLE"])

    # Scenario A: "Strict Single" (커플 제외)
    # Keywords imply absence of a current partner or desire to return to a past one.
    is_strict_single = any(k in title for k in [
        "재회", "전 연인", "전 남친", "전 여친", "전연인", "헤어진", "다시 만날", "연락", # Past
        "미련",  # 프롬프트에 있지만 코드에 누락됨 - 추가
        "솔로", "탈출", "새로운 사랑", "새로운", "나타날", "생길까", "안생겨요", "고백", "소개팅", # Absence
        "짝사랑", "썸"  # 프롬프트에 있지만 코드에 누락됨 - 추가
    ])

    # Scenario B: "Strict Couple" (싱글 제외)
    # Keywords imply the existence of a partner and relationship-specific contexts.
    is_strict_couple = any(k in title for k in [
        "부부", "남편", "아내",  # 남편, 아내 추가 (프롬프트에 있지만 코드에 누락됨)
        "이혼", "임신", "자녀", "출산", "권태기", "바람기", "외도", "불륜",
        "잠자리", "가정", "시댁", "처가"
    ])

    # Scenario C: "Dual Target" (아무것도 제외하지 않음)
    # 명시적으로 Dual Target 키워드 체크 (프롬프트 명세에 따라)
    is_dual_target = any(k in title for k in [
        "결혼 시기", "미래 배우자", "궁합", "속마음", "도화살", "연애운", "운명의 상대"
    ])

    # --- Step 2: 소거법에 따라 Scope 결정 ---
    # 기본값에서 시작해서 조건에 따라 제거
    # Strict 키워드가 있으면 Dual Target보다 우선 (더 명확한 맥락)
    if is_strict_single:
        scope.remove("LOVE_COUPLE")  # 커플 제외
    elif is_strict_couple:
        scope.remove("LOVE_SINGLE")  # 싱글 제외
    # else: Dual Target이거나 특별한 제외 조건이 없으면 둘 다 유지

    # --- Step 3: 비연애 콘텐츠 체크 (재물, 직업, 신년운세) ---
    # 프롬프트 명세: 연애와 무관한 콘텐츠는 ["ALL"]로 설정
    is_non_love_content = (
        not any(k in title for k in ["연애", "사랑", "결혼", "궁합", "속마음", "재회", "솔로", "짝사랑", "부부", "이혼"]) and
        any(k in title for k in ["재물", "금전", "돈", "부자", "로또", "직업", "취업", "사업", "신년", "토정비결", "202", "대운", "총운", "퇴사", "이직"
            # 예외케이스 처리용
            "사주팔자", "내 인생 언제", "내 운이 트이는", "일생 풀이", "인생 역전", "인생역전", "팔자가 바뀌는", "인생 피는"])
    )

    if is_non_love_content:
        scope = set(["ALL"])

    # --- Step 4: Determine Tags (Interest) based on Intent ---
    tags = set()
    
    # [FAMILY]
    if any(k in title for k in ["임신", "자녀", "아기", "출산", "가족", "내 아이"]): tags.add("FAMILY")
    
    # [WEALTH / CAREER / NEW_YEAR]
    if any(k in title for k in ["재물", "금전", "돈", "부자", "로또", "대박", "적금", "잔고", "통장", "재산"]): tags.add("WEALTH")
    if any(k in title for k in ["직업", "취업", "합격", "승진", "사업", "이직", "사장", "커리어", "퇴사", "직장", "동료", "시험", "면접", "회사", "재수", "수능"]): tags.add("CAREER")
    if any(k in title for k in ["신년", "202", "토정비결", "년 운세", "새해", "하반기", 
        "20년", "21년", "22년", "23년", "24년", "25년", "26년", "27년", "28년", "29년", "30년"]): tags.add("NEW_YEAR")

    # [LOVE SPECIFIC]

    # LOVE_REUNION (재회 관련)
    # 프롬프트 명세에는 스코프 제한이 없음
    if any(k in title for k in ["재회", "미련", "전 연인", "헤어진", "연락", "다시 만날", "돌아", "이별", "전연인"]):
        tags.add("LOVE_REUNION")

# LOVE_CRISIS (위기 관련)
    # 프롬프트 명세에는 스코프 제한이 없음
    if any(k in title for k in ["권태기", "이별수", "갈등", "바람", "위기", "이혼", "불안", 
        # 예외케이스 처리용
        "헤어져도 될까"]):
        tags.add("LOVE_CRISIS")
        
    # LOVE_MARRIAGE (결혼 관련)
    if any(k in title for k in ["결혼", "배우자", "혼인", "웨딩", "남편", "아내", "시집", "장가"]):
        tags.add("LOVE_MARRIAGE")
        # 추가 맥락 기반 태그 (코드의 추가 정교화 로직 유지)
        # "내 결혼 상대"처럼 찾는 의도가 있으면 LOVE_NEW도 추가
        if any(k in title for k in ["언제", "누구", "미래", "내 ", "나의 "]) and "결혼" in title:
            if "LOVE_SINGLE" in scope:  # 싱글이 찾는 경우에만
                tags.add("LOVE_NEW")
        if "궁합" in title or "잘" in title:
            tags.add("LOVE_MATCH")

    # LOVE_NEW (새로운 만남/솔로)
    # 프롬프트 명세: (싱글 Scope일 때) 키워드: 솔로, 새로운 만남, 도화, 짝사랑, 썸, 누구일까
    # 싱글 스코프에만 해당하는 태그로 명시됨
    if "LOVE_SINGLE" in scope and any(k in title for k in [
        "솔로", "새로운 만남", "새로운", "도화", "짝사랑", "썸", "누구일까", "누굴까", "누구",
        "나타날", "탈출", "언제", "생길까", "고백", "사귈 수 있을까", "유혹할"
        # 예외케이스 처리용
        "다가올 인연", "지금 날 간절히 원하는", "천년배필", "언제 만날까", "놓치면 안 될 결혼 상대", "만나게 될", "우리 사이", "미래의 연인", "소개팅"
    ]):
        tags.add("LOVE_NEW")
        
    # LOVE_MATCH (궁합/속마음)
    # 프롬프트 명세: 싱글/커플 모두 가능
    if any(k in title for k in ["궁합", "속마음", "진심", "좋아할까", "관계 점수", "관계", "애정", "케미", "사귈", "사귀", "시그널",
        "그 사람", "나 보고 싶을까", "전연인 어떻게", "우리 얼마나"]):
        tags.add("LOVE_MATCH")
        
    # LOVE_GENERAL (연애운 전반)
    # 프롬프트 명세: 연애운, 사랑운, 운명의 상대 (구체적 목적 없이 전반적인 운을 볼 때)
    if any(k in title for k in ["연애운", "사랑운", "운명의 상대", "연애", "사랑", "운명", "인연"]):
        # 다른 구체적인 Love 태그가 없을 때만 추가 (코드의 추가 로직 유지)
        if not (tags & {"LOVE_NEW", "LOVE_REUNION", "LOVE_MATCH", "LOVE_CRISIS", "LOVE_MARRIAGE"}):
            tags.add("LOVE_GENERAL")

    # OVERALL (종합운)
    # 프롬프트 명세: 총운, 인생, 사주팔자, 운명, 종합 보고서
    if any(k in title for k in ["총운", "인생", "사주팔자", "운세", "사주", "운명", "종합", "통합", "보고서"]):
        # 태그가 없거나 보고서/통합이 있을 때 추가 (코드의 추가 로직 유지)
        if not tags or "보고서" in title or "통합" in title or "사주팔자" in title or "종합" in title:
            tags.add("OVERALL")


    # --- Step 5: 최종 Scope 정리 ---
    # ALL 스코프인데 Love 태그가 있으면 LOVE_SINGLE + LOVE_COUPLE로 변경
    # (코드의 추가 안전장치 유지)
    is_love_tag = any(t.startswith("LOVE_") for t in tags) or "FAMILY" in tags
    if "ALL" in scope and is_love_tag:
        scope = set(["LOVE_SINGLE", "LOVE_COUPLE"])

    # 스코프가 비어있으면 기본값 설정 (안전장치)
    if not scope:
        # 연애 관련 태그가 있으면 둘 다, 아니면 ALL
        if is_love_tag:
            scope = set(["LOVE_SINGLE", "LOVE_COUPLE"])
        else:
            scope = set(["ALL"])

    # Scope 정렬 (LOVE_SINGLE을 먼저, 그 다음 LOVE_COUPLE, 나머지는 알파벳순)
    scope_order = {"LOVE_SINGLE": 1, "LOVE_COUPLE": 2, "ALL": 3}
    sorted_scope = sorted(list(scope), key=lambda x: scope_order.get(x, 99))

    return ", ".join(sorted_scope), ", ".join(sorted(list(tags)))

def process_file(input_filename, title_column='스킬', limit=None):
    """
    CSV 파일을 읽어서 태깅을 수행하고 _tagged.csv 파일로 저장

    Args:
        input_filename: 입력 CSV 파일명
        title_column: 분석할 제목이 있는 컬럼명 (기본값: '스킬')
        limit: 처리할 행 수 제한 (None이면 전체 처리)

    Returns:
        처리된 DataFrame
    """
    # CSV 파일 읽기
    try:
        df = pd.read_csv(input_filename, encoding='utf-8-sig')
    except UnicodeDecodeError:
        df = pd.read_csv(input_filename, encoding='utf-8')

    # 제한이 있으면 적용
    if limit:
        df = df.iloc[:limit].copy()
    else:
        df = df.copy()

    # 제목 컬럼이 없으면 에러
    if title_column not in df.columns:
        raise ValueError(f"'{title_column}' 컬럼을 찾을 수 없습니다. 사용 가능한 컬럼: {list(df.columns)}")

    # 태깅 수행
    print(f"태깅 시작... (총 {len(df)}개 항목)")
    df['Target Scope'], df['Target Tags'] = zip(*df[title_column].apply(analyze_user_persona))

    # 출력 파일명 생성 (_tagged.csv 추가)
    base_name = os.path.splitext(input_filename)[0]
    output_filename = f"{base_name}_tagged.csv"

    # 저장
    df.to_csv(output_filename, index=False, encoding='utf-8-sig')
    print(f"태깅 완료! 결과 저장: {output_filename}")

    return df

# 메인 실행 부분 - 직접 실행될 때만 수행
if __name__ == "__main__":
    # 명령줄 인자 확인
    if len(sys.argv) < 2:
        print("사용법: python tagging.py <input_file.csv> [title_column] [limit]")
        print("예시: python tagging.py data.csv")
        print("     python tagging.py data.csv '제목'")
        print("     python tagging.py data.csv '스킬' 1000")
        sys.exit(1)

    # 입력 파일명
    input_file = sys.argv[1]

    # 선택적 인자들
    title_col = sys.argv[2] if len(sys.argv) > 2 else '스킬'
    row_limit = int(sys.argv[3]) if len(sys.argv) > 3 else None

    # 파일 존재 확인
    if not os.path.exists(input_file):
        print(f"에러: '{input_file}' 파일을 찾을 수 없습니다.")
        sys.exit(1)

    try:
        # 파일 처리
        df_result = process_file(input_file, title_col, row_limit)

        # 샘플 결과 출력 (선택사항)
        print("\n=== 태깅 결과 샘플 (처음 5개) ===")
        pd.set_option('display.max_colwidth', None)
        sample = df_result[[title_col, 'Target Scope', 'Target Tags']].head(5)
        print(sample.to_string(index=False))

    except Exception as e:
        print(f"에러 발생: {e}")
        sys.exit(1)
