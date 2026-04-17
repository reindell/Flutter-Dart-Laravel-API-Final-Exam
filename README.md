# finalalmazan

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# Smart Order Management System 🍕

A professional, high-performance food ordering application featuring a minimalist glossy blue theme. This system integrates a **Flutter** mobile frontend with a **Laravel (PHP)** REST API backend for real-time order processing and user management.

## ✨ Features
- **Glossy Minimalist UI:** Premium professional blue theme with refined transitions and elevation.
- **Secure Authentication:** Complete Login and Registration system.
- **Dynamic Menu Listing:** Real-time food fetching with individual item quantity tracking.
- **Smart Cart Management:** Built using **Provider** for persistent state management; supports adding, removing, and adjusting item counts.
- **Profile Dashboard:** View and update user contact details directly within the app.
- **Order Processing:** Automated total calculations and direct integration with the Laravel database.

## 🛠️ Tech Stack
- **Frontend:** Flutter (Dart)
- **State Management:** Provider
- **Backend:** Laravel (PHP)
- **Database:** MySQL
- **Architecture:** RESTful API

---

## 🚀 Getting Started

Follow these steps to get the development environment running on your local machine.

### 1. Prerequisites
- **Flutter SDK:** [Install Flutter](https://docs.flutter.dev/get-started/install)
- **PHP & MySQL:** (XAMPP, Laragon, or Local PHP/MySQL installation)
- **Composer:** [Install Composer](https://getcomposer.org/)

### 2. Backend Setup (Laravel)
1. Navigate to your backend directory:
   ```bash
   cd your-backend-folder
Install dependencies:

Bash
composer install
Configure your environment:

Bash
cp .env.example .env
Edit the .env file to set your DB_DATABASE, DB_USERNAME, and DB_PASSWORD.

Initialize the database:

Bash
php artisan key:generate
php artisan migrate
Start the server:

Bash
php artisan serve --host=0.0.0.0
(Using --host=0.0.0.0 ensures your mobile device/emulator can connect via your local network).

3. Frontend Setup (Flutter)
Navigate to the Flutter project directory:

Bash
cd your-flutter-folder
Fetch required packages:

Bash
flutter pub get
Configure API Connection:
Open lib/main.dart (or your Provider file) and update the baseUrl to match your PC's local IP address:

Dart
final String baseUrl = "[http://192.168.1.](http://192.168.1.)XX:8000/api";
Run the app:

Bash
flutter run
📁 Project Structure
lib/ : Contains the Flutter UI screens, custom glossy widgets, and Provider state logic.

app/Http/Controllers/ : (Backend) Handles API logic for order storage and user authentication.

routes/api.php : (Backend) Defines the endpoints used by the Flutter application.

👤 Author
Reindell M. Almazan - 

---

### How to add this to your GitHub now:
If you are using the terminal in VS Code or Android Studio, run these commands to update your repo with the new README:

1.  **Create/Open the file:** `README.md` in your project folder.
2.  **Paste** the content above and save.
3.  **Run these commands:**
    ```bash
    git add README.md
    git commit -m "docs: add professional README with setup instructions"
    git push origin main
    ```
