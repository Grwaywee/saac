import Foundation
import CloudKit

class AttendanceViewModel: ObservableObject {
    @Published var sessions: [WorkSession] = []
    private let database = CKContainer.default().publicCloudDatabase

    //MARK: - 🔹 iCloud 사용자 레코드 확인 또는 생성
    func fetchOrCreateUserRecord(forAppleID userIdentifier: String, userName: String?, completion: @escaping (CKRecord?) -> Void) {
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: userIdentifier)

        // 기존 레코드 조회
        database.fetch(withRecordID: recordID) { existingRecord, fetchError in
            if let existingRecord = existingRecord {
                print("✅ 기존 사용자 레코드 불러옴")
                completion(existingRecord)
            } else {
                // 새 사용자 레코드 생성
                let newUser = CKRecord(recordType: "AppUsers", recordID: recordID)
                newUser["id"] = userIdentifier as CKRecordValue
                newUser["email"] = "unknown@icloud.com" as CKRecordValue
                newUser["createdAt"] = Date() as CKRecordValue

                // 이름을 fallback으로 직접 입력받음
                if let name = userName, !name.isEmpty {
                    print("✅ 사용자 이름 획득: \(name)")
                    newUser["userName"] = name as CKRecordValue
                } else {
                    print("📥 이름이 없어서 fallback 처리: 이름없음")
                    newUser["userName"] = "이름없음" as CKRecordValue
                }
                
                database.save(newUser) { savedRecord, saveError in
                    if let savedRecord = savedRecord {
                        print("✅ 새 Users 레코드 생성됨")
                        completion(savedRecord)
                    } else {
                        print("❌ Users 레코드 저장 실패: \(saveError?.localizedDescription ?? "")")
                        completion(nil)
                    }
                }
            }
        }
    }

    //MARK: - 🔹 특정 사용자의 WorkSession 기록을 가져오는 함수
    func fetchUserSessions(userRecord: CKRecord) {
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        let predicate = NSPredicate(format: "userReference == %@", userReference)
        let query = CKQuery(recordType: "worksession", predicate: predicate)

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = CKQueryOperation.maximumResults

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                if let session = WorkSession(from: record) {
                    DispatchQueue.main.async {
                        if !self.sessions.contains(where: { $0.id == session.id }) {
                            self.sessions.append(session)
                        }
                    }
                }
            case .failure(let error):
                print("❌ [fetchUserSessions] 사용자 세션 불러오기 오류: \(error.localizedDescription)")
            }
        }

        database.add(operation)
    }

    //MARK: - 🔹 출근 기록 (Users 레코드 참조 추가)
    func checkIn(userRecord: CKRecord, workOption: String) {
    let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
    
    guard let userName = userRecord["userName"] as? String else {
        print("❌ [checkIn] 사용자 이름 없음")
        return
    }
    
    let newSession = WorkSession(
        id: UUID().uuidString,
        date: Date(),
        userReference: userReference,
        userName: userName,
        workOption: workOption,
        checkInTime: Date(),
        checkOutTime: nil,
        breaks: [],
        lastUpdated: Date()
    )
    
    let record = newSession.toRecord()
    database.save(record) { savedRecord, error in
        if let error = error {
            print("❌ [checkIn] 출근 기록 저장 실패: \(error.localizedDescription)")
            return
        }
        if let savedRecord = savedRecord, let savedSession = WorkSession(from: savedRecord) {
            DispatchQueue.main.async {
                self.sessions.append(savedSession)
                print("✅ [checkIn] 출근 기록 성공적으로 저장됨")
            }
        }
    }
    }

    //MARK: - 🔹 퇴근 기록
    func checkOut(session: WorkSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].checkOutTime = Date()
        sessions[index].lastUpdated = Date()

        let record = sessions[index].toRecord()
        database.save(record) { savedRecord, error in
            if let error = error {
                print("❌ [checkOut] 퇴근 기록 저장 실패: \(error.localizedDescription)")
                return
            }
            print("✅ [checkOut] 퇴근 기록 성공적으로 저장됨")
        }
    }
}
