# HelloBot 콘텐츠 추천 알고리즘 - 기술 요구사항 정의서

## 1. 시스템 아키텍처 요구사항

### 1.1 전체 시스템 구조
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │  Recommendation │
│   (App/Web)     │◄──►│                 │◄──►│     Engine      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │  Data Pipeline  │◄──►│    Database     │
                       │                 │    │   (BigQuery)    │
                       └─────────────────┘    └─────────────────┘
```

### 1.2 핵심 컴포넌트

#### A. 추천 엔진 (Recommendation Engine)
- **언어**: Python 3.9+
- **프레임워크**: FastAPI
- **목적**: 실시간 개인화 콘텐츠 추천
- **성능 요구사항**: 
  - 응답시간 < 100ms
  - 동시 처리 > 1000 RPS
  - 가용성 > 99.9%

#### B. 데이터 파이프라인
- **스트리밍**: Apache Kafka / Google Pub/Sub
- **배치 처리**: Apache Airflow
- **실시간 처리**: Apache Beam / Dataflow
- **목적**: 사용자 행동 데이터 실시간 수집 및 처리

#### C. 데이터 저장소
- **주 데이터베이스**: Google BigQuery
- **캐시**: Redis Cluster
- **실시간 데이터**: Cloud Firestore
- **모델 저장**: Google Cloud Storage

## 2. 데이터 모델 요구사항

### 2.1 핵심 테이블 구조

#### A. 사용자 관심사 점수 테이블
```sql
CREATE TABLE `hellobot.recommendation.user_interest_scores` (
    user_id STRING NOT NULL,
    interest_segment STRING NOT NULL,
    score FLOAT64 NOT NULL,
    confidence_level FLOAT64 NOT NULL,
    last_updated TIMESTAMP NOT NULL,
    decay_factor FLOAT64 NOT NULL,
    interaction_count INT64 NOT NULL
)
PARTITION BY DATE(last_updated)
CLUSTER BY user_id, interest_segment;
```

#### B. 콘텐츠 성과 테이블
```sql
CREATE TABLE `hellobot.recommendation.skill_performance` (
    skill_id STRING NOT NULL,
    date DATE NOT NULL,
    impressions INT64 NOT NULL,
    clicks INT64 NOT NULL,
    purchases INT64 NOT NULL,
    conversion_rate FLOAT64 NOT NULL,
    arpu FLOAT64 NOT NULL,
    repeat_purchase_rate FLOAT64 NOT NULL,
    avg_rating FLOAT64,
    category STRING NOT NULL,
    content_type STRING NOT NULL, -- 'saju', 'tarot', etc.
    price INT64 NOT NULL
)
PARTITION BY date
CLUSTER BY skill_id, category;
```

#### C. 개인화 로그 테이블
```sql
CREATE TABLE `hellobot.recommendation.personalization_logs` (
    user_id STRING NOT NULL,
    skill_id STRING NOT NULL,
    exposure_type STRING NOT NULL, -- 'main_banner', 'category', 'section', 'search'
    position INT64 NOT NULL,
    personalized_score FLOAT64 NOT NULL,
    interest_segments ARRAY<STRING>,
    algorithm_version STRING NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    session_id STRING,
    device_type STRING,
    converted BOOLEAN NOT NULL,
    conversion_value FLOAT64
)
PARTITION BY DATE(timestamp)
CLUSTER BY user_id, skill_id;
```

#### D. A/B 테스트 테이블
```sql
CREATE TABLE `hellobot.recommendation.ab_test_assignments` (
    user_id STRING NOT NULL,
    experiment_id STRING NOT NULL,
    variant_id STRING NOT NULL,
    assigned_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP,
    metadata JSON
)
PARTITION BY DATE(assigned_at)
CLUSTER BY user_id, experiment_id;
```

### 2.2 캐시 데이터 구조 (Redis)

#### A. 사용자 관심사 캐시
```redis
Key: user:interest:{user_id}
Value: {
    "신년운세": {"score": 8.5, "confidence": 0.95, "last_updated": "2025-08-24T10:00:00Z"},
    "솔로연애운": {"score": 6.2, "confidence": 0.78, "last_updated": "2025-08-24T09:30:00Z"},
    ...
}
TTL: 1800 seconds (30분)
```

#### B. 콘텐츠 성과 캐시
```redis
Key: skill:performance:{skill_id}:{date}
Value: {
    "conversion_rate": 0.045,
    "arpu": 18500,
    "impressions": 12450,
    "category": "신년운세",
    "content_type": "saju"
}
TTL: 3600 seconds (1시간)
```

#### C. 개인화 추천 결과 캐시
```redis
Key: recommendations:{user_id}:{exposure_type}
Value: [
    {"skill_id": "skill_001", "score": 0.95, "position": 1},
    {"skill_id": "skill_012", "score": 0.87, "position": 2},
    ...
]
TTL: 900 seconds (15분)
```

## 3. API 설계 요구사항

### 3.1 핵심 API 엔드포인트

#### A. 개인화 추천 API
```python
@app.get("/api/v1/recommendations/{user_id}")
async def get_personalized_recommendations(
    user_id: str,
    exposure_type: ExposureType,
    limit: int = 20,
    exclude_purchased: bool = True,
    include_metadata: bool = False
) -> RecommendationResponse:
    """
    개인화된 콘텐츠 추천 반환
    
    Args:
        user_id: 사용자 ID
        exposure_type: 노출 타입 (main_banner, category, section, search)
        limit: 반환할 추천 수
        exclude_purchased: 구매한 스킬 제외 여부
        include_metadata: 메타데이터 포함 여부
    
    Returns:
        RecommendationResponse: 추천 스킬 리스트와 메타데이터
    """
