#!/usr/bin/env python3
"""
Gold (Au) Price Client
ExGold API를 사용한 금 시세 전용 클라이언트
"""

import requests
from typing import Dict, Optional
from datetime import datetime
import pandas as pd
from tabulate import tabulate


class GoldPriceClient:
    """금(Au) 시세 전용 API 클라이언트"""

    BASE_URL = "https://www.exgold.co.kr"

    def __init__(self):
        """Initialize the Gold Price client"""
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })

    def get_live_exchange_rate(self) -> Dict:
        """
        실시간 USD/KRW 환율 조회

        Returns:
            dict: 환율 데이터
        """
        endpoint = f"{self.BASE_URL}/api/price/rate/live"
        response = self.session.get(endpoint)
        response.raise_for_status()
        return response.json()

    def get_gold_price(self) -> Optional[Dict]:
        """
        실시간 금(Au) 시세만 조회

        Returns:
            dict: 금 시세 데이터
        """
        endpoint = f"{self.BASE_URL}/api/price/market/live"
        response = self.session.get(endpoint)
        response.raise_for_status()
        data = response.json()

        # 금(Au) 데이터만 추출
        for asset in data['list']:
            if asset['type'] == 'Au':
                return asset
        return None

    def get_gold_table_data(self) -> pd.DataFrame:
        """
        테이블 형식의 금 시세 데이터 생성

        Returns:
            DataFrame: 금 시세 테이블 데이터
        """
        # 환율 정보
        exchange_data = self.get_live_exchange_rate()
        exchange_rate = exchange_data['exchangeRate']['bid']

        # 금 시세
        gold = self.get_gold_price()

        if not gold:
            raise ValueError("금 시세 데이터를 가져올 수 없습니다.")

        # 테이블 데이터 생성
        data = {
            '날짜': [datetime.now().strftime('%Y-%m-%d')],
            '시간': [datetime.now().strftime('%H:%M:%S')],
            '국제가(USD/oz)': [f"${gold['bid']:.2f}"],
            '환율(USD/KRW)': [f"₩{exchange_rate:,.2f}"],
            '국내 기준가(KRW/g)': [f"₩{gold['domesticPrice']:,.0f}"],
            '국내 기준가(KRW/돈)': [f"₩{gold['domesticPriceDon']:,.0f}"],
            '전일대비': [f"₩{gold['fluctuation']:+,.0f}"]
        }

        return pd.DataFrame(data)

    def display_gold_prices(self):
        """금 시세 테이블 출력"""

        df = self.get_gold_table_data()

        print("\n" + "=" * 100)
        print("  금(Gold/Au) 실시간 시세")
        print("=" * 100)

        # tabulate로 테이블 출력
        print(tabulate(df, headers='keys', tablefmt='grid', showindex=False))

        print("\n* 1돈 = 3.75g")
        print("* 매수가 기준")
        print("* 데이터 출처: ExGold (www.exgold.co.kr)")
        print("=" * 100)

    def save_to_csv(self, filename: str = None):
        """
        금 시세 데이터를 CSV로 저장

        Args:
            filename: 저장할 파일명 (없으면 자동생성)

        Returns:
            str: 저장된 파일명
        """
        df = self.get_gold_table_data()

        if filename is None:
            filename = f"gold_price_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"

        df.to_csv(filename, index=False, encoding='utf-8-sig')
        print(f"\n✓ 데이터 저장 완료: {filename}")

        return filename

    def get_gold_summary(self) -> Dict:
        """
        금 시세 요약 정보 반환

        Returns:
            dict: 요약 정보
        """
        exchange_data = self.get_live_exchange_rate()
        gold = self.get_gold_price()

        if not gold:
            raise ValueError("금 시세 데이터를 가져올 수 없습니다.")

        return {
            'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'international_price_usd': gold['bid'],
            'exchange_rate_krw': exchange_data['exchangeRate']['bid'],
            'domestic_price_per_gram': gold['domesticPrice'],
            'domestic_price_per_don': gold['domesticPriceDon'],
            'change': gold['fluctuation'],
            'closed_price': gold.get('closedPrice', 0)
        }


def main():
    """메인 실행"""
    client = GoldPriceClient()

    try:
        # 금 시세 테이블 출력
        client.display_gold_prices()

        # CSV 저장
        client.save_to_csv()

        # 요약 정보
        summary = client.get_gold_summary()
        print(f"\n📊 금 시세 요약")
        print(f"  국제가: ${summary['international_price_usd']:.2f}/oz")
        print(f"  환율: ₩{summary['exchange_rate_krw']:,.2f}")
        print(f"  국내가: ₩{summary['domestic_price_per_gram']:,.0f}/g")
        print(f"  전일대비: ₩{summary['change']:+,.0f}")

    except Exception as e:
        print(f"❌ 오류 발생: {e}")


if __name__ == "__main__":
    main()