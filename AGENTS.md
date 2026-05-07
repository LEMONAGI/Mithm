# Mithm — Claude Code / AI 에이전트 작업 지침

> 이 파일은 **map** 역할을 한다. 작업 시 해당 영역의 `CLAUDE.md`(Claude Code) 또는 `AGENTS.md`(Codex/Cursor/Antigravity)를 먼저 읽고 진행한다.
>
> root에 모든 가이드를 몰아넣지 않고 영역별로 분리한 이유는 토큰 효율 + 컨텍스트 정확도다.
> 작업 영역만 정확히 참조하면 다른 영역 가이드가 컨텍스트를 오염시키지 않는다.

## 프로젝트

**Mithm(미듬)** — 월경 주기 기록을 넘어 몸의 변화(월경기·난포기·배란기·황체기)를 인식하고 일정을 조율하도록 돕는 iOS 앱.  
SwiftUI + HealthKit + EventKit. 외부 의존성 없음. 단일 타겟.

- Xcode 프로젝트: `Mithm/Mithm.xcodeproj`
- 아키텍처: Clean Architecture + MVVM. 의존성 방향: **Presentation → Domain ← Data ← Core**

## 프로젝트 구조

```
Mithm/
├── Mithm.xcodeproj
├── Mithm/                      # 앱 소스
│   ├── Core/                   # HealthKit/EventKit 네이티브 래퍼
│   ├── Data/                   # Repository 구현체 + Mapper
│   ├── Domain/                 # UseCase / State / Model / 예측엔진
│   ├── Presentation/           # SwiftUI View + ViewModel + AppDIContainer
│   ├── Resource/               # 폰트, 색상, 로컬라이징 (Presentation과 함께 작업)
│   └── Utility/                # FormatterUtility 등 (Presentation과 함께 작업)
└── MithmTests/                 # Swift Testing 단위 테스트
```

## 빌드 / 테스트

```bash
# 빌드
xcodebuild build \
  -project Mithm/Mithm.xcodeproj -scheme Mithm \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# 전체 테스트
xcodebuild test \
  -project Mithm/Mithm.xcodeproj -scheme Mithm \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

XcodeBuildMCP 툴이 사용 가능하면 셸 명령보다 우선 사용 (`session_show_defaults` → `build_run_sim` / `test_sim`).

## 영역별 가이드

작업 영역에 해당하는 가이드를 먼저 읽고 진행한다.

- **Domain** — 비즈니스 로직 (UseCase, 예측엔진, 상태) → [`Mithm/Mithm/Domain/CLAUDE.md`](Mithm/Mithm/Domain/CLAUDE.md)
- **Data** — Repository 구현체 + HealthKit/EventKit Mapper → [`Mithm/Mithm/Data/CLAUDE.md`](Mithm/Mithm/Data/CLAUDE.md)
- **Core** — HealthKit/EventKit 네이티브 API 래퍼 → [`Mithm/Mithm/Core/CLAUDE.md`](Mithm/Mithm/Core/CLAUDE.md)
- **Presentation** — SwiftUI View/ViewModel/DI + Resource/Utility → [`Mithm/Mithm/Presentation/CLAUDE.md`](Mithm/Mithm/Presentation/CLAUDE.md)
- **MithmTests** — 단위 테스트 (예측엔진, Phase 판정, UseCase) → [`Mithm/MithmTests/CLAUDE.md`](Mithm/MithmTests/CLAUDE.md)

## 영역 가이드의 구조

각 영역의 가이드 파일은 다음 7섹션으로 구성된다:

1. **WHAT** — 이 모듈이 무엇을 하는가
2. **CONTENTS** — 디렉토리 맵 + 기술 스택
3. **HOW** — 일반적인 수정은 어떻게 하는가
4. **HOW NOT** — 시스템을 깨뜨리는 비명백한 함정
5. **WHERE** — 다른 모듈과의 의존성
6. **WHY** — 코드에 안 적힌 배경 지식
7. **LEARNED CAUTIONS** — `learn` 스킬로 누적

## 코드 컨벤션

- **언어**: 사용자에게 보이는 문자열·주석·문서는 한국어. 식별자는 영어.
- **커밋**: `[Feat]`, `[Fix]`, `[Refactor]`, `[Merge]` prefix + PR 번호 `#19` 형식.
- **Demo/ 폴더**: Core/HealthKit/Demo/, Core/EventKit/Demo/ 등 — 개발/디버깅용, 본 앱 흐름 미포함.

## 주의사항 학습 (learn 스킬)

작업 중 실수가 발견되면 해당 영역 가이드 파일의 "⚠️ LEARNED CAUTIONS" 섹션에 누적한다.

- Claude Code/Cursor/Antigravity: `/learn <메모>` (인자 없이도 호출 가능)
- Codex: `$learn <메모>`

스킬 위치: `.claude/skills/learn/SKILL.md` (Claude Code), `.agents/skills/learn/SKILL.md` (기타)
