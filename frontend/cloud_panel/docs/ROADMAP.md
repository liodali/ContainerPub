# Roadmap

## Immediate Next Steps (Priority: High)

### 1. Function Details Page - Overview Tab

- [ ] **Stats Display**: Show function statistics:
  - Total invocations count
  - Error count and error rate
  - Average latency
  - Last invocation timestamp
- [ ] **Deployment Management**:
  - List all deployments with active indicator
  - Show current active deployment
  - Switch between deployments (call rollback API)
  - Display deployment version and status

### 2. Function Details Page - API Keys Tab

- [ ] **API Key Management**:
  - List all API keys for the function
  - Show key prefix, validity, expiration date
  - Display active/inactive status
  - Revoke/delete API keys
  - Generate new API key with dialog showing secret key
  - Copy secret key to clipboard

### 3. Function Details Page - Invoke Tab

- [ ] **HTTP Client for Function Invocation**:
  - Request body editor (JSON)
  - API key selection dropdown (from function's API keys)
  - Default to signed request (--sign) with selected key
  - Option to invoke without signature
  - Response display with syntax highlighting
  - Error handling and display

### 4. Backend Integration

- [ ] **Verify Endpoints**: Ensure backend supports:
  - `GET /functions/:uuid/stats` (Invocations, Errors, Latency).
  - `GET /functions/:uuid/logs` (Runtime logs).
  - `POST /functions/:uuid/rollback` (Switch deployments).
  - `GET /functions/:uuid/deployments` (List with active indicator).
  - `GET /functions/:uuid/apikeys` (List API keys).
  - `POST /functions/:uuid/apikeys/generate` (Generate new key).
  - `DELETE /functions/:uuid/apikeys/:keyId` (Revoke key).
  - `POST /functions/:uuid/invoke` (Invoke with signature).
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
