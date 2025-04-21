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

    init(viewModel: AttendanceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                if isSignedIn {
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
                    LoginView(viewModel: viewModel) { record in
                        self.isLoading = true
                        self.currentUserRecord = record
                        self.viewModel.fetchUserSessions(userRecord: record)
                        self.isSignedIn = true
                        self.isLoading = false
                    }
                    .padding()
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
            
            .onAppear {
                CloudKitService.requestiCloudPermission { granted in
                    if granted {
                        CloudKitService.fetchCurrentUser { record in
                            if let record = record {
                                self.currentUserRecord = record
                                self.viewModel.fetchUserSessions(userRecord: record)
                            }
                            isLoading = false
                        }
                    } else {
                        print("❌ iCloud 권한이 필요합니다.")
                        isLoading = false
                    }
                }
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
