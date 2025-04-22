import Foundation
import CloudKit

class AttendanceViewModel: ObservableObject {
    @Published var sessions: [WorkSession] = []
    private let database = CKContainer.default().publicCloudDatabase

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

    //MARK: - ✅ 출근 기록 (Users 레코드 참조 추가)
    func checkIn(userRecord: CKRecord, workOption: String) {
        print("🟢 checkIn 함수 호출됨")
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
            lastUpdated: Date(),
            coreStartTime: nil,
            coreEndTime: nil
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

    //MARK: - 🗑 사용자 탈퇴 처리 (사용자 레코드 + 모든 WorkSession 삭제)
    func deleteUserData(userRecord: CKRecord, completion: @escaping (Bool) -> Void) {
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        let sessionPredicate = NSPredicate(format: "userReference == %@", userReference)
        let sessionQuery = CKQuery(recordType: "worksession", predicate: sessionPredicate)

        // Step 1: Fetch all sessions for this user
        self.database.perform(sessionQuery, inZoneWith: nil) { results, error in
            if let error = error {
                print("❌ 사용자 세션 조회 실패: \(error.localizedDescription)")
                completion(false)
                return
            }

            var recordsToDelete = results?.map { $0.recordID } ?? []

            // Step 2: Add the user record itself
            recordsToDelete.append(userRecord.recordID)

            // Step 3: Batch delete
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordsToDelete)
            deleteOperation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("✅ 사용자 및 세션 전부 삭제 완료")
                    DispatchQueue.main.async {
                        self.sessions.removeAll()
                        completion(true)
                    }
                case .failure(let error):
                    print("❌ 사용자 및 세션 삭제 실패: \(error.localizedDescription)")
                    completion(false)
                }
            }
            self.database.add(deleteOperation)
        }
    }
}
