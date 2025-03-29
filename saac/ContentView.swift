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

    let workOptions = ["에자일 근무", "린 근무", "파트타임 근무"]  // ✅ 동적 선택 가능

    init(viewModel: AttendanceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                if isSignedIn {
                    if let userRecord = currentUserRecord {
                        Text("사용자: \(userRecord["userName"] as? String ?? "이름없음")")
                            .font(.headline)

                        Picker("근무 옵션", selection: $selectedWorkOption) {
                            ForEach(workOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()

                        HStack {
                            Button("출근") {
                                let userRecord = userRecord
                                self.viewModel.checkIn(userRecord: userRecord, workOption: selectedWorkOption)
                            }
                            .buttonStyle(.borderedProminent)

                            Button("퇴근") {
                                if let lastRecord = self.viewModel.sessions.last, lastRecord.checkOutTime == nil {
                                    self.viewModel.checkOut(session: lastRecord)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()

                        List {
                            ForEach(self.viewModel.sessions, id: \.id) { record in
                                VStack(alignment: .leading) {
                                    Text("이름: \(record.userName)")
                                    Text("출근: \(record.checkInTime ?? Date(), formatter: DateFormatter.shortTime)")
                                    if let checkOut = record.checkOutTime {
                                        Text("퇴근: \(checkOut, formatter: DateFormatter.shortTime)")
                                    } else {
                                        Text("퇴근 기록 없음").foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ProgressView("사용자 정보를 불러오는 중...")
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

                                let userID = appleIDCredential.user
                                let fullNameComponents = appleIDCredential.fullName
                                let fullName = [fullNameComponents?.familyName, fullNameComponents?.givenName]
                                    .compactMap { $0 }
                                    .joined(separator: " ")
                                let finalName = fullName.isEmpty ? "이름없음" : fullName

                                viewModel.fetchOrCreateUserRecord(forAppleID: userID, userName: finalName) { record in
                                    if let record = record {
                                        DispatchQueue.main.async {
                                            self.currentUserRecord = record
                                            self.viewModel.fetchUserSessions(userRecord: record)
                                            self.isSignedIn = true
                                        }
                                    }
                                }

                            case .failure(let error):
                                print("❌ Apple 로그인 실패: \(error.localizedDescription)")
                            }
                        }
                    )
                    .frame(height: 44)
                    .frame(maxWidth: .infinity) // prevent constraint conflict
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
            .navigationTitle("사악한 시스템")
            .onAppear {
                requestiCloudPermission { granted in
                    if granted {
                        fetchCurrentUser()
                    } else {
                        print("❌ iCloud 권한이 필요합니다.")
                    }
                }
            }
        }
    }

    func requestiCloudPermission(completion: @escaping (Bool) -> Void) {
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

    func fetchCurrentUser() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "AppUsers", predicate: predicate) // Updated record type
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                DispatchQueue.main.async {
                    self.currentUserRecord = record
                    self.viewModel.fetchUserSessions(userRecord: record)
                }
            case .failure(let error):
                print("❌ 사용자 로드 실패: \(error.localizedDescription)")
            }
        }

        CKContainer.default().publicCloudDatabase.add(operation)
    }
}

/// ✅ 날짜 포맷 설정 (중복 선언 방지)
extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
