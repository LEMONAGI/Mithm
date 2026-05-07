//
//  MaintainabilityRefactorTests.swift
//  MithmTests
//

import Foundation
import Testing
@testable import Mithm

@MainActor
struct RecordCurrentMenstrualPeriodUseCaseTests {

    private let calendar = RefactorTestCalendar.make()

    @Test("월경 시작은 날짜를 정규화하고 open episode를 저장한다")
    func startNormalizesDateAndPersistsOpenEpisode() async throws {
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase()
        let episodeStore = FakeCurrentMenstrualEpisodeStore()
        let useCase = RecordCurrentMenstrualPeriodUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            currentMenstrualEpisodeStore: episodeStore,
            calendar: calendar
        )

        try await useCase.start(on: date("2026-03-10 15:30"))

        let savedRecord = try #require(menstrualRecordUseCase.savedRecords.first)
        #expect(savedRecord.record.type == .menstrualRecord)
        #expect(savedRecord.record.startDate == date("2026-03-10 00:00"))
        #expect(savedRecord.record.endDate == date("2026-03-10 00:00"))
        #expect(savedRecord.deleteFrom == date("2026-03-10 00:00"))
        #expect(savedRecord.deleteThrough == date("2026-03-10 00:00"))
        #expect(episodeStore.episode?.startDate == date("2026-03-10 00:00"))
        #expect(episodeStore.episode?.endDate == nil)
        #expect(episodeStore.episode?.closedReason == nil)
    }

    @Test("월경 종료는 시작일보다 이른 종료일을 시작일로 보정하고 closed episode를 저장한다")
    func endClampsEndDateAndPersistsClosedEpisode() async throws {
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase()
        let episodeStore = FakeCurrentMenstrualEpisodeStore()
        let now = date("2026-03-20 09:00")
        let useCase = RecordCurrentMenstrualPeriodUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            currentMenstrualEpisodeStore: episodeStore,
            calendar: calendar,
            now: { now }
        )
        let status = CurrentMenstrualStatus(
            isActive: true,
            activeStartDate: date("2026-03-10 00:00"),
            latestStartDate: date("2026-03-10 00:00"),
            expectedEndDate: date("2026-03-14 00:00"),
            shouldAutoClose: false
        )

        let didEnd = try await useCase.end(
            on: date("2026-03-08 13:00"),
            currentStatus: status
        )

        let savedRecord = try #require(menstrualRecordUseCase.savedRecords.first)
        #expect(didEnd)
        #expect(savedRecord.record.startDate == date("2026-03-10 00:00"))
        #expect(savedRecord.record.endDate == date("2026-03-10 00:00"))
        #expect(savedRecord.deleteFrom == date("2026-03-10 00:00"))
        #expect(savedRecord.deleteThrough == now)
        #expect(episodeStore.episode?.endDate == date("2026-03-10 00:00"))
        #expect(episodeStore.episode?.closedReason == .userEnded)
    }

    @Test("활성 월경 상태가 없으면 월경 종료 액션은 저장하지 않는다")
    func endWithoutActiveStatusDoesNotPersist() async throws {
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase()
        let episodeStore = FakeCurrentMenstrualEpisodeStore()
        let useCase = RecordCurrentMenstrualPeriodUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            currentMenstrualEpisodeStore: episodeStore,
            calendar: calendar
        )

        let didEnd = try await useCase.end(
            on: date("2026-03-10 00:00"),
            currentStatus: .inactive()
        )

        #expect(!didEnd)
        #expect(menstrualRecordUseCase.savedRecords.isEmpty)
        #expect(episodeStore.episode == nil)
    }

    @Test("오늘 종료한 표시용 월경 기간은 다시 종료 기록을 저장할 수 있다")
    func endPersistsAgainWhenDisplayWindowExists() async throws {
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase()
        let episodeStore = FakeCurrentMenstrualEpisodeStore()
        let now = date("2026-05-03 18:00")
        let useCase = RecordCurrentMenstrualPeriodUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            currentMenstrualEpisodeStore: episodeStore,
            calendar: calendar,
            now: { now }
        )
        let status = CurrentMenstrualStatus.inactive(
            latestStartDate: date("2026-05-01 00:00"),
            expectedEndDate: date("2026-05-05 00:00"),
            displayWindow: MenstrualDisplayWindow(
                startDate: date("2026-05-01 00:00"),
                endDate: date("2026-05-03 00:00")
            )
        )

        let firstDidEnd = try await useCase.end(
            on: date("2026-05-03 12:00"),
            currentStatus: status
        )
        let secondDidEnd = try await useCase.end(
            on: date("2026-05-03 13:00"),
            currentStatus: status
        )

        #expect(firstDidEnd)
        #expect(secondDidEnd)
        #expect(menstrualRecordUseCase.savedRecords.count == 2)
        #expect(menstrualRecordUseCase.savedRecords.allSatisfy {
            $0.record.startDate == date("2026-05-01 00:00")
                && $0.record.endDate == date("2026-05-03 00:00")
                && $0.deleteFrom == date("2026-05-01 00:00")
                && $0.deleteThrough == now
        })
        #expect(episodeStore.episode?.startDate == date("2026-05-01 00:00"))
        #expect(episodeStore.episode?.endDate == date("2026-05-03 00:00"))
        #expect(episodeStore.episode?.closedReason == .userEnded)
    }

    private func date(_ value: String) -> Date {
        RefactorTestCalendar.dateTime(value, calendar: calendar)
    }
}

