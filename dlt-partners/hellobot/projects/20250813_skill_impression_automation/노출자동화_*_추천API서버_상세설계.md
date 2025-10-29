추천 API 서버를 두는 구조로 구현한다고 할 때 추천 API 서버가 수행해야 하는 일에 대해서 정리해서 알려줘
전체 구조를 그리고, 어떤 작업들이 수행되는지 구체적으로 순차적으로 설명해줘

위 분석을 수행할 때 구체화 되어야 하는 부분이 있다면 해당 부분에 대해 어떤식의 구체화가 필요한지도 추가로 정리해줘

# 추천 API 서버 상세 설계

## 목차

1. [전체 아키텍처](#1-전체-아키텍처)
2. [추천 API 서버의 역할과 책임](#2-추천-api-서버의-역할과-책임)
3. [상세 작업 흐름](#3-상세-작업-흐름)
4. [API 스펙 정의](#4-api-스펙-정의)
5. [데이터 모델](#5-데이터-모델)
6. [구체화 필요 항목](#6-구체화-필요-항목)

---

## 1. 전체 아키텍처

### 1.1 시스템 구성도

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                             │
│  [iOS App] [Android App] [Web]                                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTPS
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                   헬로우봇 서비스 API (NodeJS)                     │
│  - 사용자 인증/인가                                                │
│  - 비즈니스 로직 처리                                              │
│  - 응답 조합 및 포맷팅                                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ GET /api/recommendations/home-banner
                             │     ?userId={userId}
                             │     &experimentGroup={group}
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                   추천 API 서버 (NodeJS/Python)                   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              API Gateway Layer                          │   │
│  │  - 요청 검증 (Validation)                               │   │
│  │  - 인증 확인 (Authentication)                           │   │
│  │  - Rate Limiting                                        │   │
│  │  - 로깅 및 메트릭 수집                                   │   │
│  └───────────────────────┬─────────────────────────────────┘   │
│                          │                                       │
│  ┌───────────────────────▼─────────────────────────────────┐   │
│  │         Recommendation Service Layer                    │   │
│  │                                                          │   │
│  │  1. A/B Test Router                                     │   │
│  │     └─ 실험 그룹 결정 및 알고리즘 선택                   │   │
│  │                                                          │   │
│  │  2. Cache Manager                                       │   │
│  │     └─ Redis 캐시 조회/저장                             │   │
│  │                                                          │   │
│  │  3. Algorithm Selector                                  │   │
│  │     ├─ Default Algorithm                                │   │
│  │     ├─ Popularity Algorithm                             │   │
│  │     └─ Collaborative Filtering Algorithm                │   │
│  │                                                          │   │
│  │  4. User Context Loader                                 │   │
│  │     └─ 사용자 프로필, 이력 로드                          │   │
│  │                                                          │   │
│  │  5. Ranking Engine                                      │   │
│  │     └─ 후보 스킬 점수 계산 및 정렬                       │   │
│  │                                                          │   │
│  │  6. Re-ranking & Filtering                              │   │
│  │     ├─ 비즈니스 규칙 적용                                │   │
│  │     ├─ 다양성 확보                                       │   │
│  │     └─ 이미 본 스킬 제외                                 │   │
│  │                                                          │   │
│  │  7. Response Builder                                    │   │
│  │     └─ 최종 응답 포맷팅                                  │   │
│  └───────────────────────┬─────────────────────────────────┘   │
└────────────────────────────┼─────────────────────────────────────┘
                             │
                             │ (데이터 레이어 접근)
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ↓                    ↓                    ↓
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    Redis     │    │   BigQuery   │    │  PostgreSQL  │
│              │    │              │    │              │
│ - 캐시        │    │ - 사용자 행동 │    │ - 스킬 메타  │
│ - 세션 데이터  │    │ - 통계 데이터 │    │ - 실험 설정  │
│ - 추천 결과   │    │ - 배치 집계   │    │ - 알고리즘   │
└──────────────┘    └──────────────┘    └──────────────┘
```

---

## 2. 추천 API 서버의 역할과 책임

### 2.1 핵심 역할

#### 1️⃣ **실험 관리 (A/B Test Orchestration)**

- 사용자를 실험 그룹에 할당
- 그룹별 알고리즘 매핑 관리
- 실험 메타데이터 추적

#### 2️⃣ **추천 알고리즘 실행**

- 다양한 추천 전략 구현 및 실행
- 사용자 컨텍스트 기반 개인화
- 실시간 점수 계산

#### 3️⃣ **성능 최적화**

- 캐싱 전략 구현
- 응답 시간 100ms 이내 보장
- 병렬 처리 및 배치 최적화

#### 4️⃣ **데이터 수집 및 로깅**

- 추천 결과 로깅 (impression)
- 알고리즘 성능 메트릭 수집
- A/B 테스트 데이터 기록

#### 5️⃣ **비즈니스 규칙 적용**

- 운영�� 큐레이션 반영
- 부스팅/필터링 규칙 적용
- 다양성 및 공정성 보장

---

## 3. 상세 작업 흐름

### 3.1 전체 플로우 다이어그램

```
[요청 수신] → [검증] → [A/B 그룹 결정] → [캐시 확인] → [알고리즘 실행]
   → [재랭킹] → [응답 생성] → [로깅] → [응답 반환]
```

### 3.2 단계별 상세 작업

---

#### **Step 1: 요청 수신 및 검증 (Request Validation)**

**입력**:

```http
GET /api/v1/recommendations/home-banner?userId=user123&limit=20&context=morning
Authorization: Bearer {token}
```

**처리 작업**:

1. API 엔드포인트 라우팅
2. 요청 파라미터 파싱
3. 필수 파라미터 검증
   - userId: 필수
   - limit: 선택 (기본값: 20)
   - context: 선택 (시간대, 디바이스 등)
4. 인증 토큰 검증 (서비스 API에서 이미 처리된 경우 생략 가능)
5. Rate Limiting 체크
   - 사용자당 초당 최대 요청수 제한

**출력**: 검증된 요청 객체

**에러 처리**:

- 400 Bad Request: 잘못된 파라미터
- 401 Unauthorized: 인증 실패
- 429 Too Many Requests: Rate Limit 초과

---

#### **Step 2: A/B 테스트 그룹 결정 (Experiment Assignment)**

**입력**: userId

**처리 작업**:

1. **실험 설정 조회**

   ```javascript
   const experiment = await db.getActiveExperiment("home_banner");
   // {
   //   id: 'exp_001',
   //   name: 'home_banner_algorithm_test',
   //   startDate: '2025-01-20',
   //   endDate: '2025-02-20',
   //   groups: [
   //     { name: 'control', ratio: 0.33, algorithm: 'default_v1' },
   //     { name: 'variant_a', ratio: 0.33, algorithm: 'popularity_v1' },
   //     { name: 'variant_b', ratio: 0.34, algorithm: 'collaborative_v1' }
   //   ]
   // }
   ```

2. **사용자 그룹 할당**

   ```javascript
   // 결정론적 해싱 (같은 사용자는 항상 같은 그룹)
   function assignUserToGroup(userId, experiment) {
     const hash = hashFunction(userId + experiment.id);
     const normalized = hash % 100;

     if (normalized < 33) return "control";
     else if (normalized < 66) return "variant_a";
     else return "variant_b";
   }
   ```

3. **알고리즘 매핑**
   ```javascript
   const group = assignUserToGroup(userId, experiment);
   const algorithm = experiment.groups.find((g) => g.name === group).algorithm;
   // algorithm = 'popularity_v1'
   ```

**출력**:

- experimentId: 'exp_001'
- groupName: 'variant_a'
- algorithmId: 'popularity_v1'

---

#### **Step 3: 캐시 확인 (Cache Lookup)**

**입력**:

- userId
- algorithmId
- context (선택적)

**처리 작업**:

1. **캐시 키 생성**

   ```javascript
   const cacheKey = `rec:${userId}:home_banner:${algorithmId}:${contextHash}`;
   // 예: "rec:user123:home_banner:popularity_v1:morning"
   ```

2. **Redis 조회**

   ```javascript
   const cached = await redis.get(cacheKey);
   if (cached) {
     const data = JSON.parse(cached);

     // 캐시 신선도 확인 (TTL 체크)
     const age = Date.now() - data.createdAt;
     if (age < CACHE_TTL_MS) {
       logger.info("Cache hit", { userId, algorithm: algorithmId });
       return data.recommendations;
     }
   }
   ```

3. **캐시 미스 시 다음 단계 진행**

**출력**:

- Cache Hit: 캐시된 추천 결과 반환
- Cache Miss: null 반환, 다음 단계 진행

**캐시 전략**:

- TTL: 30분 (컨텍스트에 따라 조정)
- Stale-While-Revalidate 패턴 고려
- 캐시 워밍: 인기 사용자는 사전 캐싱

---

#### **Step 4: 사용자 컨텍스트 로드 (User Context Loading)**

**입력**: userId

**처리 작업**:

1. **사용자 프로필 조회**

   ```javascript
   const userProfile = await bigquery.query(
     `
     SELECT
       user_id,
       gender,
       age_group,
       signup_date,
       user_segment,  -- 'new', 'active', 'whale', 'dormant'
       last_active_at
     FROM user_profile
     WHERE user_id = @userId
   `,
     { userId }
   );
   ```

2. **구매 이력 조회**

   ```javascript
   const purchaseHistory = await bigquery.query(`
     SELECT
       skill_id,
       purchased_at,
       price,
       category
     FROM purchase_history
     WHERE user_id = @userId
       AND purchased_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
     ORDER BY purchased_at DESC
     LIMIT 50
   `);
   ```

3. **최근 행동 이력 조회**

   ```javascript
   const recentViews = await redis.lrange(`recent_views:${userId}`, 0, 19);
   // ['skill_456', 'skill_789', ...]
   ```

4. **사용자 세그먼트 판단**

   ```javascript
   function determineUserSegment(profile, purchases) {
     if (!profile) return "new_user";

     const totalSpent = purchases.reduce((sum, p) => sum + p.price, 0);
     const daysSinceSignup = daysBetween(profile.signup_date, Date.now());

     if (daysSinceSignup < 7) return "new_user";
     if (totalSpent > 100000) return "whale";
     if (purchases.length > 10) return "active_buyer";
     if (daysSinceLastActive > 30) return "dormant";
     return "casual_user";
   }
   ```

**출력**: UserContext 객체

```javascript
{
  userId: 'user123',
  segment: 'active_buyer',
  profile: { gender: 'F', ageGroup: '20s' },
  purchasedSkills: ['skill_001', 'skill_002', ...],
  viewedSkills: ['skill_456', 'skill_789', ...],
  preferences: {
    categories: ['saju', 'tarot'],
    priceRange: [3000, 15000]
  }
}
```

---

#### **Step 5: 알고리즘 실행 (Algorithm Execution)**

**입력**:

- UserContext
- algorithmId

**처리 작업**:

##### **5.1 알고리즘 선택 및 실행**

```javascript
class RecommendationEngine {
  async execute(userId, algorithmId, userContext) {
    const algorithm = this.getAlgorithm(algorithmId);
    return await algorithm.recommend(userId, userContext);
  }

  getAlgorithm(algorithmId) {
    const algorithms = {
      default_v1: new DefaultAlgorithm(),
      popularity_v1: new PopularityAlgorithm(),
      collaborative_v1: new CollaborativeFilteringAlgorithm(),
    };
    return algorithms[algorithmId];
  }
}
```

##### **5.2 알고리즘별 상세 로직**

**Algorithm 1: Default (기본 추천)**

```javascript
class DefaultAlgorithm {
  async recommend(userId, userContext) {
    // 1. 후보군 생성: 최근 7일 베스트셀러
    const candidates = await bigquery.query(`
      SELECT
        skill_id,
        COUNT(DISTINCT user_id) as buyers,
        SUM(price) as revenue
      FROM purchases
      WHERE purchased_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
        AND skill_status = 'active'
      GROUP BY skill_id
      ORDER BY buyers DESC, revenue DESC
      LIMIT 100
    `);

    // 2. 기본 필터링
    const filtered = candidates.filter((skill) => {
      return !userContext.purchasedSkills.includes(skill.skill_id);
    });

    // 3. 기본 점수 계산
    const scored = filtered.map((skill) => ({
      skillId: skill.skill_id,
      score: skill.buyers * 0.7 + (skill.revenue / 10000) * 0.3,
      reason: "popular",
    }));

    // 4. 정렬 및 상위 N개 반환
    return scored.sort((a, b) => b.score - a.score).slice(0, 20);
  }
}
```

**Algorithm 2: Popularity (인기도 기반)**

```javascript
class PopularityAlgorithm {
  async recommend(userId, userContext) {
    // 1. 사용자 세그먼트별 인기 스킬 조회
    const candidates = await bigquery.query(`
      SELECT
        s.skill_id,
        s.category,
        s.price,
        COUNT(DISTINCT p.user_id) as segment_buyers,
        AVG(CASE WHEN v.clicked = 1 THEN 1 ELSE 0 END) as ctr
      FROM skills s
      LEFT JOIN purchases p
        ON s.skill_id = p.skill_id
        AND p.purchased_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
      LEFT JOIN views v
        ON s.skill_id = v.skill_id
        AND v.viewed_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
      WHERE s.status = 'active'
      GROUP BY s.skill_id, s.category, s.price
      HAVING segment_buyers > 0
      ORDER BY segment_buyers DESC
      LIMIT 100
    `);

    // 2. 시간대별 가중치 적용
    const hourOfDay = new Date().getHours();
    const timeWeight = this.getTimeWeight(hourOfDay);

    // 3. 점수 계산
    const scored = candidates
      .filter((skill) => !userContext.purchasedSkills.includes(skill.skill_id))
      .map((skill) => {
        const baseScore = skill.segment_buyers * 0.6 + skill.ctr * 100 * 0.4;
        const finalScore = baseScore * timeWeight;

        return {
          skillId: skill.skill_id,
          score: finalScore,
          reason: "popularity",
          metadata: {
            buyers: skill.segment_buyers,
            ctr: skill.ctr,
          },
        };
      });

    return scored.sort((a, b) => b.score - a.score).slice(0, 20);
  }

  getTimeWeight(hour) {
    // 시간대별 가중치 (예: 점심시간, 저녁시간 부스팅)
    const weights = {
      morning: 1.0, // 06:00 - 11:59
      lunch: 1.2, // 12:00 - 13:59
      afternoon: 1.0, // 14:00 - 17:59
      evening: 1.3, // 18:00 - 22:59
      night: 0.9, // 23:00 - 05:59
    };

    if (hour >= 6 && hour < 12) return weights.morning;
    if (hour >= 12 && hour < 14) return weights.lunch;
    if (hour >= 14 && hour < 18) return weights.afternoon;
    if (hour >= 18 && hour < 23) return weights.evening;
    return weights.night;
  }
}
```

**Algorithm 3: Collaborative Filtering (협업 필터링)**

```javascript
class CollaborativeFilteringAlgorithm {
  async recommend(userId, userContext) {
    // 1. 유사 사용자 찾기
    const similarUsers = await this.findSimilarUsers(userId, userContext);

    // 2. 유사 사용자들이 구매한 스킬 집계
    const candidateSkills = await bigquery.query(
      `
      SELECT
        p.skill_id,
        COUNT(DISTINCT p.user_id) as similar_user_purchases,
        AVG(p.price) as avg_price
      FROM purchases p
      WHERE p.user_id IN UNNEST(@similarUserIds)
        AND p.skill_id NOT IN UNNEST(@userPurchasedSkills)
        AND p.purchased_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      GROUP BY p.skill_id
      ORDER BY similar_user_purchases DESC
      LIMIT 50
    `,
      {
        similarUserIds: similarUsers.map((u) => u.userId),
        userPurchasedSkills: userContext.purchasedSkills,
      }
    );

    // 3. 점수 계산 (유사도 기반 가중 평균)
    const scored = candidateSkills.map((skill) => {
      const score = skill.similar_user_purchases * 10;

      return {
        skillId: skill.skill_id,
        score: score,
        reason: "collaborative",
        metadata: {
          similarUserCount: similarUsers.length,
          purchases: skill.similar_user_purchases,
        },
      };
    });

    return scored.sort((a, b) => b.score - a.score).slice(0, 20);
  }

  async findSimilarUsers(userId, userContext) {
    // 사전 계산된 유사도 테이블에서 조회
    const similar = await redis.zrevrange(
      `similar_users:${userId}`,
      0,
      49,
      "WITHSCORES"
    );

    return similar
      .map((item, idx) => {
        if (idx % 2 === 0) {
          return {
            userId: item,
            similarity: similar[idx + 1],
          };
        }
      })
      .filter(Boolean);
  }
}
```

**출력**: 알고리즘별 추천 결과

```javascript
[
  {
    skillId: "skill_789",
    score: 87.5,
    reason: "popularity",
    metadata: { buyers: 150, ctr: 0.12 },
  },
  {
    skillId: "skill_456",
    score: 82.3,
    reason: "popularity",
    metadata: { buyers: 140, ctr: 0.1 },
  },
  // ... 18개 더
];
```

---

#### **Step 6: 재랭킹 및 필터링 (Re-ranking & Filtering)**

**입력**:

- 알고리즘 추천 결과 (20개)
- UserContext
- 비즈니스 규칙

**처리 작업**:

##### **6.1 비즈니스 규칙 적용**

```javascript
class ReRankingEngine {
  async rerank(recommendations, userContext, businessRules) {
    let reranked = [...recommendations];

    // 1. 운영자 큐레이션 부스팅
    reranked = this.applyCurationBoosting(reranked, businessRules.curation);

    // 2. 신규 스킬 우대
    reranked = this.applyNewSkillBoosting(
      reranked,
      businessRules.newSkillBoost
    );

    // 3. 다양성 확보
    reranked = this.ensureDiversity(reranked, businessRules.diversity);

    // 4. 가격대 분산
    reranked = this.spreadPriceRange(reranked, userContext);

    // 5. 최종 필터링
    reranked = this.applyFinalFilters(reranked, userContext);

    return reranked;
  }

  applyCurationBoosting(items, curationRules) {
    // 운영자가 특정 스킬에 부여한 가중치 적용
    return items
      .map((item) => {
        const boost = curationRules[item.skillId] || 1.0;
        return {
          ...item,
          score: item.score * boost,
          boosted: boost !== 1.0,
        };
      })
      .sort((a, b) => b.score - a.score);
  }

  applyNewSkillBoosting(items, boostFactor = 1.2) {
    const newSkillThresholdDays = 14;
    const now = Date.now();

    return items
      .map((item) => {
        const daysSinceRelease = daysBetween(item.releaseDate, now);

        if (daysSinceRelease < newSkillThresholdDays) {
          return {
            ...item,
            score: item.score * boostFactor,
            isNew: true,
          };
        }
        return item;
      })
      .sort((a, b) => b.score - a.score);
  }

  ensureDiversity(items, diversityConfig) {
    const result = [];
    const categoryCount = {};

    for (const item of items) {
      const category = item.category;
      const currentCount = categoryCount[category] || 0;
      const maxPerCategory = diversityConfig.maxPerCategory || 5;

      if (currentCount < maxPerCategory) {
        result.push(item);
        categoryCount[category] = currentCount + 1;
      }

      if (result.length >= 20) break;
    }

    return result;
  }

  spreadPriceRange(items, userContext) {
    // 가격대별로 골고루 분산
    const priceGroups = {
      low: items.filter((i) => i.price < 5000),
      mid: items.filter((i) => i.price >= 5000 && i.price < 15000),
      high: items.filter((i) => i.price >= 15000),
    };

    // 사용자 선호 가격대에 따라 비율 조정
    const ratio = this.getPriceRatio(userContext);

    const result = [
      ...priceGroups.low.slice(0, ratio.low),
      ...priceGroups.mid.slice(0, ratio.mid),
      ...priceGroups.high.slice(0, ratio.high),
    ];

    return result.sort((a, b) => b.score - a.score);
  }

  applyFinalFilters(items, userContext) {
    return items.filter((item) => {
      // 1. 이미 구매한 스킬 제외
      if (userContext.purchasedSkills.includes(item.skillId)) {
        return false;
      }

      // 2. 최근 본 스킬 제외 (재노출 방지)
      if (userContext.viewedSkills.includes(item.skillId)) {
        return false;
      }

      // 3. 품절/비활성 스킬 제외
      if (item.status !== "active") {
        return false;
      }

      // 4. 연령 제한 확인
      if (item.ageLimit && userContext.age < item.ageLimit) {
        return false;
      }

      return true;
    });
  }
}
```

**출력**: 재랭킹된 추천 결과 (최종 20개)

---

#### **Step 7: 응답 생성 (Response Building)**

**입력**:

- 재랭킹된 추천 결과
- 실험 메타데이터

**처리 작업**:

```javascript
class ResponseBuilder {
  build(recommendations, metadata) {
    return {
      recommendations: recommendations.map((item, index) => ({
        skillId: item.skillId,
        position: index + 1,
        score: item.score,
        reason: item.reason,
        metadata: item.metadata,
      })),
      meta: {
        experimentId: metadata.experimentId,
        groupName: metadata.groupName,
        algorithm: metadata.algorithmId,
        generatedAt: new Date().toISOString(),
        ttl: 1800, // 30분
        fromCache: false,
      },
    };
  }
}
```

**출력**: 최종 API 응답

```json
{
  "recommendations": [
    {
      "skillId": "skill_789",
      "position": 1,
      "score": 95.2,
      "reason": "popularity",
      "metadata": {
        "buyers": 150,
        "ctr": 0.12
      }
    }
    // ... 19개 더
  ],
  "meta": {
    "experimentId": "exp_001",
    "groupName": "variant_a",
    "algorithm": "popularity_v1",
    "generatedAt": "2025-01-24T10:30:00Z",
    "ttl": 1800,
    "fromCache": false
  }
}
```

---

#### **Step 8: 로깅 및 이벤트 기록 (Logging & Event Tracking)**

**처리 작업**:

```javascript
async function logRecommendation(request, response) {
  // 1. 성능 메트릭 기록
  await metrics.record({
    metric: "recommendation_latency",
    value: response.processingTime,
    tags: {
      algorithm: response.meta.algorithm,
      cacheHit: response.meta.fromCache,
    },
  });

  // 2. 추천 이벤트 로깅 (BigQuery)
  await bigquery.insert("recommendation_logs", {
    timestamp: new Date(),
    userId: request.userId,
    experimentId: response.meta.experimentId,
    groupName: response.meta.groupName,
    algorithm: response.meta.algorithm,
    recommendedSkills: response.recommendations.map((r) => r.skillId),
    context: request.context,
  });

  // 3. 애플리케이션 로그
  logger.info("Recommendation generated", {
    userId: request.userId,
    algorithm: response.meta.algorithm,
    itemCount: response.recommendations.length,
    processingTime: response.processingTime,
  });
}
```

---

#### **Step 9: 캐시 저장 (Cache Writing)**

**처리 작업**:

```javascript
async function cacheRecommendation(cacheKey, response, ttl = 1800) {
  const cacheData = {
    recommendations: response.recommendations,
    createdAt: Date.now(),
    algorithm: response.meta.algorithm,
  };

  await redis.setex(cacheKey, ttl, JSON.stringify(cacheData));
}
```

---

#### **Step 10: 응답 반환 (Response Return)**

**최종 응답**:

```json
HTTP/1.1 200 OK
Content-Type: application/json
X-Processing-Time: 85ms
X-Cache-Status: MISS

{
  "recommendations": [ /* ... */ ],
  "meta": { /* ... */ }
}
```

---

## 4. API 스펙 정의

### 4.1 엔드포인트 목록

#### **GET /api/v1/recommendations/home-banner**

**설명**: 홈 배너 추천 스킬 목록 조회

**요청**:

```http
GET /api/v1/recommendations/home-banner?userId=user123&limit=20&context=morning
Authorization: Bearer {token}
```

**쿼리 파라미터**:
| 파라미터 | 타입 | 필수 | 설명 | 기본값 |
|---------|------|------|------|--------|
| userId | string | ✅ | 사용자 ID | - |
| limit | integer | ❌ | 추천 개수 | 20 |
| context | string | ❌ | 컨텍스트 (morning, evening 등) | null |
| refresh | boolean | ❌ | 캐시 무시 강제 재계산 | false |

**응답** (200 OK):

```json
{
  "recommendations": [
    {
      "skillId": "skill_789",
      "position": 1,
      "score": 95.2,
      "reason": "popularity"
    }
  ],
  "meta": {
    "experimentId": "exp_001",
    "groupName": "variant_a",
    "algorithm": "popularity_v1",
    "generatedAt": "2025-01-24T10:30:00Z",
    "ttl": 1800,
    "fromCache": false
  }
}
```

---

#### **POST /api/v1/experiments**

**설명**: 새로운 A/B 테스트 실험 생성

**요청**:

```json
{
  "name": "home_banner_algorithm_test_v2",
  "surface": "home_banner",
  "startDate": "2025-02-01T00:00:00Z",
  "endDate": "2025-02-28T23:59:59Z",
  "groups": [
    {
      "name": "control",
      "ratio": 0.5,
      "algorithm": "default_v1"
    },
    {
      "name": "variant_a",
      "ratio": 0.5,
      "algorithm": "ml_embedding_v1"
    }
  ]
}
```

**응답** (201 Created):

```json
{
  "experimentId": "exp_002",
  "status": "created",
  "message": "Experiment created successfully"
}
```

---

#### **GET /api/v1/experiments/{experimentId}/metrics**

**설명**: 실험 메트릭 조회

**응답** (200 OK):

```json
{
  "experimentId": "exp_001",
  "groups": [
    {
      "name": "control",
      "metrics": {
        "users": 10000,
        "impressions": 150000,
        "clicks": 18000,
        "purchases": 2000,
        "ctr": 0.12,
        "cvr": 0.0133,
        "arppu": 22500
      }
    },
    {
      "name": "variant_a",
      "metrics": {
        "users": 10000,
        "impressions": 150000,
        "clicks": 21000,
        "purchases": 2400,
        "ctr": 0.14,
        "cvr": 0.016,
        "arppu": 25000
      }
    }
  ],
  "statistical_significance": {
    "ctr": { "p_value": 0.001, "significant": true },
    "cvr": { "p_value": 0.032, "significant": true },
    "arppu": { "p_value": 0.058, "significant": false }
  }
}
```

---

## 5. 데이터 모델

### 5.1 실험 설정 (Experiment Configuration)

**PostgreSQL 테이블**: `experiments`

```sql
CREATE TABLE experiments (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  surface VARCHAR(50) NOT NULL,  -- 'home_banner', 'category', etc.
  status VARCHAR(20) NOT NULL,   -- 'draft', 'active', 'paused', 'completed'
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE experiment_groups (
  id SERIAL PRIMARY KEY,
  experiment_id VARCHAR(50) REFERENCES experiments(id),
  name VARCHAR(50) NOT NULL,
  ratio DECIMAL(3, 2) NOT NULL,  -- 0.00 ~ 1.00
  algorithm_id VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 5.2 추천 로그 (Recommendation Logs)

**BigQuery 테이블**: `recommendation_logs`

```sql
CREATE TABLE recommendation_logs (
  timestamp TIMESTAMP,
  user_id STRING,
  experiment_id STRING,
  group_name STRING,
  algorithm STRING,
  recommended_skills ARRAY<STRING>,
  context STRING,
  processing_time_ms INT64,
  from_cache BOOL
)
PARTITION BY DATE(timestamp)
CLUSTER BY user_id, experiment_id;
```

### 5.3 사용자 행동 이벤트

**BigQuery 테이블**: `user_events`

```sql
CREATE TABLE user_events (
  event_id STRING,
  timestamp TIMESTAMP,
  user_id STRING,
  event_type STRING,  -- 'impression', 'click', 'purchase'
  skill_id STRING,
  experiment_id STRING,
  group_name STRING,
  position INT64,
  metadata JSON
)
PARTITION BY DATE(timestamp)
CLUSTER BY user_id, event_type;
```

---

## 6. 구체화 필요 항목

### 🔴 Critical (즉시 결정 필요)

#### 1. **사용자 세그먼트 정의**

**현재 상태**: 개념만 언급됨
**구체화 필요 사항**:

- 세그먼트 기준 명확화
  - 신규 사용자: 가입 후 며칠? 구매 횟수 기준?
  - Active 사용자: 구매 금액? 방문 빈도?
  - Whale 사용자: 금액 기준? (예: 10만원 이상?)
  - Dormant 사용자: 마지막 활동 기준? (예: 30일 이상?)
- 세그먼트별 추천 전략 차별화 정도

**결정 필요**:

```javascript
const SEGMENT_CRITERIA = {
  new_user: { days_since_signup: 7, purchases: 0 },
  casual_user: { purchases_30d: [1, 3], total_spent: [0, 30000] },
  active_buyer: { purchases_30d: [4, 10], total_spent: [30000, 100000] },
  whale: { total_spent: 100000 },
  dormant: { days_since_last_active: 30 },
};
```

---

#### 2. **알고리즘 성능 목표 및 평가 기준**

**현재 상태**: "100ms 이내 응답" 만 언급
**구체화 필요 사항**:

- 각 알고리즘별 성능 목표
  - Default: ?ms
  - Popularity: ?ms
  - Collaborative: ?ms
- 타임아웃 정책
  - 알고리즘 실행 최대 시간?
  - 타임아웃 시 폴백 전략?

**결정 필요**:

```javascript
const ALGORITHM_SLA = {
  default_v1: { target: 50, timeout: 100 },
  popularity_v1: { target: 70, timeout: 150 },
  collaborative_v1: { target: 80, timeout: 200 },
  ml_embedding_v1: { target: 90, timeout: 300 },
};
```

---

#### 3. **비즈니스 규칙 우선순위 및 가중치**

**현재 상태**: 규칙들만 나열됨
**구체화 필요 사항**:

- 운영자 큐레이션 부스팅 계수
  - 최소/최대 부스팅 값?
  - 어떤 방식으로 설정? (배수? 고정 점수 추가?)
- 신규 스킬 우대 정책
  - 출시 후 며칠까지 신규로 간주?
  - 부스팅 계수는?
- 다양성 확보 기준
  - 카테고리별 최대 노출 개수?
  - 동일 작가 스킬 최대 개수?

**결정 필요**:

```javascript
const BUSINESS_RULES = {
  curation_boost: {
    min: 0.5, // 50% 감소 가능
    max: 2.0, // 2배 증가 가능
    default: 1.0,
  },
  new_skill: {
    threshold_days: 14,
    boost_factor: 1.2,
  },
  diversity: {
    max_per_category: 5,
    max_per_author: 2,
    min_categories: 3,
  },
};
```

---

### 🟡 High (1차 구현 전 결정)

#### 4. **캐시 전략 세부 설정**

**구체화 필요**:

- TTL 설정 기준
  - 시간대별 차등 적용?
  - 사용자 세그먼트별 차등?
- 캐시 워밍 전략
  - 어떤 사용자를 사전 캐싱?
  - 언제 워밍? (배치 시간?)
- Invalidation 정책
  - 어떤 이벤트 발생 시 캐시 무효화?

---

#### 5. **A/B 테스트 통계적 유의성 판단 기준**

**구체화 필요**:

- 최소 샘플 사이즈
  - 그룹당 최소 사용자 수?
  - 최소 이벤트 수?
- P-value 임계값
  - 0.05? 0.01?
- 실험 조기 종료 조건
  - 명확한 승자 판단 기준?
  - 심각한 성능 저하 기준?

---

#### 6. **데이터 수집 및 로깅 상세**

**구체화 필요**:

- 어떤 이벤트를 로깅?
  - Impression (노출)
  - Click (클릭)
  - View (상세 조회)
  - Purchase (구매)
- 로깅 시점 및 방법
  - 클라이언트 로깅? 서버 로깅?
  - 배치? 실시간?
- 개인정보 보호
  - 로깅 시 마스킹 필요 항목?
  - 보관 기간?

---

### 🟢 Medium (2차 구현 전 결정)

#### 7. **ML 모델 서빙 전략**

**구체화 필요**:

- 모델 버전 관리
- 모델 롤백 정책
- A/B 테스트 시 모델 비교 방법

#### 8. **실시간 피처 업데이트 범위**

**구체화 필요**:

- 어떤 피처를 실시간 업데이트?
- 업데이트 주기?
- 비용 vs 효과 분석

---

## 7. 다음 단계

1. **구체화 필요 항목 결정** (1주)

   - 비즈니스 팀, 데이터 팀과 협의
   - 우선순위 Critical 항목부터 결정

2. **상세 설계 문서 작성** (1주)

   - API 스펙 finalize
   - 데이터베이스 스키마 확정
   - 알고리즘 의사 코드 작성

3. **프로토타입 개발** (2주)

   - Default 알고리즘만 구현
   - E2E 플로우 검증

4. **전체 시스템 구현** (3-4주)
   - 모든 알고리즘 구현
   - A/B 테스트 인프라 구축
   - 모니터링 대시보드 구축
