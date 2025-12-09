# 🔮 운세 콘텐츠 추천 시스템 설계서 (v1.0)

## 1\. 개요 (Overview)

본 시스템은 사용자의 \*\*물리적 상태(Status)\*\*와 \*\*심리적 니즈(Interest)\*\*를 분석하여, 콘텐츠의 특성(Target Scope, Tags)과 매칭하는 \*\*하이브리드 추천 엔진(Hybrid Recommendation Engine)\*\*이다.

  * **핵심 철학:** 사용자의 고민을 정밀 타격하는 **'맞춤형(Sniper)'** 추천과, 흥미를 유발하는 **'범용형(General)'** 추천을 **5:5 비율**로 혼합하여 제공한다.
  * **주요 특징:** 상태와 관심사의 분리, `LOVE_GENERAL` 태그를 활용한 유연한 운명 확인 니즈 수용.

  - 사용자의 정보와 콘텐츠에 설정된 메타데이터의 매칭 로직의 구성으로 적절한 콘텐츠를 조합하여 제공할 수 있다.
  - 단순히 태그 일치만으로 추천하는게 아니므로 '가능한 많은 태그'가 아닌 '적절한 태그'세팅이 중요
  - 사용자 프로필은 사용자의 입력, 사용자의 행동 로그를 통한 추론 등 다양하게 수집한 데이터로 추정된다.
  - 콘텐츠 메타데이터는 콘텐츠 제작자가 직접 입력하는 정보이고, 제작 의도에 가장 적절한 태그를 세팅한다.

-----

## 2\. 데이터 모델 (Data Model)

### 2.1. 사용자 프로필 (User Profile)

- 사용자의 상태를 물리적인 현재 상태와 사용자가 가진 관심사의 조합으로 추정할 수 있도록 모델을 구성한다.
- 상태 정보는 연애 관심과 비연애 관심이 확실한 경우가 아닌경우 UNKNOWN. 모든 스킬을 추천받을 수 있는 상태.
- 현재는 연애 위주로만 관심있는 경우만 특정하고 콘텐츠 추천에 참고.
- 관심사는 중복으로 관심사를 가질 수 있고, 사용자의 구매 이력등 행동에 따라 가중치로 주 관심사를 특정하게 됨.

시스템이 사용자를 식별하는 변수 정의.

| 변수명 | 설명 | 데이터 타입 / 예시 | 비고 |
| :--- | :--- | :--- | :--- |
| **User ID** | 고유 식별자 | `String` (U12345) | |
| **Status** | **물리적 상태** | `Enum` (아래 코드표 참조) | 1차 필터링 기준 |
| **Interest** | **심리적 니즈** | `Enum` (아래 코드표 참조) | 2차 매칭 기준 (다중 선택 가능) |

  * **Logic:** 사용자가 `Status`만 선택하고 `Interest`를 선택하지 않은 경우, 상태별 \*\*기본 관심사(Default Interest)\*\*가 자동 할당됨.
      * `LOVE_SINGLE` 선택 시 → `LOVE_NEW` 자동 할당.
      * `LOVE_COUPLE` 선택 시 → `LOVE_MATCH` 자동 할당.

### 2.2. 콘텐츠 메타데이터 (Content Metadata)

- 콘텐츠 메타데이터 태깅은 해당 콘텐츠가 매칭되는 사용자에게 추천되어 사용할 경우 만족도가 평균이상 좋게하는 것을 목표로 설정한다.
- 너무 뾰족하면 노출이 덜 될 것이고, 너무 많은 스킬을 ALL, GENERAL 같은걸로 세팅하면 추천의 효율이 하락한다.
- 헷갈리면 기존의 유사한 콘텐츠에 세팅값을 참조하여 세팅한다.

콘텐츠 분류를 위한 태그 정의.

