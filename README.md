# saac (Software As ACkkibary)

saacApp은 SwiftUI 기반으로 개발된 출퇴근 기록 및 업무 시간 관리용 iOS 애플리케이션입니다. CloudKit을 통해 사용자 정보를 안전하게 저장하고, 에자일 기반의 업무 패턴을 시각화하며 기록을 자동화합니다.

---


---

## 📌 주요 기능 상세 설명

### 1. 출퇴근 기록 시스템
- `MainUIView.swift`에 구현된 UI에서 출근/퇴근 버튼을 누르면 `AttendanceViewModel`을 통해 CloudKit에 `WorkSession` 레코드가 생성됩니다.
- 출근 시각과 퇴근 시각은 CloudKit 서버 시간을 기준으로 하며, 중복 출근/퇴근을 방지하는 로직이 포함되어 있습니다.

### 2. 코어타임 근무 시각화
- 개발자가 설정한 팀의 코어타임(예: 13:00~17:00)을 기준으로 사용자의 실제 근무 시간과의 겹침 여부를 시각적으로 표시합니다.
- `TimeBarCalculator.swift`에서 시간 단위의 막대를 계산해 `MainUIView`에서 캡슐 형태로 UI 표시해줍니다.

### 3. 근무 시간 통계
- `StatisticsView.swift`를 통해 주간/일간 단위로 WorkSession을 불러와 근무 시간 총합을 계산합니다.
- 출근 시간 분포, 집중 시간대 등의 인사이트도 시각적으로 제공합니다.

### 4. WorkSession 실시간 UI 반영
- 현재 활성 세션은 `MainUIView`에서 `xOffset`, `widthBetween` 값으로 시간 흐름에 따라 UI 막대 길이가 실시간 업데이트됩니다.
- 실시간 타이머를 활용하여 `onReceive`로 1분 간격 갱신이 이루어집니다.

### 5. 자동 로그인 및 사용자 복원
- `AppStateViewModel.swift`에서 UserDefaults를 확인하여 userID가 존재하면 자동 로그인 절차를 진행합니다.
- CloudKit에서 사용자 정보를 검증한 후 `MainUIView`로 진입하며, 그렇지 않은 경우 `LoginView`로 이동합니다.

---

---

## 💡 기술 스택 및 활용 방식

### 🧱 SwiftUI
- 애플의 선언형 UI 프레임워크로, 모든 뷰는 상태 기반으로 자동 업데이트되도록 설계
- `@State`, `@Binding`, `@ObservedObject`, `@EnvironmentObject` 등 SwiftUI의 데이터 흐름 구조를 적극 활용
- 모든 주요 화면(`MainUIView`, `LoginView`, `StatisticsView` 등)은 SwiftUI 기반으로 구성되어 있으며,
  반복적인 뷰 구조를 줄이기 위해 `Components` 디렉토리에서 공통 버튼 컴포넌트화(`SessionButton`, `CoreTimeButton`) 진행
- 다크모드 대응: 시스템 appearance에 따라 자동 색상 전환 처리
- 접근성 고려: 시스템 폰트, 사이즈 조절 자동 반영, VoiceOver 사용시 구조 파악 용이하게 설계

### ☁️ CloudKit (퍼블릭 데이터베이스)
- Apple의 iCloud 기반 백엔드 솔루션 사용
- 사용자의 로그인 상태는 CloudKit의 `Users` 레코드 기반으로 식별하며, 자동 로그인 구현 시 `recordID`를 기준으로 검증
- 모든 WorkSession 데이터는 CloudKit의 `WorkSession` 레코드로 저장되며, `CloudKitService.swift`를 통해 모든 CRUD 작업을 추상화
- CloudKit 동기화 방식:
  - 저장 시: `CKRecord`로 생성 후 `CKModifyRecordsOperation` 사용
  - 조회 시: `CKQuery`로 사용자 ID 기준 WorkSession 가져오기
  - 삭제 시: `CKRecord.ID`로 직접 삭제
- 앱에서 에러 발생 시 사용자에게 안내 알림을 표시하는 방식으로 CloudKit의 오류 관리 처리

### 🔄 Combine
- Apple의 리액티브 프레임워크
- 사용자 로그인 여부(`AppStateViewModel`) 및 출퇴근 상태(`AttendanceViewModel`)를 `@Published`로 선언하여 뷰에서 자동으로 상태 반영
- 타이머를 사용한 실시간 UI 업데이트(`Timer.publish(every: 60, on: .main, in: .common).autoconnect()`)는 `onReceive` 구문으로 처리
- 사용자 입력 처리 흐름도 Combine 파이프라인으로 구성해 코드의 예측 가능성과 재사용성을 높임

### 🧪 Xcode Previews
- SwiftUI의 `PreviewProvider`를 적극 활용하여 각 View의 시각적 구성과 상태 조합을 사전에 확인
- 디자인 수정 사항이나 레이아웃 문제를 빠르게 식별할 수 있도록 프리뷰용 더미 모델(`Users`, `WorkSession`)을 구성하여 연동

### 🧰 기타 툴/구조
- `UserDefaults`를 통해 유저의 `recordName`을 저장해 자동 로그인 구현
- `AppStorage`를 부분적으로 활용해 일부 사용자의 환경설정이나 이름 등 간단한 값 유지
- 앱 상태에 따라 화면 분기 처리: `saacApp.swift` → `AppStateViewModel` → `ContentView` 또는 `MainUIView`
- 앱 전체 진입 및 종료 상태 확인 시 `UIApplicationDelegateAdaptor` 사용으로 life cycle 연동

---

