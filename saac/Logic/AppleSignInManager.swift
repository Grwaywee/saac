import Foundation
import AuthenticationServices
import CloudKit

final class AppleSignInManager: NSObject, ObservableObject {
    
    var appState: AppStateViewModel?

    //MARK: - ✅ 이게 뭘하는지 잘모르겠음
    func startSignIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.performRequests()
    }
    
    //MARK: - ✅ iCloud 사용자 신규 생성
    func fetchOrCreateUserRecord(forAppleID userIdentifier: String, userName: String?, email: String?, completion: @escaping (CKRecord?) -> Void) {
        print("\n----------사용자 신규 로그인 로그----------AppleSignInManager----------\n")
        print("🪪 userID: \(userIdentifier)")
        print("🧑 userName: \(userName ?? "nil")")
        print("📧 email: \(email ?? "nil")")
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: userIdentifier)

        let newUser = CKRecord(recordType: "AppUsers", recordID: recordID)
        newUser["id"] = userIdentifier as CKRecordValue
        newUser["email"] = (email ?? "unknown@icloud.com") as CKRecordValue
        newUser["createdAt"] = Date() as CKRecordValue

        if let name = userName, !name.isEmpty {
            newUser["userName"] = name as CKRecordValue
        } else {
            print("📥 이름이 없어서 fallback 처리: 이름없음")
            newUser["userName"] = "이름없음" as CKRecordValue
        }

        database.save(newUser) { savedRecord, error in
            if let savedRecord = savedRecord {
                print("✅ 클라우드 킷 저장 성공 및 userDefaults에 userID 저장: \(savedRecord.recordID.recordName)")
                UserDefaults.standard.set(userIdentifier, forKey: "currentUserID")
                print("----------이상 끝----------AppleSignInManager----------")
                completion(savedRecord)
            } else {
                print("❌ Users 레코드 저장 실패: \(error?.localizedDescription ?? "알 수 없음")")
                print("----------이상 끝----------AppleSignInManager----------")
                completion(nil)
            }
        }
    }
}