| 변수명 | 설명 | 데이터 타입 / 예시 | 비고 |
| :--- | :--- | :--- | :--- |
| **Content ID** | 고유 식별자 | `Integer` (1001) | |
| **Title** | 콘텐츠 제목 | `String` | |
| **Target Scope** | **타겟 범위** | `List<Enum>` [`LOVE_SINGLE`, `LOVE_COUPLE`] | 이 상태인 사람만 볼 수 있음 (`OR` 조건) |
| **Target Tags** | **타겟 관심사** | `List<Enum>` [`LOVE_REUNION`, `LOVE_GENERAL`] | 이 니즈를 가진 사람에게 추천됨 |
| **Metrics** | 성과 지표 | `Object` {sales, views, reg\_date} | 랭킹 점수 산정용 |

-----

## 3\. 분류 코드표 (Taxonomy)

### 3.1. 상태 코드 (Status / Target Scope)

| 코드명 | 의미 | 포함 범위 |
| :--- | :--- | :--- |
| **`LOVE_SINGLE`** | **싱글** | 모태솔로, 이별 후 솔로, 돌싱, 썸(초기) |
| **`LOVE_COUPLE`** | **커플** | 연애 중, 결혼 전, 기혼(부부) |
| **`ALL`** | **전체** | 상태 무관 (콘텐츠 메타데이터 전용) |

### 3.2. 관심사 태그 코드 (Interest / Target Tags)

| 카테고리 | 코드명 | 설명 & 매칭 규칙 |
| :--- | :--- | :--- |
| **연애 (특수)** | **`LOVE_NEW`** | **연애_새로운만남** (솔로 탈출, 짝사랑, 도화살) |
| | **`LOVE_REUNION`** | **연애_재회** (전 연인, 미련, 이별 후 회복) |
| | **`LOVE_MATCH`** | **연애_궁합/관계** (속마음, 궁합, 애정전선) |
| | **`LOVE_MARRIAGE`** | **연애_결혼키워드** (결혼 시기, 결혼 궁합, 배우자 운) |
| | **`LOVE_CRISIS`** | **연애_위기/갈등** (권태기, 이별수, 외도) |
| **연애 (범용)** | **`LOVE_GENERAL`** | **연애_일반** (연애운 전반, 운명의 상대 확인) <br> *※ 모든 `LOVE_` 계열 니즈 사용자에게 2순위로 매칭됨* |
| **일반** | **`NEW_YEAR`** | **신년운세** (신년운세, 하반기 신년운세) |
| | **`OVERALL`** | **종합운** (토정비결, 인생 총운) |
| | **`FAMILY`** | **가족/자녀운** (임신, 출산, 자녀운) |
| | **`WEALTH`** | **재물/금전운** |
| | **`CAREER`** | **학업/직업운** |
| | **`ELSE`** | **기타** |

-----

## 4\. 추천 엔진 로직 (Algorithm Logic)

### Step 1: 유효성 필터링 (Safety Filter)

사용자의 물리적 상태(`Status`)에 맞지 않는 콘텐츠를 1차적으로 제거한다.

  * **Rule:** `Content.Target_Scope`가 `ALL`이거나, 사용자의 `User.Status`를 포함해야 함.
  * *Ex: `Status=LOVE_COUPLE` 사용자에게 `Target_Scope=[LOVE_SINGLE]`인 '솔로탈출' 콘텐츠 노출 금지.*

### Step 2: 그룹핑 (Grouping)

필터를 통과한 콘텐츠를 두 그룹으로 나눈다.

  * **A그룹: 스나이퍼 (Sniper - 맞춤형)**
      * 조건: `Content.Target_Tags`가 `User.Interest`와 일치하는 경우.
      * **확장 규칙:** 사용자가 연애 관련 Interest(`NEW`, `REU`, `MAT`, `MAR`, `CRI`)를 가진 경우, **`LOVE_GENERAL`** 태그 콘텐츠도 스나이퍼 그룹에 포함.
  * **B그룹: 제너럴 (General - 범용형)**
      * 조건: `Content.Target_Tags`에 `NEW_YEAR`, `OVERALL`, `WEALTH`, `CAREER` 등이 포함된 경우.

