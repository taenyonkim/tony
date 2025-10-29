# 신규 기능 출시가 기존 구매 사용자에게 미친 영향 분석 계획서

## 1. 분석 개요

### 1.1 분석 목적
- 2025년 10월 12일 출시된 신규 기능(Daily Tab)이 기존 구매자들의 행동 패턴에 미친 영향 분석
- 신규 기능 사용 여부에 따른 구매 행동 변화 측정

### 1.2 분석 기간
- 전체 데이터: 2025년 1월 1일 ~ 2025년 10월 29일
- 기능 출시일: 2025년 10월 12일
- 프로모션 기간: 2025년 10월 1일 ~ 10월 13일 (할인 쿠폰 프로모션)

### 1.3 주요 용어 정의
- **기존 구매자**: 10월 12일 이전에 1회 이상 구매 이력이 있는 사용자
- **신규 기능 사용자**: `viewed_daily_tab = 1`인 로그가 있는 사용자
- **구매 행동**: `event_name`에 'pay_for_' 문자열을 포함하는 이벤트
- **구매 금액**: `revenue_krw` 필드 값

## 2. 데이터 전처리 계획

### 2.1 기존 구매자 식별
```sql
-- 10월 12일 이전 구매자 리스트 추출
WITH existing_buyers AS (
  SELECT DISTINCT user_id
  FROM data_table
  WHERE event_date < '2025-10-12'
    AND event_name LIKE '%pay_for_%'
    AND revenue_krw > 0
)
```

### 2.2 사용자 세그먼트 분류
1. **Treatment Group (처치군)**: 기존 구매자 중 10/12 이후 신규 기능 사용자
2. **Control Group (대조군)**: 기존 구매자 중 10/12 이후 신규 기능 미사용자

### 2.3 프로모션 영향 최소화 전략
- **방법 1: 프로모션 기간 제외**
  - Before Period: 2025년 8월 1일 ~ 9월 30일 (프로모션 전)
  - After Period: 2025년 10월 14일 ~ 10월 29일 (프로모션 후)

- **방법 2: 프로모션 효과 보정**
  - 9월 대비 10월 1일~11일의 구매 증가율을 프로모션 효과로 추정
  - 해당 효과를 제거한 보정값으로 분석

## 3. 핵심 분석 지표 및 방법론

### 3.1 구매 횟수 변화 분석

#### 지표 정의
- **일평균 구매 횟수** = 총 구매 횟수 / 활동 일수
- **주평균 구매 횟수** = 총 구매 횟수 / 활동 주수

#### 분석 방법
```python
# Before Period (기능 출시 전)
before_purchases = df[df['event_date'] < '2025-10-12'].groupby(['user_id', 'group'])
  .agg({
    'transaction_id': 'count',  # 구매 횟수
    'event_date': 'nunique'     # 활동 일수
  })

# After Period (기능 출시 후)
after_purchases = df[df['event_date'] >= '2025-10-14'].groupby(['user_id', 'group'])
  .agg({
    'transaction_id': 'count',
    'event_date': 'nunique'
  })

# 변화율 계산
change_rate = (after_purchases - before_purchases) / before_purchases * 100
```

#### 통계 검정
- **Difference-in-Differences (DID)** 분석
- **Mann-Whitney U test** (비모수 검정)

### 3.2 평균 구매 금액 변화 분석

#### 지표 정의
- **ARPU (Average Revenue Per User)** = 총 매출 / 사용자 수
- **ARPPU (Average Revenue Per Paying User)** = 총 매출 / 구매 사용자 수
- **AOV (Average Order Value)** = 총 매출 / 총 구매 건수

#### 분석 방법
```python
# 사용자별 평균 구매 금액
avg_revenue = df.groupby(['user_id', 'period', 'group'])['revenue_krw'].mean()

# 중앙값 기반 분석 (이상치 영향 최소화)
median_revenue = df.groupby(['user_id', 'period', 'group'])['revenue_krw'].median()
```

#### 통계 검정
- **Two-way ANOVA** (정규성 만족 시)
- **Kruskal-Wallis test** (정규성 불만족 시)

### 3.3 방문 리텐션 변화 분석

