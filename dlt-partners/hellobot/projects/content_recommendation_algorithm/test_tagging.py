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