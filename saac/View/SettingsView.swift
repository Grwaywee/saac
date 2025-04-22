import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var viewModel: AttendanceViewModel
    @State private var showDeleteAlert = false
    @State private var deleteCount = 0
    @State private var confirmDelete = false
    @State private var showLogoutInfo = false
    var body: some View {
        Form {
            Section(header: Text("계정")) {
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text("사용자 정보")
                }
                HStack {
                    Image(systemName: "envelope")
                    Text("이메일")
                }
            }

            Section(header: Text("앱 설정")) {
                Toggle(isOn: .constant(true)) {
                    Text("알림 받기")
                }
                Toggle(isOn: .constant(false)) {
                    Text("다크 모드")
                }
            }

            Section {
                Button(role: .destructive) {
                    showLogoutInfo = true
                } label: {
                    Text("로그아웃")
                }
                .alert("로그아웃 안내", isPresented: $showLogoutInfo) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text("애플 설정 > Apple 계정 > Apple로 로그인에서 로그아웃할 수 있어요.")
                }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Text("탈퇴하기")
                }
                .alert("정말 탈퇴하시겠습니까?", isPresented: $confirmDelete) {
                    Button("취소", role: .cancel) {}
                    Button("탈퇴하기", role: .destructive) {
                        showDeleteAlert = true
                        let currentCount = UserDefaults.standard.integer(forKey: "deleteClickCount")
                        let newCount = currentCount + 1
                        UserDefaults.standard.set(newCount, forKey: "deleteClickCount")
                        deleteCount = newCount
                    }
                } message: {
                    Text("정말 사악함을 내려놓고 탈퇴하시겠습니까?")
                }
                .alert("그만 사악해지시겠습니까?", isPresented: $showDeleteAlert) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text("이 버튼을 \(deleteCount)번 누르셨습니다. (사악, 사악, 사악, 사악, 사악, 사악, 사악, 사악, 사악)?")
                }
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
