# 💸 Ultra-Premium Expense Tracker (iOS)

A production-level, highly advanced iOS Expense Tracker application built entirely programmatically in **Swift** using **UIKit** and **Core Data**. 

This app avoids Storyboards and SwiftUI, showcasing how to build complex, scalable, and premium user interfaces natively using code.

---

## ✨ Key Features

- **Programmatic UI (No Storyboards):** The entire application lifecycle, views, and navigation are built cleanly with code.
- **Glassmorphism Design:** Beautiful translucent cards with blur effects (`UIVisualEffectView`), custom shadows, and dynamic dark mode support.
- **Core Data (Programmatic):** Built without a `.xcdatamodeld` file to ensure zero XML corruption. Pure Swift `NSManagedObjectModel` implementation for entities and relationships.
- **Smart Receipt Scanning (OCR):** Uses Apple's native `Vision` framework to scan bills through the camera and automatically extract the highest amount.
- **Interactive Data Visualization:** Custom Core Graphics `PieChartView` with smooth `CABasicAnimation` and tap-to-filter capabilities.
- **Budget Tracking & Alerts:** Dynamic category monitoring. Warns you visually when expenses cross 80% of your allocated budget.
- **Dynamic Localization:** Uses `NumberFormatter` to dynamically adapt currency symbols (e.g., $, ₹, €, £) based on your device's region.
- **Haptic Micro-interactions:** Tactile feedback via `UIImpactFeedbackGenerator` when interacting with charts, saving data, or modifying settings.
- **CSV Data Export:** Generate comprehensive Excel-compatible reports and share them directly via the native iOS Share Sheet.
- **Local Reminders:** `UNUserNotificationCenter` integration for daily logging reminders.

---

## 🛠 Tech Stack & Architecture

- **Language:** Swift 5+
- **UI Framework:** UIKit (Programmatic exclusively)
- **Database:** Core Data
- **Machine Learning:** Vision Framework (OCR)
- **Architecture Pattern:** MVC (Model-View-Controller)
- **External Dependencies:** Zero (100% Native)

---

## 🚀 How to Run Locally

Since this project uses a programmatic structure, running it on your Mac is seamless.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/dev-rajat1/expenseTracker.git
   ```
2. **Open the project in Xcode:**
   - Double click on `expenseTracker.xcodeproj`.
3. **Link Files (If needed):**
   - Since the UI is purely programmatic, if you don't see `Models`, `Views`, and `Controllers` in the Project Navigator, simply drag and drop them from Finder into Xcode. Make sure to check **"Add to targets: expenseTracker"**.
4. **Compile and Run:**
   - Select your preferred iOS Simulator (e.g., iPhone 15 Pro).
   - Hit `Cmd + R` to run!

---

## 📸 Screenshots

*(Add screenshots here after running the app)*

---

*Built with ❤️ for a premium iOS experience.*