@MainActor
struct RefreshMenstrualCycleUseCaseTests {

    private let calendar = RefactorTestCalendar.make()

    @Test("진행 중 월경이 있으면 active start date로 overview를 한 번 더 조회한다")
    func refreshRefetchesOverviewWithActiveStartDate() async throws {
        let activeStartDate = date("2026-03-10")
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase(
            overviewResponses: [
                overview(
                    actualRecords: [record(.menstrualRecord, "2026-03-10", "2026-03-10")],
                    predictedPeriodLength: 5
                ),
                overview(
                    actualRecords: [record(.menstrualRecord, "2026-03-10", "2026-03-10")],
                    predictedPeriodLength: 5
                )
            ]
        )
        let episodeStore = FakeCurrentMenstrualEpisodeStore(
            episode: CurrentMenstrualEpisode(
                startDate: activeStartDate,
                endDate: nil,
                closedReason: nil
            )
        )
        let useCase = makeRefreshUseCase(
            menstrualRecordUseCase: menstrualRecordUseCase,
            episodeStore: episodeStore
        )

        _ = try await useCase.execute(
            userSetting: UserSettingState(),
            runAutoClose: false,
            referenceDate: date("2026-03-12")
        )

        #expect(menstrualRecordUseCase.fetchRequests.count == 2)
        #expect(menstrualRecordUseCase.fetchRequests[0].activeMenstrualStartDate == nil)
        #expect(menstrualRecordUseCase.fetchRequests[1].activeMenstrualStartDate == activeStartDate)
    }

    @Test("건강앱에 대응되는 시작일이 없으면 stale current episode를 정리한다")
    func refreshClearsStaleCurrentEpisodeWhenHealthRecordWasDeleted() async throws {
        let episodeStore = FakeCurrentMenstrualEpisodeStore(
            episode: CurrentMenstrualEpisode(
                startDate: date("2026-03-10"),
                endDate: nil,
                closedReason: nil
            )
        )
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase(
            overviewResponses: [
                overview(
                    actualRecords: [],
                    predictedPeriodLength: 5
                )
            ]
        )
        let useCase = makeRefreshUseCase(
            menstrualRecordUseCase: menstrualRecordUseCase,
            episodeStore: episodeStore
        )

        let snapshot = try await useCase.execute(
            userSetting: UserSettingState(),
            runAutoClose: true,
            referenceDate: date("2026-03-17")
        )

        #expect(episodeStore.episode == nil)
        #expect(episodeStore.clearCount == 1)
        #expect(snapshot.currentStatus.isActive == false)
        #expect(snapshot.currentStatus.shouldAutoClose == false)
        #expect(menstrualRecordUseCase.savedRecords.isEmpty)
    }

