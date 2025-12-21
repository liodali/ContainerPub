# Function Details Page - Implementation Tracking

**Status**: In Progress  
**Last Updated**: 2025-12-21  
**Owner**: Frontend Lead  
**Target Completion**: 2026-03-02 (see `docs/ROADMAP.md`)

## Overview

This document tracks the Function Details Page (`lib/ui/pages/function_details_page.dart`) work. The page currently has 4 tabs: Overview, Deployments, API Keys, Invoke. A 5th tab (Code Editor) is planned.

## Architecture

### Current State

**Page**: `lib/ui/pages/function_details_page.dart`

- ✅ Overview Tab: Stats cards + hourly/daily charts (`lib/ui/widgets/overview_function_tab.dart`)
- ✅ Deployments Tab: Active deployment + rollback (`lib/ui/widgets/deployments_tab.dart`)
- ✅ API Keys Tab: List + generate + optional local storage (`lib/ui/widgets/api_keys_tab.dart`)
- ✅ Invoke Tab: JSON body + signed/unsigned (`lib/ui/widgets/invoke_tab.dart`)
- ❌ Code Editor Tab: Not implemented

**Providers**: `lib/providers/function_details_provider.dart`

- ✅ `functionDetailsProvider` - Get function details
- ✅ `functionDeploymentsProvider` - Get deployments list
- ✅ `functionApiKeysProvider` - Get API keys list
- ✅ `functionStatsProvider` - Get function statistics
- ✅ `functionHourlyStatsProvider` - Hourly series
- ✅ `functionDailyStatsProvider` - Daily series

**API Client**: `packages/cloud_api_client/lib/src/cloud_api_client_base.dart`

- ✅ `listApiKeys()` - List API keys
- ✅ `generateApiKey()` - Generate new API key
- ✅ `revokeApiKey()` - Revoke API key
- ✅ `getDeployments()` - Get deployments
- ✅ `rollbackFunction()` - Rollback to deployment
- ✅ `invokeFunction()` - Invoke function with optional signature
- ✅ `getStats()` - Get function statistics
- ✅ `getHourlyStats()` / `getDailyStats()` - Time series stats

**Models**: `packages/cloud_api_client/lib/src/models/`

- ✅ `CloudFunction` - Function metadata
- ✅ `FunctionDeployment` - Deployment info
- ✅ `ApiKey` - API key info
- ✅ `FunctionStats` / `OverviewStats` - Stats models
- ✅ `HourlyStatsResponse` / `DailyStatsResponse` - Chart series models

## Implementation Tasks

### Completed Work (Verified in Code)

- ✅ Function stats model: `packages/cloud_api_client/lib/src/models/stats.dart`
- ✅ Function stats API methods: `getStats`, `getHourlyStats`, `getDailyStats` in `packages/cloud_api_client/lib/src/cloud_api_client_base.dart`
- ✅ Providers: `functionStatsProvider`, `functionHourlyStatsProvider`, `functionDailyStatsProvider` in `lib/providers/function_details_provider.dart`
- ✅ Overview tab UI: `lib/ui/widgets/overview_function_tab.dart`
- ✅ Deployments tab UI: `lib/ui/widgets/deployments_tab.dart`
- ✅ API keys tab UI: `lib/ui/widgets/api_keys_tab.dart`
- ✅ Invoke tab UI: `lib/ui/widgets/invoke_tab.dart`

### Remaining Work Items

#### R1: Code Editor Tab (Owner: FE, Depends on: BE)

- [ ] Add Code tab in `lib/ui/pages/function_details_page.dart`
- [ ] Add API client methods:
  - `GET /api/functions/:uuid/code`
  - `PUT /api/functions/:uuid/code`
- [ ] Add providers for fetching and updating code
- [ ] Implement editor UI:
  - Syntax highlighting
  - Save & Deploy
  - Loading/error/success states

#### R2: Invoke Tab Enhancements (Owner: FE)

- [ ] Add API key dropdown populated from `functionApiKeysProvider`
- [ ] Add response pretty-print toggle (JSON formatting)

#### R3: Overview Tab Quality (Owner: FE)

