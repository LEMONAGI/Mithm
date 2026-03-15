//
//  AppDIContainer.swift
//  Mithm
//
//  Created by YunhakLee on 3/14/26.
//

import Foundation

struct AppDIContainer {

    static func makeAppState() -> AppState {
        let healthKitDataStore = HealthKitDataStoreImpl()
        let healthKitRepository = HealthKitRepositoryImpl(dataStore: healthKitDataStore)
        let menstrualRecordUseCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: healthKitRepository
        )
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
            menstrualRecordUseCase: menstrualRecordUseCase,
            homePhaseUseCase: homePhaseUseCase,
            syncMenstrualCalendarUseCase: syncMenstrualCalendarUseCase,
            userSettingUseCase: userSettingUseCase
        )
    }
}
