import SwiftUI

struct CoreTimeButton: View {
    var isCoreTimeActive: Bool
    var isVisible: Bool
    var action: () -> Void = {}

    var body: some View {
        if isVisible {
            Button(action: action) {
                Text(isCoreTimeActive ? "코어타임중..." : "코어타임 시작")
                    .font(.callout)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isCoreTimeActive ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
            }
        }
    }
}