    @Test("건강앱에 같은 시작일이 있어도 종료일이 달라지면 stale closed episode를 정리한다")
    func refreshClearsStaleClosedEpisodeWhenHealthRecordEndDateChanged() async throws {
        let episodeStore = FakeCurrentMenstrualEpisodeStore(
            episode: CurrentMenstrualEpisode(
                startDate: date("2026-05-01"),
                endDate: date("2026-05-03"),
                closedReason: .userEnded
            )
        )
        let changedOverview = overview(
            actualRecords: [record(.menstrualRecord, "2026-05-01", "2026-05-02")],
            predictedPeriodLength: 5
        )
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase(
            overviewResponses: [
                changedOverview,
                changedOverview
            ]
        )
        let useCase = makeRefreshUseCase(
            menstrualRecordUseCase: menstrualRecordUseCase,
            episodeStore: episodeStore
        )

        let snapshot = try await useCase.execute(
            userSetting: UserSettingState(),
            runAutoClose: false,
            referenceDate: date("2026-05-03")
        )

        #expect(episodeStore.episode == nil)
        #expect(episodeStore.clearCount == 1)
        #expect(snapshot.currentStatus.isActive)
        #expect(snapshot.currentStatus.activeStartDate == date("2026-05-01"))
        #expect(menstrualRecordUseCase.fetchRequests.count == 2)
        #expect(menstrualRecordUseCase.fetchRequests[1].activeMenstrualStartDate == date("2026-05-01"))
    }

    @Test("건강앱의 시작일과 종료일이 같으면 closed episode를 유지한다")
    func refreshKeepsClosedEpisodeWhenHealthRecordRangeMatches() async throws {
        let episode = CurrentMenstrualEpisode(
            startDate: date("2026-05-01"),
            endDate: date("2026-05-03"),
            closedReason: .userEnded
        )
        let episodeStore = FakeCurrentMenstrualEpisodeStore(episode: episode)
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase(
            overviewResponses: [
                overview(
                    actualRecords: [record(.menstrualRecord, "2026-05-01", "2026-05-03")],
                    predictedPeriodLength: 5
                )
            ]
        )
        let useCase = makeRefreshUseCase(
            menstrualRecordUseCase: menstrualRecordUseCase,
            episodeStore: episodeStore
        )

        let snapshot = try await useCase.execute(
            userSetting: UserSettingState(),
            runAutoClose: false,
            referenceDate: date("2026-05-03")
        )

        #expect(episodeStore.episode == episode)
        #expect(episodeStore.clearCount == 0)
        #expect(snapshot.currentStatus.isActive == false)
        #expect(snapshot.currentStatus.displayWindow?.startDate == date("2026-05-01"))
        #expect(snapshot.currentStatus.displayWindow?.endDate == date("2026-05-03"))
        #expect(menstrualRecordUseCase.fetchRequests.count == 1)
    }

    @Test("건강앱 최신 시작일과 로컬 episode 시작일이 다르면 로컬 episode를 무시하고 건강앱 기준으로 갱신한다")
    func refreshIgnoresLocalEpisodeWhenHealthRecordStartDateDiffers() async throws {
        let episodeStore = FakeCurrentMenstrualEpisodeStore(
            episode: CurrentMenstrualEpisode(
                startDate: date("2026-03-10"),
                endDate: nil,
                closedReason: nil
            )
        )
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase(
            overviewResponses: [
                overview(
                    actualRecords: [record(.menstrualRecord, "2026-03-08", "2026-03-08")],
                    predictedPeriodLength: 5
                ),
                overview(
                    actualRecords: [record(.menstrualRecord, "2026-03-08", "2026-03-08")],
                    predictedPeriodLength: 5
                )
            ]
        )
        let useCase = makeRefreshUseCase(
            menstrualRecordUseCase: menstrualRecordUseCase,
            episodeStore: episodeStore
        )

        let snapshot = try await useCase.execute(
            userSetting: UserSettingState(),
            runAutoClose: false,
            referenceDate: date("2026-03-12")
        )

        #expect(episodeStore.episode == nil)
        #expect(episodeStore.clearCount == 1)
        #expect(snapshot.currentStatus.isActive)
        #expect(snapshot.currentStatus.activeStartDate == date("2026-03-08"))
        #expect(menstrualRecordUseCase.fetchRequests.count == 2)
        #expect(menstrualRecordUseCase.fetchRequests[1].activeMenstrualStartDate == date("2026-03-08"))
    }

