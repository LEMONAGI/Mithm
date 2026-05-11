# Mithm AI 작업 지침

> 이 파일은 루트 진입 문서다. 자세한 규칙은 `docs/agent/`와 각 영역의 `AGENTS.md` 또는 `CLAUDE.md`에서 필요한 것만 읽는다.

## 프로젝트

**Mithm(미듬)** — 월경 주기 기록을 넘어 몸의 변화(월경기, 난포기, 배란기, 황체기)를 인식하고 일정을 조율하도록 돕는 iOS 앱.

- SwiftUI + HealthKit + EventKit
- 외부 의존성 없음
- 단일 Xcode 프로젝트: `Mithm/Mithm.xcodeproj`
- 아키텍처: Clean Architecture + MVVM

## 필수 시작 순서

1. 이 루트 문서를 읽는다.
2. 작업 유형에 맞는 `docs/agent/` 문서를 읽는다.
3. 수정 대상 영역의 `AGENTS.md` 또는 `CLAUDE.md`를 읽는다.
4. 관련 코드와 기존 테스트를 먼저 탐색한다.
5. 코드 변경 전 테스트 또는 검증 기준을 먼저 작성한다.
6. 최소 구현 후 테스트, 빌드, 또는 수동 체크로 검증한다.

## 공통 문서 지도

- 구조와 시작 위치: `docs/agent/architecture.md`
- 설계 결정 기록: `docs/agent/decisions.md`
- HealthKit/EventKit/예측/refresh 핵심 흐름: `docs/agent/critical-flows.md`
- 작업 절차, TDD, 검증 원칙: `docs/agent/working-rules.md`
- 큰 작업 분해와 step 카드: `docs/agent/task-harness.md`
- 제품 맥락, 한국어 톤, UX 원칙: `docs/agent/product-context.md`

## 영역별 가이드

각 영역에는 `AGENTS.md`와 `CLAUDE.md`가 같은 내용으로 존재한다. 작업 영역만 골라 읽는다.

- Domain: `Mithm/Mithm/Domain/`
- Data: `Mithm/Mithm/Data/`
- Core: `Mithm/Mithm/Core/`
- Presentation: `Mithm/Mithm/Presentation/`
- Tests: `Mithm/MithmTests/`

## 절대 규칙

- 의존성 방향은 `Presentation -> Domain <- Data <- Core`를 유지한다.
- Domain은 Data/Core/Presentation을 import하지 않는다.
- Core는 Domain/Data/Presentation을 import하지 않는다.
- HealthKit이 월경 기록의 단일 진실 공급원이다.
- UserDefaults는 월경 기록 저장소가 아니다.
- 외부 라이브러리, DI 프레임워크, DB 프레임워크를 추가하지 않는다.
- 사용자에게 보이는 문자열과 문서는 한국어로 작성한다.

## TDD 원칙

코드 변경은 TDD-first로 진행한다.

- 테스트 가능한 로직은 실패하는 Swift Testing 테스트를 먼저 작성한다.
- 실기기 의존 흐름은 구현 전에 검증 가능한 절차와 기대 결과를 먼저 작성한다.
- 순수 UI 스타일 변경은 화면 확인 기준을 먼저 정한다.
- 문서 전용 변경은 문서 동일성, 링크, 경로 검증을 먼저 정한다.

## 검증 원칙

- Domain 로직: 관련 단위 테스트 실행
- Data Mapper/Repository 계약: 가능한 단위 테스트와 필요한 빌드 실행
- Presentation 일반 변경: 빌드와 화면 확인
- HealthKit/EventKit 권한 및 실제 시스템 반영: 실기기 체크리스트 병행
- 문서 변경: `AGENTS.md` / `CLAUDE.md` 동일성, 링크, 경로 확인

시뮬레이터 이름을 가정하지 않는다. 빌드/테스트 전에 설치된 iPhone 시뮬레이터를 확인한다.

```bash
xcrun simctl list devices available | rg "iPhone"
```

자세한 빌드/테스트 명령은 `docs/agent/working-rules.md`를 따른다.

## 문서 동기화

- 루트 `AGENTS.md`와 `CLAUDE.md`는 반드시 동일하게 유지한다.
- 영역별 `AGENTS.md`와 `CLAUDE.md`도 반드시 동일하게 유지한다.
- 세부 규칙은 루트에 길게 추가하지 말고 `docs/agent/` 또는 해당 영역 문서에 추가한다.
