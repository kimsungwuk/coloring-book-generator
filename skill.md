# Project: [MyColoringBook] - Flutter Development Skill Specification

## 1. Technical Stack
- **Framework:** Flutter (Latest Stable)
- **State Management:** Provider or Riverpod (선택 가능)
- **Backend:** Firebase (Cloud Firestore, Firebase Messaging)
- **Monetization:** google_mobile_ads (Banner Ads)
- **Architecture:** Clean Architecture (Data, Domain, Presentation)

## 2. Layout & UI Guidelines (Safe Area)
- **Edge-to-Edge:** 시스템 상태바와 하단 네비게이션 바 침범을 방지하기 위해 최상위 위젯을 `SafeArea`로 감싸거나 `Scaffold`를 적절히 활용한다.
- **Design System:** Material 3 디자인 가이드를 준수한다.

## 3. Back Button & Exit Dialog Logic
- **Behavior:** 홈 화면에서 시스템 백버튼(또는 스와이프 뒤로가기) 감지 시 바로 종료되지 않도록 `PopScope` (또는 이전 버전의 `WillPopScope`) 위젯을 사용한다.
- **Exit Dialog:** - 백버튼 클릭 시 `showDialog`를 호출하여 종료 확인 창을 띄운다.
    - **AdMob Integration:** 다이얼로그 `content` 영역에 `AdSize.banner` 크기의 광고 위젯을 배치한다.
    - 광고 로딩 중 레이아웃 깨짐을 방지하기 위해 `SizedBox`로 높이를 고정(50px~60px)한다.
    - '확인' 클릭 시 `SystemNavigator.pop()`을 호출하여 앱을 종료한다.

## 4. Firebase & AdMob Implementation
- **Firestore:** `FirebaseFirestore.instance`를 직접 호출하지 않고, Repository 클래스를 통해 데이터에 접근한다.
- **FCM:** `FirebaseMessaging.onMessage` 및 `onMessageOpenedApp`을 통해 푸시 알림을 처리한다.
- **AdMob (Bottom):** 메인 화면 `Scaffold`의 `bottomNavigationBar` 또는 `PersistentBottomSheet` 위치에 배너 광고를 고정한다.

## 5. Coding Principles for Antigravity
- 모든 UI 구성 요소는 최대한 작은 단위의 `StatelessWidget`으로 분리한다.
- 비즈니스 로직은 UI 위젯에서 분리하여 전용 상태 관리 클래스에서 처리한다.
- 하드코딩된 문자열은 별도의 상수로 관리하거나 l10n을 고려한다.

## 6. Localization (다국어 지원)
- **Framework:** Flutter `intl` 패키지를 사용하여 다국어를 관리한다.
- **Resource File:** 모든 문자열은 `lib/l10n/` 폴더 내의 `.arb` 파일(app_en.arb, app_ko.arb 등)에 정의한다.
- **Rules:**
    - UI 코드 내에 문자열을 직접 하드코딩(Hard-coding)하지 않는다.
    - 반드시 `AppLocalizations.of(context)!.keyName` 형식을 사용하여 문자열을 불러온다.
    - 새로운 기능을 만들 때 해당 기능에 필요한 문자열을 `.arb` 파일에 먼저 추가한 후 코드를 작성한다.