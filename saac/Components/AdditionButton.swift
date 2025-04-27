import SwiftUI
import CloudKit

struct AdditionButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            Text("근무 조정")
                .font(.callout)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 2)
        }
    }
}

struct AdditionPopupView: View {
    @Binding var isPresented: Bool
    @State private var workType: String = "추가근무"
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var note = ""
    @StateObject private var viewModel = AttendanceViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 작업 설명
                    VStack(alignment: .leading, spacing: 8) {
                        Text("작업 설명")
                            .font(.headline)
                            .foregroundColor(.primary)
                        TextField("예: 외부 미팅, 회의 참석 등", text: $note)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                    }

                    // 근무 유형 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("조정 유형")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Picker("근무 유형", selection: $workType) {
                            Text("추가근무").tag("추가근무")
                            Text("공석 등록").tag("공석 등록")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // 날짜 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("날짜 선택")
                            .font(.headline)
                            .foregroundColor(.primary)
                        DatePicker("",
                                   selection: $selectedDate,
                                   displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .frame(height: 350) // ✅ 패치: 높이 명시
                            .labelsHidden()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemGray6))
                            )
                    }

                    // 시간 설정
                    VStack(alignment: .leading, spacing: 8) {
                        Text("시간 설정")
                            .font(.headline)
                            .foregroundColor(.primary)
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("시작")
                                    .font(.caption)
                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }

                            VStack(alignment: .leading) {
                                Text("종료")
                                    .font(.caption)
                                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                    }

                    // 버튼
                    Button(action: {
                        if let userRecord = self.viewModel.currentUserRecord {
                            print("✅ currentUserRecord 있음: \(userRecord)")
                            self.viewModel.saveAdjustedSession(
                                userRecord: userRecord,
                                workType: self.workType,
                                note: self.note,
                                selectedDate: self.selectedDate,
                                startTime: self.startTime,
                                endTime: self.endTime
                            )
                        } else if let userID = UserDefaults.standard.string(forKey: "currentUserID") {
                            print("✅ currentUserID 기반으로 추가 세션 저장")
                            self.viewModel.saveAdjustedSessionWithoutUserRecord(
                                userID: userID,
                                workType: self.workType,
                                note: self.note,
                                selectedDate: self.selectedDate,
                                startTime: self.startTime,
                                endTime: self.endTime
                            )
                        } else {
                            print("❌ 저장 실패: userRecord도 userID도 없음")
                        }
                        DispatchQueue.main.async {
                            isPresented = false
                        }
                    }) {
                        Text("확인")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top)

                }
                .padding()
            }
            .navigationTitle("근무 조정")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.fetchCurrentUserRecordFromUserDefaults()
        }
    }
}
