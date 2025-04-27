import SwiftUI

struct WorkSessionRowView: View {
    let session: WorkSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.userName)
                    .font(.title3).bold()
                
                if let note = session.note, !note.isEmpty, session.workOption != "Main" {
                    Text(note)
                        .font(.title3)
                        .fontWeight(.regular)
                }
                Spacer()
                
                if session.checkOutTime != nil, let start = session.coreStartTime, let end = session.coreEndTime {
                    let coreTimeHours = end.timeIntervalSince(start) / 3600
                    Text(coreTimeHours >= 4 ? "코어타임 참여" : "코어타임 미참여")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(coreTimeHours >= 4 ? Color.blue : Color.red)
                        .clipShape(Capsule())
                }
                
                Text(session.workOption)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(workOptionBackgroundColor(for: session.workOption))
                    .clipShape(Capsule())
            }

            HStack(spacing: 4) {
                Label(formattedDate(session.date), systemImage: "calendar")
                Spacer()
                Label(formattedTimeRange(start: session.checkInTime, end: session.checkOutTime), systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(session.checkOutTime == nil ? Color.red.opacity(0.1) : Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedTimeRange(start: Date?, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startStr = start.map { formatter.string(from: $0) } ?? "-"
        let endStr = end.map { formatter.string(from: $0) } ?? "-"
        return "\(startStr) ~ \(endStr)"
    }
}


    private func noteBackgroundColor(for workOption: String) -> Color {
        switch workOption {
        case "Add":
            return .green
        case "Del":
            return .orange
        default:
            return .clear
        }
    }

    private func workOptionBackgroundColor(for workOption: String) -> Color {
        switch workOption {
        case "Main":
            return .blue
        case "Add":
            return .green
        case "Del":
            return .orange
        default:
            return .gray
        }
    }
