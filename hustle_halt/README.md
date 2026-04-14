# HustleHalt - Income Insurance for Gig Workers

HustleHalt is an AI-powered parametric income insurance mobile app built for delivery partners (Zepto, Blinkit, Swiggy Instamart) in India. It automatically provides income protection when external factors like extreme weather, high AQI, or platform outages disrupt work.

## App Overview
- **Aesthetic:** Minimalist, strong contrast dark mode with logistics-app vibes.
- **Tech Stack:** Flutter 3.x, Dart
- **Architecture:** Clean Architecture + Feature-First (Domain, Data, Presentation)
- **State Management:** Riverpod
- **Routing:** GoRouter (with persistent Bottom Navigation via ShellRoute)
- **Styling:** Google Fonts (Inter) & Vanilla Flutter Theme

## Features Implemented
1. **Onboarding & Auth Flow:** Phone standard signup -> OTP -> Profile setup -> Live API Premium calculations.
2. **Dashboard:** Active Coverage overview, Live environmental feeds (Rainfall, Temp, AQI), and Recent payouts.
3. **Policy History:** Smooth scrolling history of past weekly premiums, with expandable breakdown of triggers.
4. **Claims:** A status tracker demonstrating Auto-Approved, Processing, and Blocked claims with exact timestamps and reasoning.
5. **Real-time Event Simulator:** Tucked away in `Profile` -> `Developer Tools`, this allows triggering a real-life weather crisis on the app to visually demonstrate the parametric logic and state changes reflecting in the Dashboard!

## Folder Structure
```text
lib/
├── core/
│   ├── network/       # Mock data abstractions and models
│   ├── router/        # GoRouter navigation paths
│   ├── theme/         # Complete Dark Theme definition
│   └── widgets/       # Global inputs, buttons, and display widgets
├── features/
│   ├── auth/          # Login, OTP, Onboarding sequence
│   ├── claims/        # Claim Status Details
│   ├── dashboard/     # Metric feeds, Active Coverage, Real-time state
│   ├── policy/        # History list formatting
│   └── profile/       # Profile management and Simulator trigger
└── main.dart          # Entrypoint (ProviderScope + Setup)
```

## How to Run

1. Make sure you have Flutter installed (`flutter channel stable`).
2. Navigate into the app root: `cd hustle_halt`
3. Fetch dependencies: `flutter pub get`
4. Run the app: `flutter run`

**Testing the Simulator:** Once logged in (skip through mocked OTP), click the `Profile` tab at the bottom. Under "Developer Tools", click "Trigger Mock Simulation". You'll get a success snackbar. Navigate back to the "Home" tab to see your Rainfall spike, your Zone Risk go to HIGH, and a new payout credited to your account!
