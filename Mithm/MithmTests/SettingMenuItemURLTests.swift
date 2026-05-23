//
//  SettingMenuItemURLTests.swift
//  MithmTests
//

import Foundation
import Testing
@testable import Mithm

struct SettingMenuItemURLTests {
    @Test("첫 선호 언어가 한국어이면 개인정보 처리방침 한국어 URL을 반환한다")
    func privacyPolicyUsesKoreanURLWhenFirstPreferredLanguageIsKorean() throws {
        let url = try #require(SettingMenuItem.privacyPolicy.url(preferredLanguages: ["ko-KR"]))

        #expect(url.absoluteString == "https://jinthelemon.notion.site/2cc90636549f80cea5ebfbdd29671611?source=copy_link")
    }

    @Test("첫 선호 언어가 한국어 underscore 형식이어도 지원 한국어 URL을 반환한다")
    func supportUsesKoreanURLWhenFirstPreferredLanguageUsesUnderscore() throws {
        let url = try #require(SettingMenuItem.support.url(preferredLanguages: ["ko_KR"]))

        #expect(url.absoluteString == "https://jinthelemon.notion.site/2cc90636549f80999adace0a614b046d?source=copy_link")
    }

    @Test("첫 선호 언어가 영어이면 영어 URL을 반환한다")
    func legalLinksUseEnglishURLWhenFirstPreferredLanguageIsEnglish() throws {
        let privacyPolicyURL = try #require(SettingMenuItem.privacyPolicy.url(preferredLanguages: ["en-US"]))
        let supportURL = try #require(SettingMenuItem.support.url(preferredLanguages: ["en-US"]))

        #expect(privacyPolicyURL.absoluteString == "https://jinthelemon.notion.site/Miridum-Privacy-Policy-35190636549f8094bd70cf6344efd3a1?source=copy_link")
        #expect(supportURL.absoluteString == "https://jinthelemon.notion.site/App-Support-Page-35190636549f80e69371f0f7dffcfa38?source=copy_link")
    }

    @Test("한국어가 두 번째 선호 언어이면 영어 URL을 반환한다")
    func legalLinksUseEnglishURLWhenKoreanIsNotFirstPreferredLanguage() throws {
        let privacyPolicyURL = try #require(SettingMenuItem.privacyPolicy.url(preferredLanguages: ["ja-JP", "ko-KR"]))
        let supportURL = try #require(SettingMenuItem.support.url(preferredLanguages: ["ja-JP", "ko-KR"]))

        #expect(privacyPolicyURL.absoluteString == "https://jinthelemon.notion.site/Miridum-Privacy-Policy-35190636549f8094bd70cf6344efd3a1?source=copy_link")
        #expect(supportURL.absoluteString == "https://jinthelemon.notion.site/App-Support-Page-35190636549f80e69371f0f7dffcfa38?source=copy_link")
    }

    @Test("외부 URL이 없는 설정 항목은 nil을 반환한다")
    func nonExternalLinkItemsReturnNil() {
        #expect(SettingMenuItem.calendarExport.url(preferredLanguages: ["ko-KR"]) == nil)
        #expect(SettingMenuItem.predictionMethod.url(preferredLanguages: ["ko-KR"]) == nil)
        #expect(SettingMenuItem.cycleSetting.url(preferredLanguages: ["ko-KR"]) == nil)
    }
}
