# ExGold API Endpoints Analysis

## Website
https://www.exgold.co.kr/price/inquiry/international

## Discovered API Endpoints

### 1. Live Price Endpoints

#### Get Live USD Exchange Rate
```
GET /api/price/rate/live
```
- Returns real-time USD exchange rate

#### Get Live Market Prices
```
GET /api/price/market/live
```
- Returns real-time prices for assets (Gold, Silver, Platinum, Palladium)

### 2. Historical Price Endpoints

#### Get Historical Exchange Rates
```
GET /api/price/rate/period/list
```
- Returns historical USD exchange rate data
- Supports date range filtering

#### Get Historical Market Prices
```
GET /api/price/market/period/list
```
- Returns historical asset price data
- Supports date range filtering and asset type filtering

## Asset Types

Based on the analysis, the following asset types are supported:

- **AU** - Gold (금)
- **AG** - Silver (은)
- **PT** - Platinum (백금)
- **PD** - Palladium (팔라듐)
- **USD** - US Dollar exchange rate

## Expected Parameters

### For Period List Endpoints:
- `assetType` - Asset code (AU, AG, PT, PD, USD)
- `startDate` - Start date for historical data
- `endDate` - End date for historical data

## Implementation Notes

1. **Base URL**: `https://www.exgold.co.kr`
2. **Request Method**: GET with jQuery AJAX
3. **Response Format**: JSON
4. **Frontend Framework**: Uses ApexCharts for visualization

## Response Data Structure

Expected fields in the response:
- Price information (bid/ask prices)
- Exchange rate data
- Timestamp/Date information
- Asset metadata

## Next Steps for Scraping

1. Test each endpoint with sample requests
2. Identify exact parameter names and formats
3. Determine authentication requirements (if any)
4. Test rate limiting and response structure
5. Build Python client to interact with these APIs
