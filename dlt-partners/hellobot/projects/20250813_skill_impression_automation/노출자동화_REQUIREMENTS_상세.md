# 노출 알고리즘 A/B 테스트 시스템 요구사항 정의서

> - **문서 버전:** 1.0
> - **작성일:** 2025-10-21
> - **목적:** 홈 화면 노출 알고리즘 A/B 테스트 환경 구축
> - **솔루션:** Firebase Remote Config / Firebase A/B Testing

---

## 1. 프로젝트 개요

### 1.1 비즈니스 목표
- **최종 목표**: 지속적인 노출 알고리즘 개발/적용/테스트를 통한 최적화
- **핵심 성과 지표 (KPI)**:
  - 사용자당 클릭한 콘텐츠 수 증가
  - 사용자 1주일 LTV 향상

### 1.2 현황 분석
- **As-Is**: 홈 화면에 단일 노출 알고리즘만 적용 가능
- **To-Be**: 사용자 그룹별로 다른 노출 알고리즘 동시 운영 및 성과 비교

### 1.3 프로젝트 범위
- 1단계: A/B 테스트 인프라 구축
- 향후 확장: 지속적인 알고리즘 개선 및 자동화

---

## 2. 기능 요구사항

### 2.1 노출 알고리즘 관리

#### 2.1.1 알고리즘 설정 및 운영

**기본 운영 모드**
- 평상시 1개의 기본(default) 노출 알고리즘 운영
- 모든 사용자에게 기본 알고리즘 적용
- 운영 중인 알고리즘은 언제든지 변경 가능

**테스트 운영 모드**
- 동시에 2개 이상의 노출 알고리즘 병렬 운영 가능
- 각 알고리즘은 고유 식별자(algorithm_id) 보유
- 대조군(control) + 실험군(variant) 구조
  - Control: 기존 default 알고리즘
  - Variant A, B, C...: 테스트할 새로운 알고리즘들

#### 2.1.2 알고리즘 구성 요소 (예시)

각 알고리즘은 다음과 같은 파라미터로 정의됩니다:

```json
{
  "algorithm_id": "algorithm_v2",
  "algorithm_name": "개인화 추천 강화 버전",
  "parameters": {
    "sort_order": "personalized_score",
    "content_mix": {
      "personalized": 0.7,
      "popular": 0.2,
      "new": 0.1
    },
    "category_weights": {
      "연애운": 0.3,
      "재물운": 0.25,
      "건강운": 0.15,
      "기타": 0.3
    },
    "diversity_factor": 0.5,
    "recency_weight": 0.2
  }
}
```

**주요 설정 항목**:
- 콘텐츠 정렬 기준 (최신순, 인기순, 개인화 점수순 등)
- 콘텐츠 유형별 노출 비율 (개인화/인기/신규)
- 카테고리별 가중치
- 다양성 계수 (동일 카테고리 연속 노출 방지)
- 최신성 가중치

---

### 2.2 사용자 그룹 관리

#### 2.2.1 그룹 할당 방식

**1) 랜덤 할당 (Random Assignment)**

- 신규 사용자 또는 미할당 사용자를 무작위로 그룹 배정
- 그룹별 비율 설정 가능
  - 예: Control 70% vs Variant A 30%
  - 예: Control 50% vs Variant A 25% vs Variant B 25%
- 해시 기반 일관성 보장 (user_id를 seed로 사용)

**2) 규칙 기반 할당 (Rule-based Assignment)**

사용자 속성을 기반으로 특정 그룹 타겟팅:
- 가입 날짜 (신규/기존 사용자)
- 지역 (서울/경기/지방 등)
- 디바이스 타입 (iOS/Android)
- 앱 버전 (최신 버전만 테스트)
- 사용자 활동도 (활성/비활성)
- 구매 이력 (구매자/비구매자)

조건 조합 예시:
```
IF (가입일 < 2025-01-01) AND (디바이스 == "iOS") AND (지역 == "서울")
THEN variant_id = "variant_a"
```

