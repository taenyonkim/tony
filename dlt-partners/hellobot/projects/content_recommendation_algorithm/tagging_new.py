import pandas as pd
import sys
import os

# 2. Scenario-Based Intent Analysis Logic
def analyze_user_persona(title):
    title = str(title).strip()

    # --- Step 1: 소거법(Elimination Method) 적용 ---
    # 기본값은 ["연애상태_싱글", "연애상태_커플"]에서 시작
    scope = set(["연애상태_싱글", "연애상태_커플"])

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
        scope.remove("연애상태_커플")  # 커플 제외
    elif is_strict_couple:
        scope.remove("연애상태_싱글")  # 싱글 제외
    # else: Dual Target이거나 특별한 제외 조건이 없으면 둘 다 유지

    # --- Step 3: 비연애 콘텐츠 체크 (재물, 직업, 신년운세) ---
    # 프롬프트 명세: 연애와 무관한 콘텐츠는 ["전체"]로 설정
    is_non_love_content = (
        not any(k in title for k in ["연애", "사랑", "결혼", "궁합", "속마음", "재회", "솔로", "짝사랑", "부부", "이혼"]) and
        any(k in title for k in ["재물", "금전", "돈", "부자", "로또", "직업", "취업", "사업", "신년", "토정비결", "202", "대운", "총운", "퇴사", "이직",
            # 예외케이스 처리용
            "사주팔자", "내 인생 언제", "내 운이 트이는", "일생 풀이", "인생 역전", "인생역전", "팔자가 바뀌는", "인생 피는"])
    )

    if is_non_love_content:
        scope = set(["전체"])

    # --- Step 4: Determine Tags (Interest) based on Intent ---
    tags = set()

    # [가족자녀운]
    if any(k in title for k in ["임신", "자녀", "아기", "출산", "가족", "내 아이"]):
        tags.add("가족자녀운")

    # [재물금전운 / 학업직업운 / 신년운세]
    if any(k in title for k in ["재물", "금전", "돈", "부자", "로또", "대박", "적금", "잔고", "통장", "재산"]):
        tags.add("재물금전운")
    if any(k in title for k in ["직업", "취업", "합격", "승진", "사업", "이직", "사장", "커리어", "퇴사", "직장", "동료", "시험", "면접", "회사", "재수", "수능"]):
        tags.add("학업직업운")
    if any(k in title for k in ["신년", "202", "토정비결", "년 운세", "새해", "하반기",
        "20년", "21년", "22년", "23년", "24년", "25년", "26년", "27년", "28년", "29년", "30년"]):
        tags.add("신년운세")

    # [연애 관련 태그들]

    # 연애_재회 (재회 관련)
    # 프롬프트 명세에는 스코프 제한이 없음
    if any(k in title for k in ["재회", "미련", "전 연인", "헤어진", "연락", "다시 만날", "돌아", "이별", "전연인"]):
        tags.add("연애_재회")

    # 연애_위기갈등 (위기 관련)
    # 프롬프트 명세에는 스코프 제한이 없음
    if any(k in title for k in ["권태기", "이별수", "갈등", "바람", "위기", "이혼", "불안",
        # 예외케이스 처리용
        "헤어져도 될까"]):
        tags.add("연애_위기갈등")

    # 연애_결혼 (결혼 관련)
    if any(k in title for k in ["결혼", "배우자", "혼인", "웨딩", "남편", "아내", "시집", "장가"]):
        tags.add("연애_결혼")
        # 추가 맥락 기반 태그 (코드의 추가 정교화 로직 유지)
        # "내 결혼 상대"처럼 찾는 의도가 있으면 연애_새로운만남도 추가
        if any(k in title for k in ["언제", "누구", "미래", "내 ", "나의 "]) and "결혼" in title:
            if "연애상태_싱글" in scope:  # 싱글이 찾는 경우에만
                tags.add("연애_새로운만남")
        if "궁합" in title or "잘" in title:
            tags.add("연애_궁합관계")

    # 연애_새로운만남 (새로운 만남/솔로)
    # 프롬프트 명세: (싱글 Scope일 때) 키워드: 솔로, 새로운 만남, 도화, 짝사랑, 썸, 누구일까
    # 싱글 스코프에만 해당하는 태그로 명시됨
    if "연애상태_싱글" in scope and any(k in title for k in [
        "솔로", "새로운 만남", "새로운", "도화", "짝사랑", "썸", "누구일까", "누굴까", "누구",
        "나타날", "탈출", "언제", "생길까", "고백", "사귈 수 있을까", "유혹할",
        # 예외케이스 처리용
        "다가올 인연", "지금 날 간절히 원하는", "천년배필", "언제 만날까", "놓치면 안 될 결혼 상대", "만나게 될", "우리 사이", "미래의 연인", "소개팅"
    ]):
        tags.add("연애_새로운만남")

    # 연애_속마음 (속마음/진심)
    # 프롬프트 명세: 속마음, 진심, 감정, 좋아할까, 나를 어떻게, 상대방 마음, 심리
    if any(k in title for k in ["속마음", "진심", "감정", "좋아할까", "나를 어떻게", "상대방 마음", "심리",
        "날 사랑", "날 좋아", "나 보고 싶을까", "마음", "느낌", "관심"]):
        tags.add("연애_속마음")

    # 연애_궁합관계 (궁합/관계)
    # 프롬프트 명세: 궁합, 애정도, 관계 점수, 케미, 상성, 관계 발전
    if any(k in title for k in ["궁합", "관계 점수", "관계", "애정", "케미", "사귈", "사귀", "시그널",
        "상성", "관계 발전", "우리 얼마나", "잘 맞", "그 사람"]):
        tags.add("연애_궁합관계")

    # 연애_일반 (연애운 전반)
    # 프롬프트 명세: 연애운, 사랑운, 운명의 상대 (구체적 목적 없이 전반적인 운을 볼 때)
    if any(k in title for k in ["연애운", "사랑운", "운명의 상대", "연애", "사랑", "운명", "인연"]):
        # 다른 구체적인 Love 태그가 없을 때만 추가 (코드의 추가 로직 유지)
        love_tags = {"연애_새로운만남", "연애_재회", "연애_속마음", "연애_궁합관계", "연애_위기갈등", "연애_결혼"}
        if not (tags & love_tags):
            tags.add("연애_일반")

    # 종합운 (종합운)
    # 프롬프트 명세: 총운, 인생, 사주팔자, 운명, 종합 보고서
    if any(k in title for k in ["총운", "인생", "사주팔자", "운세", "사주", "운명", "종합", "통합", "보고서"]):
        # 태그가 없거나 보고서/통합이 있을 때 추가 (코드의 추가 로직 유지)
        if not tags or "보고서" in title or "통합" in title or "사주팔자" in title or "종합" in title:
            tags.add("종합운")

    # --- Step 5: 최종 Scope 정리 ---
    # 전체 스코프인데 Love 태그가 있으면 연애상태_싱글 + 연애상태_커플로 변경
    # (코드의 추가 안전장치 유지)
    is_love_tag = any(t.startswith("연애_") for t in tags) or "가족자녀운" in tags
    if "전체" in scope and is_love_tag:
        scope = set(["연애상태_싱글", "연애상태_커플"])

    # 스코프가 비어있으면 기본값 설정 (안전장치)
    if not scope:
        # 연애 관련 태그가 있으면 둘 다, 아니면 전체
        if is_love_tag:
            scope = set(["연애상태_싱글", "연애상태_커플"])
        else:
            scope = set(["전체"])

    # Scope 정렬 (연애상태_싱글을 먼저, 그 다음 연애상태_커플, 나머지는 알파벳순)
    scope_order = {"연애상태_싱글": 1, "연애상태_커플": 2, "전체": 3}
    sorted_scope = sorted(list(scope), key=lambda x: scope_order.get(x, 99))

    return ", ".join(sorted_scope), ", ".join(sorted(list(tags)))