### Step 3: 스코어링 (Scoring)

각 그룹 내 콘텐츠의 순위를 결정한다.
$$Score = (Sales \times 0.6) + (Views \times 0.2) + (NewBooster \times 0.2)$$

  * *NewBooster:* 출시 7일 이내 콘텐츠는 고정 가산점 부여 (Cold Start 방지).

### Step 4: 믹싱 (Mixing)

최종 리스트 10개를 생성한다.

  * **비율:** 스나이퍼(5) : 제너럴(5)
  * **배치:** `A1` -\> `B1` -\> `A2` -\> `B2` ... 순으로 교차 배치하여 지루함 방지.

-----

## 5\. 로직 적용 예시 (Use Case Simulation)

| 사용자 케이스 | 프로필 설정 | 추천 전략 (Key Logic) | 추천 콘텐츠 예시 |
| :--- | :--- | :--- | :--- |
| **1. 재회 희망 솔로** | Status: `SINGLE`<br>Interest: `REUNION` | 재회 가능성(`REUNION`)을 최상단에, 운명의 흐름(`GENERAL`)과 마음 정리(`OVERALL`)를 서브로 추천. | 1. 재회 사주<br>2. 2026 신년운세<br>3. D-DAY 재회 타로 |
| **2. 결혼 고민 커플** | Status: `COUPLE`<br>Interest: `MARRIAGE` | 결혼 궁합/시기(`MARRIAGE`) 집중 공략. 단순히 좋은지(`MATCH`)보다 결혼 성사 여부를 강조. | 1. 결혼 OX 궁합<br>2. 우리 커플 삼단궁합<br>3. 25년 재물운 |
| **3. 무기력한 솔로** | Status: `SINGLE`<br>Interest: `NEW` | 당장의 연애(`NEW`)보다 내 팔자에 연애가 있는지(`GENERAL`) 확인시켜 주는 콘텐츠 비중 확대. | 1. 내 사주에 연애상대 몇 명?<br>2. 내 팔자의 천년배필<br>3. 사주 직업 컨설팅 |

-----

## 6\. 부록: 콘텐츠 메타데이터 매핑 테이블 (Reference)

총 99개의 콘텐츠에 대한 최종 태깅 데이터입니다. (데이터베이스 초기 구축용)

