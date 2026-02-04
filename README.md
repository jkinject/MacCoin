# MacCoin

macOS 메뉴바에서 실시간 비트코인(BTC/USDT) 가격을 확인할 수 있는 앱입니다.

## 기능

- 메뉴바에 BTC/USDT 실시간 가격 표시
- Binance API를 통한 가격 조회
- 설정 가능한 폴링 주기 (10초 ~ 5분)
- 자동 업데이트 확인 (GitHub Releases 기반)

## 설치

1. [Releases](https://github.com/jkinject/MacCoin/releases/latest) 페이지에서 최신 `MacCoin.app.zip` 다운로드
2. ZIP 파일 압축 해제
3. `MacCoin.app`을 `/Applications` 폴더로 이동
4. 앱 실행

## 빌드 (개발자용)

```bash
cd MacCoin
./build.sh
```

## 시스템 요구사항

- macOS 14.0 (Sonoma) 이상

## 업데이트 내역

### v1.0
- 최초 릴리스
- BTC/USDT 실시간 가격 메뉴바 표시
- 폴링 주기 설정
- 자동 업데이트 확인 기능
