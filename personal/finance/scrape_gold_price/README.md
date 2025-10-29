# ExGold Price Scraper

A Python client and data collector for tracking precious metal prices from ExGold (exgold.co.kr).

## Overview

This project provides tools to fetch and track real-time prices for:
- **Gold (금)** - Au
- **Silver (은)** - Ag
- **Platinum (백금)** - Pt
- **Palladium (파라듐)** - Pd

## Files

### Documentation
- `API_COMPLETE_DOCUMENTATION.md` - Complete API reference with examples
- `API_ENDPOINTS_ANALYSIS.md` - Initial API analysis notes
- `README.md` - This file

### Python Scripts
- `exgold_client.py` - Python client library for ExGold API
- `price_collector.py` - Data collection and CSV storage utility
- `test_api_endpoints.py` - API endpoint testing script

### Data
- `data/` - Directory containing CSV files with historical price data
  - `au_prices.csv` - Gold prices
  - `ag_prices.csv` - Silver prices
  - `pt_prices.csv` - Platinum prices
  - `pd_prices.csv` - Palladium prices

## Quick Start

### 1. Installation

No special dependencies required beyond the standard library. If you want to use the client:

```bash
pip install requests
```

### 2. Get Current Prices

```python
from exgold_client import ExGoldClient

client = ExGoldClient()

# Print all current prices
client.print_current_prices()

# Get specific asset
gold = client.get_gold_price()
print(f"Gold: ${gold['ask']:.2f}/oz")
print(f"Domestic: ₩{gold['domesticPrice']:,.0f}/g")
```

### 3. Collect and Store Price Data

```bash
# Collect current prices and save to CSV
python price_collector.py --collect

# View statistics for gold
python price_collector.py --stats au

# Show latest 10 gold prices
python price_collector.py --latest au --limit 10
```

## API Endpoints

### Live Prices (Working ✓)

**Get USD Exchange Rate:**
```
GET https://www.exgold.co.kr/api/price/rate/live
```

**Get All Asset Prices:**
```
GET https://www.exgold.co.kr/api/price/market/live
```

### Historical Data (Limited)

Historical endpoints exist but return empty results with recent dates:
```
GET /api/price/rate/period/list?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
GET /api/price/market/period/list?assetType=AU&startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
```

**Recommendation:** Use the price collector to build your own historical database.

## Price Units

### International Prices
- **Unit**: USD per troy ounce (31.1035g)
- **Fields**: `bid` (buy), `ask` (sell)

### Domestic Prices
- **Per Gram**: KRW per gram (`domesticPrice`)
- **Per Don**: KRW per don (3.75g) (`domesticPriceDon`)

## Data Format

CSV files contain the following columns:

| Column | Description |
|--------|-------------|
| timestamp | Date and time of price |
| type | Asset code (Au, Ag, Pt, Pd) |
| type_name | Korean name (금, 은, 백금, 파라듐) |
| international_bid | USD price per oz (buy) |
| international_ask | USD price per oz (sell) |
| domestic_price_per_gram | KRW per gram |
| domestic_price_per_don | KRW per don (3.75g) |
| closed_price | Previous close price |
| fluctuation | Price change from close |
| usd_exchange_rate | USD/KRW rate used |

## Usage Examples

### Example 1: Monitor Gold Price

```python
from exgold_client import ExGoldClient

client = ExGoldClient()
gold = client.get_gold_price()

print(f"Current Gold Price: ₩{gold['domesticPrice']:,.0f}/g")
print(f"Change: ₩{gold['fluctuation']:+,.0f}")
```

### Example 2: Automated Price Collection

Set up a cron job to collect prices every hour:

```bash
# Edit crontab
crontab -e

# Add this line to run every hour
0 * * * * cd /path/to/scrape_gold_price && python price_collector.py --collect
```

### Example 3: Price Analysis

```python
from price_collector import PriceCollector

collector = PriceCollector()

# Collect current data
collector.collect_and_save()

# Get statistics
collector.print_statistics('au')

# Get latest prices
recent = collector.get_latest_prices('au', limit=24)  # Last 24 records
```

## API Response Examples

### Live Exchange Rate
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

### Live Market Prices
```json
{
  "date": "2025-10-10 20:24:15",
  "list": [
    {
      "type": "Au",
      "typeName": "금",
      "exchangeRate": 1422.87,
      "ask": 3999.0,
      "bid": 3996.8,
      "domesticPrice": 182940.0,
      "domesticPriceDon": 686025.0,
      "closedPrice": 182552,
      "fluctuation": 388.0
    }
  ]
}
```

## Notes

1. **No Authentication Required** - All endpoints are public
2. **Real-time Data** - Prices are updated in real-time
3. **Rate Limiting** - Be respectful, avoid excessive requests
4. **Error Handling** - Always implement proper error handling
5. **Historical Data** - Build your own by collecting regularly

## License

This is a personal project for educational purposes. Please respect ExGold's terms of service when using their API.

## Contributing

This is a personal project, but suggestions are welcome!

## Contact

For questions about the ExGold API, contact ExGold directly.
