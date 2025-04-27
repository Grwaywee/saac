import SwiftUI
import CloudKit

struct WorkSessionView: View {
    @State private var sessions: [WorkSession] = []
    @State private var selectedFilter: String = "전체"
    let workOptions = ["전체", "Main", "Add", "Del"]
    
    private var filteredSessions: [WorkSession] {
        selectedFilter == "전체" ? sessions : sessions.filter { $0.workOption == selectedFilter }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Custom Picker
                Picker("필터", selection: $selectedFilter) {
                    ForEach(workOptions, id: \.self) { option in
                        let text = Text(option.capitalized)
                            .fontWeight(.semibold)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                        text
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .background(Color(.systemGray6))
                .padding(.horizontal)

                // Filtered session cards
                LazyVStack(spacing: 16) {
                    ForEach(filteredSessions, id: \.id) { session in
                        WorkSessionRowView(session: session)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedFilter)
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("전체 WorkSession")
        .onAppear {
            fetchAllSessions()
        }
    }
    
    //MARK : - ✅ 워크세션 리스트 전체를 불러
    func fetchAllSessions() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "WorkSession", predicate: predicate)
        query.sortDescriptors = []
        
        print("\n----------워크세션 데이터 풀 로그----------WorkSessionView----------\n")
        
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ WorkSession 전체 조회 실패: \(error.localizedDescription)")
                print("----------이상 끝----------WorkSessionView----------")
                return
            }
            
            guard let records = records else {
                print("❌ WorkSession 전체 조회 실패 - records == nil")
                print("----------이상 끝----------WorkSessionView----------")
                return
            }
            
            let sessions = records.compactMap { WorkSession(from: $0) }
            print("✅ WorkSession 전체 \(sessions.count)개 불러옴")
            print("----------이상 끝----------WorkSessionView----------")
            
            DispatchQueue.main.async {
                self.sessions = sessions.sorted { $0.date > $1.date }
            }
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func formattedTimeRange(start: Date?, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startStr = start.map { formatter.string(from: $0) } ?? "-"
        let endStr = end.map { formatter.string(from: $0) } ?? "-"
        return "\(startStr) ~ \(endStr)"
    }
}