def process_file(input_filename, title_column='스킬', limit=None):
    """
    CSV 파일을 읽어서 태깅을 수행하고 _tagged_korean.csv 파일로 저장

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
    df['타겟_범위'], df['타겟_태그'] = zip(*df[title_column].apply(analyze_user_persona))

    # 출력 파일명 생성 (_tagged_korean.csv 추가)
    base_name = os.path.splitext(input_filename)[0]
    output_filename = f"{base_name}_tagged_korean.csv"

    # 저장
    df.to_csv(output_filename, index=False, encoding='utf-8-sig')
    print(f"태깅 완료! 결과 저장: {output_filename}")

    return df

def convert_english_to_korean(input_filename, output_filename=None):
    """
    기존 영문 태그 CSV를 한글 태그로 변환

    Args:
        input_filename: 영문 태그가 포함된 CSV 파일
        output_filename: 출력 파일명 (없으면 자동 생성)

    Returns:
        변환된 DataFrame
    """
    # 영문 -> 한글 매핑 테이블
    scope_mapping = {
        "LOVE_SINGLE": "연애상태_싱글",
        "LOVE_COUPLE": "연애상태_커플",
        "ALL": "전체"
    }

    tag_mapping = {
        "LOVE_NEW": "연애_새로운만남",
        "LOVE_REUNION": "연애_재회",
        "LOVE_MIND": "연애_속마음",
        "LOVE_MATCH": "연애_궁합관계",
        "LOVE_MARRIAGE": "연애_결혼",
        "LOVE_CRISIS": "연애_위기갈등",
        "LOVE_GENERAL": "연애_일반",
        "NEW_YEAR": "신년운세",
        "OVERALL": "종합운",
        "FAMILY": "가족자녀운",
        "WEALTH": "재물금전운",
        "CAREER": "학업직업운",
        "ELSE": "기타"
    }

    # CSV 파일 읽기
    try:
        df = pd.read_csv(input_filename, encoding='utf-8-sig')
    except UnicodeDecodeError:
        df = pd.read_csv(input_filename, encoding='utf-8')

    # 영문 컬럼이 있는지 확인
    if 'Target Scope' in df.columns and 'Target Tags' in df.columns:
        # Scope 변환
        def convert_scope(scope_str):
            if pd.isna(scope_str):
                return ""
            scopes = [s.strip() for s in str(scope_str).split(',')]
            converted = [scope_mapping.get(s, s) for s in scopes]
            return ", ".join(converted)

        # Tags 변환
        def convert_tags(tags_str):
            if pd.isna(tags_str):
                return ""
            tags = [t.strip() for t in str(tags_str).split(',')]
            converted = [tag_mapping.get(t, t) for t in tags]
            return ", ".join(converted)

        # 변환 수행
        df['타겟_범위'] = df['Target Scope'].apply(convert_scope)
        df['타겟_태그'] = df['Target Tags'].apply(convert_tags)

        # 기존 영문 컬럼 제거 (선택사항)
        # df = df.drop(['Target Scope', 'Target Tags'], axis=1)

        # 출력 파일명 생성
        if output_filename is None:
            base_name = os.path.splitext(input_filename)[0]
            output_filename = f"{base_name}_korean.csv"

        # 저장
        df.to_csv(output_filename, index=False, encoding='utf-8-sig')
        print(f"영문 -> 한글 변환 완료! 결과 저장: {output_filename}")

        return df
    else:
        print("영문 태그 컬럼을 찾을 수 없습니다.")
        return None

# 메인 실행 부분 - 직접 실행될 때만 수행
if __name__ == "__main__":
    # 명령줄 인자 확인
    if len(sys.argv) < 2:
        print("사용법:")
        print("  신규 태깅: python tagging_new.py <input_file.csv> [title_column] [limit]")
        print("  영문 변환: python tagging_new.py --convert <input_file.csv> [output_file.csv]")
        print("")
        print("예시:")
        print("  python tagging_new.py data.csv")
        print("  python tagging_new.py data.csv '제목'")
        print("  python tagging_new.py data.csv '스킬' 1000")
        print("  python tagging_new.py --convert old_tagged.csv")
        sys.exit(1)

    # 변환 모드 체크
    if sys.argv[1] == "--convert":
        if len(sys.argv) < 3:
            print("변환할 파일을 지정해주세요.")
            sys.exit(1)

        input_file = sys.argv[2]
        output_file = sys.argv[3] if len(sys.argv) > 3 else None

        if not os.path.exists(input_file):
            print(f"에러: '{input_file}' 파일을 찾을 수 없습니다.")
            sys.exit(1)

        try:
            df_result = convert_english_to_korean(input_file, output_file)
            if df_result is not None:
                print("\n=== 변환 결과 샘플 (처음 5개) ===")
                pd.set_option('display.max_colwidth', None)
                if '타겟_범위' in df_result.columns and '타겟_태그' in df_result.columns:
                    sample_cols = [col for col in df_result.columns if col in ['스킬', '스킬명', 'Title', '제목']]
                    sample_cols.extend(['타겟_범위', '타겟_태그'])
                    sample = df_result[sample_cols].head(5)
                    print(sample.to_string(index=False))
        except Exception as e:
            print(f"변환 중 에러 발생: {e}")
            sys.exit(1)

    # 일반 태깅 모드
    else:
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
            sample = df_result[[title_col, '타겟_범위', '타겟_태그']].head(5)
            print(sample.to_string(index=False))

        except Exception as e:
            print(f"에러 발생: {e}")
            sys.exit(1)
