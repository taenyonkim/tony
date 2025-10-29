A/B 테스트는 Firebase의 Remote Config와 A/B Testing를 활용하여 구현하려고 해.
A/B 테스트를 위한 사용자 세그먼트 구분과 세그먼트 정보는 Firebase의 A/B Testing에서 결정을 해주고 클라이언트에 전달되는 구조로 알고 있어.

이 경우 A/B 테스트를 고려한 Firebase, 헬로우봇 API 서버, 추천 API 서버의 구조와 각 서버에서 수행해야 하는 역할에 대해 상세하게 설계해줘

# Firebase A/B Testing 통합 추천 시스템 아키텍처

## 목차

1. [Firebase A/B Testing 개요](#1-firebase-ab-testing-개요)
2. [전체 시스템 아키텍처](#2-전체-시스템-아키텍처)
3. [각 컴포넌트별 역할과 책임](#3-각-컴포넌트별-역할과-책임)
4. [상세 작업 흐름](#4-상세-작업-흐름)
5. [Firebase 설정 및 구현](#5-firebase-설정-및-구현)
6. [데이터 흐름 및 로깅](#6-데이터-흐름-및-로깅)
7. [구현 가이드](#7-구현-가이드)

---

## 1. Firebase A/B Testing 개요

### 1.1 Firebase A/B Testing의 작동 방식

Firebase A/B Testing은 **Remote Config**를 기반으로 작동합니다:

1. **실험 정의** (Firebase Console)

   - 실험 이름, 목표 지표 설정
   - 변형(Variants) 정의
   - 타겟팅 조건 설정

2. **사용자 할당** (Firebase SDK)

   - 앱 시작 시 Firebase SDK가 서버와 통신
   - 사용자가 자동으로 실험 그룹에 할당
   - Remote Config 값을 클라이언트로 전달

3. **지표 수집** (Firebase Analytics)
   - 앱에서 이벤트 로깅
   - Firebase Console에서 실시간 결과 확인

### 1.2 핵심 특징

- **클라이언트 기반 할당**: Firebase SDK가 사용자 그룹 결정
- **Remote Config 통합**: 실험 파라미터를 Remote Config로 전달
- **자동 지표 수집**: Firebase Analytics와 연동
- **통계 분석 자동화**: Firebase가 자동으로 유의성 검정

---

## 2. 전체 시스템 아키텍처

### 2.1 전체 구조도

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Firebase Cloud                              │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │              Firebase A/B Testing                          │    │
│  │  - 실험 정의 및 관리                                        │    │
│  │  - 사용자 그룹 할당 로직                                    │    │
│  │  - 통계 분석 엔진                                          │    │
│  └────────────────────┬───────────────────────────────────────┘    │
│                       │                                              │
│  ┌────────────────────▼───────────────────────────────────────┐    │
│  │              Remote Config                                 │    │
│  │  - 실험 파라미터 저장                                       │    │
│  │  - 클라이언트별 설정 값 전달                                │    │
│  └────────────────────┬───────────────────────────────────────┘    │
│                       │                                              │
│  ┌────────────────────▼───────────────────────────────────────┐    │
│  │              Firebase Analytics                            │    │
│  │  - 이벤트 수집 및 저장                                      │    │
│  │  - 실험 결과 집계                                          │    │
│  └────────────────────────────────────────────────────────────┘    │
└───────────────────────┬───────────────────────────────────────────┘
                        │
                        │ Firebase SDK
                        │
┌───────────────────────▼───────────────────────────────────────────┐
│                        Client (iOS/Android)                        │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  1. 앱 시작 시 Firebase SDK 초기화                         │  │
│  │     - Remote Config Fetch                                  │  │
│  │     - 실험 그룹 할당 수신                                   │  │
│  └─────────────────────┬──────────────────────────────────────┘  │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────────────┐  │
│  │  2. 추천 알고리즘 파라미터 확인                            │  │
│  │     recommendation_algorithm = Remote Config 값            │  │
│  └─────────────────────┬──────────────────────────────────────┘  │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────────────┐  │
│  │  3. 헬로우봇 API 호출 시 파라미터 전달                     │  │
│  │     GET /home-banner?algorithm={value}                     │  │
│  └─────────────────────┬──────────────────────────────────────┘  │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────────────┐  │
│  │  4. 사용자 행동 이벤트 로깅                                │  │
│  │     Firebase Analytics.logEvent()                          │  │
│  └────────────────────────────────────────────────────────────┘  │
└───────────────────────┬───────────────────────────────────────────┘
                        │
                        │ HTTPS
                        │
┌───────────────────────▼───────────────────────────���───────────────┐
│                   헬로우봇 서비스 API (NodeJS)                     │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  1. 클라이언트 요청 수신                                    │  │
│  │     - 사용자 인증                                           │  │
│  │     - algorithm 파라미터 추출                              │  │
│  └─────────────────────┬──────────────────────────────────────┘  │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────────────┐  │
│  │  2. 추천 API 호출                                          │  │
│  │     GET /recommendations?userId=X&algorithm=Y              │  │
│  └─────────────────────┬──────────────────────────────────────┘  │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────────────┐  │
│  │  3. 스킬 메타데이터 조합                                    │  │
│  │     - 추천 스킬 ID → 상세 정보 조회                         │  │
│  │     - 응답 포맷팅                                           │  │
│  └─────────────────────┬──────────────────────────────────────┘  │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────────────┐  │
│  │  4. 로깅 (서버 사이드)                                      │  │
│  │     - BigQuery에 추천 이벤트 기록                           │  │
│  │     - 실험 메타데이터 포함                                  │  │
│  └────────────────────────────────────────────────────────────┘  │
└───────────────────────┬───────────────────────────────────────────┘
                        │
                        │ Internal API
                        │
┌───────────────────────▼───────────────────────────────────────────┐
│                   추천 API 서버 (NodeJS/Python)                    │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  1. 알고리즘 파라미터 파싱                                  │  │
│  │     - algorithm 값 검증                                    │  │
│  │     - 지원하지 않는 알고리즘은 기본값으로 폴백              │  │
│  └─────────────────────┬──────────────────────────────────────┘  │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────────────┐  │
│  │  2. 캐시 확인                                              │  │
│  │     key: rec:{userId}:{algorithm}                          │  │
│  └─────────────────────┬──────────────────────────────────────┘  │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────────────┐  │
│  │  3. 알고리즘 실행                                          │  │
│  │     - Default / Popularity / Collaborative                 │  │
│  │     - 사용자 컨텍스트 기반 추천                             │  │
│  └─────────────────────┬──────────────────────────────────────┘  │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────────────┐  │
│  │  4. 추천 결과 반환                                         │  │
│  │     { skillIds: [...], algorithm: 'popularity_v1' }        │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 각 컴포넌트별 역할과 책임

### 3.1 Firebase (Cloud)

#### ✅ **역할**

1. **실험 설계 및 관리**

   - Firebase Console에서 A/B 테스트 생성
   - 실험 그룹(Variants) 정의
   - 타겟팅 조건 설정 (국가, 앱 버전, 사용자 속성 등)

2. **사용자 그룹 할당**

   - 사용자 ID 기반 결정론적 해싱
   - 실험 그룹별 비율 적용 (예: 33%/33%/34%)
   - 같은 사용자는 항상 같은 그룹 유지

3. **설정 값 전달 (Remote Config)**

   - 실험 그룹별 파라미터 값 저장
   - 클라이언트 요청 시 해당 그룹의 설정 값 반환

4. **이벤트 수집 및 분석**
   - Firebase Analytics 이벤트 수신
   - 그룹별 지표 집계
   - 통계적 유의성 자동 계산

#### ❌ **하지 않는 것**

- 추천 알고리즘 실행 (추천 API 서버 담당)
- 스킬 메타데이터 관리 (헬로우봇 API 서버 담당)
- 비즈니스 로직 처리

---

### 3.2 Client (iOS/Android)

#### ✅ **역할**

1. **Firebase 초기화 및 설정 수신**

   ```swift
   // iOS 예시
   func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       FirebaseApp.configure()

       // Remote Config Fetch
       let remoteConfig = RemoteConfig.remoteConfig()
       remoteConfig.fetch(withExpirationDuration: 3600) { status, error in
           if status == .success {
               remoteConfig.activate()
           }
       }

       return true
   }
   ```

2. **실험 파라미터 읽기**

   ```swift
   func getRecommendationAlgorithm() -> String {
       let remoteConfig = RemoteConfig.remoteConfig()
       let algorithm = remoteConfig["home_banner_algorithm"].stringValue ?? "default_v1"
       return algorithm
   }
   ```

3. **API 호출 시 파라미터 전달**

   ```swift
   func fetchHomeBanner() {
       let algorithm = getRecommendationAlgorithm()

       let url = "https://api.hellobot.com/v1/home-banner"
       let params = [
           "userId": currentUserId,
           "algorithm": algorithm  // Firebase에서 받은 값
       ]

       APIClient.get(url, parameters: params) { response in
           // 처리
       }
   }
   ```

4. **사용자 행동 이벤트 로깅**

   ```swift
   // 노출 이벤트
   func logSkillImpression(skillId: String, position: Int) {
       Analytics.logEvent("skill_impression", parameters: [
           "skill_id": skillId,
           "position": position,
           "surface": "home_banner",
           "algorithm": getRecommendationAlgorithm()
       ])
   }

   // 클릭 이벤트
   func logSkillClick(skillId: String) {
       Analytics.logEvent("skill_click", parameters: [
           "skill_id": skillId,
           "surface": "home_banner",
           "algorithm": getRecommendationAlgorithm()
       ])
   }

   // 구매 이벤트 (Firebase 표준 이벤트)
   func logPurchase(skillId: String, price: Double) {
       Analytics.logEvent(AnalyticsEventPurchase, parameters: [
           AnalyticsParameterItemID: skillId,
           AnalyticsParameterValue: price,
           AnalyticsParameterCurrency: "KRW",
           "surface": "home_banner",
           "algorithm": getRecommendationAlgorithm()
       ])
   }
   ```

#### ❌ **하지 않는 것**

- 추천 알고리즘 실행
- 사용자 그룹 할당 결정 (Firebase가 자동 처리)
- 실험 결과 분석

---

### 3.3 헬로우봇 서비스 API (NodeJS)

#### ✅ **역할**

1. **클라이언트 요청 처리**

   ```javascript
   // routes/homeBanner.js
   router.get("/v1/home-banner", authenticate, async (req, res) => {
     const { userId } = req.user;
     const algorithm = req.query.algorithm || "default_v1";

     try {
       // 1. 추천 API 호출
       const recommendations = await recommendationService.getRecommendations({
         userId,
         algorithm,
         surface: "home_banner",
         limit: 20,
       });

       // 2. 스킬 메타데이터 조합
       const enrichedSkills = await enrichSkillMetadata(
         recommendations.skillIds
       );

       // 3. 응답 포맷팅
       res.json({
         skills: enrichedSkills,
         meta: {
           algorithm: algorithm,
           generatedAt: new Date().toISOString(),
         },
       });

       // 4. 서버 사이드 로깅 (비동기)
       logRecommendationEvent({
         userId,
         algorithm,
         skillIds: recommendations.skillIds,
         timestamp: new Date(),
       });
     } catch (error) {
       logger.error("Home banner error", { error, userId, algorithm });

       // 폴백: 기본 알고리즘으로 재시도
       const fallbackRecs = await recommendationService.getRecommendations({
         userId,
         algorithm: "default_v1",
         surface: "home_banner",
         limit: 20,
       });

       const enrichedSkills = await enrichSkillMetadata(fallbackRecs.skillIds);
       res.json({ skills: enrichedSkills });
     }
   });
   ```

2. **스킬 메타데이터 조합**

   ```javascript
   async function enrichSkillMetadata(skillIds) {
     const skills = await db.skills.findMany({
       where: { id: { in: skillIds } },
       select: {
         id: true,
         title: true,
         description: true,
         thumbnailUrl: true,
         price: true,
         category: true,
         author: true,
         rating: true,
       },
     });

     // skillIds 순서 유지
     return skillIds
       .map((id) => skills.find((s) => s.id === id))
       .filter(Boolean);
   }
   ```

3. **서버 사이드 로깅 (BigQuery)**

   ```javascript
   async function logRecommendationEvent(data) {
     await bigquery.insert("recommendation_events", {
       timestamp: data.timestamp,
       user_id: data.userId,
       algorithm: data.algorithm,
       skill_ids: data.skillIds,
       surface: "home_banner",
       session_id: data.sessionId,
     });
   }
   ```

4. **에러 처리 및 폴백**
   - 추천 API 타임아웃 시 캐시된 결과 사용
   - 알 수 없는 알고리즘은 기본값으로 대체
   - 에러 발생 시 사용자 경험 보호

#### ❌ **하지 않는 것**

- 추천 알고리즘 구현 (추천 API 서버 담당)
- 실험 그룹 할당 (Firebase 담당)
- A/B 테스트 결과 분석

---

### 3.4 추천 API 서버 (NodeJS/Python)

#### ✅ **역할**

1. **알고리즘 파라미터 검증 및 매핑**

   ```javascript
   class AlgorithmValidator {
     static SUPPORTED_ALGORITHMS = {
       default_v1: "default",
       popularity_v1: "popularity",
       collaborative_v1: "collaborative",
       // Firebase 실험에서 설정한 값들
     };

     static validate(algorithmParam) {
       if (this.SUPPORTED_ALGORITHMS[algorithmParam]) {
         return this.SUPPORTED_ALGORITHMS[algorithmParam];
       }

       logger.warn("Unknown algorithm, fallback to default", {
         requestedAlgorithm: algorithmParam,
       });

       return "default";
     }
   }
   ```

2. **추천 알고리즘 실행**

   ```javascript
   router.get("/recommendations", async (req, res) => {
     const { userId, algorithm, surface, limit = 20 } = req.query;

     // 알고리즘 검증
     const validatedAlgorithm = AlgorithmValidator.validate(algorithm);

     // 캐시 확인
     const cacheKey = `rec:${userId}:${surface}:${validatedAlgorithm}`;
     const cached = await redis.get(cacheKey);
     if (cached) {
       return res.json(JSON.parse(cached));
     }

     // 사용자 컨텍스트 로드
     const userContext = await loadUserContext(userId);

     // 알고리즘 실행
     const engine = new RecommendationEngine();
     const recommendations = await engine.execute(
       validatedAlgorithm,
       userContext,
       { limit }
     );

     // 캐싱
     await redis.setex(cacheKey, 1800, JSON.stringify(recommendations));

     res.json({
       skillIds: recommendations.map((r) => r.skillId),
       algorithm: validatedAlgorithm,
       scores: recommendations.map((r) => r.score),
     });
   });
   ```

3. **캐싱 전략**

   - 사용자별 + 알고리즘별 캐시
   - TTL: 30분
   - 캐시 키 구조: `rec:{userId}:{surface}:{algorithm}`

4. **성능 모니터링**

   ```javascript
   async function executeWithMetrics(algorithm, userContext) {
     const startTime = Date.now();

     try {
       const result = await algorithm.recommend(userContext);

       const duration = Date.now() - startTime;
       metrics.histogram("recommendation.latency", duration, {
         algorithm: algorithm.name,
       });

       return result;
     } catch (error) {
       metrics.increment("recommendation.error", {
         algorithm: algorithm.name,
         error: error.message,
       });
       throw error;
     }
   }
   ```

#### ❌ **하지 않는 것**

- 실험 그룹 할당 (Firebase 담당)
- 클라이언트 인증/인가 (헬로우봇 API 담당)
- 스킬 메타데이터 조합 (헬로우봇 API 담당)
- Firebase Analytics 이벤트 로깅 (클라이언트 담당)

---

## 4. 상세 작업 흐름

### 4.1 전체 시퀀스 다이어그램

```
사용자 → Client → Firebase → 헬로우봇 API → 추천 API → BigQuery
                                                    ↓
                                              Firebase Analytics
```

### 4.2 단계별 상세 흐름

#### **Phase 1: 앱 시작 및 초기화**

```
┌──────────┐                 ┌─────────────┐
│ Client   │                 │  Firebase   │
└────┬─────┘                 └──────┬──────┘
     │                              │
     │  1. FirebaseApp.configure()  │
     │─────────────────────────────>│
     │                              │
     │  2. Remote Config Fetch      │
     │─────────────────────────────>│
     │                              │
     │         3. 사용자 그룹 할당    │
     │         (서버 사이드)         │
     │                              │
     │  4. Config 값 반환           │
     │<─────────────────────────────│
     │  {                           │
     │    "home_banner_algorithm":  │
     │      "popularity_v1"         │
     │  }                           │
     │                              │
     │  5. Config 활성화            │
     │  remoteConfig.activate()     │
     │                              │
```

**상세 설명**:

1. **앱 시작 시 Firebase 초기화**

   - `FirebaseApp.configure()` 호출
   - Google Services 파일 로드

2. **Remote Config Fetch**

   - Firebase 서버에 현재 설정 요청
   - 사용자 속성 전달 (userId, 앱 버전 등)

3. **사용자 그룹 할당 (Firebase 서버)**

   - Firebase가 내부적으로 해시 기반 할당
   - 실험 설정에 따라 그룹별 비율 적용
   - 예: user_hash % 100 < 33 → Control
   - 예: 33 ≤ user_hash % 100 < 66 → Variant A
   - 예: 66 ≤ user_hash % 100 → Variant B

4. **Config 값 반환**

   - 할당된 그룹의 파라미터 값 반환
   - 예: Control → "default_v1"
   - 예: Variant A → "popularity_v1"
   - 예: Variant B → "collaborative_v1"

5. **Config 활성화**
   - 앱 메모리에 설정 값 저장
   - 이후 즉시 사용 가능

---

#### **Phase 2: 홈 화면 진입 및 추천 요청**

```
┌──────────┐   ┌────────────────┐   ┌──────────────┐   ┌───────────┐
│ Client   │   │ 헬로우봇 API    │   │ 추천 API     │   │  Redis    │
└────┬─────┘   └───────┬────────┘   └──────┬───────┘   └─────┬─────┘
     │                 │                    │                 │
     │ 1. Remote Config에서 알고리즘 읽기   │                 │
     │ algorithm = "popularity_v1"         │                 │
     │                 │                    │                 │
     │ 2. GET /home-banner?algorithm=popularity_v1          │
     │────────────────>│                    │                 │
     │                 │                    │                 │
     │                 │ 3. GET /recommendations?            │
     │                 │    userId=123&algorithm=popularity_v1
     │                 │───────────────────>│                 │
     │                 │                    │                 │
     │                 │                    │ 4. 캐시 조회    │
     │                 │                    │────────────────>│
     │                 │                    │                 │
     │                 │                    │ 5. Cache Miss   │
     │                 │                    │<────────────────│
     │                 │                    │                 │
     │                 │                    │ 6. 알고리즘 실행 │
     │                 │                    │ (Popularity)    │
     │                 │                    │                 │
     │                 │  7. 추천 결과      │                 │
     │                 │<───────────────────│                 │
     │                 │  [skill1, skill2,...]               │
     │                 │                    │                 │
     │                 │ 8. 스킬 메타데이터 조합              │
     │                 │ (DB 조회)          │                 │
     │                 │                    │                 │
     │  9. 응답 반환   │                    │                 │
     │<────────────────│                    │                 │
     │  {              │                    │                 │
     │    skills: [...],                    │                 │
     │    meta: {      │                    │                 │
     │      algorithm: "popularity_v1"      │                 │
     │    }            │                    │                 │
     │  }              │                    │                 │
```

---

#### **Phase 3: 사용자 행동 이벤트 로깅**

```
┌──────────┐                 ┌──────────────────┐
│ Client   │                 │ Firebase         │
└────┬─────┘                 │ Analytics        │
     │                       └────────┬─────────┘
     │                                │
     │ 1. 스킬 노출 (Impression)       │
     │ Analytics.logEvent(            │
     │   "skill_impression",           │
     │   {                             │
     │     skill_id: "skill_789",      │
     │     position: 1,                │
     │     algorithm: "popularity_v1"  │
     │   }                             │
     │ )                               │
     │────────────────────────────────>│
     │                                │
     │ 2. 스킬 클릭                    │
     │ Analytics.logEvent(            │
     │   "skill_click",                │
     │   { skill_id: "skill_789", ... }│
     │ )                               │
     │────────────────────────────────>│
     │                                │
     │ 3. 구매 완료                    │
     │ Analytics.logEvent(            │
     │   "purchase",                   │
     │   {                             │
     │     item_id: "skill_789",       │
     │     value: 15000,               │
     │     currency: "KRW",            │
     │     algorithm: "popularity_v1"  │
     │   }                             │
     │ )                               │
     │────────────────────────────────>│
     │                                │
     │                      4. Firebase가 자동으로
     │                         실험 그룹별 집계
```

---

## 5. Firebase 설정 및 구현

### 5.1 Firebase Console 실험 설정

#### Step 1: 새 실험 만들기

**Firebase Console > A/B Testing > 실험 만들기**

```yaml
실험 이름: home_banner_algorithm_test_2025_01
실험 설명: 홈 배너 추천 알고리즘 비교 (Default vs Popularity vs Collaborative)

타겟팅:
  앱: HelloBot (iOS/Android)
  사용자 기준:
    - 국가: 대한민국
    - 앱 버전: >= 3.5.0
    - 사용자 속성: has_made_purchase = true
  사용자 비율: 100%

목표:
  주요 지표: purchase (구매 전환)
  보조 지표:
    - skill_click (클릭)
    - session_duration (세션 시간)

변형(Variants):
  - Control (Baseline): 33%
    Remote Config:
      home_banner_algorithm: "default_v1"

  - Variant A: 33%
    Remote Config:
      home_banner_algorithm: "popularity_v1"

  - Variant B: 34%
    Remote Config:
      home_banner_algorithm: "collaborative_v1"

기간: 2025-01-25 ~ 2025-02-25 (1개월)
```

#### Step 2: Remote Config 파라미터 정의

**Firebase Console > Remote Config**

```json
{
  "home_banner_algorithm": {
    "defaultValue": "default_v1",
    "description": "홈 배너 추천 알고리즘 선택",
    "valueType": "STRING"
  }
}
```

---

### 5.2 클라이언트 구현 (iOS - Swift)

#### Step 1: Firebase SDK 초기화

```swift
// AppDelegate.swift
import UIKit
import Firebase
import FirebaseRemoteConfig

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Firebase 초기화
        FirebaseApp.configure()

        // Remote Config 설정
        setupRemoteConfig()

        return true
    }

    private func setupRemoteConfig() {
        let remoteConfig = RemoteConfig.remoteConfig()

        // 개발 시 빠른 갱신 (프로덕션에서는 3600 권장)
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings

        // 기본값 설정
        remoteConfig.setDefaults([
            "home_banner_algorithm": "default_v1" as NSString
        ])

        // Remote Config Fetch
        remoteConfig.fetch { status, error in
            if status == .success {
                remoteConfig.activate { changed, error in
                    print("Remote Config activated")
                }
            } else {
                print("Remote Config fetch failed: \(error?.localizedDescription ?? "")")
            }
        }
    }
}
```

#### Step 2: Remote Config 값 읽기

```swift
// RemoteConfigManager.swift
import FirebaseRemoteConfig

class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    private let remoteConfig = RemoteConfig.remoteConfig()

    private init() {}

    var homeBannerAlgorithm: String {
        return remoteConfig["home_banner_algorithm"].stringValue ?? "default_v1"
    }

    func refreshConfig(completion: @escaping (Bool) -> Void) {
        remoteConfig.fetch { status, error in
            if status == .success {
                self.remoteConfig.activate { _, _ in
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }
}
```

#### Step 3: API 호출 시 알고리즘 전달

```swift
// HomeBannerService.swift
import Foundation

class HomeBannerService {
    private let apiClient = APIClient.shared

    func fetchHomeBanner(completion: @escaping (Result<[Skill], Error>) -> Void) {
        // Firebase Remote Config에서 알고리즘 읽기
        let algorithm = RemoteConfigManager.shared.homeBannerAlgorithm

        let endpoint = "/v1/home-banner"
        let params: [String: Any] = [
            "userId": UserSession.shared.userId,
            "algorithm": algorithm,
            "limit": 20
        ]

        apiClient.get(endpoint, parameters: params) { result in
            switch result {
            case .success(let data):
                let skills = try? JSONDecoder().decode([Skill].self, from: data)
                completion(.success(skills ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
```

#### Step 4: 이벤트 로깅

```swift
// AnalyticsManager.swift
import FirebaseAnalytics

class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    // 노출 이벤트
    func logSkillImpression(skillId: String, position: Int, surface: String = "home_banner") {
        let algorithm = RemoteConfigManager.shared.homeBannerAlgorithm

        Analytics.logEvent("skill_impression", parameters: [
            "skill_id": skillId,
            "position": position,
            "surface": surface,
            "algorithm": algorithm,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    // 클릭 이벤트
    func logSkillClick(skillId: String, surface: String = "home_banner") {
        let algorithm = RemoteConfigManager.shared.homeBannerAlgorithm

        Analytics.logEvent("skill_click", parameters: [
            "skill_id": skillId,
            "surface": surface,
            "algorithm": algorithm
        ])
    }

    // 구매 이벤트 (Firebase 표준 이벤트)
    func logPurchase(skillId: String, skillName: String, price: Double) {
        let algorithm = RemoteConfigManager.shared.homeBannerAlgorithm

        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: skillId,
            AnalyticsParameterItemName: skillName,
            AnalyticsParameterValue: price,
            AnalyticsParameterCurrency: "KRW",
            "algorithm": algorithm,
            "surface": "home_banner"
        ])
    }

    // 스킬 리스트 노출 (배치 로깅)
    func logSkillListImpression(skills: [Skill], surface: String = "home_banner") {
        for (index, skill) in skills.enumerated() {
            logSkillImpression(skillId: skill.id, position: index + 1, surface: surface)
        }
    }
}
```

#### Step 5: UI에서 이벤트 로깅 호출

```swift
// HomeBannerViewController.swift
import UIKit

class HomeBannerViewController: UIViewController {
    private var skills: [Skill] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        loadHomeBanner()
    }

    private func loadHomeBanner() {
        HomeBannerService().fetchHomeBanner { [weak self] result in
            switch result {
            case .success(let skills):
                self?.skills = skills
                self?.collectionView.reloadData()

                // 노출 이벤트 로깅
                AnalyticsManager.shared.logSkillListImpression(skills: skills)

            case .failure(let error):
                print("Error loading home banner: \(error)")
            }
        }
    }
}

extension HomeBannerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                       didSelectItemAt indexPath: IndexPath) {
        let skill = skills[indexPath.row]

        // 클릭 이벤트 로깅
        AnalyticsManager.shared.logSkillClick(skillId: skill.id)

        // 스킬 상세 화면으로 이동
        navigateToSkillDetail(skill: skill)
    }
}
```

---

### 5.3 헬로우봇 API 서버 구현 (NodeJS)

```javascript
// routes/homeBanner.js
const express = require("express");
const router = express.Router();
const { authenticate } = require("../middleware/auth");
const recommendationService = require("../services/recommendationService");
const skillService = require("../services/skillService");
const logger = require("../utils/logger");
const { logToBigQuery } = require("../utils/bigquery");

router.get("/v1/home-banner", authenticate, async (req, res) => {
  const { userId } = req.user;
  const algorithm = req.query.algorithm || "default_v1";
  const limit = parseInt(req.query.limit) || 20;

  const startTime = Date.now();

  try {
    logger.info("Home banner request", { userId, algorithm });

    // 1. 추천 API 호출
    const recommendations = await recommendationService.getRecommendations({
      userId,
      algorithm,
      surface: "home_banner",
      limit,
    });

    // 2. 스킬 메타데이터 조합
    const enrichedSkills = await skillService.enrichMetadata(
      recommendations.skillIds
    );

    const duration = Date.now() - startTime;

    // 3. 응답 반환
    res.json({
      skills: enrichedSkills,
      meta: {
        algorithm: algorithm,
        count: enrichedSkills.length,
        generatedAt: new Date().toISOString(),
        processingTime: duration,
      },
    });

    // 4. 서버 사이드 로깅 (비동기)
    setImmediate(() => {
      logToBigQuery("recommendation_events", {
        timestamp: new Date(),
        user_id: userId,
        algorithm: algorithm,
        skill_ids: recommendations.skillIds,
        surface: "home_banner",
        processing_time_ms: duration,
        session_id: req.sessionId,
      }).catch((err) => {
        logger.error("BigQuery logging failed", { error: err });
      });
    });
  } catch (error) {
    logger.error("Home banner error", {
      error: error.message,
      userId,
      algorithm,
    });

    // 폴백: 기본 알고리즘으로 재시도
    try {
      const fallbackRecs = await recommendationService.getRecommendations({
        userId,
        algorithm: "default_v1",
        surface: "home_banner",
        limit,
      });

      const enrichedSkills = await skillService.enrichMetadata(
        fallbackRecs.skillIds
      );

      res.json({
        skills: enrichedSkills,
        meta: {
          algorithm: "default_v1",
          fallback: true,
        },
      });
    } catch (fallbackError) {
      logger.error("Fallback also failed", { error: fallbackError });
      res.status(500).json({
        error: "Failed to generate recommendations",
      });
    }
  }
});

module.exports = router;
```

---

### 5.4 추천 API 서버 구현 (NodeJS)

```javascript
// routes/recommendations.js
const express = require("express");
const router = express.Router();
const redis = require("../utils/redis");
const AlgorithmValidator = require("../utils/algorithmValidator");
const RecommendationEngine = require("../engines/recommendationEngine");
const { loadUserContext } = require("../services/userService");
const logger = require("../utils/logger");

router.get("/recommendations", async (req, res) => {
  const { userId, algorithm, surface, limit = 20 } = req.query;

  if (!userId || !algorithm) {
    return res.status(400).json({
      error: "userId and algorithm are required",
    });
  }

  const startTime = Date.now();

  try {
    // 1. 알고리즘 검증
    const validatedAlgorithm = AlgorithmValidator.validate(algorithm);

    // 2. 캐시 확인
    const cacheKey = `rec:${userId}:${surface}:${validatedAlgorithm}`;
    const cached = await redis.get(cacheKey);

    if (cached) {
      const data = JSON.parse(cached);
      logger.info("Cache hit", { userId, algorithm: validatedAlgorithm });

      return res.json({
        ...data,
        fromCache: true,
        processingTime: Date.now() - startTime,
      });
    }

    // 3. 사용자 컨텍스트 로드
    const userContext = await loadUserContext(userId);

    // 4. 알고리즘 실행
    const engine = new RecommendationEngine();
    const recommendations = await engine.execute(
      validatedAlgorithm,
      userContext,
      { limit: parseInt(limit) }
    );

    const result = {
      skillIds: recommendations.map((r) => r.skillId),
      scores: recommendations.map((r) => r.score),
      algorithm: validatedAlgorithm,
      generatedAt: new Date().toISOString(),
    };

    // 5. 캐싱 (30분)
    await redis.setex(cacheKey, 1800, JSON.stringify(result));

    const duration = Date.now() - startTime;

    res.json({
      ...result,
      fromCache: false,
      processingTime: duration,
    });

    logger.info("Recommendation generated", {
      userId,
      algorithm: validatedAlgorithm,
      count: recommendations.length,
      duration,
    });
  } catch (error) {
    logger.error("Recommendation error", {
      error: error.message,
      userId,
      algorithm,
    });

    res.status(500).json({
      error: "Failed to generate recommendations",
      message: error.message,
    });
  }
});

module.exports = router;
```

---

## 6. 데이터 흐름 및 로깅

### 6.1 데이터 흐름 요약

```
1. Firebase → Client
   - Remote Config 값 전달 (algorithm 파라미터)

2. Client → 헬로우봇 API
   - algorithm 파라미터 포함한 추천 요청

3. 헬로우봇 API → 추천 API
   - 알고리즘 실행 요청

4. 추천 API → Redis/BigQuery
   - 사용자 컨텍스트 조회, 결과 캐싱

5. Client → Firebase Analytics
   - 사용자 행동 이벤트 로깅

6. 헬로우봇 API → BigQuery
   - 서버 사이드 추천 이벤트 로깅
```

### 6.2 로깅 전략

#### **클라이언트 로깅 (Firebase Analytics)**

**목적**: 사용자 행동 추적, A/B 테스트 지표 수집

**이벤트**:

- `skill_impression`: 스킬 노출
- `skill_click`: 스킬 클릭
- `purchase`: 구매 완료

**필수 파라미터**:

- `skill_id`: 스킬 ID
- `algorithm`: 사용된 알고리즘
- `surface`: 노출 지면 (home_banner)

#### **서버 로깅 (BigQuery)**

**목적**: 추천 시스템 성능 분석, 디버깅

**테이블**: `recommendation_events`

```sql
CREATE TABLE recommendation_events (
  timestamp TIMESTAMP,
  user_id STRING,
  algorithm STRING,
  skill_ids ARRAY<STRING>,
  surface STRING,
  processing_time_ms INT64,
  from_cache BOOL,
  session_id STRING
)
PARTITION BY DATE(timestamp)
CLUSTER BY user_id, algorithm;
```

---

## 7. 구현 가이드

### 7.1 구현 순서

#### Phase 1: Firebase 설정 (1일)

- [ ] Firebase Console에서 A/B 테스트 생성
- [ ] Remote Config 파라미터 정의
- [ ] 실험 그룹 및 비율 설정

#### Phase 2: 클라이언트 구현 (3일)

- [ ] Firebase SDK 통합
- [ ] Remote Config 읽기 로직
- [ ] API 호출 시 algorithm 파라미터 전달
- [ ] Firebase Analytics 이벤트 로깅

#### Phase 3: 헬로우봇 API 수정 (2일)

- [ ] algorithm 파라미터 수신 처리
- [ ] 추천 API 호출 로직 수정
- [ ] 에러 처리 및 폴백

#### Phase 4: 추천 API 구현 (5일)

- [ ] 알고리즘 검증 로직
- [ ] 캐싱 전략 구현
- [ ] 알고리즘 실행 엔진

#### Phase 5: 모니터링 및 테스트 (3일)

- [ ] BigQuery 로깅 검증
- [ ] Firebase Analytics 이벤트 확인
- [ ] E2E 테스트
- [ ] 성능 테스트

### 7.2 체크리스트

#### Firebase 설정

- [ ] Remote Config 파라미터가 올바르게 설정되었는가?
- [ ] A/B 테스트 그룹 비율이 정확한가?
- [ ] 목표 지표가 올바르게 설정되었는가?

#### 클라이언트

- [ ] Firebase SDK가 올바르게 초기화되는가?
- [ ] Remote Config 값을 정확히 읽어오는가?
- [ ] 모든 이벤트가 로깅되는가?

#### 서버

- [ ] 알 수 없는 algorithm 파라미터 처리가 되는가?
- [ ] 추천 API 타임아웃 처리가 되는가?
- [ ] 캐시가 올바르게 작동하는가?

### 7.3 주의사항

1. **Firebase Remote Config 캐싱**

   - 클라이언트는 설정을 로컬에 캐시
   - 실험 변경 후 즉시 반영되지 않을 수 있음
   - `minimumFetchInterval` 설정 주의

2. **알고리즘 파라미터 검증**

   - 클라이언트에서 전달된 값을 항상 검증
   - 지원하지 않는 알고리즘은 기본값으로 폴백

3. **이벤트 로깅 필수 파라미터**

   - 모든 이벤트에 `algorithm` 포함
   - Firebase가 자동으로 실험 그룹과 연결

4. **실험 기간 중 변경 금지**
   - 실험 실행 중 그룹 비율 변경 X
   - 알고리즘 로직 변경 X
   - 통계적 유의성에 영향

---

## 결론

Firebase A/B Testing을 활용하면:

✅ **장점**:

- 사용자 그룹 할당 자동화
- 통계 분석 자동화
- 클라이언트 기반 실험으로 빠른 적용
- Remote Config로 유연한 파라미터 관리

✅ **역할 분담 명확화**:

- **Firebase**: 실험 관리, 그룹 할당, 이벤트 수집
- **Client**: Remote Config 읽기, 이벤트 로깅
- **헬로우봇 API**: 요청 라우팅, 메타데이터 조합
- **추천 API**: 알고리즘 실행, 캐싱

이 아키텍처를 통해 추천 알고리즘 A/B 테스트를 효율적으로 수행할 수 있습니다.
