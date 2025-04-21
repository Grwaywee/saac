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
                    print("✅ iCloud 사용자 발견 권한 부여됨")
                    completion(true)
                case .denied:
                    print("❌ 사용자 권한 거부")
                    completion(false)
                default:
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
}