    @Test("캘린더 동기화 토글 on/off 값은 sync usecase에 그대로 전달된다")
    func refreshPassesCalendarExportToggleToSyncUseCase() async throws {
        let syncUseCase = FakeSyncMenstrualCalendarUseCase()
        let expectedRecords = [record(.menstrualRecord, "2026-01-01", "2026-01-05")]
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase(
            overviewResponses: [
                overview(
                    actualRecords: expectedRecords,
                    allRecords: expectedRecords,
                    predictedPeriodLength: 5
                ),
                overview(
                    actualRecords: expectedRecords,
                    allRecords: expectedRecords,
                    predictedPeriodLength: 5
                )
            ]
        )
        let useCase = makeRefreshUseCase(
            menstrualRecordUseCase: menstrualRecordUseCase,
            syncUseCase: syncUseCase
        )

        _ = try await useCase.execute(
            userSetting: UserSettingState(calendarExportEnabled: true),
            runAutoClose: false,
            referenceDate: date("2026-03-01")
        )
        _ = try await useCase.execute(
            userSetting: UserSettingState(calendarExportEnabled: false),
            runAutoClose: false,
            referenceDate: date("2026-03-01")
        )

        #expect(syncUseCase.calls.count == 2)
        #expect(syncUseCase.calls[0].isEnabled)
        #expect(!syncUseCase.calls[1].isEnabled)
        #expect(syncUseCase.calls[0].records == expectedRecords)
        #expect(syncUseCase.calls[1].records == expectedRecords)
    }

    @Test("자동 종료 조건이면 예상 종료일로 기록을 닫고 autoClosed episode를 저장한다")
    func refreshAutoClosesCurrentEpisodeWhenDeadlinePassed() async throws {
        let activeStartDate = date("2026-03-10")
        let expectedEndDate = date("2026-03-14")
        let referenceDate = date("2026-03-17")
        let openOverview = overview(
            actualRecords: [record(.menstrualRecord, "2026-03-10", "2026-03-10")],
            predictedPeriodLength: 5
        )
        let closedOverview = overview(
            actualRecords: [record(.menstrualRecord, "2026-03-10", "2026-03-14")],
            predictedPeriodLength: 5
        )
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase(
            overviewResponses: [openOverview, openOverview, closedOverview]
        )
        let episodeStore = FakeCurrentMenstrualEpisodeStore(
            episode: CurrentMenstrualEpisode(
                startDate: activeStartDate,
                endDate: nil,
                closedReason: nil
            )
        )
        let useCase = makeRefreshUseCase(
            menstrualRecordUseCase: menstrualRecordUseCase,
            episodeStore: episodeStore
        )

        let snapshot = try await useCase.execute(
            userSetting: UserSettingState(),
            runAutoClose: true,
            referenceDate: referenceDate
        )

        let savedRecord = try #require(menstrualRecordUseCase.savedRecords.first)
        #expect(savedRecord.record.startDate == activeStartDate)
        #expect(savedRecord.record.endDate == expectedEndDate)
        #expect(savedRecord.deleteFrom == activeStartDate)
        #expect(savedRecord.deleteThrough == referenceDate)
        #expect(episodeStore.episode?.endDate == expectedEndDate)
        #expect(episodeStore.episode?.closedReason == .autoClosed)
        #expect(snapshot.overview.actualRecords == closedOverview.actualRecords)
    }

    private func makeRefreshUseCase(
        menstrualRecordUseCase: FakeMenstrualRecordUseCase,
        syncUseCase: FakeSyncMenstrualCalendarUseCase = FakeSyncMenstrualCalendarUseCase(),
        episodeStore: FakeCurrentMenstrualEpisodeStore = FakeCurrentMenstrualEpisodeStore()
    ) -> RefreshMenstrualCycleUseCaseImpl {
        RefreshMenstrualCycleUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            syncMenstrualCalendarUseCase: syncUseCase,
            currentMenstrualEpisodeStore: episodeStore,
            currentMenstrualStatusResolver: CurrentMenstrualStatusResolver(),
            calendar: calendar
        )
    }

    private func overview(
        actualRecords: [MenstrualRecord],
        allRecords: [MenstrualRecord]? = nil,
        predictedPeriodLength: Int?
    ) -> MenstrualOverview {
        MenstrualOverview(
            actualRecords: actualRecords,
            allRecords: allRecords ?? actualRecords,
            prediction: prediction(predictedPeriodLength: predictedPeriodLength)
        )
    }

    private func prediction(predictedPeriodLength: Int?) -> MenstrualPredictionResult {
        MenstrualPredictionResult(
            menstrualPredictions: [],
            predictedCycleLength: 28,
            predictedPeriodLength: predictedPeriodLength,
            confidence: .medium,
            usedRecordCount: 3,
            detectedShift: false,
            usedDefaultRule: false
        )
    }

    private func record(
        _ type: MenstrualRecordType,
        _ start: String,
        _ end: String?
    ) -> MenstrualRecord {
        MenstrualRecord(
            type: type,
            startDate: date(start),
            endDate: end.map(date)
        )
    }

    private func date(_ value: String) -> Date {
        RefactorTestCalendar.date(value, calendar: calendar)
    }
}

