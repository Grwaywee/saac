import Foundation
import CloudKit

extension Date {
func convert(to targetTimeZone: TimeZone, using calendar: Calendar) -> Date {
    let components = calendar.dateComponents(in: calendar.timeZone, from: self)
    var targetCalendar = calendar
    targetCalendar.timeZone = targetTimeZone
    return targetCalendar.date(from: components) ?? self
}
}

class AttendanceViewModel: ObservableObject {
    @Published var sessions: [WorkSession] = []
    private let database = CKContainer.default().publicCloudDatabase
    
    //MARK: - 🔹 특정 사용자의 WorkSession 기록을 가져오는 함수
    func fetchUserSessions(userRecord: CKRecord) {
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        let predicate = NSPredicate(format: "userReference == %@", userReference)
        let query = CKQuery(recordType: "worksession", predicate: predicate)
        
        // ✅ Clear existing sessions before fetching new ones
        DispatchQueue.main.async {
            self.sessions = []
        }
        
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
    
    //MARK: - ✅ 특정 사용자의 Main WorkSession 쿼리하기
    func fetchTodayMainSession(userRecord: CKRecord) {
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        // Step 1: Create KST-based calendar
        let koreanTimeZone = TimeZone(identifier: "Asia/Seoul")!
        var kstCalendar = Calendar(identifier: .gregorian)
        kstCalendar.timeZone = koreanTimeZone
        
        // Step 2: Get KST start and end of today
        let startOfTodayKST = kstCalendar.startOfDay(for: Date())
        let startOfTomorrowKST = kstCalendar.date(byAdding: .day, value: 1, to: startOfTodayKST)!
        
        // Step 3: Convert to UTC for CloudKit query
        let utcCalendar = Calendar(identifier: .gregorian)
        let utcTodayStart = startOfTodayKST.convert(to: .gmt, using: utcCalendar)
        let utcTomorrowStart = startOfTomorrowKST.convert(to: .gmt, using: utcCalendar)
        
        print("💫 fetchTodayMainSession 쿼리 시작")
        print("🧪 유저ID: \(userRecord.recordID.recordName)")
        print("🧪 조건: userReference == \(userReference.recordID.recordName), workOption == 'Main'")
        print("🧪 조건: date >= \(utcTodayStart), date < \(utcTomorrowStart) (UTC 기준)")
        
        let predicate = NSPredicate(format: "userReference == %@ AND workOption == %@ AND date >= %@ AND date < %@",
                                    userReference, "Main", utcTodayStart as CVarArg, utcTomorrowStart as CVarArg)
        
        let query = CKQuery(recordType: "worksession", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = CKQueryOperation.maximumResults
        
        DispatchQueue.main.async {
            self.sessions = [] // Clear sessions before fetching new ones
        }
        
        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                print("✅ 매칭된 레코드 ID: \(recordID.recordName)")
                print("----------이상 조회 끝----------AttenceViewModel----------")
                if let session = WorkSession(from: record) {
                    DispatchQueue.main.async {
                        self.sessions = [session]
                        //                    print("✅ [fetchTodayMainSession] Main session 저장 완료: \(session)")
                    }
                }
            case .failure(let error):
                print("❌ 레코드 매칭 실패: \(error.localizedDescription)")
            }
        }
        
        operation.queryResultBlock = { result in
            switch result {
            case .success:
                print("✅ [단독 로그] fetchTodayMainSession 쿼리 성공")
            case .failure(let error):
                print("❌ [단독 로그] fetchTodayMainSession 쿼리 실패: \(error.localizedDescription)")
            }
        }
        
        database.add(operation)
    }
    
    //MARK: - ✅ 출근 기록 (Users 레코드 참조 추가)
    func checkIn(userRecord: CKRecord) {
        print("\n----------Main WorkSession 생성----------AttendanceViewModel----------\n")
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        guard let userName = userRecord["userName"] as? String else {
            print("❌ [checkIn] 사용자 이름 없음")
            return
        }
        
        let newSession = WorkSession(
            id: UUID().uuidString,
            date: Calendar.current.startOfDay(for: Date()),
            userReference: userReference,
            userName: userName,
            workOption: "Main",
            checkInTime: Date(),
            checkOutTime: nil,
            breaks: [],
            lastUpdated: Date(),
            coreStartTime: nil,
            coreEndTime: nil,
            note: nil // optional 텍스트 필드
        )
        
        let record = newSession.toRecord()
        database.save(record) { savedRecord, error in
            if let error = error {
                print("❌ [checkIn] 출근 기록 저장 실패: \(error.localizedDescription)")
                print("----------이상 끝----------AttendanceViewModel----------")
                return
            }
            if let savedRecord = savedRecord, let savedSession = WorkSession(from: savedRecord) {
                DispatchQueue.main.async {
                    self.sessions.append(savedSession)
                    print("✅ [checkIn] 출근 기록 성공적으로 저장됨")
                    print("----------이상 끝----------AttendanceViewModel----------")
                }
            }
        }
    }
    