**3) 수동 할당 (Manual Override)**

- 특정 사용자 ID 리스트를 지정하여 강제 그룹 할당
- 내부 테스트 계정, VIP 사용자 제외 등에 활용
- QA 및 검증 용도

#### 2.2.2 그룹 식별자 체계

**그룹 ID 구조**:
- `experiment_id`: 실험 고유 식별자 (예: "exp_home_algorithm_202510")
- `variant_id`: 변형 그룹 식별자 (예: "control", "variant_a", "variant_b")
- `algorithm_id`: 실제 적용되는 알고리즘 ID (예: "algorithm_v1", "algorithm_v2")

**매핑 관계**:
```json
{
  "experiment_id": "exp_home_algorithm_202510",
  "variants": [
    {
      "variant_id": "control",
      "algorithm_id": "algorithm_v1",
      "allocation_percent": 50
    },
    {
      "variant_id": "variant_a",
      "algorithm_id": "algorithm_v2",
      "allocation_percent": 50
    }
  ]
}
```

#### 2.2.3 그룹 할당 저장 및 일관성 보장

**저장 위치**:
- **1차**: Firebase Remote Config (실시간 조회)
- **2차**: 사용자 프로필 DB (백업 및 감사 목적)

**일관성 정책**:
- 한 번 할당된 그룹은 실험 기간 동안 **절대 변경 금지**
- 실험 종료 후 새로운 실험 시작 시에만 재할당 가능
- 그룹 할당 변경 이력 추적 (audit log)

**예외 처리**:
- Remote Config fetch 실패 시 → 로컬 캐시 사용
- 캐시도 없는 경우 → default 알고리즘 적용
- 오류 로깅 및 모니터링

---

### 2.3 사용자 이벤트 로깅

#### 2.3.1 필수 로깅 필드

모든 주요 이벤트에 다음 정보를 **필수로 포함**:

| 필드명 | 타입 | 설명 | 예시 |
|--------|------|------|------|
| `user_id` | string | 사용자 고유 식별자 | "user_12345" |
| `experiment_id` | string | 실험 식별자 | "exp_home_algorithm_202510" |
| `variant_id` | string | 할당된 변형 그룹 | "variant_a" |
| `algorithm_id` | string | 적용된 알고리즘 ID | "algorithm_v2" |
| `timestamp` | datetime | 이벤트 발생 시각 (UTC) | "2025-10-21T12:34:56Z" |
| `session_id` | string | 세션 식별자 | "session_abc123" |

#### 2.3.2 추적할 이벤트 유형

**1) 노출 이벤트 (Impression)**

- 이벤트명: `content_impression`
- 추가 필드:
  - `content_id`: 노출된 콘텐츠 ID
  - `content_type`: 콘텐츠 유형 (스킬, 배너 등)
  - `position`: 노출 위치 (1, 2, 3...)
  - `section`: 화면 섹션 (메인배너, 카테고리, 섹션)
  - `category`: 콘텐츠 카테고리

예시:
```json
{
  "event": "content_impression",
  "user_id": "user_12345",
  "experiment_id": "exp_home_algorithm_202510",
  "variant_id": "variant_a",
  "algorithm_id": "algorithm_v2",
  "content_id": "skill_789",
  "content_type": "skill",
  "position": 1,
  "section": "main_banner",
  "category": "연애운",
  "timestamp": "2025-10-21T12:34:56Z"
}
```

**2) 상호작용 이벤트 (Engagement)**

- 이벤트명: `content_click`
- 추가 필드:
  - `content_id`: 클릭된 콘텐츠 ID
  - `position`: 클릭 위치
  - `time_to_click`: 노출 후 클릭까지 소요 시간(초)

기타 이벤트:
- `scroll_depth`: 스크롤 깊이 (25%, 50%, 75%, 100%)
- `content_view_duration`: 콘텐츠 상세 화면 체류 시간

**3) 전환 이벤트 (Conversion)**

