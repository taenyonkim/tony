# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a personal development repository containing data analysis projects, primarily focused on HelloBot analytics and data science work. The repository is organized into:

- `dlt-partners/hellobot/` - Main directory for HelloBot-related analytics projects
- `personal/` - Personal projects and experiments

## Python Environment

The project uses Python with data science libraries for analytics work. Key dependencies include:

- **Jupyter/Analysis**: jupyterlab, ipykernel, nbconvert, matplotlib, seaborn
- **Data Processing**: pandas, numpy, scipy
- **Visualization**: matplotlib, seaborn, plotly

## Development Commands

### Environment Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Start Jupyter Lab for notebook development
jupyter lab
```

### Running Analysis Scripts

```bash
# Run A/B test analysis
python dlt-partners/hellobot/data_analysis/abtest_coupon_app_new_user_20250808/abtest_analysis.py

# Alternative analysis script
python dlt-partners/hellobot/data_analysis/abtest_coupon_app_new_user_20250808/analysis_abtest_app_new_by_cursor.py
```

## HelloBot Analytics Architecture

### Data Analysis Projects

The repository contains comprehensive A/B testing and analytics frameworks:

1. **A/B Test Analysis Framework** (`dlt-partners/hellobot/data_analysis/`)

   - Statistical testing for conversion rates and ARPPU
   - Automated report generation with visualizations
   - Korean language support for charts and reports

2. **BigQuery Data Pipeline** (`dlt-partners/hellobot/projects/20250813_skill_impression_automation/`)
   - SQL scripts for data mart creation
   - User behavior analysis with skill statistics
   - RFM analysis integration

### Key Analysis Components

#### A/B Testing Framework

- `abtest_analysis.py` - Comprehensive analysis with statistical tests
- `analysis_abtest_app_new_by_cursor.py` - Streamlined statistical comparison
- `abtest_analysis_report.ipynb` - Interactive Jupyter notebook with visualizations

#### Data Warehouse Queries

- `adhoc_mart_user_key_actions_with_skill_stats.sql` - Complex user behavior analysis combining:
  - Skill usage events and payments
  - User property calculations (RFM, lifetime value)
  - Funnel attribution (home banner, sections, categories, search)
  - Skill performance statistics (revenue, buyers, daily averages)

## Code Style Conventions

- Use Korean language for user-facing text and report outputs
- Follow statistical analysis best practices with proper significance testing
- Include comprehensive visualizations for business stakeholders
- Structure SQL queries with CTEs for readability
- Use meaningful variable names in both Korean and English contexts

## Data Analysis Guidelines

1. **Statistical Testing**: Always include t-tests, effect sizes (Cohen's d), and confidence intervals
2. **Visualization**: Create publication-ready charts with proper Korean font settings
3. **Business Metrics**: Focus on conversion rates, ARPPU, and revenue impact
4. **Documentation**: Include methodology explanations for non-technical stakeholders
