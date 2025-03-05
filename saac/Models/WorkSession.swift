import Foundation
import CloudKit

struct WorkSession: Identifiable {
    let id: String
    let date: Date
    let userReference: CKRecord.Reference  // ✅ Users 레코드 참조
    var workOption: String
    var checkInTime: Date?
    var checkOutTime: Date?
    var breaks: [BreakTime]
    var lastUpdated: Date

    // ✅ CloudKit이 자동 생성하는 메타데이터 필드
    let createdTimestamp: Date?
    let createdUserRecordName: String?
    let modifiedTimestamp: Date?
    let modifiedUserRecordName: String?
    let recordName: String?
    let etag: String?

    // CloudKit Record 변환
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "worksession")
        record["id"] = id as CKRecordValue
        record["date"] = date as CKRecordValue
        record["userReference"] = userReference as CKRecordValue  // ✅ Users 레코드 참조 저장
        record["workOption"] = workOption as CKRecordValue
        record["checkInTime"] = checkInTime as CKRecordValue?
        record["checkOutTime"] = checkOutTime as CKRecordValue?
        record["lastUpdated"] = lastUpdated as CKRecordValue

        // ✅ breaks 필드 변환 (빈 배열 예외 처리 추가)
        let breakTimes = breaks.flatMap { [$0.startTime, $0.endTime] }
        record["breaks"] = breakTimes.isEmpty ? nil : breakTimes as CKRecordValue

        return record
    }

    // CloudKit Record에서 변환
    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let date = record["date"] as? Date,
              let userReference = record["userReference"] as? CKRecord.Reference,  // ✅ 참조값 가져오기
              let workOption = record["workOption"] as? String,
              let lastUpdated = record["lastUpdated"] as? Date
        else { return nil }

        self.id = id
        self.date = date
        self.userReference = userReference
        self.workOption = workOption
        self.checkInTime = record["checkInTime"] as? Date
        self.checkOutTime = record["checkOutTime"] as? Date
        
        // ✅ breaks 필드 변환 (빈 배열 예외 처리 추가)
        if let breakTimes = record["breaks"] as? [Date], breakTimes.count % 2 == 0 {
            self.breaks = stride(from: 0, to: breakTimes.count, by: 2).map { index in
                BreakTime(startTime: breakTimes[index], endTime: breakTimes[index + 1])
            }
        } else {
            self.breaks = []
        }

        self.lastUpdated = lastUpdated

        // ✅ CloudKit 메타데이터 추가
        self.createdTimestamp = record.creationDate
        self.modifiedTimestamp = record.modificationDate
        self.recordName = record.recordID.recordName
        self.createdUserRecordName = record["createdUserRecordName"] as? String
        self.modifiedUserRecordName = record["modifiedUserRecordName"] as? String
        self.etag = record["__etag"] as? String
    }
}

// ✅ BreakTime 구조체 정의
struct BreakTime {
    var startTime: Date
    var endTime: Date
}

// ✅ chunked 메서드 추가 (배열을 2개씩 묶어 BreakTime으로 변환할 때 사용)
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