- `content_purchase`: 콘텐츠 구매
- `content_complete`: 콘텐츠 완독/완료
- 추가 필드:
  - `purchase_amount`: 구매 금액
  - `currency`: 통화 ("KRW")

#### 2.3.3 데이터 저장 및 분석 파이프라인

**데이터 흐름**:
```
앱 클라이언트
  ↓ (Firebase Analytics SDK)
Firebase Analytics
  ↓ (자동 export, 일 1회)
BigQuery
  ↓ (SQL 분석)
Looker Studio 대시보드
```

**저장 위치별 역할**:
1. **Firebase Analytics**: 실시간 이벤트 수집 및 기본 분석
2. **BigQuery**: 상세 분석 및 커스텀 쿼리
3. **자체 로깅 시스템**: 백업 및 디버깅 (선택사항)

**데이터 보관 정책**:
- Firebase Analytics: 14개월
- BigQuery: 무제한 (비용 고려하여 파티셔닝)

---

### 2.4 Firebase Remote Config 연동

#### 2.4.1 Remote Config 스키마 설계

**설정 키**: `impression_algorithm_config`

**값 구조** (JSON):
```json
{
  "default_algorithm_id": "algorithm_v1",
  "experiments": [
    {
      "experiment_id": "exp_home_algorithm_202510",
      "experiment_name": "홈 화면 개인화 추천 강화",
      "enabled": true,
      "start_date": "2025-10-21T00:00:00Z",
      "end_date": "2025-11-04T23:59:59Z",
      "variants": [
        {
          "variant_id": "control",
          "variant_name": "기존 알고리즘",
          "algorithm_id": "algorithm_v1",
          "allocation_percent": 50
        },
        {
          "variant_id": "variant_a",
          "variant_name": "개인화 강화 버전",
          "algorithm_id": "algorithm_v2",
          "allocation_percent": 50
        }
      ]
    }
  ],
  "algorithms": {
    "algorithm_v1": {
      "sort_order": "popular",
      "content_mix": {"personalized": 0.5, "popular": 0.3, "new": 0.2}
    },
    "algorithm_v2": {
      "sort_order": "personalized_score",
      "content_mix": {"personalized": 0.7, "popular": 0.2, "new": 0.1}
    }
  }
}
```

#### 2.4.2 클라이언트 적용 흐름

1. **앱 시작 시 Remote Config fetch**
   ```kotlin
   // Android 예시
   remoteConfig.fetchAndActivate()
     .addOnCompleteListener { task ->
       if (task.isSuccessful) {
         val config = remoteConfig.getString("impression_algorithm_config")
         applyAlgorithmConfig(config)
       }
     }
   ```

2. **사용자 그룹 확인 및 알고리즘 결정**
   ```kotlin
   fun getUserVariant(userId: String, experiments: List<Experiment>): String {
     // 활성화된 실험 찾기
     val activeExperiment = experiments.find { it.enabled && isInDateRange(it) }
       ?: return "default"

     // 이미 할당된 그룹이 있는지 확인
     val assignedVariant = getUserAssignedVariant(userId, activeExperiment.id)
     if (assignedVariant != null) return assignedVariant

     // 신규 할당 (해시 기반 일관성 보장)
     return assignVariantByHash(userId, activeExperiment.variants)
   }
   ```

3. **알고리즘 파라미터 로드 및 적용**
   ```kotlin
   val algorithmId = getAlgorithmIdForVariant(variantId)
   val algorithmParams = config.algorithms[algorithmId]

   // 홈 화면 콘텐츠 로드 시 적용
   loadHomeContent(algorithmParams)
   ```

#### 2.4.3 캐싱 및 업데이트 정책

**캐시 전략**:
- 기본 캐시 유지 시간: **12시간**
- 오프라인 시 마지막 캐시된 값 사용
- 실시간 업데이트 필요 시 `fetchAndActivate()` 강제 호출 가능

