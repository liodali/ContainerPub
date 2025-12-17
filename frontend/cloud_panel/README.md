# ContainerPub Cloud Panel

A modern, Flutter-based dashboard for managing the ContainerPub serverless platform.

## 🚀 Project Status
**Status**: Alpha  
**Current Version**: 0.1.0  
**Focus**: Core Infrastructure, Authentication, Function Management.

See detailed status in [docs/STATUS.md](docs/STATUS.md).

## 📚 Documentation
- [Implementation Status](docs/STATUS.md) - What's built and what's missing.
- [Roadmap](docs/ROADMAP.md) - Next steps and future plans.
- [Technical Specifications](docs/TECHNICAL_SPECS.md) - Tech stack and architecture.
- [API Requirements](docs/API_REQUIREMENTS.md) - Backend needs.

## ✨ Key Features
- **Secure Authentication**: JWT-based auth with auto-refresh and secure storage.
- **Function Management**: Create, list, and manage serverless functions.
- **Dashboard**: Overview of your cloud resources (Functions, Containers, Webhooks).
- **Responsive UI**: Built with `forui` for a clean, consistent look.

## 🛠️ Environment Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10+)
- [Bun](https://bun.sh/) (for any JS tooling)
- Dart 3.x

### Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/liodali/containerpub.git
   cd cloud_panel
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run -d chrome
   ```

## 🧪 Testing
We maintain a high standard of testing for core logic.

### Running Unit Tests
```bash
# Run all tests
flutter test

# Run specific API client tests
cd packages/cloud_api_client
dart test
```

### Coverage
- **Auth Guard**: Verified to block unauthorized access.
- **API Client**: >90% coverage on methods and interceptors.

## 🤝 Contribution
1. Check the [Roadmap](docs/ROADMAP.md) for open tasks.
2. Create a feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes.
4. Push to the branch.
5. Open a Pull Request.

## 🔐 Authentication Plans
We are actively working on integrating social logins:
- **Google OAuth**: Coming in v0.2.0
- **GitHub OAuth**: Coming in v0.2.0

See [docs/ROADMAP.md](docs/ROADMAP.md) for details.
