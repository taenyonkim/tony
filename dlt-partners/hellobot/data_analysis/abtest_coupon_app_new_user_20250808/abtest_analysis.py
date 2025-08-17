import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

plt.rcParams['font.family'] = 'DejaVu Sans'
plt.rcParams['axes.unicode_minus'] = False

def load_data(file_path):
    """AB 테스트 데이터 로드"""
    df = pd.read_csv(file_path)
    
    # 구매 전환율에서 % 제거하고 숫자로 변환
    df['구매 전환율'] = df['구매 전환율'].str.rstrip('%').astype(float) / 100
    
    # 천단위 콤마 제거하고 숫자로 변환
    numeric_columns = ['총 사용자수', '쿠폰발행 사용자수', '쿠폰 사용 사용자수', '구매자수', '총 구매금액', '인당 구매금액 ARPU', '인당 구매금액 ARPPU']
    for col in numeric_columns:
        df[col] = df[col].astype(str).str.replace(',', '').astype(float)
    
    # 날짜 변환
    df['일자'] = pd.to_datetime(df['일자'])
    
    return df

def exploratory_analysis(df):
    """탐색적 데이터 분석"""
    print("=== 데이터 기본 정보 ===")
    print(f"데이터 기간: {df['일자'].min()} ~ {df['일자'].max()}")
    print(f"총 데이터 포인트: {len(df)}")
    print("\n그룹별 데이터 포인트:")
    print(df['사용자 그룹'].value_counts())
    
    print("\n=== 기본 통계량 ===")
    print(df.groupby('사용자 그룹')[['총 사용자수', '구매자수', '구매 전환율', '인당 구매금액 ARPPU']].describe())

def analyze_conversion_rate(df):
    """구매 전환율 분석"""
    print("\n" + "="*50)
    print("구매 전환율 분석")
    print("="*50)
    
    # 그룹별 전환율 통계
    conversion_stats = df.groupby('사용자 그룹').agg({
        '구매 전환율': ['mean', 'std', 'min', 'max', 'count'],
        '총 사용자수': 'sum',
        '구매자수': 'sum'
    }).round(4)
    
    print("\n그룹별 구매 전환율 통계:")
    print(conversion_stats)
    
    # 실제 전체 전환율 계산 (가중평균)
    group_summary = df.groupby('사용자 그룹').agg({
        '총 사용자수': 'sum',
        '구매자수': 'sum'
    })
    group_summary['실제_전환율'] = group_summary['구매자수'] / group_summary['총 사용자수']
    
    print("\n그룹별 전체 전환율 (실제 계산):")
    print(group_summary)
    
    # 일별 전환율 차이
    daily_comparison = df.pivot(index='일자', columns='사용자 그룹', values='구매 전환율')
    daily_comparison['차이(실험군-대조군)'] = daily_comparison['실험군(Odd)'] - daily_comparison['대조군(Even)']
    
    print("\n일별 전환율 차이:")
    print(daily_comparison.round(4))
    
    return group_summary, daily_comparison

def analyze_arppu(df):
    """ARPPU 분석"""
    print("\n" + "="*50)
    print("ARPPU (Average Revenue Per Paying User) 분석")
    print("="*50)
    
    # 그룹별 ARPPU 통계
    arppu_stats = df.groupby('사용자 그룹').agg({
        '인당 구매금액 ARPPU': ['mean', 'std', 'min', 'max', 'count']
    }).round(2)
    
    print("\n그룹별 ARPPU 통계:")
    print(arppu_stats)
    
    # 일별 ARPPU 차이
    daily_arppu = df.pivot(index='일자', columns='사용자 그룹', values='인당 구매금액 ARPPU')
    daily_arppu['차이(실험군-대조군)'] = daily_arppu['실험군(Odd)'] - daily_arppu['대조군(Even)']
    
    print("\n일별 ARPPU 차이:")
    print(daily_arppu.round(2))
    
    # 총 매출 분석
    total_revenue = df.groupby('사용자 그룹')['총 구매금액'].sum()
    print(f"\n그룹별 총 매출:")
    print(total_revenue)
    print(f"매출 차이: {total_revenue['실험군(Odd)'] - total_revenue['대조군(Even)']:,.0f}원")
    
    return daily_arppu, total_revenue

