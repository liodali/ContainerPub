# API Requirements

**Last Updated**: 2025-12-21  
**Owner**: Backend + Frontend Leads

This document is the source of truth for API contracts used by the Flutter web panel. Contracts below are cross-referenced against:

- Client: `packages/cloud_api_client/lib/src/cloud_api_client_base.dart`
- Models: `packages/cloud_api_client/lib/src/models/*`
- UI usage: `lib/ui/*` and `lib/providers/*`

## Error Handling Contract (Client Behavior)

The API client maps server failures as follows (see `_handleRequest` in `packages/cloud_api_client/lib/src/cloud_api_client_base.dart`):

- `401` → throws `AuthException`
- `404` → throws `NotFoundException`
- other → throws `CloudApiException(statusCode, data)`
- message source: `response.data['error']` (preferred) or `DioException.message`

## Implementation Status (as used by current UI)

### Authentication

| Endpoint              | Used in UI | Notes |
| --------------------- | ---------- | ----- |
| `POST /api/auth/login`    | ✅ Yes | Login flow |
| `POST /api/auth/refresh`  | ✅ Yes | Token refresh used by interceptor |
| `POST /api/auth/register` | ❌ No  | Client supports, UI missing |

### Functions (Core)

| Endpoint                         | Used in UI | Notes |
| -------------------------------- | ---------- | ----- |
| `GET /api/functions`            | ✅ Yes | Functions list |
| `POST /api/functions/init`      | ✅ Yes | Create “empty” function (name only) |
| `GET /api/functions/:uuid`      | ✅ Yes | Function details |
| `DELETE /api/functions/:uuid/delete` | ❌ No | API client supports; no UI action yet |
| `POST /api/functions/:uuid/invoke`   | ✅ Yes | Invoke tool |

### Deployments

| Endpoint                         | Used in UI | Notes |
| -------------------------------- | ---------- | ----- |
| `GET /api/functions/:uuid/deployments` | ✅ Yes | Deployments tab |
| `POST /api/functions/:uuid/rollback`   | ✅ Yes | Rollback flow |

### API Keys

| Endpoint                               | Used in UI | Notes |
| -------------------------------------- | ---------- | ----- |
| `GET /api/apikey/:functionUuid/list` | ✅ Yes | List keys |
| `POST /api/apikey/generate`          | ✅ Yes | Generate key |
| `DELETE /api/apikey/:apiKeyUuid/revoke` | ✅ Yes | Revoke key |
| `DELETE /api/apikey/:apiKeyUuid`        | ✅ Yes  | Client supports; UI may add later |
| `PUT /api/apikey/:apiKeyUuid/roll`      | ✅ Yes  | Client supports; UI may add later |
| `PUT /api/apikey/:apiKeyUuid/enable`    | ✅ Yes | Client supports; UI may add later |

### Statistics

| Endpoint                                | Used in UI | Notes |
| --------------------------------------- | ---------- | ----- |
| `GET /api/stats/overview?period=...`    | ✅ Yes | `lib/ui/views/overview_view.dart` uses `period=30d` |
| `GET /api/functions/:uuid/stats`        | ✅ Yes | Per-function stat cards |
| `GET /api/functions/:uuid/stats/hourly?hours=...` | ✅ Yes | Per-function chart |
| `GET /api/functions/:uuid/stats/daily?days=...`   | ✅ Yes | Per-function chart |
| `GET /api/stats/overview/hourly`        | ❌ No | Not wired in UI (planned) |
| `GET /api/stats/overview/daily`         | ❌ No | Not wired in UI (planned) |

## Endpoint Contracts

### 1) `POST /api/auth/login`

**Request**
```json
{ "email": "user@example.com", "password": "..." }
```

**Response (expected by client)**
```json
{ "accessToken": "…", "refreshToken": "…" }
```

### 1b) `POST /api/auth/refresh`

**Request**
```json
{ "refreshToken": "…" }
```

**Response (expected by client)**
```json
{ "accessToken": "…", "refreshToken": "…" }
```

