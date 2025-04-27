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
    @Published var currentUserRecord: CKRecord?
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
    
    //MARK: - ✅ 퇴근 기록 (코어타임 종료 처리 포함)
    func checkOut(session: WorkSession? = nil, userRecord: CKRecord? = nil) {
        // 항상 userRecord 기반으로 fetchTodayMainSession을 호출할 수 있도록 userRecord를 인자로 받음
        if let session = session {
            print("\n----------Main WorkSession 마무리----------AttendanceViewModel----------\n")

            let recordID = CKRecord.ID(recordName: session.id)
            database.fetch(withRecordID: recordID) { fetchedRecord, error in
                if let error = error {
                    print("❌ [checkOut] 기존 레코드 조회 실패: \(error.localizedDescription)")
                    print("----------이상 끝----------AttendanceViewModel----------")
                    return
                }

                guard let record = fetchedRecord else {
                    print("❌ [checkOut] 기존 레코드가 nil입니다.")
                    print("----------이상 끝----------AttendanceViewModel----------")
                    return
                }

                DispatchQueue.main.async {
                    let now = Date()
                    record["checkOutTime"] = now as CKRecordValue
                    record["lastUpdated"] = now as CKRecordValue
                    // 코어타임이 존재하고, coreEndTime이 현재보다 미래면 coreEndTime을 현재로 덮어씀
                    if let coreEndTime = record["coreEndTime"] as? Date,
                       coreEndTime > now {
                        record["coreEndTime"] = now as CKRecordValue
                        print("✅ [checkOut] CoreEndTime 조정 완료")
                    }
                    self.database.save(record) { savedRecord, saveError in
                        if let saveError = saveError {
                            print("❌ [checkOut] 퇴근 기록 저장 실패: \(saveError.localizedDescription)")
                        } else {
                            print("✅ [checkOut] 퇴근 기록 성공적으로 저장됨")
                        }
                        print("----------이상 끝----------AttendanceViewModel----------")
                        // 퇴근 성공 후, userRecord가 있으면 오늘 세션을 새로고침
                        if let userRecord = userRecord {
                            self.fetchTodayMainSession(userRecord: userRecord)
                        }
                    }
                }
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
                // 항상 userRecord를 넘겨서, 저장 후 fetchTodayMainSession이 수행됨
                checkOut(session: match, userRecord: userRecord)
            } else {
                print("⚠️ [checkOut] 오늘 날짜에 맞는 퇴근 가능한 세션을 찾지 못했습니다.")
                print("----------이상 끝----------AttendanceViewModel----------")
            }
        } else {
            print("❌ [checkOut] session 또는 userRecord 둘 중 하나는 반드시 필요합니다.")
            print("----------이상 끝----------AttendanceViewModel----------")
        }
    }
    
    // MARK: - ✅ 코어타임 업데이트 메서드 (KST → UTC 변환 후 저장)
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
            // KST → UTC 변환하여 저장
            record["coreStartTime"] = startUTC as CKRecordValue
            record["coreEndTime"] = endUTC as CKRecordValue
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
    
    // MARK: - ✅ 추가 세션 저장 메서드
    func saveAdjustedSession(userRecord: CKRecord, workType: String, note: String?, selectedDate: Date, startTime: Date, endTime: Date) {
        print("\n----------추가 세션 저장 시작----------AttendanceViewModel----------\n")
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        guard let userName = userRecord["userName"] as? String else {
            print("❌ [saveAdjustedSession] 사용자 이름 없음")
            return
        }
        
        // workOption 결정
        let workOption: String
        switch workType {
        case "추가근무":
            workOption = "Add"
        case "공석 등록":
            workOption = "Del"
        default:
            print("❌ [saveAdjustedSession] 알 수 없는 workType: \(workType)")
            return
        }
        
        // 선택된 날짜와 시간을 조합하여 체크인/체크아웃 시간 생성 (KST 기준)
        let calendar = Calendar.current
        let koreanTimeZone = TimeZone(identifier: "Asia/Seoul")!
        var kstCalendar = calendar
        kstCalendar.timeZone = koreanTimeZone
        
        let startComponents = kstCalendar.dateComponents([.year, .month, .day], from: selectedDate)
        let startHourMinute = kstCalendar.dateComponents([.hour, .minute, .second], from: startTime)
        var combinedStartComponents = DateComponents()
        combinedStartComponents.year = startComponents.year
        combinedStartComponents.month = startComponents.month
        combinedStartComponents.day = startComponents.day
        combinedStartComponents.hour = startHourMinute.hour
        combinedStartComponents.minute = startHourMinute.minute
        combinedStartComponents.second = startHourMinute.second ?? 0
        guard let combinedStartDate = kstCalendar.date(from: combinedStartComponents) else {
            print("❌ [saveAdjustedSession] 시작 시간 생성 실패")
            return
        }
        
        let endHourMinute = kstCalendar.dateComponents([.hour, .minute, .second], from: endTime)
        var combinedEndComponents = DateComponents()
        combinedEndComponents.year = startComponents.year
        combinedEndComponents.month = startComponents.month
        combinedEndComponents.day = startComponents.day
        combinedEndComponents.hour = endHourMinute.hour
        combinedEndComponents.minute = endHourMinute.minute
        combinedEndComponents.second = endHourMinute.second ?? 0
        guard let combinedEndDate = kstCalendar.date(from: combinedEndComponents) else {
            print("❌ [saveAdjustedSession] 종료 시간 생성 실패")
            return
        }
        
        let newSession = WorkSession(
            id: UUID().uuidString,
            date: kstCalendar.startOfDay(for: selectedDate),
            userReference: userReference,
            userName: userName,
            workOption: workOption,
            checkInTime: combinedStartDate,
            checkOutTime: combinedEndDate,
            breaks: [],
            lastUpdated: Date(),
            coreStartTime: nil,
            coreEndTime: nil,
            note: note
        )
        
        let record = newSession.toRecord()
        database.save(record) { savedRecord, error in
            if let error = error {
                print("❌ [saveAdjustedSession] 추가 세션 저장 실패: \(error.localizedDescription)")
                return
            }
            if let savedRecord = savedRecord, let savedSession = WorkSession(from: savedRecord) {
                DispatchQueue.main.async {
                    self.sessions.append(savedSession)
                    print("✅ [saveAdjustedSession] 추가 세션 저장 성공")
                    // Refresh all user sessions after saving
                    if let currentUserRecord = self.currentUserRecord {
                        self.fetchUserSessions(userRecord: currentUserRecord)
                    }
                }
            }
        }
    }
    // MARK: - ✅ UserDefaults 기반 currentUserRecord 세팅
    func fetchCurrentUserRecordFromUserDefaults() {
        if let userID = UserDefaults.standard.string(forKey: "userID") {
            let recordID = CKRecord.ID(recordName: userID)
            let userRecord = CKRecord(recordType: "Users", recordID: recordID)
            DispatchQueue.main.async {
                self.currentUserRecord = userRecord
            }
            print("✅ [fetchCurrentUserRecordFromUserDefaults] UserDefaults 기반 currentUserRecord 세팅 완료")
        } else {
            print("❌ [fetchCurrentUserRecordFromUserDefaults] UserDefaults에 userID 없음")
        }
    }
    // MARK: - ✅ userID 기반 추가 세션 저장 메서드 (CloudKit에서 userName 조회)
    func saveAdjustedSessionWithoutUserRecord(userID: String, workType: String, note: String?, selectedDate: Date, startTime: Date, endTime: Date) {
        print("\n----------추가 세션 저장 시작 (userID 기반, CloudKit 조회)----------AttendanceViewModel----------\n")

        let recordID = CKRecord.ID(recordName: userID)
        let userReference = CKRecord.Reference(recordID: recordID, action: .none)

        database.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                print("❌ [saveAdjustedSessionWithoutUserRecord] AppUsers 레코드 조회 실패: \(error.localizedDescription)")
                return
            }

            guard let record = record else {
                print("❌ [saveAdjustedSessionWithoutUserRecord] AppUsers 레코드가 nil입니다.")
                return
            }

            let userName = record["userName"] as? String ?? ""

            DispatchQueue.main.async {
                self._saveSessionInternally(
                    userReference: userReference,
                    userName: userName,
                    workType: workType,
                    note: note,
                    selectedDate: selectedDate,
                    startTime: startTime,
                    endTime: endTime
                )
            }
        }
    }

    // MARK: - 내부적으로 세션 생성 및 저장 (userName과 userReference를 모두 알고 있을 때)
    private func _saveSessionInternally(
        userReference: CKRecord.Reference,
        userName: String,
        workType: String,
        note: String?,
        selectedDate: Date,
        startTime: Date,
        endTime: Date
    ) {
        let workOption: String
        switch workType {
        case "추가근무":
            workOption = "Add"
        case "공석 등록":
            workOption = "Del"
        default:
            print("❌ [_saveSessionInternally] 알 수 없는 workType: \(workType)")
            return
        }

        let calendar = Calendar.current
        let koreanTimeZone = TimeZone(identifier: "Asia/Seoul")!
        var kstCalendar = calendar
        kstCalendar.timeZone = koreanTimeZone

        let startComponents = kstCalendar.dateComponents([.year, .month, .day], from: selectedDate)
        let startHourMinute = kstCalendar.dateComponents([.hour, .minute, .second], from: startTime)
        var combinedStartComponents = DateComponents()
        combinedStartComponents.year = startComponents.year
        combinedStartComponents.month = startComponents.month
        combinedStartComponents.day = startComponents.day
        combinedStartComponents.hour = startHourMinute.hour
        combinedStartComponents.minute = startHourMinute.minute
        combinedStartComponents.second = startHourMinute.second ?? 0
        guard let combinedStartDate = kstCalendar.date(from: combinedStartComponents) else {
            print("❌ [_saveSessionInternally] 시작 시간 생성 실패")
            return
        }

        let endHourMinute = kstCalendar.dateComponents([.hour, .minute, .second], from: endTime)
        var combinedEndComponents = DateComponents()
        combinedEndComponents.year = startComponents.year
        combinedEndComponents.month = startComponents.month
        combinedEndComponents.day = startComponents.day
        combinedEndComponents.hour = endHourMinute.hour
        combinedEndComponents.minute = endHourMinute.minute
        combinedEndComponents.second = endHourMinute.second ?? 0
        guard let combinedEndDate = kstCalendar.date(from: combinedEndComponents) else {
            print("❌ [_saveSessionInternally] 종료 시간 생성 실패")
            return
        }

        let newSession = WorkSession(
            id: UUID().uuidString,
            date: kstCalendar.startOfDay(for: selectedDate),
            userReference: userReference,
            userName: userName,
            workOption: workOption,
            checkInTime: combinedStartDate,
            checkOutTime: combinedEndDate,
            breaks: [],
            lastUpdated: Date(),
            coreStartTime: nil,
            coreEndTime: nil,
            note: note
        )

        let record = newSession.toRecord()
        database.save(record) { savedRecord, error in
            if let error = error {
                print("❌ [_saveSessionInternally] 추가 세션 저장 실패: \(error.localizedDescription)")
                return
            }
            if let savedRecord = savedRecord, let savedSession = WorkSession(from: savedRecord) {
                DispatchQueue.main.async {
                    self.sessions.append(savedSession)
                    print("✅ [_saveSessionInternally] 추가 세션 저장 성공")
                    // Refresh all user sessions after saving
                    if let currentUserRecord = self.currentUserRecord {
                        self.fetchUserSessions(userRecord: currentUserRecord)
                    }
                }
            }
        }
    }
}