- [ ] Localize hard-coded strings currently in `lib/ui/widgets/overview_function_tab.dart` (e.g. chart titles and error messages)
- [ ] Add period selection (hours/days) and consistent refresh behavior

#### R4: Global Overview Stats Enhancements (Owner: FE/BE)

- [ ] Add more stats and charts to `lib/ui/views/overview_view.dart`
- [ ] Wire overview hourly/daily endpoints if backend supports them

## API Endpoints Required (Editor)

- [ ] `GET /api/functions/:uuid/code`
- [ ] `PUT /api/functions/:uuid/code`

## Test Checklist (Validation Plan)

- [ ] Overview tab: stats load, chart loads, empty-series handled
- [ ] Deployments: rollback confirmation works and refreshes list
- [ ] API keys: generate shows secret, save locally works, revoke works
- [ ] Invoke: invalid JSON error, signed invoke, unsigned invoke, copy response
- [ ] Editor (when implemented): load code, edit, save, deployment refresh

## UI Evidence (Screenshots Needed)

Screenshots must be captured from a running build and embedded here once available:

- Login page (`lib/ui/pages/login_page.dart`)
- Dashboard overview (`lib/ui/views/overview_view.dart`)
- Function details: Overview / Deployments / API Keys / Invoke tabs (`lib/ui/pages/function_details_page.dart`)

## API Endpoints Required

### Backend Verification Checklist

- [ ] `GET /api/functions/:uuid/stats` - Returns function statistics

  - Response: `{ "stats": { "invocations_count": 0, "errors": 0, "error_rate": 0.0, "avg_latency": 0, "last_invocation": null, "min_latency": 0, "max_latency": 0 } }`

- [ ] `GET /api/functions/:uuid/deployments` - List deployments with active indicator

  - Response: `{ "deployments": [...], "active_deployment_uuid": "..." }`

- [ ] `POST /api/functions/:uuid/rollback` - Switch to deployment

  - Request: `{ "deployment_uuid": "..." }`

- [ ] `GET /api/auth/apikey/:functionUuid/list` - List API keys

  - ✅ Already working

- [ ] `POST /api/auth/apikey/generate` - Generate new API key

  - ✅ Already working

- [ ] `DELETE /api/auth/apikey/:apiKeyUuid/revoke` - Revoke API key

  - ✅ Already working

- [ ] `POST /api/functions/:uuid/invoke` - Invoke with signature
  - ✅ Already working

## Dependencies

### cloud_api_client package

- `equatable: ^2.0.0` - For model equality (already in pubspec.yaml)
- `dio: ^5.0.0` - HTTP client (already in pubspec.yaml)

### cloud_panel package

- `flutter_riverpod: ^3.0.3` - State management (already in pubspec.yaml)
- `forui: ^0.16.0` - UI components (already in pubspec.yaml)

## Implementation Order

1. **Create FunctionStats model** (Task 1.1)
2. **Add getStats() to CloudApiClient** (Task 1.2)
3. **Export FunctionStats** (Task 1.3)
4. **Add functionStatsProvider** (Task 2.1)
5. **Enhance Overview Tab** (Task 3.1)
6. **Enhance Deployments Tab** (Task 3.2)
7. **Enhance API Keys Tab** (Task 3.3)
8. **Enhance Invoke Tab** (Task 3.4)

## Testing Checklist

- [ ] Stats load correctly on Overview tab
- [ ] Deployment switching works via rollback
- [ ] Active deployment is highlighted
- [ ] API key generation shows secret key
- [ ] API key revocation works
- [ ] Function invocation with signature works
- [ ] Function invocation without signature works
- [ ] API key selection in Invoke tab works
- [ ] Error handling for all operations
- [ ] Loading states display correctly
- [ ] Empty states display correctly

## Notes

- All existing functionality is preserved
- No breaking changes to existing APIs
- Backward compatible with current implementations
- Stats endpoint may need backend implementation
- Consider caching stats with appropriate TTL
- API key dropdown should load keys dynamically

## Blockers

- Backend `/api/functions/:uuid/stats` endpoint needs verification
- Backend response format for stats needs confirmation
- Active deployment indicator needs backend support