@MainActor
struct AppStateRefreshTests {

    @Test("foreground refresh는 자동 종료 없이 snapshot을 화면 상태에 반영한다")
    func foregroundRefreshAppliesSnapshotWithoutAutoClose() async {
        let overview = MenstrualOverview(
            actualRecords: [record("2026-01-01", "2026-01-05")],
            allRecords: [record("2026-01-01", "2026-01-05")],
            prediction: nil
        )
        let expectedStatus = CurrentMenstrualStatus.inactive(
            latestStartDate: date("2026-01-01"),
            expectedEndDate: date("2026-01-05")
        )
        let refreshUseCase = FakeRefreshMenstrualCycleUseCase(
            snapshot: MenstrualCycleSnapshot(
                overview: overview,
                currentStatus: expectedStatus,
                didAutoClose: false
            )
        )
        let appState = AppState(
            menstrualRecordUseCase: FakeMenstrualRecordUseCase(),
            refreshMenstrualCycleUseCase: refreshUseCase,
            loadUserSettingsUseCase: FakeLoadUserSettingsUseCase()
        )

        await appState.refreshOnForeground()

        #expect(refreshUseCase.calls.count == 1)
        #expect(!refreshUseCase.calls[0].runAutoClose)
        #expect(appState.menstrualOverview.actualRecords == overview.actualRecords)
        #expect(appState.currentMenstrualStatus == expectedStatus)
    }

    @Test("initial load는 설정을 불러오고 최초 1회만 자동 종료 refresh를 요청한다")
    func initialLoadRequestsAutoCloseOnlyOnce() async {
        let settings = UserSettingState(
            menstrualUserInput: MenstrualUserInput(cycleLength: 31, periodLength: 6),
            calendarExportEnabled: true,
            userInputMode: .blendUserInput
        )
        let menstrualRecordUseCase = FakeMenstrualRecordUseCase()
        let refreshUseCase = FakeRefreshMenstrualCycleUseCase()
        let appState = AppState(
            menstrualRecordUseCase: menstrualRecordUseCase,
            refreshMenstrualCycleUseCase: refreshUseCase,
            loadUserSettingsUseCase: FakeLoadUserSettingsUseCase(settings: settings)
        )

        await appState.performInitialLoad()
        await appState.performInitialLoad()

        #expect(menstrualRecordUseCase.requestedAuthorizationCount == 2)
        #expect(refreshUseCase.calls.map(\.runAutoClose) == [true, false])
        #expect(appState.userSetting.calendarExportEnabled)
        #expect(appState.userSetting.menstrualUserInput?.cycleLength == 31)
        #expect(appState.userSetting.menstrualUserInput?.periodLength == 6)
        #expect(appState.userSetting.userInputMode == .blendUserInput)
    }

    private func record(_ start: String, _ end: String) -> MenstrualRecord {
        MenstrualRecord(
            type: .menstrualRecord,
            startDate: date(start),
            endDate: date(end)
        )
    }

    private func date(_ value: String) -> Date {
        RefactorTestCalendar.date(
            value,
            calendar: RefactorTestCalendar.make()
        )
    }
}

@MainActor
struct HomeViewModelEndMenstruationTests {

    private let calendar = RefactorTestCalendar.make()

    @Test("월경 종료일이 오늘이면 저장 성공 후 완료 알럿 표시 대상으로 반환한다")
    func endTodayReturnsEndsTodayAlertKind() async {
        let viewModel = makeViewModel(
            endResult: true,
            now: dateTime("2026-05-04 10:00")
        )

        let result = await viewModel.endMenstruation(
            endDate: dateTime("2026-05-04 08:00")
        )

        #expect(result.didRecord)
        #expect(result.completionAlertKind == .endsToday)
    }

    @Test("월경 종료일이 오늘 이전이면 일반 기록 완료 알럿 대상으로 반환한다")
    func endPastDateReturnsRecordedAlertKind() async {
        let viewModel = makeViewModel(
            endResult: true,
            now: dateTime("2026-05-04 10:00")
        )

        let result = await viewModel.endMenstruation(
            endDate: dateTime("2026-05-03 08:00")
        )

        #expect(result.didRecord)
        #expect(result.completionAlertKind == .recorded)
    }