**업데이트 타이밍**:
- 앱 시작 시 (cold start)
- 백그라운드에서 포그라운드로 전환 시
- 수동 트리거 (개발자/운영자 요청)

---

### 2.5 A/B 테스트 운영 프로세스

#### 2.5.1 실험 기획 단계

**1) 가설 수립**
- 예: "개인화 추천 비율을 50%에서 70%로 높이면 클릭률이 15% 증가할 것이다"

**2) 성공 지표 정의**

**Primary Metric (주 지표)**:
- 사용자당 평균 콘텐츠 클릭 수
- 측정 방법: `COUNT(content_click) / COUNT(DISTINCT user_id)`

**Secondary Metrics (보조 지표)**:
- 1주일 LTV (평균 구매 금액)
- 홈 화면 체류 시간
- 스크롤 깊이
- 콘텐츠 구매 전환율

**Guardrail Metrics (안전 지표)**:
- 앱 크래시율 (실험군에서 증가 시 즉시 중단)
- 홈 화면 로딩 시간 (200ms 이상 증가 시 경고)

**3) 샘플 사이즈 계산**

통계적 검정력 확보를 위한 최소 샘플 계산:
- 유의 수준 (α): 0.05 (5%)
- 검정력 (1-β): 0.8 (80%)
- 기대 효과 크기: 15% 증가
- 계산 도구: [Evan's Awesome A/B Tools](http://www.evanmiller.org/ab-testing/sample-size.html)

예시 결과: 그룹당 최소 **10,000명** 필요

**4) 실험 기간 설정**

- 최소 기간: **2주** (주중/주말 패턴 고려)
- 샘플 사이즈 충족 시까지 연장 가능
- 최대 기간: **4주** (너무 길면 외부 요인 증가)

#### 2.5.2 실험 설정 및 배포

**1) Firebase Console 설정**

옵션 A: **Firebase A/B Testing 사용**
- Firebase Console > A/B Testing > 실험 만들기
- 타겟 사용자: "모든 사용자" 또는 특정 조건
- 변형 그룹: Control, Variant A
- 목표: "content_click" 이벤트 증가
- 배포 비율: 50% vs 50%

옵션 B: **Remote Config만 사용**
- Remote Config에 실험 설정 수동 작성
- 클라이언트에서 그룹 할당 로직 직접 구현
- Firebase Analytics로 이벤트 수집
- BigQuery에서 수동 분석

**2) 앱 코드 구현**

```kotlin
// 1. Remote Config 초기화
val remoteConfig = Firebase.remoteConfig
remoteConfig.setConfigSettingsAsync(
  remoteConfigSettings {
    minimumFetchIntervalInSeconds = 3600 // 1시간
  }
)

// 2. 설정 fetch 및 활성화
remoteConfig.fetchAndActivate().addOnCompleteListener {
  val configJson = remoteConfig.getString("impression_algorithm_config")
  val config = Json.decodeFromString<AlgorithmConfig>(configJson)

  // 3. 사용자 그룹 결정
  val variant = getUserVariant(userId, config.experiments)
  val algorithmId = getAlgorithmForVariant(variant, config)

  // 4. 사용자 프로퍼티 설정 (Analytics에서 세그먼트 분석용)
  Firebase.analytics.setUserProperty("experiment_id", experimentId)
  Firebase.analytics.setUserProperty("variant_id", variant)

  // 5. 알고리즘 적용
  applyHomeAlgorithm(algorithmId, config.algorithms[algorithmId])
}

// 6. 이벤트 로깅
fun logContentImpression(contentId: String, position: Int) {
  Firebase.analytics.logEvent("content_impression") {
    param("content_id", contentId)
    param("position", position.toLong())
    param("experiment_id", experimentId)
    param("variant_id", variantId)
    param("algorithm_id", algorithmId)
  }
}
```

**3) QA 및 검증**

- 내부 테스트 계정으로 각 variant 동작 확인
- 로깅 이벤트가 Firebase Console에 정상 수집되는지 확인
- 예외 상황 테스트 (네트워크 오류, 캐시 만료 등)