def statistical_tests(df):
    """통계적 유의성 검정"""
    print("\n" + "="*50)
    print("통계적 유의성 검정")
    print("="*50)
    
    # 구매 전환율에 대한 t-test
    control_conversion = df[df['사용자 그룹'] == '대조군(Even)']['구매 전환율']
    treatment_conversion = df[df['사용자 그룹'] == '실험군(Odd)']['구매 전환율']
    
    t_stat_conv, p_val_conv = stats.ttest_ind(treatment_conversion, control_conversion)
    
    print("1. 구매 전환율 t-test:")
    print(f"   대조군 평균: {control_conversion.mean():.4f}")
    print(f"   실험군 평균: {treatment_conversion.mean():.4f}")
    print(f"   t-statistic: {t_stat_conv:.4f}")
    print(f"   p-value: {p_val_conv:.4f}")
    print(f"   유의성 (α=0.05): {'유의함' if p_val_conv < 0.05 else '유의하지 않음'}")
    
    # ARPPU에 대한 t-test
    control_arppu = df[df['사용자 그룹'] == '대조군(Even)']['인당 구매금액 ARPPU']
    treatment_arppu = df[df['사용자 그룹'] == '실험군(Odd)']['인당 구매금액 ARPPU']
    
    t_stat_arppu, p_val_arppu = stats.ttest_ind(treatment_arppu, control_arppu)
    
    print("\n2. ARPPU t-test:")
    print(f"   대조군 평균: {control_arppu.mean():.2f}")
    print(f"   실험군 평균: {treatment_arppu.mean():.2f}")
    print(f"   t-statistic: {t_stat_arppu:.4f}")
    print(f"   p-value: {p_val_arppu:.4f}")
    print(f"   유의성 (α=0.05): {'유의함' if p_val_arppu < 0.05 else '유의하지 않음'}")
    
    return {
        'conversion_test': {'t_stat': t_stat_conv, 'p_value': p_val_conv},
        'arppu_test': {'t_stat': t_stat_arppu, 'p_value': p_val_arppu}
    }

def create_visualizations(df, daily_comparison, daily_arppu):
    """결과 시각화"""
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    
    # 1. 일별 구매 전환율 비교
    axes[0,0].plot(daily_comparison.index, daily_comparison['대조군(Even)'], 
                   marker='o', label='대조군(Even)', linewidth=2)
    axes[0,0].plot(daily_comparison.index, daily_comparison['실험군(Odd)'], 
                   marker='s', label='실험군(Odd)', linewidth=2)
    axes[0,0].set_title('일별 구매 전환율 비교', fontsize=14, fontweight='bold')
    axes[0,0].set_ylabel('구매 전환율')
    axes[0,0].legend()
    axes[0,0].grid(True, alpha=0.3)
    axes[0,0].tick_params(axis='x', rotation=45)
    
    # 2. 구매 전환율 박스플롯
    conversion_data = []
    groups = []
    for group in df['사용자 그룹'].unique():
        group_data = df[df['사용자 그룹'] == group]['구매 전환율']
        conversion_data.extend(group_data.tolist())
        groups.extend([group] * len(group_data))
    
    conversion_df = pd.DataFrame({'그룹': groups, '구매 전환율': conversion_data})
    sns.boxplot(data=conversion_df, x='그룹', y='구매 전환율', ax=axes[0,1])
    axes[0,1].set_title('그룹별 구매 전환율 분포', fontsize=14, fontweight='bold')
    
    # 3. 일별 ARPPU 비교
    axes[1,0].plot(daily_arppu.index, daily_arppu['대조군(Even)'], 
                   marker='o', label='대조군(Even)', linewidth=2)
    axes[1,0].plot(daily_arppu.index, daily_arppu['실험군(Odd)'], 
                   marker='s', label='실험군(Odd)', linewidth=2)
    axes[1,0].set_title('일별 ARPPU 비교', fontsize=14, fontweight='bold')
    axes[1,0].set_ylabel('ARPPU (원)')
    axes[1,0].legend()
    axes[1,0].grid(True, alpha=0.3)
    axes[1,0].tick_params(axis='x', rotation=45)
    
    # 4. ARPPU 박스플롯
    arppu_data = []
    groups = []
    for group in df['사용자 그룹'].unique():
        group_data = df[df['사용자 그룹'] == group]['인당 구매금액 ARPPU']
        arppu_data.extend(group_data.tolist())
        groups.extend([group] * len(group_data))
    
    arppu_df = pd.DataFrame({'그룹': groups, 'ARPPU': arppu_data})
    sns.boxplot(data=arppu_df, x='그룹', y='ARPPU', ax=axes[1,1])
    axes[1,1].set_title('그룹별 ARPPU 분포', fontsize=14, fontweight='bold')
    
    plt.tight_layout()
    plt.show()
    
    # 추가 시각화: 쿠폰 사용률
    fig2, ax = plt.subplots(1, 1, figsize=(10, 6))
    
    coupon_data = df[df['사용자 그룹'] == '실험군(Odd)'].copy()
    coupon_data['쿠폰_사용률'] = coupon_data['쿠폰 사용 사용자수'] / coupon_data['쿠폰발행 사용자수']
    
    ax.plot(coupon_data['일자'], coupon_data['쿠폰_사용률'], 
            marker='o', linewidth=2, color='green')
    ax.set_title('실험군 쿠폰 사용률 추이', fontsize=14, fontweight='bold')
    ax.set_ylabel('쿠폰 사용률')
    ax.grid(True, alpha=0.3)
    ax.tick_params(axis='x', rotation=45)
    
    plt.tight_layout()
    plt.show()