## 📂 폴더 구조 상세

```
📁 saac/
├── App/
│   ├── ContentView.swift             # 앱 진입점, 로그인 상태에 따라 분기
│   └── saacApp.swift                 # SwiftUI 앱의 @main 구조 및 초기화 담당
├── Components/
│   ├── SessionButton.swift          # 출퇴근 버튼
│   ├── CoreTimeButton.swift         # 코어타임 확인 버튼
│   └── AdditionButton.swift         # 업무 세션 추가 버튼
├── Logic/
│   ├── AppleSignInManager.swift      # 애플 로그인 처리 로직
│   ├── CloudKitService.swift         # CloudKit 데이터 처리
│   └── TimeBarCalculator.swift       # 시간 막대 계산 로직
├── Model/
│   ├── Users.swift                   # 사용자 모델
│   ├── WorkSession.swift             # 업무 세션 모델
│   └── Item.swift                    # (기타 앱 내 객체 모델)
├── View/
│   ├── LoginView.swift              # 로그인 화면
│   ├── MainUIView.swift             # 메인 UI
│   ├── SettingsView.swift           # 환경 설정 화면
│   ├── StatisticsView.swift         # 근무 시간 통계 화면
│   └── WorkSessionView.swift        # 세션 목록 뷰
├── ViewModel/
│   ├── AppStateViewModel.swift       # 앱 전역 상태 관리
│   └── AttendanceViewModel.swift     # 출퇴근 상태 관리
├── Preview Content/                  # SwiftUI 프리뷰용 리소스
│   └── (예: WorkSession + Users 더미 데이터 저장소 용도)
├── Resources/
│   └── Assets.xcassets               # 앱 아이콘 및 색상 설정
├── Config/
│   └── Info.plist                    # 앱 메타데이터 설정
├── saacTests/                        # 단위 테스트
├── saacUITests/                      # UI 테스트
```

---

## 🔄 데이터 흐름 다이어그램 (요약)

```plaintext
[앱 실행]
    ↓
[saacApp.swift]
    ↓
[AppStateViewModel.tryAutoSignIn()]
    ↓
[UserDefaults에 userID 존재?]
    → (예) → CloudKit → 사용자 정보 Fetch → MainUIView
    → (아니오) → LoginView → Apple 로그인 → 사용자 입력 저장 → CloudKit 저장

--- 이후 사용자 상호작용 흐름 ---
[MainUIView] ⟷ [AttendanceViewModel] ⟷ [CloudKitService] ⟷ CloudKit
               ⬑ 출퇴근 버튼 누름 → WorkSession 생성
               ⬐ 실시간 UI 갱신 (타이머 + Combine)
```

---

## 🎨 UI 디자인 철학

- **직관적이고 간결한 인터페이스**: 버튼을 중심으로 한 동선 구성으로 출근, 퇴근, 업무 세션 추가 등 주요 기능에 빠르게 접근 가능하도록 설계했습니다.
- **실시간 반응성**: 사용자의 근무 시간 및 세션 상태가 즉시 UI에 반영되도록 실시간 갱신 구조(`onReceive`, 타이머 활용)를 적용했습니다.
- **시각적 피드백 강화**: 코어타임 근무 시간은 시각적으로 캡슐 형태의 막대 UI로 표시되며, 시간대별 집중도 시각화를 통해 사용자의 업무 패턴을 직관적으로 이해할 수 있게 구성했습니다.
- **Apple Human Interface Guideline 준수**: macOS 기본 디자인 언어를 따르며, 다크모드 및 기본 시스템 폰트를 사용해 일관성과 가독성을 확보했습니다.

---

## 🔐 로그인 및 데이터 흐름 요약

- 앱 실행 → `saacApp.swift`에서 CloudKit 초기화
- 자동 로그인 시도 → `AppStateViewModel`에서 UserDefaults 확인
- 유효한 userID가 존재하면 → CloudKit에서 사용자 Fetch → `MainUIView` 진입
- 없으면 → `LoginView`로 이동 → 애플 로그인 → 사용자 이름 저장

---

## 🧑‍💼 사용자 페르소나

### Persona #1: 김세은 (27세, 스타트업 PM)
- 사용 목적: 원격 근무 중 자기 주도적인 시간 관리 및 출결 기록 자동화
- 니즈: 매일 몇 시부터 집중했는지 시각적으로 보고 싶고, 하루 업무를 팀원과 공유하고 싶음
- 기대 기능:
  - 실시간 출근/퇴근 버튼
  - 하루 업무 시간 통계
  - 근무 집중도 시각화

### Persona #2: 이주형 (34세, 개발팀 리드)
- 사용 목적: 팀의 코어타임 근무 집중도를 추적하고, 정기 회고 시 데이터를 활용하기 위함
- 니즈: 코어타임 기준 근무 현황을 파악하고, 팀원별 근무 세션 패턴을 주간 단위로 확인하고 싶음
- 기대 기능:
  - 코어타임 시각화
  - 주간 통계
  - 근무 세션별 분포 그래프

---

## 🧪 향후 개선 계획

- [ ] 온디바이스 저장 방식 지원
- [ ] 더 정교한 통계 기능 (예: 집중도 분석)
- [ ] 팀 단위 출결 공유 및 관리자 권한

## ⚙️ 설치 및 실행

---

1. 이 저장소를 클론합니다.
```bash
git clone https://github.com/yourname/saac.git
```

2. `saac.xcodeproj` 또는 `saac.xcworkspace`를 Xcode에서 엽니다.

3. 시뮬레이터 또는 실제 macOS 디바이스에서 실행합니다.