#### 2.5.3 실험 모니터링

**1) 실시간 대시보드**

Firebase Console 또는 Looker Studio에서 모니터링:
- **사용자 분포**: 각 variant별 할당 사용자 수
- **주요 지표 추이**: 일별 클릭 수, LTV 변화
- **통계적 유의성**: p-value, 신뢰 구간 (95% CI)
- **안전 지표**: 크래시율, 로딩 시간

**2) 모니터링 주기**

- **1~3일차**: 매일 2회 (오전/오후) 확인
  - 심각한 버그나 크래시 없는지 점검
  - 이벤트 로깅 정상 동작 확인
- **4~7일차**: 매일 1회 확인
  - 초기 지표 추이 분석
- **8일차 이후**: 2~3일마다 확인
  - 통계적 유의성 도달 여부 판단

**3) 이상 징후 감지 및 대응**

**즉시 중단 조건** (자동 롤백):
- 크래시율 **20% 이상 증가**
- 주요 API 에러율 **50% 이상 증가**
- 홈 화면 로딩 시간 **2초 이상 증가**

**주의 관찰 조건** (수동 검토):
- 주 지표가 예상과 반대 방향으로 움직임
- 보조 지표에서 큰 차이 발생

#### 2.5.4 실험 종료 및 의사결정

**1) 통계적 유의성 판단**

- p-value < 0.05 (95% 신뢰 수준)
- 신뢰 구간이 0을 포함하지 않음
- 충분한 샘플 사이즈 확보

**2) 의사결정 기준**

| 결과 | 조건 | 액션 |
|------|------|------|
| **명확한 승리** | Variant가 통계적으로 유의하게 우수 | Variant를 새로운 default로 적용 |
| **근소한 승리** | 통계적으로 유의하지만 효과 크기 작음 | 추가 개선 후 재실험 고려 |
| **차이 없음** | 통계적으로 유의한 차이 없음 | Control 유지, 다른 가설 테스트 |
| **패배** | Variant가 Control보다 나쁨 | Control 유지, 원인 분석 |

**3) 결과 문서화**

실험 종료 후 다음 내용을 포함한 보고서 작성:
- 실험 개요 (가설, 기간, 샘플 사이즈)
- 주요 지표 결과 (표, 그래프)
- 통계 분석 결과 (p-value, 신뢰 구간, 효과 크기)
- 의사결정 및 다음 액션
- 학습한 내용 (lessons learned)

---

## 3. 비기능 요구사���

### 3.1 성능 요구사항

| 항목 | 목표 | 측정 방법 |
|------|------|-----------|
| Remote Config fetch 시간 | 2초 이내 | Firebase Performance Monitoring |
| 알고리즘 적용 후 홈 화면 렌더링 | 1초 이내 (기존 대비 +200ms 이내) | 앱 성능 프로파일링 |
| 이벤트 로깅 지연 | 사용자 경험에 영향 없음 (비동기) | 백그라운드 큐 모니터링 |
| 홈 API 응답 시간 | p95 기준 500ms 이내 | APM 도구 |

### 3.2 확장성 요구사항

| 항목 | 목표 | 고려사항 |
|------|------|----------|
| 동시 실행 가능한 실험 수 | 최소 5개 | Remote Config key 분리 |
| 실험당 variant 수 | 최소 10개 | 해시 기반 할당 알고리즘 |
| 타겟팅 조건 조합 | 최소 10개 조건 AND/OR | Firebase Targeting 기능 활용 |
| 일일 이벤트 수집량 | 1000만 건 이상 | BigQuery 파티셔닝 |

### 3.3 안정성 요구사항

**장애 대응**:
- Remote Config fetch 실패 → 로컬 캐시 사용 (최대 24시간)
- 캐시도 없는 경우 → default 알고리즘 하드코딩 값 사용
- 알고리즘 파라미터 오류 → fallback 안전 설정 적용
- 로깅 실패 → 로컬 큐에 저장 후 재시도 (최대 3회)

