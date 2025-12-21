# Current Implementation Status

## Overview
**ContainerPub Cloud Panel** is a Flutter-based dashboard for managing serverless functions, containers, and webhooks.

**Phase**: Alpha  
**Last Updated**: 2025-12-21  
**Owner**: Frontend Lead

## Completed Features

### 1. Authentication & Security
- **Login Flow**: 
  - Email/Password authentication using `CloudApiClient`.
  - Token-based session management (Access + Refresh Tokens).
  - Secure token storage using `Hive` (encrypted box capability ready).
- **Route Protection**:
  - `AuthGuard` implementation protecting `/dashboard` and sub-routes.
  - Automatic redirection to `/login` for unauthenticated access.
  - Synchronous auth state check to prevent UI flickering.
- **Session Management**:
  - `TokenAuthInterceptor` handles 401 errors automatically.
  - Automatic token refresh logic.
  - Automatic logout and redirect on refresh failure.
  - `onLogout` callback integration for seamless UI updates.

### 2. Dashboard Architecture
- **Layout**: 
  - Responsive Sidebar navigation.
  - Tab-based routing using `AutoTabsRouter` for persistent state between views.
- **Views**:
  - **Overview**: Global overview stats cards implemented.
  - **Functions**: List view of deployed functions.
    - Fetching data via `FunctionsProvider`.
    - Empty state handling with "Create Function" CTA.
    - "Create Function" dialog implementation.
  - **Containers**: Placeholder view.
  - **Webhooks**: Placeholder view.
  - **Settings**: Placeholder view.

### 3. Core Infrastructure
- **Routing**: `auto_route` setup with manual route definitions (no generator dependency for simple updates).
- **State Management**: `flutter_riverpod` for dependency injection and state management.
- **UI Library**: `forui` for consistent, modern UI components.
- **Networking**: Custom `cloud_api_client` package wrapping `Dio` with interceptors.

### 4. Testing
- **Unit Tests**:
  - `AuthGuard` verification (Allow/Block/Redirect).
  - `CloudApiClient` comprehensive suite (25 tests covering all methods and interceptors).
  - Mocking strategy using `http_mock_adapter`.

### 5. Function Details (Implemented)
- **Overview Tab**:
  - Per-function stats cards and charts implemented in `lib/ui/widgets/overview_function_tab.dart`.
- **Deployments Tab**:
  - Active deployment and rollback implemented in `lib/ui/widgets/deployments_tab.dart`.
- **API Keys Tab**:
  - Key generation (secret shown once), listing, and optional secure local storage in `lib/ui/widgets/api_keys_tab.dart`.
- **Invoke Tab**:
  - JSON body input, signed/unsigned toggle, response display in `lib/ui/widgets/invoke_tab.dart`.

## Technical Specifications of Components

### Frontend (`cloud_panel`)
- **Framework**: Flutter (Dart)
- **Key Libraries**:
  - `flutter_riverpod`: State management.
  - `auto_route`: Navigation.
  - `forui`: UI Component library.
  - `hive_ce`: Local storage.
  - `dio`: HTTP client.

### Client SDK (`cloud_api_client`)
- **Architecture**: Repository pattern with segregated services (`AuthService`, `TokenService`).
- **Interceptors**: 
  - `TokenAuthInterceptor`: Manages Authorization headers and Refresh Token loop.
- **Models**: Serializable Dart classes for `User`, `Function`, `Deployment`, `ApiKey`.

## In Progress / Planned

### 1. Registration UI
- UI page is missing; backend client supports registration (`POST /api/auth/register`).
- Login page has Google/GitHub buttons but they are currently no-op.

### 2. Editor Integration
- No code editor UI exists yet.
- Requires new backend endpoints described in `docs/API_REQUIREMENTS.md`.

### 3. “Create Empty” Function Flow Improvements
- Current create flow only posts `{ name }` to `POST /api/functions/init`.

## Known Limitations
1. **Mock Data**: The application currently relies on local mocks or a local backend (`http://127.0.0.1:8080`) which may not be running.
2. **Registration**: Users cannot sign up via the UI yet.
3. **Editor**: No in-browser editor exists yet.
4. **Invoke UX**: No API key dropdown; users paste secret keys manually.
5. **Error Handling**: Mixed use of Material snackbars/toasts; needs consolidation with `forui` patterns.
6. **Responsive Design**: Optimized for Desktop/Web; mobile layout needs refinement.

## Documentation Verification Notes

This status reflects a codebase cross-reference review (static). Feature validation testing has not been executed in this update cycle.

## Changelog (Unreleased)

- Added function-level stats cards and charts (hourly/daily) in function details overview.
- Added deployments tab with active deployment and rollback flow.
- Added API keys tab with generation flow and optional local storage.
- Added invoke tab with signed/unsigned request support.
