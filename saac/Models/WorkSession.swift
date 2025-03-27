import CloudKit

struct WorkSession: Identifiable {
    let id: String
    let date: Date
    let userReference: CKRecord.Reference
    let userName: String
    var workOption: String
    var checkInTime: Date?
    var checkOutTime: Date?
    var breaks: [Date]
    var lastUpdated: Date

    init(
        id: String,
        date: Date,
        userReference: CKRecord.Reference,
        userName: String,
        workOption: String,
        checkInTime: Date?,
        checkOutTime: Date?,
        breaks: [Date],
        lastUpdated: Date
    ) {
        self.id = id
        self.date = date
        self.userReference = userReference
        self.userName = userName
        self.workOption = workOption
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.breaks = breaks
        self.lastUpdated = lastUpdated
    }

    // 🔹 CloudKit Record로 변환
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "worksession")
        record["id"] = id as CKRecordValue
        record["date"] = date as CKRecordValue
        record["userReference"] = userReference
        record["userName"] = userName as CKRecordValue
        record["workOption"] = workOption as CKRecordValue
        if let checkInTime = checkInTime {
            record["checkInTime"] = checkInTime as CKRecordValue
        }
        if let checkOutTime = checkOutTime {
            record["checkOutTime"] = checkOutTime as CKRecordValue
        }
        record["breaks"] = breaks as CKRecordValue
        record["lastUpdated"] = lastUpdated as CKRecordValue
        return record
    }

    // 🔹 CloudKit에서 가져오기 (from record)
    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let date = record["date"] as? Date,
              let userReference = record["userReference"] as? CKRecord.Reference,
              let userName = record["userName"] as? String,
              let workOption = record["workOption"] as? String,
              let lastUpdated = record["lastUpdated"] as? Date else {
            print("❌ WorkSession 변환 실패: 필드 불일치 가능성")
            return nil
        }

        self.id = id
        self.date = date
        self.userReference = userReference
        self.userName = userName
        self.workOption = workOption
        self.checkInTime = record["checkInTime"] as? Date
        self.checkOutTime = record["checkOutTime"] as? Date
        self.breaks = record["breaks"] as? [Date] ?? []
        self.lastUpdated = lastUpdated
    }
}