    @Test("월경 종료 저장이 수행되지 않으면 알럿 대상으로 반환하지 않는다")
    func ignoredEndReturnsNoAlertKind() async {
        let viewModel = makeViewModel(
            endResult: false,
            now: dateTime("2026-05-04 10:00")
        )

        let result = await viewModel.endMenstruation(
            endDate: dateTime("2026-05-04 08:00")
        )

        #expect(!result.didRecord)
        #expect(result.completionAlertKind == nil)
    }

    @Test("월경 종료 결과는 데이터 refresh 완료를 기다리지 않고 반환한다")
    func endReturnsBeforeRefreshCompletes() async {
        let clock = ContinuousClock()
        let viewModel = makeViewModel(
            endResult: true,
            now: dateTime("2026-05-04 10:00"),
            refreshUseCase: FakeRefreshMenstrualCycleUseCase(
                delayNanoseconds: 300_000_000
            )
        )

        let start = clock.now
        let result = await viewModel.endMenstruation(
            endDate: dateTime("2026-05-04 08:00")
        )
        let elapsed = start.duration(to: clock.now)

        #expect(result.didRecord)
        #expect(result.completionAlertKind == .endsToday)
        #expect(elapsed < .milliseconds(150))
    }

    @Test("월경 종료 후 refresh가 실패해도 저장 성공 알럿 결과를 먼저 반환하고 에러 상태를 반영한다")
    func endReturnsAlertKindAndStoresRefreshError() async {
        let refreshUseCase = FakeRefreshMenstrualCycleUseCase(
            error: FakeRefreshError()
        )
        let scenario = makeScenario(
            endResult: true,
            now: dateTime("2026-05-04 10:00"),
            refreshUseCase: refreshUseCase
        )

        let result = await scenario.viewModel.endMenstruation(
            endDate: dateTime("2026-05-04 08:00")
        )
        await waitForBackgroundTasks()

        #expect(result.didRecord)
        #expect(result.completionAlertKind == .endsToday)
        #expect(scenario.appState.menstrualRecordError != nil)
    }

    private func makeViewModel(
        endResult: Bool,
        now: Date,
        refreshUseCase: FakeRefreshMenstrualCycleUseCase = FakeRefreshMenstrualCycleUseCase()
    ) -> HomeViewModel {
        makeScenario(
            endResult: endResult,
            now: now,
            refreshUseCase: refreshUseCase
        ).viewModel
    }

    private func makeScenario(
        endResult: Bool,
        now: Date,
        refreshUseCase: FakeRefreshMenstrualCycleUseCase = FakeRefreshMenstrualCycleUseCase()
    ) -> (viewModel: HomeViewModel, appState: AppState) {
        let appState = AppState(
            menstrualRecordUseCase: FakeMenstrualRecordUseCase(),
            refreshMenstrualCycleUseCase: refreshUseCase,
            loadUserSettingsUseCase: FakeLoadUserSettingsUseCase()
        )
        appState.currentMenstrualStatus = CurrentMenstrualStatus(
            isActive: true,
            activeStartDate: dateTime("2026-05-01 00:00"),
            latestStartDate: dateTime("2026-05-01 00:00"),
            expectedEndDate: dateTime("2026-05-05 00:00"),
            shouldAutoClose: false,
            displayWindow: MenstrualDisplayWindow(
                startDate: dateTime("2026-05-01 00:00"),
                endDate: nil
            )
        )

        let viewModel = HomeViewModel(
            appState: appState,
            calendar: calendar,
            recordCurrentMenstrualPeriodUseCase: FakeRecordCurrentMenstrualPeriodUseCase(
                endResult: endResult
            ),
            homePhaseUseCase: HomePhaseUseCaseImpl(calendar: calendar),
            now: { now }
        )
        return (viewModel, appState)
    }

    private func dateTime(_ value: String) -> Date {
        RefactorTestCalendar.dateTime(value, calendar: calendar)
    }

    private func waitForBackgroundTasks() async {
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
}

@MainActor
struct CycleCalendarUseCaseTests {

    private let calendar = RefactorTestCalendar.make()

