# Mithm Critical Flows

이 문서는 여러 계층에 걸쳐 있어 깨지기 쉬운 흐름을 한곳에 모은다. 아래 흐름을 건드릴 때는 관련 영역 가이드와 테스트 가이드를 반드시 함께 읽는다.

## HealthKit 월경 기록 흐름

1. Core의 `HealthKitDataStore`가 HealthKit 샘플을 읽고 쓴다.
2. Data의 `HealthKitRepositoryImpl`이 DataStore를 호출한다.
3. Data Mapper가 HealthKit 샘플 날짜 범위를 Domain의 `MenstrualRecord`로 변환한다.
4. Domain UseCase와 Helper가 월경 상태, 예측, Phase를 계산한다.
5. Presentation은 `AppState`와 ViewModel을 통해 화면을 갱신한다.

주의:
- Mapper는 HealthKit 샘플의 `startDate`/`endDate`를 임의로 재해석하지 않는다.
- 오늘 샘플이라는 이유로 `endDate`를 `nil`로 바꾸지 않는다.
- HealthKit 저장/삭제 시 Core는 받은 날짜를 그대로 전달한다.

## CurrentMenstrualEpisode 흐름

`CurrentMenstrualEpisode`는 HealthKit을 대체하는 저장소가 아니다.

- 같은 시작일의 월경을 사용자가 종료했는지 기록한다.
- 자동 종료 여부를 보조로 기록한다.
- HealthKit에서 대응 기록이 삭제되면 stale episode로 보고 정리한다.
- 로컬 episode만 남아 있을 때 월경 중으로 되살리지 않는다.

## 월경 시작/종료와 자동 종료

- 월경 시작/종료 UseCase는 HealthKit 기록과 로컬 episode 의미를 함께 고려한다.
- 자동 종료는 HealthKit 기록의 대체가 아니라 사용자 흐름을 보조하는 안전장치다.
- 종료/자동 종료 로직을 바꿀 때는 stale 정리와 refresh 흐름까지 함께 확인한다.

## 예측 엔진

- `MenstrualPredictionEngine`은 예측의 중심이다.
- 파라미터 조정은 가능한 한 `Config.default`에 집중한다.
- 로직 변경 전 실패하는 단위 테스트를 먼저 추가한다.
- 현재 월경 중일 때 예측 anchor용 open record를 임시 주입하는 흐름을 오해하지 않는다. 이것은 HealthKit 원본이 open record라는 뜻이 아니다.

## Home Phase 판정

- `HomePhaseUseCaseImpl.execute()`의 판정 순서는 핵심 비즈니스 로직이다.
- 진행 중 월경, 배란기, 난포기, 황체기, fallback의 우선순위를 임의로 바꾸지 않는다.
- Phase window 변경은 `HomePhaseUseCaseTests`로 먼저 고정한다.

## EventKit 캘린더 동기화

- Core의 EventKit DataStore는 시스템 캘린더 CRUD를 담당한다.
- Data의 EventKit Repository는 도메인 요청을 캘린더 이벤트로 변환한다.
- `Presentation/App/UseCase/`의 `SyncMenstrualCalendarUseCase`는 동기화 의도를 조율한다.
- 실제 권한, 캘린더 생성, 이벤트 반영은 시뮬레이터만으로 충분하지 않을 수 있다.

### 동기화는 증분(set-diff)이다 — 전부 삭제+재생성 금지

- 캘린더 자체는 삭제하지 않고 유지한다(공유 설정 보존). 내부의 미리듬 이벤트만 다룬다.
- "내보낼 이벤트 집합"과 "캘린더에서 읽어온 기존 미리듬 이벤트 집합"을 비교해 **차이만** 반영한다: 없는 건 추가, 불필요한 건 삭제, 같은 건 그대로 둔다. 변동이 없으면 `commit`도 하지 않는다.
- 비교 키 = `(title, 시작일, 종료일)`이며 **캘린더에서 읽어온 실제 이벤트 필드** 기준이다(URL로 비교하지 않는다 — 사용자가 캘린더 앱에서 직접 수정한 것을 감지하려면 실제 값을 봐야 한다).
- 종일 이벤트는 EventKit이 종료일을 inclusive(마지막 날)로 read-back하므로, mapper의 exclusive(+1) 종료일은 비교 시 -1일 보정해 맞춘다.
- 미리듬 이벤트는 `mithm://` URL(`isMithmEvent`)로만 식별한다. URL 없는 사용자 일정은 후보에서 제외되어 보존된다.
- 기존 이벤트 조회는 현재 기준 -40~+2년을 3년 청크(EventKit predicate 4년 한도)로 나눠 수행하고, 구간 경계 중복은 dedupe한다.
- 변경 검증: 실기기에서 sync 2회 연속 시 2번째가 removed=0/created=0이면 정상. 캘린더 앱에서 이벤트를 옮긴 뒤 sync하면 그 이벤트만 교정되어야 한다.

## Foreground refresh

- 앱이 active로 돌아올 때 HealthKit에서 최신 상태를 다시 읽는다.
- 사용자가 Apple Health에서 기록을 수정/삭제한 뒤 돌아오는 흐름을 고려한다.
- refresh 변경은 `AppState`, 관련 UseCase, stale episode 정리를 함께 확인한다.

## 자동 테스트와 실기기 검증 경계

자동 테스트 우선:
- 예측 엔진
- Phase 판정
- 날짜/record 필터링
- stale episode 정리
- UseCase 오케스트레이션
- Mapper의 날짜 변환 규칙

실기기 체크리스트 허용:
- HealthKit 권한 요청
- Apple Health 앱에 실제 기록 반영
- Apple Health에서 수정/삭제 후 Mithm 갱신
- EventKit 권한 요청
- 실제 캘린더 이벤트 생성/수정/삭제

실기기 흐름도 구현 전에 검증 절차와 기대 결과를 먼저 문서화한다.
