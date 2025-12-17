# API Requirements

To support the planned "Function Overview" and "Details" features, the backend API must expose the following endpoints and data structures.

## Missing / Required Endpoints

### 1. Function Statistics
**Endpoint**: `GET /functions/:uuid/stats`  
**Purpose**: Display real-time or aggregated metrics on the dashboard.

**Required Response Format**:
```json
{
  "invocations_count": 1250,
  "error_count": 5,
  "average_latency_ms": 120,
  "period": "24h"
}
```

### 2. Function Logs
**Endpoint**: `GET /functions/:uuid/logs`  
**Purpose**: Show runtime logs for debugging.
**Query Params**: `?limit=100&start_time=...`

**Required Response Format**:
```json
[
  {
    "timestamp": "2023-10-27T10:00:00Z",
    "level": "INFO",
    "message": "Function started processing request",
    "deployment_id": "dep-123"
  },
  {
    "timestamp": "2023-10-27T10:00:01Z",
    "level": "ERROR",
    "message": "Database connection failed",
    "deployment_id": "dep-123"
  }
]
```

### 3. Deployment History
**Endpoint**: `GET /functions/:uuid/deployments`  
**Purpose**: List past versions of the function.

**Required Response Format**:
```json
[
  {
    "uuid": "dep-123",
    "tag": "v1.0.1",
    "status": "active",
    "created_at": "2023-10-27T09:00:00Z",
    "image_digest": "sha256:..."
  }
]
```

## Mock Data Specifications

For frontend development before backend readiness, use the following mock objects in `cloud_api_client/test/mocks.dart`:

**Mock Function Stats**:
```dart
final mockStats = {
  "invocations_count": 42,
  "error_count": 0,
  "average_latency_ms": 45,
  "period": "24h"
};
```

**Mock Logs**:
```dart
final mockLogs = [
  LogEntry(
    timestamp: DateTime.now(),
    level: "INFO",
    message: "Cold start initialization",
  ),
  LogEntry(
    timestamp: DateTime.now().add(Duration(milliseconds: 100)),
    level: "INFO",
    message: "Request processed successfully",
  ),
];
```
