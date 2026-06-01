# Data 작업 가이드

> 이 가이드는 에이전트가 이 영역에서 코드를 건드리기 전에 반드시 알아야 할 컨텍스트를 담는다.
> 코드만 읽어선 알 수 없는 의도/함정/배경이 핵심이다.

## 1. WHAT — 이 모듈은 무엇을 하는가

HealthKit/EventKit 원시 데이터와 UserDefaults를 Domain 모델로 변환하는 Repository 구현체와 Mapper를 담당한다. Domain이 정의한 Repository 프로토콜을 구현하여 상위 계층(Domain/Presentation)이 데이터 출처를 알지 않아도 되게 한다.

## 2. CONTENTS — 파일/디렉토리와 기술 스택

- `HealthKit/HealthKitRepositoryImpl.swift` — HealthKit Repository 구현체 (읽기/쓰기 조율)
- `HealthKit/Mapper/` — HealthKit 샘플 ↔ 도메인 모델(`MenstrualRecord` 등) 변환
- `EventKit/EventKitRepositoryImpl.swift` — 캘린더 동기화 Repository 구현체
- `UserSetting/UserSettingRepositoryImpl.swift` — UserDefaults ↔ `UserSettingState` 변환

기술 스택: Swift, HealthKit, EventKit, Foundation(UserDefaults)

## 3. HOW — 일반적인 수정은 어떻게 하는가

- **새 HealthKit 데이터 읽기**: `Core/HealthKit/Sources/`의 DataStore에 메서드 추가 → `HealthKitRepositoryImpl`에서 호출 → Domain Repository 프로토콜에 인터페이스 추가
- **Mapper 수정**: HealthKit 샘플의 `startDate`/`endDate`를 도메인 `MenstrualRecord`로 변환하는 로직. 샘플 날짜 범위를 그대로 닫힌 record로 읽는 것이 원칙
- **사용자 설정 추가**: `Domain/Repository/UserSettingRepository.swift`에 프로토콜 메서드 추가 → `UserSettingRepositoryImpl`에 구현 → `Domain/State/UserSettingState.swift` 반영
- **캘린더 동기화 수정**: `EventKitRepositoryImpl` + `Domain/UseCase/`의 `SyncMenstrualCalendarUseCase` 함께 확인. 동기화는 증분(set-diff)이다 — 캘린더에서 읽어온 기존 미리듬 이벤트와 내보낼 집합의 차이만 반영한다(변동 없으면 commit도 안 함)

## 4. ⛔ HOW NOT — 시스템을 깨뜨리는 비명백한 함정

- **Mapper에서 HealthKit 샘플의 `endDate`를 nil로 변환 금지** — Mapper는 샘플 날짜 범위를 그대로 닫힌 record로 읽는다. "오늘 샘플이라도 endDate를 nil로 바꾸지 않는다"는 규칙이 있다. 어기면 `CurrentMenstrualStatusResolver`의 월경 중 판정이 틀어진다
- **UserDefaults를 HealthKit 대체 영속 저장소로 사용 금지** — `CurrentMenstrualEpisode`(UserDefaults)는 "사용자가 종료했는지/자동 종료됐는지"만 보조로 기억하는 플래그다. 월경 기록 자체를 UserDefaults에 저장하면 HealthKit과 불일치가 발생한다
- **Data 계층이 Presentation을 import 금지** — 의존성 방향: `Presentation → Domain ← Data ← Core`
- **HealthKit 샘플 저장 시 날짜 범위 재해석 금지** — `HealthKitRepositoryImpl.updateMenstrualCycleRecord`는 정확한 시작일~종료일을 Core에 그대로 전달해야 한다. Data에서 날짜를 임의로 확장/축소하면 HealthKit에 잘못된 기록이 남는다
- **캘린더 동기화를 전부 삭제+재생성으로 되돌리기 금지** — 매번 이벤트를 전부 지우고 다시 만들면 공유 캘린더 구독자에게 변경 알림이 폭탄처럼 발생한다. 반드시 set-diff로 변경분만 반영한다. 비교는 앱이 써둔 URL이 아니라 **캘린더에서 읽어온 실제 이벤트 필드(`title`, 시작일, 종료일)** 기준이어야 사용자의 직접 수정을 감지한다. 종일 이벤트 종료일은 read-back 시 inclusive(마지막 날)라 mapper의 exclusive 종료일을 비교 시 -1일 보정한다

## 5. WHERE — 다른 모듈과의 의존성

- **의존**: `Core/`(HealthKit/EventKit DataStore 호출), `Domain/`(Repository 프로토콜 준수, 도메인 모델 사용)
- **피의존**: `Presentation/App/AppDIContainer.swift`에서 구현체를 생성하여 Domain UseCase에 주입
- **경계**: `Domain/Repository/` 프로토콜이 Data ↔ Domain 계약 지점. `Core/HealthKit/Sources/`의 DataStore 프로토콜이 Data ↔ Core 계약 지점

## 6. WHY — 코드에 안 적힌 배경 지식

- **자체 영속 저장소(SwiftData/CoreData) 없음** — 모든 월경 기록은 Apple Health에 저장되고, 앱은 매번 HealthKit에서 읽어 예측을 실시간 계산한다. 앱을 삭제하고 재설치해도 데이터가 살아있는 것이 이 구조의 장점이다
- **`RefreshMenstrualCycleUseCaseImpl`이 stale 로컬 episode를 정리하는 이유** — 사용자가 건강 앱에서 월경 기록을 삭제했을 때, 앱이 다시 월경 중으로 되살리거나 자동 종료를 재저장하지 않게 하기 위함이다. HealthKit에 대응되는 시작일이 없는 로컬 episode는 stale로 보고 `clearCurrentEpisode()`로 정리한다
- **캘린더 동기화가 증분(set-diff)인 이유** — 과거에 캘린더를 통째로 삭제(사용자 공유 설정 소실)하거나 내부 이벤트를 전부 재생성(공유 알림 폭탄)하던 방식을 거쳐, 지금은 변경분만 교체한다. 자세한 배경/검증은 `docs/agent/decisions.md` ADR-009와 `docs/agent/critical-flows.md` "EventKit 캘린더 동기화" 참조

_(이 영역의 비명백한 함정·배경 지식이 더 있다면 자유롭게 추가하세요. `learn` 스킬(`/learn` 또는 `$learn`)로도 누적 가능합니다.)_

## 7. ⚠️ LEARNED CAUTIONS — 학습된 주의사항
> `learn` 스킬(`/learn` 또는 Codex의 `$learn`)로 누적되는 영역.

_(아직 없음)_
