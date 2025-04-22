import Foundation
import CloudKit
import Combine

final class AppStateViewModel: ObservableObject {
    // 로그인 상태
    @Published var isSignedIn: Bool = false
    
    // 현재 사용자 정보
    @Published var currentUserRecord: CKRecord?
    @Published var currentUserName: String = "이름없음"
    @Published var isLoadingUser: Bool = false
    
    // 에러 메시지 (사용자에게 표시 가능)
    @Published var errorMessage: String?

    //MARK: - ✅ 자동 로그인 여부 확인
    func tryAutoSignIn() {
        print("\n----------로그인 분기 처리 로그----------AppStateViewModel----------\n")
        if let savedUserID = UserDefaults.standard.string(forKey: "currentUserID") {
            print("🧪 UserDefaults에 저장된 userID 있음 → \(savedUserID)")
            isLoadingUser = true
            CloudKitService.fetchUserRecord(by: savedUserID) { record in
                DispatchQueue.main.async {
                    self.isLoadingUser = false
                    if let record = record {
                        print("✅ CloudKit에서 유효한 사용자 레코드 확인됨 → 콜드스타트")
                        self.completeSignIn(with: record)
                        print("----------이상 끝----------AppStateViewModel----------")
                    } else {
                        print("⚠️ CloudKit에서 해당 userID의 레코드 없음 → UserDefaults 초기화")
                        UserDefaults.standard.removeObject(forKey: "currentUserID")
                        self.isSignedIn = false
                        print("----------이상 끝----------AppStateViewModel----------")
                    }
                }
            }
        } else {
            print("🧊 UserDefaults에 userID 없음 → 초기 로그인 시작")
            // 대기 상태로 유지, AppleSignInManager 쪽에서 로그인 처리 유도
            self.isSignedIn = false  // ✅ 명시적으로 로그인 안된 상태로 처리
            print("----------이상 끝----------AppStateViewModel----------")
        }
    }

    //MARK: - ✅  로그인 완료 후 상태 업데이트
    func completeSignIn(with record: CKRecord) {
        currentUserRecord = record
        currentUserName = record["userName"] as? String ?? "이름없음"
        isSignedIn = true
        if let userID = record["id"] as? String {
            UserDefaults.standard.set(userID, forKey: "currentUserID")
        }
    }

    //MARK: - ✅  로그아웃 처리
    func signOut() {
        currentUserRecord = nil
        currentUserName = "이름없음"
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: "currentUserID")
    }
}
