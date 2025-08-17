import pandas as pd
import numpy as np
from scipy import stats

# 파일 경로
PATH = "/Users/taenyonkim/Development/taenyon/playground/analysis/20250808_abtest_app_new_coupon/abtest_results_daily.csv"

# 숫자 클린업 함수 (천단위 콤마/따옴표/퍼센트 등 제거)
def to_int(series):
    return (
        pd.to_numeric(series.astype(str).str.replace(r"[^0-9]", "", regex=True),
                      errors="coerce")
        .fillna(0)
        .astype(int)
    )

def to_float(series):
    return (
        pd.to_numeric(series.astype(str).str.replace(r"[^0-9.]", "", regex=True),
                      errors="coerce")
        .astype(float)
    )

# 데이터 로드
df = pd.read_csv(PATH, encoding="utf-8-sig")

# 필요한 열 정리
df["총 사용자수"] = to_int(df["총 사용자수"])
df["구매자수"]   = to_int(df["구매자수"])
df["총 구매금액"] = to_int(df["총 구매금액"])

# 일자별 지표 재계산 (요약CSV에 기존 지표가 있어도 재계산 사용)
df["전환율"] = df["구매자수"] / df["총 사용자수"]
df["ARPPU(일자별)"] = np.where(df["구매자수"] > 0,
                           df["총 구매금액"] / df["구매자수"],
                           np.nan)

# 그룹 라벨
CONTROL = "대조군(Even)"
TREAT   = "실험군(Odd)"

# 전체 집계 (전환율/ARPPU 총괄)
agg = (
    df.groupby("사용자 그룹")
      .agg(total_users=("총 사용자수", "sum"),
           buyers=("구매자수", "sum"),
           revenue=("총 구매금액", "sum"))
)

# 결측/존재 체크
if CONTROL not in agg.index or TREAT not in agg.index:
    raise ValueError("필요한 그룹 라벨(대조군/실험군)이 데이터에 없습니다.")

n_c, x_c, r_c = int(agg.loc[CONTROL, "total_users"]), int(agg.loc[CONTROL, "buyers"]), int(agg.loc[CONTROL, "revenue"])
n_t, x_t, r_t = int(agg.loc[TREAT,   "total_users"]), int(agg.loc[TREAT,   "buyers"]), int(agg.loc[TREAT,   "revenue"])

p_c = x_c / n_c if n_c > 0 else np.nan
p_t = x_t / n_t if n_t > 0 else np.nan
arppu_c_overall = (r_c / x_c) if x_c > 0 else np.nan
arppu_t_overall = (r_t / x_t) if x_t > 0 else np.nan

# 2표본 비율 z-검정 (전환율: 전체 집계 기준)
def two_prop_z_test(n1, x1, n2, x2, alpha=0.05):
    p1, p2 = x1 / n1, x2 / n2
    se = np.sqrt(p1*(1-p1)/n1 + p2*(1-p2)/n2)
    z  = (p2 - p1) / se
    pval = 2 * (1 - stats.norm.cdf(abs(z)))
    zcrit = stats.norm.ppf(1 - alpha/2)
    ci_low, ci_high = (p2 - p1) - zcrit*se, (p2 - p1) + zcrit*se
    return {
        "p1": p1, "p2": p2, "diff": p2 - p1,
        "z": z, "pval": pval,
        "ci": (ci_low, ci_high)
    }

conv_test = two_prop_z_test(n_c, x_c, n_t, x_t, alpha=0.05)
lift_conv = (conv_test["p2"] / conv_test["p1"] - 1.0) if conv_test["p1"] > 0 else np.nan

# Welch t-검정 (ARPPU: 일자 단위 평균 비교)
c_daily = df.loc[df["사용자 그룹"] == CONTROL, "ARPPU(일자별)"].dropna().values
t_daily = df.loc[df["사용자 그룹"] == TREAT,   "ARPPU(일자별)"].dropna().values

tstat, pval_t = stats.ttest_ind(t_daily, c_daily, equal_var=False, nan_policy="omit")

mu_c, mu_t = float(np.nanmean(c_daily)), float(np.nanmean(t_daily))
diff_mu = mu_t - mu_c
lift_arppu = (mu_t / mu_c - 1.0) if mu_c > 0 else np.nan

# Welch CI for difference of means
def welch_ci(x, y, alpha=0.05):
    n1, n2 = len(x), len(y)
    s1, s2 = np.var(x, ddof=1), np.var(y, ddof=1)
    se = np.sqrt(s1/n1 + s2/n2)
    df_w = (s1/n1 + s2/n2)**2 / ((s1/n1)**2/(n1-1) + (s2/n2)**2/(n2-1))
    tcrit = stats.t.ppf(1 - alpha/2, df_w)
    return (diff_mu - tcrit*se, diff_mu + tcrit*se), df_w, se

ci_arppu, df_welch, se_arppu = welch_ci(t_daily, c_daily, alpha=0.05)

# 출력 정리
def pct(x): return f"{x*100:,.2f}%"
def won(x): return f"{x:,.0f}원"

print("=== 집계 요약 ===")
print(f"[대조군] 사용자수={n_c:,}, 구매자수={x_c:,}, 전환율={pct(p_c)}, 총매출={won(r_c)}, ARPPU(총괄)={won(arppu_c_overall)}")
print(f"[실험군] 사용자수={n_t:,}, 구매자수={x_t:,}, 전환율={pct(p_t)}, 총매출={won(r_t)}, ARPPU(총괄)={won(arppu_t_overall)}")
print()

print("=== 전환율 비교 (2표본 비율 z-검정, 전체 집계 기준) ===")
print(f"차이(실험-대조) = {pct(conv_test['diff'])}  | 상대 리프트 = {pct(lift_conv)}")
print(f"z = {conv_test['z']:.3f}, p = {conv_test['pval']:.4g}")
print(f"95% CI(차이) = [{pct(conv_test['ci'][0])}, {pct(conv_test['ci'][1])}]")
print()

print("=== ARPPU 비교 (Welch t-검정, 일자 단위 평균) ===")
print(f"[대조군] 평균 ARPPU(일자) = {won(mu_c)}")
print(f"[실험군] 평균 ARPPU(일자) = {won(mu_t)}")
print(f"차이(실험-대조) = {won(diff_mu)}  | 상대 리프트 = {lift_arppu*100:,.2f}%")
print(f"t = {tstat:.3f}, df ≈ {df_welch:.1f}, p = {pval_t:.4g}")
print(f"95% CI(차이) = [{won(ci_arppu[0])}, {won(ci_arppu[1])}]")
