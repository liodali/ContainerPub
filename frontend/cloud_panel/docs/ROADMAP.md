# Roadmap

## Immediate Next Steps (Priority: High)

### 1. Function Documentation & Details
- [ ] **Function Details Page**: 
  - Implement a dedicated subpage (`/functions/:id`) showing:
    - Invocation URL and usage examples (curl, JS, Dart).
    - Deployment history list.
    - Environment variables management.
    - Logs viewer (websocket or polling).
- [ ] **Documentation UI**:
  - Add a "How to connect" section within the function details.
  - Display code snippets for the `cloud_api_client` usage.

### 2. Backend Integration
- [ ] **Verify Endpoints**: Ensure backend supports:
  - `GET /functions/:id/stats` (Invocations, Errors, Latency).
  - `GET /functions/:id/logs` (Runtime logs).
- [ ] **Error Handling**: Improve UI for 404s and 500s on detail pages.

## Medium Term (Priority: Medium)

### 1. Functionality
- [ ] **Webhooks**: Implement Create/List/Delete for Webhooks.
- [ ] **Containers**: Implement Create/List/Delete for Container Deployments.
- [ ] **Settings**: User profile management and API Key generation.

### 2. Authentication Enhancements
- [ ] **Social Login**:
  - **Google OAuth**: Integrate `google_sign_in` package.
  - **GitHub OAuth**: Implement OAuth2 flow for GitHub.
  - **UI**: Add "Sign in with Google" and "Sign in with GitHub" buttons to Login Page.

## Future Enhancements (Priority: Low)

### 1. UX/UI
- [ ] **Responsive Design**: 
  - Adapt sidebar to a drawer for mobile screens.
  - optimize data tables for smaller viewports.
- [ ] **Dark Mode**: Fully support system theme switching.

### 2. DevOps
- [ ] **CI/CD**: Setup GitHub Actions for building and testing the web app.
- [ ] **Docker**: Create a `Dockerfile` for serving the Flutter Web build via Nginx.
