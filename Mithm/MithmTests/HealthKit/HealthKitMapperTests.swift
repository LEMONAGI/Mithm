import XCTest
import HealthKit
@testable import Mithm

final class HealthKitMapperTests: XCTestCase {

    private var cal: Calendar!

    override func setUp() {
        super.setUp()
        cal = Calendar.current
    }

    // MARK: - Helpers

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents()
        comps.year = y
        comps.month = m
        comps.day = d
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps)!
    }

    private func makeMenstrualSample(day: Date, isStart: Bool) -> HKCategorySample {
        let type = HKCategoryType(.menstrualFlow)
        return HKCategorySample(
            type: type,
            value: HKCategoryValueVaginalBleeding.unspecified.rawValue,
            start: day,
            end: day,
            metadata: [HKMetadataKeyMenstrualCycleStart: isStart]
        )
    }

    // MARK: - 1) hkObjectTypes(from:)

    func test_hkObjectTypes_mapsAllTypes() {
        let input: Set<HealthDataType> = [.menstrualCycle, .basalTemperature]
        let result = HealthKitMapper.hkObjectTypes(from: input)

        XCTAssertEqual(result.count, 2)

        XCTAssertTrue(result.contains(HKCategoryType(.menstrualFlow)))
        XCTAssertTrue(result.contains(HKQuantityType(.basalBodyTemperature)))
    }

    func test_hkObjectTypes_emptySet_returnsEmptySet() {
        let result = HealthKitMapper.hkObjectTypes(from: [])
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - 2) hkSampleTypes(from:)

    func test_hkSampleTypes_mapsAllTypes() throws {
        let input: Set<HealthDataType> = [.menstrualCycle, .basalTemperature]
        let result = try HealthKitMapper.hkSampleTypes(from: input)

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(HKCategoryType(.menstrualFlow)))
        XCTAssertTrue(result.contains(HKQuantityType(.basalBodyTemperature)))
    }

    /// basalTemperature가 sampleType으로 매핑 가능한 구조라면 통과.
    /// 만약 설계상 "읽기만 하고 쓰기엔 안 쓰는 타입" 같은 정책이 있으면
    /// 여기서 throw를 기대하는 테스트로 바꾸면 됨.
    func test_hkSampleTypes_emptySet_returnsEmptySet() throws {
        let result = try HealthKitMapper.hkSampleTypes(from: [])
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - 3) hkMenstrualCycleSamples(from:)

    func test_hkMenstrualCycleSamples_singleDay_createsExactlyOneSample_withStartMetadataTrue() throws {
        let start = day(2025, 1, 1)
        let record = CycleRecord(type: .menstrualRecord, startDate: start, endDate: start)

        let samples = try HealthKitMapper.hkMenstrualCycleSamples(from: record)

        XCTAssertEqual(samples.count, 1)
        XCTAssertTrue(cal.isDate(samples[0].startDate, inSameDayAs: start))

        // 필수 metadata 키 존재 + 첫날 true
        let meta = samples[0].metadata
        XCTAssertEqual(meta?[HKMetadataKeyMenstrualCycleStart] as? Bool, true)
    }

    func test_hkMenstrualCycleSamples_multiDay_createsDailySamples_firstDayStartTrue_othersFalse() throws {
        let start = day(2025, 1, 1)
        let end   = day(2025, 1, 3) // 1,2,3 (3일)

        let record = CycleRecord(type: .menstrualRecord, startDate: start, endDate: end)
        let samples = try HealthKitMapper.hkMenstrualCycleSamples(from: record)

        XCTAssertEqual(samples.count, 3)

        // start day = true, others = false
        let flags = samples.compactMap { $0.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool }
        XCTAssertEqual(flags.count, 3)
        XCTAssertEqual(flags[0], true)
        XCTAssertEqual(flags[1], false)
        XCTAssertEqual(flags[2], false)

        // 날짜들이 하루씩 증가하는지
        let s0 = cal.startOfDay(for: samples[0].startDate)
        let s1 = cal.startOfDay(for: samples[1].startDate)
        let s2 = cal.startOfDay(for: samples[2].startDate)

        XCTAssertEqual(cal.dateComponents([.day], from: s0, to: s1).day, 1)
        XCTAssertEqual(cal.dateComponents([.day], from: s1, to: s2).day, 1)
    }

    func test_hkMenstrualCycleSamples_endBeforeStart_returnsEmpty() throws {
        let start = day(2025, 1, 5)
        let end   = day(2025, 1, 3)

        let record = CycleRecord(type: .menstrualRecord, startDate: start, endDate: end)

        let samples = try HealthKitMapper.hkMenstrualCycleSamples(from: record)
        XCTAssertTrue(samples.isEmpty, "end < start인 경우 샘플 생성하지 않아야 함")
    }

    func test_hkMenstrualCycleSamples_nonMenstrualRecord_returnsEmpty() throws {
        // record.type.healthDataType가 nil이거나 menstrual이 아닌 타입이면 [] 반환하는 설계였지
        let start = day(2025, 1, 1)
        let end   = day(2025, 1, 2)

        let record = CycleRecord(type: .ovulationPrediction, startDate: start, endDate: end)
        let samples = try HealthKitMapper.hkMenstrualCycleSamples(from: record)

        XCTAssertTrue(samples.isEmpty, "월경이 아닌 타입은 HealthKit 월경 샘플을 만들면 안 됨")
    }

    func test_hkMenstrualCycleSamples_endNil_returnsStartDateSample() throws {
        let start = day(2025, 1, 1)
        let record = CycleRecord(type: .menstrualRecord, startDate: start, endDate: nil)

        let samples = try HealthKitMapper.hkMenstrualCycleSamples(from: record)
        XCTAssertEqual(samples.count, 1)
    }

    // MARK: - 4) menstrualCycleRecords(from:)

    func test_menstrualCycleRecords_empty_returnsEmpty() {
        let records = HealthKitMapper.menstrualCycleRecords(from: [])
        XCTAssertTrue(records.isEmpty)
    }

    func test_menstrualCycleRecords_singleDay_returnsOneRecord_sameDay() {
        let d1 = day(2025, 1, 1)
        let samples = [makeMenstrualSample(day: d1, isStart: true)]

        let records = HealthKitMapper.menstrualCycleRecords(from: samples)

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].type, .menstrualRecord)
        XCTAssertTrue(cal.isDate(records[0].startDate, inSameDayAs: d1))
        XCTAssertTrue(cal.isDate((records[0].endDate ?? records[0].startDate), inSameDayAs: d1))
    }

    func test_menstrualCycleRecords_consecutiveDays_groupedIntoOneEpisode() {
        let d1 = day(2025, 1, 1)
        let d2 = day(2025, 1, 2)
        let d3 = day(2025, 1, 3)

        let samples = [
            makeMenstrualSample(day: d1, isStart: true),
            makeMenstrualSample(day: d2, isStart: false),
            makeMenstrualSample(day: d3, isStart: false)
        ]

        let records = HealthKitMapper.menstrualCycleRecords(from: samples)

        XCTAssertEqual(records.count, 1)
        XCTAssertTrue(cal.isDate(records[0].startDate, inSameDayAs: d1))
        XCTAssertTrue(cal.isDate((records[0].endDate ?? records[0].startDate), inSameDayAs: d3))
    }

    func test_menstrualCycleRecords_nonConsecutiveDays_splitEpisodes() {
        let d1 = day(2025, 1, 1)
        let d2 = day(2025, 1, 2)
        let d4 = day(2025, 1, 4)

        let samples = [
            makeMenstrualSample(day: d1, isStart: true),
            makeMenstrualSample(day: d2, isStart: false),
            makeMenstrualSample(day: d4, isStart: true)
        ]

        let records = HealthKitMapper.menstrualCycleRecords(from: samples)

        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(cal.isDate(records[0].startDate, inSameDayAs: d1))
        XCTAssertTrue(cal.isDate((records[0].endDate ?? records[0].startDate), inSameDayAs: d2))

        XCTAssertTrue(cal.isDate(records[1].startDate, inSameDayAs: d4))
        XCTAssertTrue(cal.isDate((records[1].endDate ?? records[1].startDate), inSameDayAs: d4))
    }

    func test_menstrualCycleRecords_unsortedSamples_stillGroupsCorrectly() {
        let d1 = day(2025, 1, 1)
        let d2 = day(2025, 1, 2)
        let d3 = day(2025, 1, 3)

        // 일부러 섞어서 넣기
        let samples = [
            makeMenstrualSample(day: d3, isStart: false),
            makeMenstrualSample(day: d1, isStart: true),
            makeMenstrualSample(day: d2, isStart: false)
        ]

        let records = HealthKitMapper.menstrualCycleRecords(from: samples)

        XCTAssertEqual(records.count, 1)
        XCTAssertTrue(cal.isDate(records[0].startDate, inSameDayAs: d1))
        XCTAssertTrue(cal.isDate((records[0].endDate ?? records[0].startDate), inSameDayAs: d3))
    }

    // 한 날짜에 중복 샘플이 있는 경우
    func test_menstrualCycleRecords_duplicateDays_shouldNotCreateExtraEpisode() {
        let d1 = day(2025, 1, 1)
        let d2 = day(2025, 1, 2)

        // 같은 날 샘플 중복
        let samples = [
            makeMenstrualSample(day: d1, isStart: true),
            makeMenstrualSample(day: d1, isStart: true),
            makeMenstrualSample(day: d2, isStart: false)
        ]

        let records = HealthKitMapper.menstrualCycleRecords(from: samples)

        XCTAssertEqual(records.count, 1)
    }
}
