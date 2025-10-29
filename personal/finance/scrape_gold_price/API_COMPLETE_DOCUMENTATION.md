# ExGold API Complete Documentation

## Base URL
```
https://www.exgold.co.kr
```

## Verified Working Endpoints

### 1. Get Live USD Exchange Rate
```
GET /api/price/rate/live
```

**Response Example:**
```json
{
  "date": "2025-10-10 20:24:15",
  "exchangeRate": {
    "ask": 1422.87,
    "type": "USD",
    "bid": 1421.58
  }
}
```

**Response Fields:**
- `date` (string): Timestamp in format "YYYY-MM-DD HH:MM:SS"
- `exchangeRate` (object):
  - `ask` (float): USD selling rate
  - `type` (string): Currency type ("USD")
  - `bid` (float): USD buying rate

---

### 2. Get Live Market Prices (All Assets)
```
GET /api/price/market/live
```

**Response Example:**
```json
{
  "date": "2025-10-10 20:24:15",
  "list": [
    {
      "exchangeRate": 1422.87,
      "typeName": "금",
      "ask": 3999.0,
      "domesticPrice": 182940.0,
      "closedPrice": 182552,
      "type": "Au",
      "bid": 3996.8,
      "fluctuation": 388.0,
      "domesticPriceDon": 686025.0
    },
    {
      "exchangeRate": 1422.87,
      "typeName": "은",
      "ask": 50.35,
      "domesticPrice": 2303.4,
      "closedPrice": 2335,
      "type": "Ag",
      "bid": 50.16,
      "fluctuation": -31.6,
      "domesticPriceDon": 8638.0
    },
    {
      "exchangeRate": 1422.87,
      "typeName": "백금",
      "ask": 1636.32,
      "domesticPrice": 74856.0,
      "closedPrice": 74388,
      "type": "Pt",
      "bid": 1623.58,
      "fluctuation": 468.0,
      "domesticPriceDon": 280710.0
    },
    {
      "exchangeRate": 1422.87,
      "typeName": "파라듐",
      "ask": 1468.0,
      "domesticPrice": 67156.0,
      "closedPrice": 65794,
      "type": "Pd",
      "bid": 1450.0,
      "fluctuation": 1362.0,
      "domesticPriceDon": 251835.0
    }
  ]
}
```

**Response Fields:**
- `date` (string): Timestamp in format "YYYY-MM-DD HH:MM:SS"
- `list` (array): Array of asset price objects
  - `type` (string): Asset code ("Au", "Ag", "Pt", "Pd")
  - `typeName` (string): Korean name of asset
  - `exchangeRate` (float): USD exchange rate used
  - `ask` (float): International ask price (USD per troy ounce)
  - `bid` (float): International bid price (USD per troy ounce)
  - `domesticPrice` (float): Domestic price per gram (KRW)
  - `domesticPriceDon` (float): Domestic price per "don" (3.75g) (KRW)
  - `closedPrice` (float): Previous close price
  - `fluctuation` (float): Price change from previous close

---

### 3. Get Historical Exchange Rates
```
GET /api/price/rate/period/list?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
```

**Parameters:**
- `startDate` (string): Start date in format "YYYY-MM-DD"
- `endDate` (string): End date in format "YYYY-MM-DD"

**Status:** Returns empty list in current tests - may require different date format or specific date range

---

### 4. Get Historical Market Prices
```
GET /api/price/market/period/list?assetType=AU&startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
```

**Parameters:**
- `assetType` (string): Asset code ("AU", "AG", "PT", "PD")
- `startDate` (string): Start date in format "YYYY-MM-DD"
- `endDate` (string): End date in format "YYYY-MM-DD"

**Status:** Returns empty list in current tests - may require different date format or specific date range

---

## Asset Types

| Code | Korean Name | English Name | Type Name |
|------|------------|--------------|-----------|
| Au   | 금         | Gold         | typeName: "금" |
| Ag   | 은         | Silver       | typeName: "은" |
| Pt   | 백금       | Platinum     | typeName: "백금" |
| Pd   | 파라듐     | Palladium    | typeName: "파라듐" |

---

## Price Units

### International Prices
- **Unit**: USD per troy ounce (약 31.1035g)
- **Fields**: `ask`, `bid`

### Domestic Prices
- **Per Gram**: KRW per gram
  - **Field**: `domesticPrice`
- **Per Don**: KRW per "don" (1 don = 3.75g = 1돈)
  - **Field**: `domesticPriceDon`

---

## Example Usage in Python

### Get Current Gold Price
```python
import requests

response = requests.get('https://www.exgold.co.kr/api/price/market/live')
data = response.json()

for asset in data['list']:
    if asset['type'] == 'Au':  # Gold
        print(f"Gold Price: ${asset['ask']:.2f}/oz")
        print(f"Domestic: ₩{asset['domesticPrice']:.0f}/g")
        print(f"Change: ₩{asset['fluctuation']:.0f}")
        break
```

### Get Current USD Exchange Rate
```python
import requests

response = requests.get('https://www.exgold.co.kr/api/price/rate/live')
data = response.json()

print(f"USD Exchange Rate:")
print(f"  Buy: ₩{data['exchangeRate']['bid']:.2f}")
print(f"  Sell: ₩{data['exchangeRate']['ask']:.2f}")
```

---

## Rate Limiting & Authentication

- **Authentication**: None required (public API)
- **Rate Limiting**: Unknown - recommend implementing reasonable delays between requests
- **HTTPS**: Required

---

## Notes

1. The historical data endpoints (`/period/list`) return empty results with recent dates. This could mean:
   - Historical data is not available for recent dates
   - Different date format might be required
   - May need to query older date ranges
   - Might be restricted or disabled

2. All prices appear to be real-time or near real-time

3. The API returns clean JSON with no authentication required

4. Response times are fast (< 1 second)

5. Asset codes are case-sensitive in the API responses (Au, Ag, Pt, Pd) but parameters might accept uppercase (AU, AG, PT, PD)

---

## Recommended Next Steps

1. ✅ Verified live price endpoints work perfectly
2. ⚠️ Historical endpoints need further investigation:
   - Try different date formats
   - Try older date ranges (e.g., 30-90 days ago)
   - Check if historical data is available at all
3. Build a scraper that polls the live endpoints at regular intervals
4. Store historical data locally since API historical endpoints may not be reliable
5. Implement error handling and retry logic
6. Add rate limiting to be respectful of the API
