import SwiftUI

struct SessionButton: View {
    @Binding var isCheckedIn: Bool
    let action: () -> Void

    var body: some View {
        let title = isCheckedIn ? "퇴근" : "출근"
        let backgroundColor = isCheckedIn ? Color.orange : Color.accentColor

        return Button(title) {
            action()
            isCheckedIn.toggle()
        }
        .font(.callout)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .foregroundColor(.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