def generate_summary_report(df, group_summary, test_results, total_revenue):
    """종합 분석 리포트 생성"""
    print("\n" + "="*60)
    print("AB 테스트 결과 종합 리포트")
    print("="*60)
    
    print("\n📊 핵심 지표 요약:")
    print(f"실험 기간: {df['일자'].min().strftime('%Y-%m-%d')} ~ {df['일자'].max().strftime('%Y-%m-%d')}")
    print(f"총 실험 일수: {df['일자'].nunique()}일")
    
    # 전환율 개선
    control_conv = group_summary.loc['대조군(Even)', '실제_전환율']
    treatment_conv = group_summary.loc['실험군(Odd)', '실제_전환율']
    conv_lift = (treatment_conv - control_conv) / control_conv * 100
    
    print(f"\n🎯 구매 전환율:")
    print(f"   대조군: {control_conv:.4f} ({control_conv*100:.2f}%)")
    print(f"   실험군: {treatment_conv:.4f} ({treatment_conv*100:.2f}%)")
    print(f"   개선율: {conv_lift:+.2f}%")
    print(f"   통계적 유의성: {'✅ 유의함' if test_results['conversion_test']['p_value'] < 0.05 else '❌ 유의하지 않음'} (p={test_results['conversion_test']['p_value']:.4f})")
    
    # ARPPU 변화
    control_arppu = df[df['사용자 그룹'] == '대조군(Even)']['인당 구매금액 ARPPU'].mean()
    treatment_arppu = df[df['사용자 그룹'] == '실험군(Odd)']['인당 구매금액 ARPPU'].mean()
    arppu_change = (treatment_arppu - control_arppu) / control_arppu * 100
    
    print(f"\n💰 ARPPU (인당 구매금액):")
    print(f"   대조군: {control_arppu:,.0f}원")
    print(f"   실험군: {treatment_arppu:,.0f}원")
    print(f"   변화율: {arppu_change:+.2f}%")
    print(f"   통계적 유의성: {'✅ 유의함' if test_results['arppu_test']['p_value'] < 0.05 else '❌ 유의하지 않음'} (p={test_results['arppu_test']['p_value']:.4f})")
    
    # 총 매출 영향
    revenue_diff = total_revenue['실험군(Odd)'] - total_revenue['대조군(Even)']
    revenue_change = revenue_diff / total_revenue['대조군(Even)'] * 100
    
    print(f"\n📈 총 매출 영향:")
    print(f"   대조군: {total_revenue['대조군(Even)']:,.0f}원")
    print(f"   실험군: {total_revenue['실험군(Odd)']:,.0f}원")
    print(f"   매출 차이: {revenue_diff:+,.0f}원")
    print(f"   매출 변화율: {revenue_change:+.2f}%")
    
    # 쿠폰 사용률
    coupon_data = df[df['사용자 그룹'] == '실험군(Odd)']
    total_issued = coupon_data['쿠폰발행 사용자수'].sum()
    total_used = coupon_data['쿠폰 사용 사용자수'].sum()
    usage_rate = total_used / total_issued
    
    print(f"\n🎫 쿠폰 사용률:")
    print(f"   발행된 쿠폰: {total_issued:,.0f}개")
    print(f"   사용된 쿠폰: {total_used:,.0f}개")
    print(f"   사용률: {usage_rate:.2%}")
    
    print(f"\n📝 결론:")
    if test_results['conversion_test']['p_value'] < 0.05 and conv_lift > 0:
        print("✅ 쿠폰 제공이 구매 전환율을 유의미하게 개선시켰습니다.")
    else:
        print("❌ 쿠폰 제공의 전환율 개선 효과가 통계적으로 유의하지 않습니다.")
        
    if revenue_change > 0:
        print("✅ 총 매출도 증가하여 가설이 검증되었습니다.")
    else:
        print("❌ 총 매출은 감소했습니다.")

def main():
    """메인 분석 함수"""
    file_path = '/Users/taenyonkim/Development/taenyon/playground/analysis/20250808_abtest_app_new_coupon/abtest_results_daily.csv'
    
    # 데이터 로드
    df = load_data(file_path)
    
    # 탐색적 분석
    exploratory_analysis(df)
    
    # 구매 전환율 분석
    group_summary, daily_comparison = analyze_conversion_rate(df)
    
    # ARPPU 분석
    daily_arppu, total_revenue = analyze_arppu(df)
    
    # 통계적 검정
    test_results = statistical_tests(df)
    
    # 시각화
    create_visualizations(df, daily_comparison, daily_arppu)
    
    # 종합 리포트
    generate_summary_report(df, group_summary, test_results, total_revenue)

if __name__ == "__main__":
    main()