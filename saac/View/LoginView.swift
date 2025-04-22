import SwiftUI
import AuthenticationServices
import CloudKit

struct LoginView: View {
    var signInManager: AppleSignInManager
    var onLoginSuccess: (CKRecord) -> Void
    
    @State private var currentMessageIndex = 0
    private let rotatingMessages = ["고객, 고객, 고객, 고객, 고객", "10X 사악하게", "린, 에자일, 헝그리"]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack {
                    Spacer()
                    Text(rotatingMessages[currentMessageIndex])
                        .frame(width: geometry.size.width * 0.8, height: 100)
                        .background(Color(UIColor.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(20)
                        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
                            currentMessageIndex = (currentMessageIndex + 1) % rotatingMessages.count
                        }
                    Spacer()
                }
                .frame(height: geometry.size.height * 0.5)

                VStack {
                    Spacer()
                    SignInWithAppleButton(.signIn,
                                          onRequest: { request in
                                              request.requestedScopes = [.fullName, .email]
                                          },
                                          onCompletion: { result in
                                              switch result {
                                              case .success(let authorization):
                                                  guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

                                                  let userID = credential.user
                                                  let nameComponents = credential.fullName
                                                  let fullName = [nameComponents?.familyName, nameComponents?.givenName]
                                                      .compactMap { $0 }
                                                      .joined(separator: " ")
                                                  let finalName = fullName.isEmpty ? "이름없음" : fullName

                                                  signInManager.fetchOrCreateUserRecord(forAppleID: userID, userName: finalName, email: credential.email) { record in
                                                      if let record = record {
                                                          DispatchQueue.main.async {
                                                              onLoginSuccess(record)
                                                          }
                                                      }
                                                  }

                                              case .failure(let error):
                                                  print("❌ Apple 로그인 실패: \(error.localizedDescription)")
                                              }
                                          })
                    .frame(height: 40)
                    .frame(width: 200)
                    Spacer()
                }
                .frame(height: geometry.size.height * 0.4)

                Spacer()

                VStack(spacing: 2) {
                    Text("Built by Weelient")
                    Text("Presented to Grway")
                }
                .font(.footnote)
                .foregroundColor(.gray)
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(signInManager: AppleSignInManager()) { _ in
            // Preview: No-op for login success
        }
    }
}
