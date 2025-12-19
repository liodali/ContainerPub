# Function Details Page - Implementation Tracking

**Status**: In Progress  
**Last Updated**: December 18, 2025  
**Target Completion**: December 20, 2025

## Overview

This document tracks the implementation of missing features in the Function Details Page (`function_details_page.dart`). The page has 4 tabs: Overview, Deployments, API Keys, and Invoke.

## Architecture

### Current State

**File**: `lib/ui/pages/function_details_page.dart`

- ✅ Overview Tab: Basic placeholder (needs enhancement)
- ✅ Deployments Tab: Lists deployments with rollback button
- ✅ API Keys Tab: Lists keys with revoke button, generate new key dialog
- ✅ Invoke Tab: HTTP client with body and secret key input

**Providers**: `lib/providers/function_details_provider.dart`

- ✅ `functionDetailsProvider` - Get function details
- ✅ `functionDeploymentsProvider` - Get deployments list
- ✅ `functionApiKeysProvider` - Get API keys list
- ❌ `functionStatsProvider` - **MISSING** - Get function statistics

**API Client**: `packages/cloud_api_client/lib/src/cloud_api_client.dart`

- ✅ `listApiKeys()` - List API keys
- ✅ `generateApiKey()` - Generate new API key
- ✅ `revokeApiKey()` - Revoke API key
- ✅ `getDeployments()` - Get deployments
- ✅ `rollbackFunction()` - Rollback to deployment
- ✅ `invokeFunction()` - Invoke function with optional signature
- ❌ `getStats()` - **MISSING** - Get function statistics

**Models**: `packages/cloud_api_client/lib/src/models/`

- ✅ `CloudFunction` - Function metadata
- ✅ `FunctionDeployment` - Deployment info
- ✅ `ApiKey` - API key info
- ❌ `FunctionStats` - **MISSING** - Function statistics model

## Implementation Tasks

### Phase 1: Backend Models & API Client (cloud_api_client package)

#### Task 1.1: Create FunctionStats Model

**File**: `packages/cloud_api_client/lib/src/models/stats.dart` (NEW)

**Requirements**:

- Total invocations count
- Error count
- Error rate (percentage)
- Average latency (ms)
- Last invocation timestamp
- Min/max latency

**Status**: ⏳ Pending

#### Task 1.2: Add getStats() Method to CloudApiClient

**File**: `packages/cloud_api_client/lib/src/cloud_api_client.dart`

**Requirements**:

- Endpoint: `GET /api/functions/:uuid/stats`
- Returns: `FunctionStats`
- Error handling for 404/500

**Status**: ⏳ Pending

#### Task 1.3: Export FunctionStats from models.dart

**File**: `packages/cloud_api_client/lib/src/models/models.dart`

**Status**: ⏳ Pending

### Phase 2: Frontend Providers (cloud_panel)

#### Task 2.1: Add functionStatsProvider

**File**: `lib/providers/function_details_provider.dart`

**Requirements**:

- FutureProvider.family for stats by function UUID
- Auto-dispose pattern
- Refresh capability

**Status**: ⏳ Pending

### Phase 3: UI Implementation (cloud_panel)

#### Task 3.1: Enhance Overview Tab

**File**: `lib/ui/pages/function_details_page.dart` - `_OverviewTab` class

**Requirements**:

- Display stats cards:
  - Total Invocations
  - Error Count & Rate
  - Average Latency
  - Last Invocation
- Show active deployment info
- Deployment switching UI (dropdown or list)
- Rollback on selection

**Status**: ⏳ Pending

#### Task 3.2: Enhance Deployments Tab

**File**: `lib/ui/pages/function_details_page.dart` - `_DeploymentsTab` class

**Requirements**:

- Add active deployment indicator (badge/highlight)
- Show deployment status more clearly
- Improve rollback button styling
- Add deployment details (version, status, created date)

**Status**: ⏳ Pending

#### Task 3.3: Enhance API Keys Tab

**File**: `lib/ui/pages/function_details_page.dart` - `_ApiKeysTab` class

**Requirements**:

- ✅ Already implemented: List keys, generate new, revoke
- Improve key display:
  - Show full UUID prefix (8 chars)
  - Display validity period
  - Show expiration date if applicable
  - Active/inactive status badge
- Add delete confirmation dialog
- Better error handling

**Status**: ✅ Mostly Complete (minor enhancements)

#### Task 3.4: Enhance Invoke Tab

**File**: `lib/ui/pages/function_details_page.dart` - `_InvokeTab` class

**Requirements**:

- ✅ Already implemented: Body editor, secret key input, invoke button
- Add API key selection dropdown:
  - Load available API keys
  - Select key for signing
  - Show key name/prefix
- Toggle for signed vs unsigned requests
- Improve response display:
  - Syntax highlighting for JSON
  - Copy response button
  - Better error display
- Request history (optional)

**Status**: ⏳ Pending (API key dropdown)

## API Endpoints Required

### Backend Verification Checklist

- [ ] `GET /api/functions/:uuid/stats` - Returns function statistics

  - Response: `{ "stats": { "invocations": 0, "errors": 0, "error_rate": 0.0, "avg_latency": 0, "last_invocation": null, "min_latency": 0, "max_latency": 0 } }`

- [ ] `GET /api/functions/:uuid/deployments` - List deployments with active indicator

  - Response: `{ "deployments": [...], "active_deployment_uuid": "..." }`

- [ ] `POST /api/functions/:uuid/rollback` - Switch to deployment

  - Request: `{ "deployment_uuid": "..." }`

- [ ] `GET /api/auth/apikey/:uuid/list` - List API keys

  - ✅ Already working

- [ ] `POST /api/auth/apikey/generate` - Generate new API key

  - ✅ Already working

- [ ] `DELETE /api/auth/apikey/:keyId` - Revoke API key

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
