# Expense Tracker (iOS) 💸

A premium, modern iOS application for tracking personal finances, built purely programmatically without Storyboards. The app features a stunning Apple-native design, CoreData for offline persistence, and cutting-edge features like OCR bill scanning using Apple's Vision framework.

## 🌟 Key Features

- **Programmatic UIKit MVC**: 100% programmatic UI using AutoLayout (no Storyboards/XIBs).
- **Beautiful Native UI**: Utilizes Apple's modern `.insetGrouped` styling, Glassmorphism, and dynamic squircle components for a cohesive, premium experience.
- **Smart OCR Bill Scanning**: Automatically extracts the total amount from physical receipts using the iPhone camera and the `Vision` framework!
- **Interactive Analytics**: Custom-built, animated Donut/Pie chart for visualizing expense breakdown by category using `CoreAnimation` and `CAShapeLayer`.
- **CoreData Persistence**: Fully offline storage. Automatically seeds standard categories (Food, Travel, Shopping, etc.) on the first launch.
- **Dynamic Theming**: Flawless Light & Dark mode support, featuring a custom robust `ThemeManager` and dynamic category coloring/icons.
- **Data Export**: Export your transaction data to Excel (CSV) or beautiful PDF reports with one tap.
- **Haptic Feedback**: Rich tactile interactions throughout the app using `UIImpactFeedbackGenerator`.

## 📸 Screenshots
*(Add screenshots here)*
- **Home Screen:** Clean transaction list with grouped headers.
- **Add Transaction:** Modern form layout with OCR Scan button.
- **Analytics:** Animated Pie Chart with horizontal category scrolling.
- **Settings:** Premium `.insetGrouped` UI with custom icons.

## 🛠 Tech Stack

- **Platform:** iOS 14.0+ (Swift 5)
- **Architecture:** Model-View-Controller (MVC)
- **UI Framework:** Programmatic UIKit (AutoLayout)
- **Database:** Core Data (NSPersistentContainer)
- **Frameworks:** `Vision` (OCR), `CoreAnimation` (Custom Graphics)

## 🚀 Installation & Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/dev-rajat1/expenseTracker.git
   ```
2. Open the `.xcodeproj` or `.xcworkspace` file in **Xcode**.
3. Select your preferred iOS Simulator or real device.
4. Hit **Run** (`Cmd + R`) to build the project.
*(Note: No third-party dependencies like CocoaPods or SPM are required. This is a 100% native iOS build!)*

## 📂 Project Structure

```
expenseTracker/
├── Models/
│   ├── CoreDataManager.swift     # CoreData stack and auto-seeding logic
│   └── (Generated Core Data Subclasses: Transaction, Category)
├── Views/
│   ├── PieChartView.swift        # Custom CoreAnimation Pie Chart
│   ├── TransactionCell.swift     # Custom cell for expense/income rows
│   ├── CategoryGridCell.swift    # Custom grid cell for summary
│   └── GlassView.swift           # Reusable frosted-glass card container
├── Controllers/
│   ├── MainTabBarController.swift
│   ├── HomeViewController.swift
│   ├── AddTransactionViewController.swift
│   ├── SummaryViewController.swift
│   ├── SettingsViewController.swift
│   └── CategoryDetailViewController.swift
├── Theme.swift                   # Centralized design tokens, colors, and SF Symbols
└── SceneDelegate.swift           # Application lifecycle
```

## 🧠 OCR Scanning Implementation

The OCR feature leverages Apple's `Vision` framework (`VNRecognizeTextRequest`). When the user scans a receipt via `UIImagePickerController`, the app processes the `cgImage`, extracts all strings containing numbers, filters them using regular expressions, and intelligently picks the maximum value as the total expense!

## 🧑‍💻 Contributing

Pull requests are welcome! If you'd like to add a feature or fix a bug, please fork the repository and submit a PR.

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