#### 지표 정의
- **일별 리텐션율** = D+n일 방문 사용자 / 전체 대상 사용자
- **주별 리텐션율** = W+n주 방문 사용자 / 전체 대상 사용자
- **Rolling Retention** = 특정 기간 이후 1회 이상 방문한 사용자 비율

#### 분석 방법
```python
# 코호트 분석
cohort_retention = pd.crosstab(
    index=df['user_id'],
    columns=df['days_since_feature_launch'],
    values=df['event_name'],
    aggfunc='count'
).fillna(0)

# 리텐션 곡선 비교
retention_curves = cohort_retention.apply(lambda x: (x > 0).sum() / len(cohort_retention))
```

#### 통계 검정
- **Log-rank test** (생존 분석)
- **Chi-square test** (범주형 비교)

### 3.4 재방문 주기 변화 분석

#### 지표 정의
- **평균 재방문 간격** = 연속된 방문일 간 평균 일수
- **방문 빈도** = 월간 방문 일수
- **방문 규칙성** = 재방문 간격의 표준편차

#### 분석 방법
```python
# 사용자별 방문 간격 계산
visit_intervals = df.groupby('user_id')['event_date'].apply(
    lambda x: x.sort_values().diff().dt.days.dropna().mean()
)

# 방문 패턴 클러스터링
from sklearn.cluster import KMeans
visit_features = df.groupby('user_id').agg({
    'event_date': ['count', 'nunique'],
    'revenue_krw': 'sum'
})
```

#### 통계 검정
- **Kolmogorov-Smirnov test** (분포 비교)
- **t-test** 또는 **Wilcoxon signed-rank test**

## 4. 심화 분석

### 4.1 Propensity Score Matching
- 신규 기능 사용 성향이 유사한 사용자끼리 매칭
- 선택 편향(Selection Bias) 제거

```python
# 성향 점수 계산을 위한 특성
matching_features = [
    'user_total_revenue_krw',
    'user_total_day_visited',
    'user_age',
    'platform',
    'rfm_payment_segment'
]
```

### 4.2 시계열 분해 분석
- 트렌드, 계절성, 잔차 분해
- ARIMA 모델을 통한 예측값 대비 실제값 비교

### 4.3 세그먼트별 상세 분석
- RFM 세그먼트별 영향도 차이
- 연령대별, 성별 영향도 차이
- 플랫폼별 (iOS/Android/Web) 영향도 차이

## 5. 예상 결과물

### 5.1 주요 산출물
1. **효과 요약 테이블**
   - 각 지표별 Before/After 비교
   - Treatment vs Control 차이
   - 통계적 유의성 검정 결과

2. **시각화 차트**
   - 일별 구매 추이 그래프
   - 리텐션 곡선 비교
   - 구매 금액 분포 박스플롯
   - 재방문 주기 히스토그램

3. **인사이트 리포트**
   - 신규 기능의 효과성 평가
   - 개선 제안사항
   - 추가 분석 필요 영역

### 5.2 리스크 및 한계점
- **프로모션 효과와의 혼재**: 완전한 분리 어려움
- **단기 관찰 기간**: 10/12 ~ 10/29 (약 17일)
- **계절성 효과**: 월말 효과 등 고려 필요
- **자기 선택 편향**: 신규 기능 사용자의 원래 활성도가 높을 가능성

## 6. 실행 계획

### 6.1 단계별 일정
1. **데이터 전처리** (Day 1)
   - 기존 구매자 추출
   - 사용자 세그먼트 생성

2. **기초 통계 분석** (Day 2-3)
   - 4대 핵심 지표 계산
   - Before/After 비교

3. **통계 검정** (Day 4)
   - 가설 검정 수행
   - 유의성 확인

4. **심화 분석** (Day 5-6)
   - PSM 분석
   - 세그먼트별 분석

5. **리포트 작성** (Day 7)
   - 결과 정리
   - 시각화 및 인사이트 도출

### 6.2 필요 리소스
- Python 환경 (pandas, numpy, scipy, sklearn)
- 시각화 도구 (matplotlib, seaborn, plotly)
- 통계 분석 도구 (statsmodels)
- SQL 쿼리 환경

## 7. 기대 효과

- 신규 기능의 ROI 측정
- 향후 기능 개발 우선순위 결정 근거
- 사용자 세그먼트별 맞춤 전략 수립
- 구매 전환율 개선 방안 도출