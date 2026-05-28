//
//  CalendarPredictionSourceNoticeTests.swift
//  MithmTests
//

import Foundation
import Testing
@testable import Mithm

struct CalendarPredictionSourceNoticeTests {
    @Test("캘린더 예측 출처 링크는 OASH 월경 주기 페이지를 사용한다")
    func calendarPredictionSourceURLUsesOASHMenstrualCyclePage() {
        #expect(
            CalendarPredictionSourceNotice.url.absoluteString
                == "https://womenshealth.gov/menstrual-cycle/your-menstrual-cycle"
        )
    }

    @Test("캘린더 예측 출처 문구는 한국어와 영어 기관명 링크 라벨을 제공한다")
    func calendarPredictionSourceLocalizationProvidesLinkLabels() throws {
        #expect(
            localizedString("calendar.prediction_source.link_label", locale: "ko")
                == "미국여성건강청(OASH)"
        )
        #expect(
            localizedString("calendar.prediction_source.link_label", locale: "en")
                == "OASH (Office on Women’s Health)"
        )
    }

    private func localizedString(_ key: String, locale: String) -> String {
        guard
            let path = Bundle.main.path(forResource: locale, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
