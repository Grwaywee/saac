import Foundation
import CloudKit

struct User {
    let id: String
    let userName: String
    let email: String
    let createdAt: Date
    let createdTimestamp: Date?
    let modifiedTimestamp: Date?
    let recordName: String?
    let createdUserRecordName: String?
    let modifiedUserRecordName: String?

    // WorkSession 목록을 저장할 변수
    var workSessions: [WorkSession] = []

    // CloudKit Record 변환
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Users")
        record["id"] = id as CKRecordValue
        record["userName"] = userName as CKRecordValue
        record["email"] = email as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        return record
    }

    // CloudKit Record에서 변환 (기본 필드 포함)
    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let userName = record["userName"] as? String,
              let email = record["email"] as? String,
              let createdAt = record["createdAt"] as? Date else { return nil }

        self.id = id
        self.userName = userName
        self.email = email
        self.createdAt = createdAt

        // ✅ CloudKit 기본 필드 가져오기
        self.createdTimestamp = record.creationDate
        self.modifiedTimestamp = record.modificationDate
        self.recordName = record.recordID.recordName
        self.createdUserRecordName = record.creatorUserRecordID?.recordName
        self.modifiedUserRecordName = record.lastModifiedUserRecordID?.recordName

        // ✅ 특정 사용자의 WorkSession 가져오기
        AttendanceViewModel().fetchUserSessions(userRecord: record)
    }
}
