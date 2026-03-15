//
//  AppDIContainer.swift
//  Mithm
//
//  Created by YunhakLee on 3/14/26.
//

import Foundation

struct AppDIContainer {

    static func makeAppState() -> AppState {
        let calendar = Calendar.current
        let healthKitDataStore = HealthKitDataStoreImpl()
        let healthKitRepository = HealthKitRepositoryImpl(dataStore: healthKitDataStore)
        let menstrualRecordUseCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: healthKitRepository,
            calendar: calendar
        )
        let openPeriodAutoCloser = OpenPeriodAutoCloser()
        let homePhaseUseCase = HomePhaseUseCaseImpl()

        let eventKitDataStore = EventKitDataStoreImpl()
        let eventKitRepository = EventKitRepositoryImpl(dataStore: eventKitDataStore)
        let syncMenstrualCalendarUseCase = SyncMenstrualCalendarUseCaseImpl(
            eventKitRepository: eventKitRepository
        )

        let userSettingRepository = UserSettingRepositoryImpl()
        let userSettingUseCase = UserSettingUseCaseImpl(
            userSettingRepository: userSettingRepository
        )

        return AppState(
            calendar: calendar,
            menstrualRecordUseCase: menstrualRecordUseCase,
            homePhaseUseCase: homePhaseUseCase,
            openPeriodAutoCloser: openPeriodAutoCloser,
            syncMenstrualCalendarUseCase: syncMenstrualCalendarUseCase,
            userSettingUseCase: userSettingUseCase
        )
    }
}