    @Test("캘린더 날짜 분류는 기존 UI 우선순위를 보존한다")
    func dayKindPreservesExistingPriority() {
        let useCase = CycleCalendarUseCaseImpl(calendar: calendar)
        let records = [
            record(.menstrualRecord, "2026-03-10", "2026-03-14"),
            record(.ovulationPrediction, "2026-03-12", "2026-03-12"),
            record(.ovulationFertileWindowPrediction, "2026-03-11", "2026-03-16"),
            record(.ovulationPrediction, "2026-03-18", "2026-03-18")
        ]

        let month = useCase.makeMonth(
            displayedMonth: date("2026-03-01"),
            records: records,
            today: date("2026-03-20")
        )

        #expect(month.days.count == 42)
        #expect(day("2026-03-12", in: month).kind == .menstrual)
        #expect(day("2026-03-15", in: month).kind == .fertileWindow)
        #expect(day("2026-03-18", in: month).kind == .ovulationDay)
        #expect(day("2026-03-20", in: month).kind == .none)
        #expect(day("2026-03-20", in: month).isToday)
        #expect(!day("2026-03-18", in: month).isToday)
    }

    @Test("오늘 표시는 기간 분류와 독립적으로 보존된다")
    func todayFlagIsIndependentFromDayKind() {
        let useCase = CycleCalendarUseCaseImpl(calendar: calendar)
        let records = [
            record(.menstrualRecord, "2026-03-10", "2026-03-14"),
            record(.ovulationPrediction, "2026-03-18", "2026-03-18"),
            record(.ovulationFertileWindowPrediction, "2026-03-20", "2026-03-24")
        ]

        let menstrualMonth = useCase.makeMonth(
            displayedMonth: date("2026-03-01"),
            records: records,
            today: date("2026-03-12")
        )
        #expect(day("2026-03-12", in: menstrualMonth).kind == .menstrual)
        #expect(day("2026-03-12", in: menstrualMonth).isToday)

        let ovulationDayMonth = useCase.makeMonth(
            displayedMonth: date("2026-03-01"),
            records: records,
            today: date("2026-03-18")
        )
        #expect(day("2026-03-18", in: ovulationDayMonth).kind == .ovulationDay)
        #expect(day("2026-03-18", in: ovulationDayMonth).isToday)

        let fertileWindowMonth = useCase.makeMonth(
            displayedMonth: date("2026-03-01"),
            records: records,
            today: date("2026-03-21")
        )
        #expect(day("2026-03-21", in: fertileWindowMonth).kind == .fertileWindow)
        #expect(day("2026-03-21", in: fertileWindowMonth).isToday)
    }

    private func day(_ value: String, in month: CycleCalendarMonth) -> CycleCalendarDay {
        month.days.first {
            calendar.isDate($0.date, inSameDayAs: date(value))
        }!
    }

    private func record(
        _ type: MenstrualRecordType,
        _ start: String,
        _ end: String?
    ) -> MenstrualRecord {
        MenstrualRecord(
            type: type,
            startDate: date(start),
            endDate: end.map(date)
        )
    }

    private func date(_ value: String) -> Date {
        RefactorTestCalendar.date(value, calendar: calendar)
    }
}

struct ArchitectureBoundaryTests {

    @Test("Domain은 Presentation 및 platform framework import에 의존하지 않는다")
    func domainDoesNotImportPresentationOrPlatformFrameworks() throws {
        let domainURL = projectRoot
            .appendingPathComponent("Mithm")
            .appendingPathComponent("Domain")
        let forbiddenSnippets = [
            "import SwiftUI",
            "import HealthKit",
            "import EventKit",
            "import Combine",
            "Bundle.main"
        ]
        let swiftFiles = try swiftFileURLs(under: domainURL)
            .filter { !$0.path.contains("/Demo/") }
        var violations: [String] = []

        for fileURL in swiftFiles {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            for snippet in forbiddenSnippets where source.contains(snippet) {
                violations.append("\(relativePath(fileURL)): \(snippet)")
            }
        }

        #expect(violations.isEmpty)
    }

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func swiftFileURLs(under rootURL: URL) throws -> [URL] {
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: Array(resourceKeys)
        ) else {
            return []
        }

        return try enumerator.compactMap { item in
            guard let fileURL = item as? URL,
                  fileURL.pathExtension == "swift"
            else {
                return nil
            }

            let values = try fileURL.resourceValues(forKeys: resourceKeys)
            return values.isRegularFile == true ? fileURL : nil
        }
    }

    private func relativePath(_ fileURL: URL) -> String {
        fileURL.path.replacingOccurrences(
            of: projectRoot.path + "/",
            with: ""
        )
    }
}

private struct SavedMenstrualRecord {
    let record: MenstrualRecord
    let deleteFrom: Date?
    let deleteThrough: Date?
}

private struct FetchMenstrualOverviewRequest {
    let activeMenstrualStartDate: Date?
    let userInput: MenstrualUserInput?
    let userInputMode: UserInputMode?
}

