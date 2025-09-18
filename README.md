# Troova

![Troova Logo](assets/icons/logo_foreground.png)

**Troova** is a cross-platform mobile application designed to connect people who offer and seek local services. Built with Flutter, the app delivers a smooth and responsive user experience across Android, iOS, and other supported platforms.

---

## 📜 Table of Contents

- [About the Project](#-about-the-project)
- [✨ Key Features](#-key-features)
- [🛠️ Technology Stack & Architecture](#️-technology-stack--architecture)
  - [Technology Stack](#technology-stack)
  - [Architecture](#architecture)
- [🚀 Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [🔧 Configuration](#-configuration)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## 📜 About the Project

Troova aims to create a simple and intuitive ecosystem where users can publish listings for the services they offer (e.g., tutoring, gardening, consulting) while also finding and contacting professionals and service providers in their area. The app includes real-time chat functionality, listing management, and detailed user profiles.

---

## ✨ Key Features

- **Listing Creation & Management**: Users can create detailed listings for services they offer, edit them, and manage them from their profile.
- **Search & Filtering**: Find services based on categories, keywords, and geographic location.
- **User Profiles**: Each user has a comprehensive profile with contact information, skills, and published listings.
- **Integrated Chat**: Secure communication with other users directly within the app to discuss details and arrangements.
- **Registration & Authentication**: Easy and secure access via email/password and Google accounts.
- **User Support**: Dedicated section for receiving support and assistance.

---

## 🛠️ Technology Stack & Architecture

### Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) - Cross-platform development with a single codebase for Android, iOS, Web, and Desktop.
- **Language**: [Dart](https://dart.dev/)
- **Backend & Database**: [Firebase](https://firebase.google.com/)
  - **Firestore**: NoSQL database for managing listings, chats, and user data.
  - **Firebase Authentication**: User authentication (Email/Password, Google Sign-In).
  - **Firebase Storage**: Image storage for profiles and listings.
- **External APIs**:
  - **Google Places API**: Address search and autocomplete during registration and listing creation.
- **State Management**: [Provider / BLoC / Riverpod / GetX] - *Specify the actual library used in the project.*

### Architecture

- **Cross-Platform**: The project architecture is based on Flutter, ensuring the application can be natively compiled for multiple platforms from a single codebase.
- **Feature-Based Modular Structure**: Source code in the `lib/` directory is organized by features (e.g., `chat`, `serviceAdv`, `signInUp`), promoting code maintainability and scalability.
- **Component-Based UI**: The user interface is built using a system of reusable widgets (`customWidgets`), following Flutter's design principles.
- **Backend as a Service (BaaS)**: The application heavily relies on Firebase services, reducing the need for a custom backend. Core business logic resides in the client app, which communicates directly with Firebase APIs.
- **Services Layer**: Logic for interacting with external services (like Firestore) is abstracted into service classes (e.g., `FirestoreService.dart`), separating business logic from direct data manipulation.

---

## 🚀 Getting Started

To get a local copy of the project up and running, follow these simple steps.

### Prerequisites

Make sure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A code editor such as [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)
- A [Firebase](https://firebase.google.com/) account

### Installation

1. **Clone the repository**
   ```sh
   git clone https://github.com/your-username/Troova.git
   ```
2. **Navigate to the project directory**
   ```sh
   cd Troova
   ```
3. **Configure Firebase**
   - Create a new project in the [Firebase Console](https://console.firebase.google.com/).
   - Add an Android and/or iOS app to your Firebase project.
   - **For Android**: Download the `google-services.json` file and place it in `android/app/`.
   - **For iOS**: Download the `GoogleService-Info.plist` file and configure it in your Xcode project.
   - Enable the necessary services such as **Firestore Database** and **Authentication** (with Google and Email/Password providers).

4. **Install Dart dependencies**
   ```sh
   flutter pub get
   ```

5. **Run the application**
   ```sh
   flutter run
   ```

---

## 🔧 Configuration

The project may require specific API keys or environment configurations.
- An `.env` file is located in the `assets/` folder. Make sure to populate it with the necessary environment variables, such as the Google Places API key.
  ```
  GOOGLE_MAPS_API_KEY=YOUR_API_KEY
  ```
- The `assets/firebase_service_account.json` file is used for admin access to the backend. **DO NOT INCLUDE THIS FILE IN PUBLIC REPOSITORIES**. It must be generated from your Firebase project and handled securely.

---

## 🤝 Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the [MIT / Apache 2.0 / etc.] License. See `LICENSE` for more information.