### 2) `POST /api/auth/register` (UI planned)

**Request**
```json
{ "email": "user@example.com", "password": "..." }
```

**Response**
- `200/201` success (body can be empty; UI will redirect to login)
- `4xx` should return `{"error":"..."}` for user-friendly message

### 3) `POST /api/functions/init`

**Request**
```json
{ "name": "my-function" }
```

**Response** (client supports both wrapped and unwrapped)
```json
{ "function": { "uuid": "...", "name": "my-function", "status": "active", "createdAt": "2025-12-21T00:00:00.000Z" } }
```

### 4) `GET /api/functions/:uuid/stats`

**Response format** (aligned with `FunctionStats.fromJson` in `packages/cloud_api_client/lib/src/models/stats.dart`)
```json
{
  "stats": {
    "invocations_count": 1250,
    "errors": 5,
    "error_rate": 0.004,
    "avg_latency": 120,
    "last_invocation": "2025-12-21T10:00:00Z",
    "min_latency": 30,
    "max_latency": 900
  }
}
```

### 5) `GET /api/functions/:uuid/stats/hourly?hours=24`

**Response format** (aligned with `HourlyStatsResponse.fromJson`)
```json
{
  "data": [
    {
      "hour": "2025-12-21T10:00:00Z",
      "total_requests": 50,
      "success_count": 48,
      "error_count": 2,
      "average_latency_ms": 120
    }
  ],
  "hours": 24
}
```

### 6) `GET /api/functions/:uuid/stats/daily?days=7`

**Response format** (aligned with `DailyStatsResponse.fromJson`)
```json
{
  "data": [
    {
      "day": "2025-12-21T00:00:00Z",
      "total_requests": 500,
      "success_count": 495,
      "error_count": 5,
      "average_latency_ms": 115
    }
  ],
  "days": 7
}
```

### 7) `POST /api/functions/:uuid/rollback`

**Request**
```json
{ "deployment_uuid": "dep-uuid" }
```

**Response**
- `200` success (UI shows toast)
- on failure return `{"error":"..."}` for user-visible message

### 8) `GET /api/auth/apikey/:functionUuid/list`

**Response** (client expects `api_keys`)
```json
{
  "api_keys": [
    {
      "uuid": "key-uuid",
      "validity": "30d",
      "expires_at": "2026-01-20T00:00:00Z",
      "is_active": true,
      "name": "prod-key",
      "created_at": "2025-12-21T00:00:00Z"
    }
  ]
}
```

### 9) `POST /api/auth/apikey/generate`

**Request**
```json
{ "function_id": "functionUuid", "validity": "forever", "name": "my-key" }
```

**Response** (UI uses `api_key.secret_key`)
```json
{
  "api_key": {
    "uuid": "key-uuid",
    "secret_key": "secret",
    "validity": "forever",
    "expires_at": null,
    "is_active": true,
    "name": "my-key",
    "created_at": "2025-12-21T00:00:00Z"
  }
}
```

## Planned Endpoints (Editor Integration)

### 10) `GET /api/functions/:uuid/code`

**Response**
```json
{ "runtime": "node-18", "entry_point": "index.js", "source_code": "..." }
```

### 11) `PUT /api/functions/:uuid/code`

**Request**
```json
{ "runtime": "node-18", "entry_point": "index.js", "source_code": "..." }
```

**Response**
- `200` success (ideally returns new deployment uuid/version)

## Mock Data Specifications

For unit tests and local development without a backend, the current repo uses:

- `packages/cloud_api_client/test/mocks.dart`: `FakeTokenService`
- `http_mock_adapter` in `packages/cloud_api_client/test/unit/*` to mock HTTP calls

Example mock payload for function stats (use in adapter replies as needed):
```dart
final mockFunctionStats = {
  "invocations_count": 42,
  "errors": 1,
  "error_rate": 1 / 42,
  "avg_latency": 45,
  "last_invocation": DateTime.now().toUtc().toIso8601String(),
  "min_latency": 12,
  "max_latency": 120,
};
```