private final class FakeMenstrualRecordUseCase: MenstrualRecordUseCase {
    var overviewResponses: [MenstrualOverview]
    private(set) var fetchRequests: [FetchMenstrualOverviewRequest] = []
    private(set) var savedRecords: [SavedMenstrualRecord] = []
    private(set) var requestedAuthorizationCount = 0

    init(overviewResponses: [MenstrualOverview] = []) {
        self.overviewResponses = overviewResponses
    }

    func requestHealthKitAuthorization() async throws {
        requestedAuthorizationCount += 1
    }

    func fetchMenstrualOverview(
        activeMenstrualStartDate: Date?,
        userInput: MenstrualUserInput?,
        userInputMode: UserInputMode?
    ) async throws -> MenstrualOverview {
        fetchRequests.append(
            FetchMenstrualOverviewRequest(
                activeMenstrualStartDate: activeMenstrualStartDate,
                userInput: userInput,
                userInputMode: userInputMode
            )
        )
        return overviewResponses.isEmpty
            ? MenstrualOverview()
            : overviewResponses.removeFirst()
    }

    func saveMenstrualRecored(
        _ record: MenstrualRecord,
        deleteFrom: Date?,
        deleteThrough: Date?
    ) async throws {
        savedRecords.append(
            SavedMenstrualRecord(
                record: record,
                deleteFrom: deleteFrom,
                deleteThrough: deleteThrough
            )
        )
    }
}

private final class FakeSyncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase {
    private(set) var calls: [(records: [MenstrualRecord], isEnabled: Bool)] = []

    func execute(records: [MenstrualRecord], isEnabled: Bool) async throws {
        calls.append((records: records, isEnabled: isEnabled))
    }
}

private final class FakeRecordCurrentMenstrualPeriodUseCase: RecordCurrentMenstrualPeriodUseCase {
    private let endResult: Bool

    init(endResult: Bool) {
        self.endResult = endResult
    }

    func start(on startDate: Date) async throws { }

    func end(
        on endDate: Date,
        currentStatus: CurrentMenstrualStatus
    ) async throws -> Bool {
        endResult
    }
}

private struct RefreshMenstrualCycleCall {
    let userSetting: UserSettingState
    let runAutoClose: Bool
    let referenceDate: Date
}

private final class FakeRefreshMenstrualCycleUseCase: RefreshMenstrualCycleUseCase {
    private(set) var calls: [RefreshMenstrualCycleCall] = []
    var snapshot: MenstrualCycleSnapshot
    var error: Error?
    var delayNanoseconds: UInt64

    init(
        snapshot: MenstrualCycleSnapshot = MenstrualCycleSnapshot(
            overview: MenstrualOverview(),
            currentStatus: .inactive(),
            didAutoClose: false
        ),
        error: Error? = nil,
        delayNanoseconds: UInt64 = 0
    ) {
        self.snapshot = snapshot
        self.error = error
        self.delayNanoseconds = delayNanoseconds
    }

    func execute(
        userSetting: UserSettingState,
        runAutoClose: Bool,
        referenceDate: Date
    ) async throws -> MenstrualCycleSnapshot {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        calls.append(
            RefreshMenstrualCycleCall(
                userSetting: userSetting,
                runAutoClose: runAutoClose,
                referenceDate: referenceDate
            )
        )
        if let error {
            throw error
        }
        return snapshot
    }
}

private struct FakeRefreshError: Error { }

private struct FakeLoadUserSettingsUseCase: LoadUserSettingsUseCase {
    let settings: UserSettingState

    init(settings: UserSettingState = UserSettingState()) {
        self.settings = settings
    }

    func execute() -> UserSettingState {
        settings
    }
}

private final class FakeCurrentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore {
    var episode: CurrentMenstrualEpisode?
    private(set) var clearCount = 0

    init(episode: CurrentMenstrualEpisode? = nil) {
        self.episode = episode
    }

    func loadCurrentEpisode() -> CurrentMenstrualEpisode? {
        episode
    }

    func saveCurrentEpisode(_ episode: CurrentMenstrualEpisode) {
        self.episode = episode
    }

    func clearCurrentEpisode() {
        clearCount += 1
        episode = nil
    }
}

private enum RefactorTestCalendar {
    static func make() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func date(_ value: String, calendar: Calendar) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }

    static func dateTime(_ value: String, calendar: Calendar) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: value)!
    }
}
