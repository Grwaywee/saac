import SwiftUI
import CloudKit
import AuthenticationServices

struct ContentView: View {
    @ObservedObject var viewModel: AttendanceViewModel
    @State private var currentUserRecord: CKRecord?
    @State private var selectedWorkOption: String = "에자일 근무"
    @State private var showingNamePrompt = false
    @State private var fallbackName = ""
    @State private var nameCompletionHandler: ((String) -> Void)? = nil
    @State private var appleIDCredential: ASAuthorizationAppleIDCredential?
    @State private var isSignedIn = false
    @State private var isLoading = false
    @State private var isCheckingAutoSignIn = true

    @EnvironmentObject var appState: AppStateViewModel
    @StateObject private var signInManager = AppleSignInManager()

    init(viewModel: AttendanceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                if isCheckingAutoSignIn {
                    ProgressView("사악한 계략 세우는 중...")
                } else if isSignedIn {
                    if isLoading {
                        ProgressView("사악한 계략 세우는 중...")
                    } else if let userRecord = currentUserRecord {
                        MainUIView(
                            viewModel: viewModel,
                            currentUserRecord: userRecord,
                            selectedWorkOption: $selectedWorkOption
                        )
                    }
                } else {
                    LoginView(
                        signInManager: signInManager,
                        onLoginSuccess: { record in
                            appState.completeSignIn(with: record)
                        }
                    )
                }
            }
            .sheet(isPresented: $showingNamePrompt) {
                VStack(spacing: 20) {
                    Text("이름을 입력해주세요")
                        .font(.headline)

                    TextField("이름", text: $fallbackName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button("확인") {
                        showingNamePrompt = false
                        nameCompletionHandler?(fallbackName)
                        nameCompletionHandler = nil
                    }
                    .disabled(fallbackName.isEmpty)
                }
                .padding()
            }
            .task {
                isCheckingAutoSignIn = true
                currentUserRecord = appState.currentUserRecord
                isSignedIn = appState.isSignedIn

                if let userRecord = currentUserRecord, isSignedIn {
                    isLoading = true
                    viewModel.fetchTodayMainSession(userRecord: userRecord)
                    // 약간의 지연을 줘서 쿼리 타이밍을 맞추거나 콜백 대체 가능
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isLoading = false
                    }
                } else {
                    isLoading = false
                }
                isCheckingAutoSignIn = false
            }
            
        }
    }
}

//MARK: -  ✅ 날짜 포맷 설정 (중복 선언 방지)
extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