**모니터링 및 알림**:
- Remote Config fetch 실패율 모니터링
- 이벤트 수집 누락률 모니터링 (예상 대비 80% 미만 시 알림)
- 크래시 발생 시 Slack 알림

### 3.4 보안 및 개인정보 보호

**개인정보 처리**:
- 사용자 그룹 할당 정보는 user_id와 **별도 저장**
- 분석 데이터에는 user_id 대신 **익명화된 ID** 사용
- 로그 데이터 보관 기간: **최대 2년**

**규정 준수**:
- GDPR 준수: 사용자 요청 시 실험 데이터 삭제
- 개인정보보호법 준수: 개인정보 수집 동의 확보
- Firebase 데이터 처리 위치: EU/미국 리전 설정

**데이터 최소화**:
- 실험에 필요한 최소한의 데이터만 수집
- 민감 정보 (결제 수단, 개인 식별 정보 등) 로깅 금지

---

## 4. 기술 스택

### 4.1 Firebase 서비스

| 서비스 | 용도 | 비고 |
|--------|------|------|
| **Firebase Remote Config** | 알고리즘 설정 배포 및 실험 제어 | 필수 |
| **Firebase A/B Testing** | 실험 관리 및 자동 분석 | 선택 (Remote Config만으로도 가능) |
| **Firebase Analytics** | 이벤트 수집 및 기본 분석 | 필수 |
| **BigQuery** | 상세 데이터 분석 및 커스텀 쿼리 | 필수 (일 1회 자동 export) |
| **Firebase Performance** | 앱 성능 모니터링 | 권장 |
| **Firebase Crashlytics** | 크래시 추적 | 권장 |

### 4.2 클라이언트 구현

**Android**:
```gradle
dependencies {
  implementation 'com.google.firebase:firebase-config-ktx:21.6.0'
  implementation 'com.google.firebase:firebase-analytics-ktx:21.5.0'
}
```

**iOS**:
```swift
import FirebaseRemoteConfig
import FirebaseAnalytics
```

**주요 기능**:
- Remote Config SDK 통합 및 캐싱
- 사용자 그룹 할당 로직 (해시 기반)
- 이벤트 로깅 래퍼 함수
- 로컬 A/B 테스트 디버깅 모드

### 4.3 데이터 분석 도구

**실시간 분석**:
- Firebase Console (기본 지표, 실시간 모니터링)

**상세 분석**:
- BigQuery (SQL 기반 커스텀 분석)
- Looker Studio (대시보드 및 시각화)

**통계 분석**:
- Python (pandas, scipy) 또는 R
- Jupyter Notebook

---

## 5. 구현 로드맵

### Phase 1: 인프라 구축 (2주)

| 작업 | 담당 | 기간 | 산출물 |
|------|------|------|--------|
| Firebase 프로젝트 설정 | DevOps | 1일 | Firebase 프로젝트 |
| Remote Config 스키마 설계 | Backend | 2일 | 스키마 문서 |
| Analytics 이벤트 스키마 설계 | Backend/Data | 2일 | 이벤트 명세서 |
| BigQuery 연동 및 테이블 설계 | Data Engineer | 3일 | BigQuery 테이블 |
| 모니터링 대시보드 구축 | Data Analyst | 4일 | Looker Studio 대시보드 |

### Phase 2: 클라이언트 개발 (3주)

| 작업 | 담당 | 기간 | 산출물 |
|------|------|------|--------|
| Remote Config SDK 통합 | Frontend | 3일 | SDK 연동 코드 |
| 사용자 그룹 할당 로직 구현 | Frontend | 3일 | 할당 모듈 |
| 알고리즘 분기 로직 구현 | Frontend | 4일 | 알고리즘 어댑터 |
| 이벤트 로깅 구현 | Frontend | 3일 | 로깅 모듈 |
| 단위 테스트 작성 | Frontend | 2일 | 테스트 코드 |
| QA 및 버그 수정 | QA/Frontend | 3일 | QA 리포트 |