    //MARK: - ✅ 퇴근 기록
    func checkOut(session: WorkSession? = nil, userRecord: CKRecord? = nil) {
        if let session = session {
            // 기존 방식
            guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
            sessions[index].checkOutTime = Date()
            sessions[index].lastUpdated = Date()
            
            print("\n----------Main WorkSession 마무리----------AttendanceViewModel----------\n")
            
            let record = sessions[index].toRecord(existingRecord: CKRecord(recordType: "worksession", recordID: CKRecord.ID(recordName: sessions[index].id)))
            database.save(record) { savedRecord, error in
                if let error = error {
                    print("❌ [checkOut] 퇴근 기록 저장 실패: \(error.localizedDescription)")
                    print("----------이상 끝----------AttendanceViewModel----------")
                    return
                }
                print("✅ [checkOut] 퇴근 기록 성공적으로 저장됨")
                print("----------이상 끝----------AttendanceViewModel----------")
            }
        } else if let userRecord = userRecord {
            let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
            let today = Date()
            if let match = sessions.first(where: {
                $0.userReference.recordID == userReference.recordID &&
                Calendar.current.isDate($0.date, inSameDayAs: today) &&
                $0.workOption == "Main" &&
                $0.checkOutTime == nil
            }) {
                checkOut(session: match)
            } else {
                print("⚠️ [checkOut] 오늘 날짜에 맞는 퇴근 가능한 세션을 찾지 못했습니다.")
                print("----------이상 끝----------AttendanceViewModel----------")
            }
        } else {
            print("❌ [checkOut] session 또는 userRecord 둘 중 하나는 반드시 필요합니다.")
            print("----------이상 끝----------AttendanceViewModel----------")
        }
    }
    
    // MARK: - ✅ 코어타임 업데이트 메서드 추가
    func updateCoreTime(for session: WorkSession, start: Date, end: Date) {
        print("\n----------코어타임 정보 업데이트 로그----------AttendanceViewModel----------\n")
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        print("📝 [updateCoreTime] 업데이트할 세션 ID: \(session.id)")
        print("🕒 [updateCoreTime] 현재 시각 (KST 기준): \(Date())")
        let utcCalendar = Calendar(identifier: .gregorian)
        let startUTC = start.convert(to: .gmt, using: utcCalendar)
        let endUTC = end.convert(to: .gmt, using: utcCalendar)
        print("🌍 [updateCoreTime] 변환된 시작 시간 (UTC): \(startUTC)")
        print("🌍 [updateCoreTime] 변환된 종료 시간 (UTC): \(endUTC)")
        sessions[index].coreStartTime = start
        sessions[index].coreEndTime = end
        sessions[index].lastUpdated = Date()
        let recordID = CKRecord.ID(recordName: sessions[index].id)
        database.fetch(withRecordID: recordID) { fetchedRecord, error in
            if let error = error {
                print("❌ [updateCoreTime] 기존 레코드 조회 실패: \(error.localizedDescription)")
                print("----------이상 업데이트 끝----------AttendanceViewModel----------")
                return
            }
            guard let record = fetchedRecord else {
                print("❌ [updateCoreTime] 기존 레코드가 nil입니다.")
                print("----------이상 업데이트 끝----------AttendanceViewModel----------")
                return
            }
            record["coreStartTime"] = start as CKRecordValue
            record["coreEndTime"] = end as CKRecordValue
            record["lastUpdated"] = Date() as CKRecordValue
            
            self.database.save(record) { savedRecord, saveError in
                if let saveError = saveError {
                    print("❌ [updateCoreTime] 코어타임 저장 실패: \(saveError.localizedDescription)")
                    print("----------이상 업데이트 끝----------AttendanceViewModel----------")
                    return
                }
                print("✅ [updateCoreTime] 코어타임 성공적으로 저장됨: \(record.recordID.recordName)")
                print("----------이상 업데이트 끝----------AttendanceViewModel----------")
            }
        }
    }
}