| No | 콘텐츠 제목 | 타겟 범위 (Scope) | 타겟 관심사 (Tags) | 
| :--- | :--- | :--- | :--- |
| 1 | 2025 을사년 운세: 사랑과 인연 | `LOVE_SINGLE`, `LOVE_COUPLE` | `NEW_YEAR`, `LOVE_GENERAL` |
| 2 | 2024 갑진년 운세: 사랑과 인연 | `LOVE_SINGLE`, `LOVE_COUPLE` | `NEW_YEAR`, `LOVE_GENERAL` |
| 3 | 재회 사주: 그 사람과 다시 만날 운명일까? | `LOVE_SINGLE` | `LOVE_REUNION` |
| 4 | 삼신할매가 점지한 내 진짜 인연 VS 가짜 인연 | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_GENERAL` |
| 5 | 2025년 신년운세 보고서 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 6 | 2024년 신년운세 보고서 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 7 | 2025 을사년 하반기 애정운 | `LOVE_SINGLE`, `LOVE_COUPLE` | `NEW_YEAR`, `LOVE_GENERAL` |
| 8 | 내 사주에 연애 상대 몇 명 있을까? | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_GENERAL` |
| 9 | 내 팔자에 새겨진 천년배필 | `LOVE_SINGLE` | `LOVE_NEW`, `LOVE_MARRIAGE` |
| 10 | 결혼 OX 궁합: 이 사람과 결혼해도 될까? | `LOVE_COUPLE` | `LOVE_MATCH`, `LOVE_MARRIAGE` |
| 11 | 내 사주에 쓰인 운명의 배우자 | `LOVE_SINGLE` | `LOVE_NEW`, `LOVE_MARRIAGE` |
| 12 | 그 사람과 나의 사주 궁합 | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_MATCH` |
| 13 | D-DAY 재회 타로: 다시 만날 수 있을까? | `LOVE_SINGLE` | `LOVE_REUNION` |
| 14 | 내 사주의 사랑운: 연애만? 결혼까지\! | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_GENERAL`, `LOVE_MARRIAGE` |
| 15 | 2024 갑진년 하반기 애정운 | `LOVE_SINGLE`, `LOVE_COUPLE` | `NEW_YEAR`, `LOVE_GENERAL` |
| 16 | 내 운명 지금 어디 있을까? | `LOVE_SINGLE` | `LOVE_NEW` |
| 17 | 2024년 솔로 탈출 시기 | `LOVE_SINGLE` | `NEW_YEAR`, `LOVE_NEW` |
| 18 | 지금 날 간절히 원하는 사람 누구일까? | `LOVE_SINGLE` | `LOVE_NEW` |
| 19 | 그 사람과 나의 3가지 사주궁합 | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_MATCH` |
| 20 | [창광] 신년운세 통합본 "2025년 을사년" | `ALL` | `NEW_YEAR`, `OVERALL` |
| 21 | 사주로 보는 내 결혼 상대는? | `LOVE_SINGLE` | `LOVE_NEW`, `LOVE_MARRIAGE` |
| 22 | 내 사주 배우자 궁(宮)에 있는 사람은? | `LOVE_SINGLE` | `LOVE_NEW`, `LOVE_MARRIAGE` |
| 23 | 타고난 결혼운 + 내 운명의 상대 | `LOVE_SINGLE` | `LOVE_GENERAL`, `LOVE_MARRIAGE` |
| 24 | [창광] 25년 을사년 사랑운과 인연운 | `LOVE_SINGLE`, `LOVE_COUPLE` | `NEW_YEAR`, `LOVE_GENERAL` |
| 25 | 사주로 보는 결혼수: 나는 언제 결혼할까? | `LOVE_SINGLE` | `LOVE_MARRIAGE` |
| 26 | 재회 vs 작별: 운명에 새겨진 우리의 엔딩 | `LOVE_SINGLE` | `LOVE_REUNION` |
| 27 | 재회 사주: 헤어져도 다시 만날 필연 | `LOVE_SINGLE` | `LOVE_REUNION` |
| 28 | 2025년 솔로 탈출 시기 | `LOVE_SINGLE` | `NEW_YEAR`, `LOVE_NEW` |
| 29 | 재회 타로 : 그 사람의 첫 연락 | `LOVE_SINGLE` | `LOVE_REUNION` |
| 30 | 재회OX궁합: 붙잡을 운명 vs 놓아줄 인연 | `LOVE_SINGLE` | `LOVE_REUNION` |
| 31 | 2026년 신년운세 보고서 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 32 | 사주로 보는 그 사람의 속마음 | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_MATCH` |
| 33 | 2024년 하반기 운세 보고서 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 34 | [창광] 24년 하반기 사랑운과 인연운 | `LOVE_SINGLE`, `LOVE_COUPLE` | `NEW_YEAR`, `LOVE_GENERAL` |
| 35 | 2024년 하반기 솔로 탈출 시기 | `LOVE_SINGLE` | `NEW_YEAR`, `LOVE_NEW` |
| 36 | 임신 타로: 이번 달 우리 아기 찾아올까? | `LOVE_COUPLE` | `FAMILY` |
| 37 | 2025년에 찾아올 두 명의 인연 | `LOVE_SINGLE` | `NEW_YEAR`, `LOVE_NEW` |
| 38 | 2026년 솔로 탈출 시기 | `LOVE_SINGLE` | `NEW_YEAR`, `LOVE_NEW` |
| 39 | 내 운이 트이는 동네는?(서울편) | `ALL` | `OVERALL` |
| 40 | 재회 사주, 속마음 타로: {{이름}}님은 n일 뒤 재회합니다 | `LOVE_SINGLE` | `LOVE_REUNION` |
| 41 | 헤어진 X와 재회할 수 있을까? | `LOVE_SINGLE` | `LOVE_REUNION` |
| 42 | 절대로 놓치면 안 될 결혼 상대와 시기는? | `LOVE_SINGLE` | `LOVE_NEW`, `LOVE_MARRIAGE` |
| 43 | {{이름}}[[이의/의]] 운명의 인연, 언제 만날까? | `LOVE_SINGLE` | `LOVE_NEW` |
| 44 | 2024년 갑진년 운세 [통합편] | `ALL` | `NEW_YEAR`, `OVERALL` |
| 45 | 🪡6개월 내 반드시 만나게 될: 붉은 실 인연🧶 | `LOVE_SINGLE` | `LOVE_NEW` |
| 46 | 2025년 하반기 운세 보고서 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 47 | 사주+타로: 임신운 심층 분석 | `LOVE_COUPLE` | `FAMILY` |
| 48 | [창광] 25년 을사년 직업운과 합격운 | `ALL` | `NEW_YEAR`, `CAREER` |
| 49 | 우리 커플 삼단궁합 : 연애궁합, 속궁합, 결혼궁합 | `LOVE_COUPLE` | `LOVE_MATCH`, `LOVE_MARRIAGE` |
| 50 | 2025년 하반기 솔로 탈출 시기 | `LOVE_SINGLE` | `NEW_YEAR`, `LOVE_NEW` |
| 51 | 월지로 보는 인연: 배우자가 될 3명의 후보 | `LOVE_SINGLE` | `LOVE_NEW`, `LOVE_MARRIAGE` |
| 52 | 내 운명의 연애, 몇 번 남았을까? | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_GENERAL` |
| 53 | [창광] 25년 을사년 재물운과 문서운 | `ALL` | `NEW_YEAR`, `WEALTH` |
| 54 | [창광] 24년 하반기 재물운과 문서운 | `ALL` | `NEW_YEAR`, `WEALTH` |
| 55 | 그 사람의 속마음 | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_MATCH` |
| 56 | 그 사람 속마음 [심화] | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_MATCH` |
| 57 | 사주 직업 컨설팅: 사업, 직장, 업종 | `ALL` | `CAREER` |
| 58 | 나는 결혼해야 좋은 팔자일까? | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_GENERAL`, `LOVE_MARRIAGE` |
| 59 | [창광] 24년 하반기 운세 통합본 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 60 | 그 사람도 날 좋아할까? | `LOVE_SINGLE` | `LOVE_MATCH` |
| 61 | 인생역전 3대운 풀이: 대운은 언제 들어올까? | `ALL` | `OVERALL` |
| 62 | 그 사람 아직 나한테 미련 있을까? | `LOVE_SINGLE` | `LOVE_REUNION` |
| 63 | 2024년에 찾아올 두 명의 인연 | `LOVE_SINGLE` | `NEW_YEAR`, `LOVE_NEW` |
| 64 | 내 인생 황금기와 암흑기: 사주팔자 풀이 | `ALL` | `OVERALL` |
| 65 | 내 인생 언제 필까?: 3번의 기회🔑 | `ALL` | `OVERALL` |
| 66 | 임신운 풀이: 삼신할매가 점지한 우리 아가 | `LOVE_COUPLE` | `FAMILY` |
| 67 | 불안한 사랑, 우리 관계의 미래는? | `LOVE_COUPLE` | `LOVE_CRISIS` |
| 68 | 🩵하늘이 맺어준 혼인길 점괘🩵 | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_MATCH`, `LOVE_MARRIAGE` |
| 69 | 사주 살풀이: 타고난 살과 2025년의 살 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 70 | 2024 갑진년 운세: 합격과 커리어 | `ALL` | `NEW_YEAR`, `CAREER` |
| 71 | 이 사랑의 결말: 그 사람과 나의 인연 | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_MATCH`, `LOVE_GENERAL` |
| 72 | 타고난 부(富): 내 사주 재물운과 평생 모을 재산은? | `ALL` | `WEALTH` |
| 73 | 2024년 놓치면 안 될 3번의 기회 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 74 | 내 사주의 연애와 결혼: 운명의 두 사람 | `LOVE_SINGLE` | `LOVE_GENERAL`, `LOVE_MARRIAGE` |
| 75 | 타고난 부(富): 재물운과 평생 모을 재산은? | `ALL` | `WEALTH` |
| 76 | 이별, 그 후… 너와 나의 속마음 | `LOVE_SINGLE` | `LOVE_REUNION` |
| 77 | [창광] 25년 하반기 운세 통합편 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 78 | [창광] 24년 하반기 직업운과 합격운 | `ALL` | `NEW_YEAR`, `CAREER` |
| 79 | 사주로 보는 결혼 : 그 사람의 본심 👤 | `LOVE_COUPLE` | `LOVE_MATCH`, `LOVE_MARRIAGE` |
| 80 | [완결판] 곧 다가올 나의 인생 연애 | `LOVE_SINGLE` | `LOVE_NEW` |
| 81 | 사주 살풀이: 타고난 살과 2024년의 살 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 82 | 내 운명의 상대 | `LOVE_SINGLE` | `LOVE_NEW` |
| 83 | 지금 날 좋아하는 사람은? | `LOVE_SINGLE` | `LOVE_NEW` |
| 84 | {{이름}}님의 3번의 결정적 결혼수💍 | `LOVE_SINGLE` | `LOVE_MARRIAGE` |
| 85 | 결혼 사주 즉문즉답: 시기・상대・개운・팔자 | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_GENERAL`, `LOVE_MARRIAGE` |
| 86 | 다시 만날 수 있을까 | `LOVE_SINGLE` | `LOVE_REUNION` |
| 87 | 도화살로 보는 연애운 전성기 | `LOVE_SINGLE` | `LOVE_NEW`, `LOVE_GENERAL` |
| 88 | 2025년 놓치면 안 될 3번의 기회 | `ALL` | `NEW_YEAR`, `OVERALL` |
| 89 | 내 사주에 자녀 몇 명일까?: 타고난 재능과 성공운까지 | `LOVE_SINGLE`, `LOVE_COUPLE` | `FAMILY` |
| 90 | 인생 역전의 비밀: 내 사주의 주목할 운명(運命)은? | `ALL` | `OVERALL` |
| 91 | D-DAY 타로: 솔로 탈출까지 며칠 남았을까? | `LOVE_SINGLE` | `LOVE_NEW` |
| 92 | 인생 역전의 비밀: 내 사주에 주목할 운명은? | `ALL` | `OVERALL` |
| 93 | 사주 궁합으로 보는 우리의 현재와 미래 | `LOVE_COUPLE` | `LOVE_MATCH` |
| 94 | 좋아하는 그 사람의 속마음은? | `LOVE_SINGLE` | `LOVE_MATCH` |
| 95 | 사주로 보는 그 사람의 '진짜' 속마음🚨 | `LOVE_SINGLE`, `LOVE_COUPLE` | `LOVE_MATCH` |
| 96 | 내 사주의 배우자 궁에 있는 사람은? | `LOVE_SINGLE` | `LOVE_NEW`, `LOVE_MARRIAGE` |
| 97 | 사업운 vs 직장운: 경제적 자유 누리는 법 | `ALL` | `CAREER` |
| 98 | 도화살 풀이: 내 매력 언제 터질까? | `LOVE_SINGLE` | `LOVE_NEW` |
| 99 | 그 사람과 나의 결혼 궁합 | `LOVE_COUPLE` | `LOVE_MATCH`, `LOVE_MARRIAGE` |