```

#### B. 사용자 행동 추적 API
```python
@app.post("/api/v1/events/track")
async def track_user_event(event: UserEventRequest) -> EventResponse:
    """
    사용자 행동 이벤트 수집
    
    Event Types:
    - skill_view: 스킬 상세페이지 조회
    - skill_enter: 스킬 진입 (채팅방 입장)
    - skill_purchase: 스킬 구매
    - skill_complete: 스킬 완료
    """
```

#### C. 관심사 업데이트 API
```python
@app.post("/api/v1/users/{user_id}/interests/update")
async def update_user_interests(
    user_id: str,
    event_data: InterestUpdateRequest
) -> InterestUpdateResponse:
    """
    사용자 관심사 점수 실시간 업데이트
    """
```

### 3.2 데이터 모델 (Pydantic)

```python
class UserInterest(BaseModel):
    segment: str
    score: float
    confidence: float
    last_updated: datetime

class SkillRecommendation(BaseModel):
    skill_id: str
    title: str
    category: str
    price: int
    personalized_score: float
    interest_match: List[str]
    metadata: Optional[Dict[str, Any]] = None

class RecommendationResponse(BaseModel):
    user_id: str
    recommendations: List[SkillRecommendation]
    algorithm_version: str
    generated_at: datetime
    cache_hit: bool
```

## 4. 성능 요구사항

### 4.1 응답 시간
- **개인화 추천 API**: 95% 요청이 100ms 이하
- **관심사 업데이트**: 95% 요청이 50ms 이하
- **이벤트 수집**: 95% 요청이 25ms 이하

### 4.2 처리량
- **동시 사용자**: 10,000명
- **초당 추천 요청**: 1,000 RPS
- **초당 이벤트 수집**: 5,000 RPS

### 4.3 가용성
- **시스템 가용성**: 99.9%
- **데이터 일관성**: Eventually Consistent (최대 5초 지연)
- **장애 복구**: RTO < 5분, RPO < 1분

## 5. 보안 요구사항

### 5.1 데이터 보호
- **개인정보 암호화**: AES-256 암호화
- **데이터 마스킹**: 로그에서 민감 정보 마스킹
- **접근 제어**: IAM 기반 역할별 접근 권한

### 5.2 API 보안
- **인증**: JWT 토큰 기반 인증
- **인가**: 역할 기반 접근 제어 (RBAC)
- **Rate Limiting**: 사용자별 API 호출 제한
- **Input Validation**: 모든 입력값 검증

## 6. 모니터링 및 로깅 요구사항

### 6.1 메트릭 수집

#### A. 비즈니스 메트릭
```python
business_metrics = {
    "conversion_rate": "추천 스킬 전환율",
    "click_through_rate": "추천 스킬 클릭률",
    "personalization_lift": "개인화 대비 베이스라인 성과 향상",
    "diversity_score": "추천 결과 다양성 점수",
    "coverage": "전체 스킬 대비 추천된 스킬 비율"
}
```

#### B. 기술 메트릭
```python
technical_metrics = {
    "api_response_time": "API 응답 시간",
    "cache_hit_rate": "캐시 적중률",
    "model_inference_time": "모델 추론 시간",
    "data_freshness": "데이터 신선도",
    "error_rate": "에러 발생률"
}
```

### 6.2 알림 설정
- **응답 시간 초과**: 95% 요청이 SLA 초과시 알림
- **에러율 증가**: 5분간 에러율 5% 초과시 알림
- **전환율 하락**: 시간당 전환율이 베이스라인 대비 20% 하락시 알림
- **시스템 장애**: 서비스 다운시 즉시 알림

## 7. 배포 및 운영 요구사항

### 7.1 배포 전략
- **Blue-Green 배포**: 무중단 서비스를 위한 배포 방식
- **Canary 배포**: 새 버전을 점진적으로 배포
- **Feature Flag**: 기능 토글을 통한 위험 관리
- **롤백 전략**: 30초 이내 이전 버전으로 롤백 가능

### 7.2 환경 구성
```yaml
environments:
  development:
    - CPU: 2 cores, Memory: 4GB
    - Instances: 2
    - Database: Development dataset
    
  staging:
    - CPU: 4 cores, Memory: 8GB  
    - Instances: 3
    - Database: Staging dataset (production 부분 복사)
    
  production:
    - CPU: 8 cores, Memory: 16GB
    - Instances: 5+ (Auto-scaling)
    - Database: Production dataset
```

### 7.3 백업 및 복구
- **데이터 백업**: 일일 자동 백업, 7일 보관
- **설정 백업**: Git을 통한 버전 관리
- **재해 복구**: Multi-region 구성으로 RTO 5분 보장

---

**문서 버전**: v1.0  
**작성일**: 2025-08-24  
**작성자**: Technical Architecture Team  
**검토자**: [시니어 개발자명]