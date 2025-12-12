import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from tagging import analyze_user_persona

# 프롬프트에 있는 예시들 테스트
test_cases = [
    "사주로 보는 내 결혼 상대는?",
    "재회 사주: 그 사람과 다시 만날까?",
    "결혼 OX 궁합: 이 사람과 결혼해도 될까?",
    "임신 타로: 우리 아기 언제 올까?",
    "2024년 솔로 탈출",
    "우리 부부 궁합",
    "그 사람의 속마음",
    "연애 운세",
    "재물운 타로",
    "2025년 신년 운세"
]

# 프롬프트의 기대값
expected_results = [
    ("LOVE_SINGLE, LOVE_COUPLE", "LOVE_MARRIAGE, LOVE_NEW"),  # 사주로 보는 내 결혼 상대는?
    ("LOVE_SINGLE", "LOVE_REUNION"),  # 재회 사주
    ("LOVE_SINGLE, LOVE_COUPLE", "LOVE_MARRIAGE, LOVE_MATCH"),  # 결혼 OX 궁합
    ("LOVE_COUPLE", "FAMILY"),  # 임신 타로
]

print("=" * 80)
print("테스트 결과")
print("=" * 80)

for i, title in enumerate(test_cases):
    scope, tags = analyze_user_persona(title)
    print(f"\n제목: {title}")
    print(f"Scope: {scope}")
    print(f"Tags: {tags}")

    # 기대값이 있는 경우 비교
    if i < len(expected_results):
        expected_scope, expected_tags = expected_results[i]
        if scope == expected_scope and tags == expected_tags:
            print("✅ 예상과 일치")
        else:
            print(f"❌ 불일치!")
            print(f"   예상 Scope: {expected_scope}")
            print(f"   예상 Tags: {expected_tags}")

print("\n" + "=" * 80)
print("LOVE_MIND 테스트 케이스")
print("=" * 80)

# LOVE_MIND 테스트 케이스 추가
love_mind_cases = [
    ("그의 속마음: 나를 진짜 좋아할까?", "LOVE_SINGLE, LOVE_COUPLE", ["LOVE_MIND"]),
    ("연인의 진심 확인 타로", "LOVE_COUPLE", ["LOVE_MIND", "LOVE_GENERAL"]),
    ("상대방 마음 읽기", "LOVE_SINGLE, LOVE_COUPLE", ["LOVE_MIND"]),
    ("나를 어떻게 생각할까", "LOVE_SINGLE, LOVE_COUPLE", ["LOVE_MIND"]),
    ("그 사람의 속마음", "LOVE_SINGLE, LOVE_COUPLE", ["LOVE_MIND"]),
]

print("\n[LOVE_MIND 태그 테스트]")
for title, expected_scope, expected_tags_list in love_mind_cases:
    scope, tags = analyze_user_persona(title)
    tags_set = set(tags.split(", ")) if tags else set()
    expected_tags_set = set(expected_tags_list)

    # LOVE_MIND가 포함되어 있는지 확인
    if "LOVE_MIND" in tags_set:
        print(f"✅ {title}: LOVE_MIND 태그 포함")
        print(f"   Scope: {scope}, Tags: {tags}")
    else:
        print(f"❌ {title}: LOVE_MIND 태그 누락!")
        print(f"   실제 - Scope: {scope}, Tags: {tags}")
        print(f"   예상 - Scope: {expected_scope}, Tags 포함: {', '.join(expected_tags_list)}")

print("\n" + "=" * 80)
print("LOVE_MATCH vs LOVE_MIND 구분 테스트")
print("=" * 80)

# LOVE_MATCH와 LOVE_MIND 구분 테스트
distinction_cases = [
    ("우리 궁합 점수는 몇 점?", "LOVE_MATCH"),  # 궁합 -> MATCH
    ("상대방의 속마음 알아보기", "LOVE_MIND"),  # 속마음 -> MIND
    ("우리 케미가 좋을까?", "LOVE_MATCH"),  # 케미 -> MATCH
    ("그가 날 사랑할까?", "LOVE_MIND"),  # 감정 -> MIND
    ("우리 관계 발전 가능성", "LOVE_MATCH"),  # 관계 발전 -> MATCH
    ("진심인지 확인하기", "LOVE_MIND"),  # 진심 -> MIND
]

print("\n[LOVE_MATCH vs LOVE_MIND 구분]")
for title, expected_tag in distinction_cases:
    scope, tags = analyze_user_persona(title)
    if expected_tag in tags:
        print(f"✅ {title}: {expected_tag} 올바르게 태깅")
    else:
        print(f"❌ {title}: {expected_tag} 예상했으나 실제 태그: {tags}")

print("\n" + "=" * 80)
print("추가 테스트 케이스")
print("=" * 80)

# Strict Single 테스트
single_cases = ["전 연인이 다시 연락할까?", "솔로 탈출하는 법", "짝사랑 상대의 마음"]
print("\n[Strict Single 테스트]")
for title in single_cases:
    scope, tags = analyze_user_persona(title)
    print(f"{title}: Scope={scope}")

# Strict Couple 테스트
couple_cases = ["우리 부부 이혼할까?", "남편의 속마음", "아내와의 궁합"]
print("\n[Strict Couple 테스트]")
for title in couple_cases:
    scope, tags = analyze_user_persona(title)
    print(f"{title}: Scope={scope}")

# Dual Target 테스트
dual_cases = ["결혼 시기", "미래 배우자", "연애운", "운명의 상대"]
print("\n[Dual Target 테스트]")
for title in dual_cases:
    scope, tags = analyze_user_persona(title)
    print(f"{title}: Scope={scope}")

# 비연애 콘텐츠 테스트
non_love_cases = ["재물운", "직업운", "2025년 신년 운세", "로또 대박운"]
print("\n[비연애 콘텐츠 테스트]")
for title in non_love_cases:
    scope, tags = analyze_user_persona(title)
    print(f"{title}: Scope={scope}")