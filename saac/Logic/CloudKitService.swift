import CloudKit

struct CloudKitService {
    
    //MARK: - ✅ 사용자의 iCloud 접근 권한을 요청하고 결과를 반환
    static func requestiCloudPermission(completion: @escaping (Bool) -> Void) {
        let container = CKContainer.default()
        container.requestApplicationPermission([.userDiscoverability]) { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ iCloud 권한 요청 실패: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                switch status {
                case .granted:
                    print("----------아이클라우드 로그인처리 로그----------CloudKitService----------")
                    print("✅ iCloud 사용자 발견 권한 부여됨 (2)")
                    completion(true)
                case .denied:
                    print("----------아이클라우드 로그인처리 로그----------CloudKitService----------")
                    print("❌ 사용자 권한 거부")
                    completion(false)
                default:
                    print("----------아이클라우드 로그인처리 로그----------CloudKitService----------")
                    print("⚠️ iCloud 권한 요청 결과: \(status.rawValue)")
                    completion(false)
                }
            }
        }
    }

    //MARK: - ✅ CloudKit에서 등록된 사용자 레코드를 조회하여 반환
    static func fetchCurrentUser(completion: @escaping (CKRecord?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "AppUsers", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                DispatchQueue.main.async {
                    completion(record)
                }
            case .failure(let error):
                print("❌ 사용자 로드 실패: \(error.localizedDescription)")
                completion(nil)
            }
        }

        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    //MARK: - ✅ 주어진 userID로 사용자 레코드를 조회
    static func fetchUserRecord(by userID: String, completion: @escaping (CKRecord?) -> Void) {
        let predicate = NSPredicate(format: "id == %@", userID)
        let query = CKQuery(recordType: "AppUsers", predicate: predicate)

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { results, error in
            if let error = error {
                print("❌ 사용자 조회 실패: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let record = results?.first {
                print("✅ userID로 사용자 레코드 조회 성공")
                completion(record)
            } else {
                print("⚠️ 해당 userID로 사용자 레코드를 찾을 수 없음")
                completion(nil)
            }
        }
    }
    //MARK: - ✅ 애플 로그인 이후 사용자 레코드 생성
    static func createUserRecord(userID: String, userName: String, email: String, completion: @escaping (CKRecord?) -> Void) {
        let record = CKRecord(recordType: "AppUsers")
        record["id"] = userID
        record["userName"] = userName
        record["email"] = email
        record["createdAt"] = Date()

        CKContainer.default().publicCloudDatabase.save(record) { savedRecord, error in
            if let error = error {
                print("❌ 사용자 레코드 저장 실패: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("✅ 사용자 레코드 생성 및 저장 성공")
                completion(savedRecord)
            }
        }
    }
}
