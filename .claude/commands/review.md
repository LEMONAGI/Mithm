# Command: review

Mithm 변경사항을 리뷰할 때 사용한다. 리뷰는 문제와 회귀 위험을 먼저 찾는다.

## 읽을 문서

1. `CLAUDE.md`
2. `docs/agent/working-rules.md`
3. `docs/agent/critical-flows.md`
4. 작업 내용에 맞는 영역별 `CLAUDE.md`

## 리뷰 기준

- TDD-first 원칙을 지켰는가
- 테스트 또는 검증 기준이 구현 전에 정의됐는가
- Domain/Data/Core/Presentation 의존성 방향을 어기지 않았는가
- HealthKit이 월경 기록의 단일 진실 공급원이라는 결정을 지켰는가
- `CurrentMenstrualEpisode`를 기록 저장소로 오해하지 않았는가
- 예측/Phase/refresh 핵심 흐름에 회귀 위험이 없는가
- 실기기 의존 흐름은 구체적인 체크리스트가 있는가
- 사용자에게 보이는 문자열은 한국어와 제품 톤에 맞는가
- `AGENTS.md` / `CLAUDE.md` 동일성이 유지됐는가

## 출력 방식

- 발견 사항을 심각도 순으로 먼저 쓴다.
- 파일과 줄 번호를 가능한 한 구체적으로 적는다.
- 문제가 없으면 그렇게 말하고, 남은 테스트 공백이나 수동 검증 필요성을 적는다.