### Phase 3: 파일럿 실험 (2주)

| 작업 | 담당 | 기간 | 산출물 |
|------|------|------|--------|
| 첫 실험 기획 (가설, 지표) | PM/Data | 2일 | 실험 계획서 |
| Firebase Console 실험 설정 | Backend | 1일 | 실험 설정 완료 |
| 10% 사용자 배포 | DevOps | 1일 | 배포 완료 |
| 초기 모니터링 (3일) | Data/PM | 3일 | 일일 리포트 |
| 전체 배포 (50% → 100%) | DevOps | 2일 | 전체 배포 |
| 결과 분석 및 의사결정 | Data/PM | 3일 | 실험 결과 보고서 |

**총 소요 기간**: **7주**

---

## 6. 성공 기준

### 6.1 시스템 구축 성공 기준

**정량적**:
- [ ] Remote Config 설정 변경 후 앱 반영까지 **1시간 이내**
- [ ] 사용자 그룹 할당 정확도 **99.9% 이상**
- [ ] 이벤트 로깅 성공률 **99% 이상**
- [ ] 홈 화면 성능 저하 **200ms 이내**

**정성적**:
- [ ] 실험 설정부터 배포까지 **1일 이내** 가능
- [ ] 비개발자도 Remote Config로 실험 설정 가능
- [ ] 문서화 완료 (설정 가이드, 운영 매뉴얼)

### 6.2 첫 A/B 테스트 성공 기준

**실험 운영**:
- [ ] 통계적 유의성 확보 (p < 0.05)
- [ ] 최소 2주간 안정적 운영 (크래시 증가 없음)
- [ ] 그룹 간 샘플 비율 오차 **5% 이내**

**비즈니스 지표** (예시):
- [ ] 클릭한 콘텐츠 수 **10% 이상 증가** (목표)
- [ ] 1주일 LTV **15% 이상 증가** (목표)
- [ ] 홈 화면 이탈률 증가 없음 (안전 지표)

---

## 7. 위험 요소 및 대응 방안

| 위험 요소 | 확률 | 영향도 | 대응 방안 |
|-----------|------|--------|-----------|
| Remote Config fetch 실패율 높음 | 중 | 고 | 로컬 캐싱 강화, fallback 로직 구현 |
| 이벤트 수집 누락 | 중 | 고 | 로컬 큐 + 재시도 메커니즘, 모니터링 강화 |
| 통계적 유의성 미달 | 중 | 중 | 실험 기간 연장, 샘플 사이즈 사전 계산 |
| 성능 저하 (로딩 시간 증가) | 중 | 고 | 조기 성능 테스트, 알고리즘 최적화 |
| 첫 실험 결과 부정적 | 중 | 중 | 즉시 롤백, 원인 분석 후 재설계 |
| Firebase 비용 급증 | 낮 | 중 | 일일 이벤트 수 모니터링, 쿼터 설정 |

---

## 8. 참고 자료

### 8.1 Firebase 공식 문서
- [Remote Config 가이드](https://firebase.google.com/docs/remote-config)
- [A/B Testing 가이드](https://firebase.google.com/docs/ab-testing)
- [Analytics 이벤트 로깅](https://firebase.google.com/docs/analytics/events)

### 8.2 통계 도구
- [Evan Miller's A/B Test Calculator](http://www.evanmiller.org/ab-testing/sample-size.html)
- [Optimizely Stats Engine](https://www.optimizely.com/stats-engine/)

### 8.3 Best Practices
- Google I/O: Firebase Remote Config for A/B Testing
- [Spotify's A/B Testing Platform](https://engineering.atspotify.com/2020/10/spotifys-new-experimentation-platform-part-1/)
- [Netflix: Experimentation Platform](https://netflixtechblog.com/its-all-a-bout-testing-the-netflix-experimentation-platform-4e1ca458c15)
