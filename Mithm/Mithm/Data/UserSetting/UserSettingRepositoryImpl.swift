//
//  UserSettingRepositoryImpl.swift
//  Mithm
//
//  Created by YunhakLee on 3/13/26.
//

import Foundation

final class UserSettingRepositoryImpl: UserSettingRepository {

    private enum Key {
        static let cycleLength = "userSetting.cycleLength"
        static let periodLength = "userSetting.periodLength"
        static let calendarExportEnabled = "userSetting.calendarExportEnabled"
        static let userInputMode = "userSetting.userInputMode"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - 사용자 월경 주기/기간 입력

    func saveMenstrualUserInput(_ input: MenstrualUserInput) {
        if let cycleLength = input.cycleLength {
            defaults.set(cycleLength, forKey: Key.cycleLength)
        } else {
            defaults.removeObject(forKey: Key.cycleLength)
        }

        if let periodLength = input.periodLength {
            defaults.set(periodLength, forKey: Key.periodLength)
        } else {
            defaults.removeObject(forKey: Key.periodLength)
        }
    }

    func loadMenstrualUserInput() -> MenstrualUserInput? {
        let hasCycle = defaults.object(forKey: Key.cycleLength) != nil
        let hasPeriod = defaults.object(forKey: Key.periodLength) != nil

        guard hasCycle || hasPeriod else { return nil }

        let cycleLength = hasCycle ? defaults.integer(forKey: Key.cycleLength) : nil
        let periodLength = hasPeriod ? defaults.integer(forKey: Key.periodLength) : nil

        return MenstrualUserInput(
            cycleLength: cycleLength,
            periodLength: periodLength
        )
    }

    // MARK: - 캘린더 내보내기 활성화

    func saveCalendarExportEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Key.calendarExportEnabled)
    }

    func loadCalendarExportEnabled() -> Bool {
        defaults.bool(forKey: Key.calendarExportEnabled)
    }

    // MARK: - 예측 엔진 UserInputMode

    func saveUserInputMode(_ mode: UserInputMode) {
        defaults.set(mode.rawValue, forKey: Key.userInputMode)
    }

    func loadUserInputMode() -> UserInputMode? {
        guard let rawValue = defaults.string(forKey: Key.userInputMode) else {
            return nil
        }
        return UserInputMode(rawValue: rawValue)
    }
}

final class UserDefaultsCurrentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore {

    private enum Key {
        static let currentEpisode = "currentMenstrualEpisode"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadCurrentEpisode() -> CurrentMenstrualEpisode? {
        guard let data = defaults.data(forKey: Key.currentEpisode) else {
            return nil
        }
        return try? decoder.decode(CurrentMenstrualEpisode.self, from: data)
    }

    func saveCurrentEpisode(_ episode: CurrentMenstrualEpisode) {
        guard let data = try? encoder.encode(episode) else { return }
        defaults.set(data, forKey: Key.currentEpisode)
    }

    func clearCurrentEpisode() {
        defaults.removeObject(forKey: Key.currentEpisode)
    }
}
