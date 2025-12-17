# API Requirements

To support the planned "Function Overview" and "Details" features, the backend API must expose the following endpoints and data structures.

## Implementation Status

### User Overview Statistics (Dashboard)

| Endpoint                         | Status         | Notes                                     |
| -------------------------------- | -------------- | ----------------------------------------- |
| `GET /api/stats/overview`        | ✅ Implemented | Aggregated stats for all user's functions |
| `GET /api/stats/overview/hourly` | ✅ Implemented | Hourly chart data for all functions       |
| `GET /api/stats/overview/daily`  | ✅ Implemented | Daily chart data for all functions        |

### Per-Function Statistics

| Endpoint                                | Status         | Notes                         |
| --------------------------------------- | -------------- | ----------------------------- |
| `GET /api/functions/:uuid/stats`        | ✅ Implemented | Statistics with period filter |
| `GET /api/functions/:uuid/stats/hourly` | ✅ Implemented | Hourly chart data             |
| `GET /api/functions/:uuid/stats/daily`  | ✅ Implemented | Daily chart data              |
| `GET /api/functions/:uuid/logs`         | ✅ Exists      | Already in FunctionHandler    |
| `GET /api/functions/:uuid/deployments`  | ✅ Exists      | Already in FunctionHandler    |

---

## Implemented Endpoints

### 0. User Overview Statistics (Dashboard) ✅

These endpoints provide aggregated statistics across **all functions** owned by the authenticated user. Ideal for dashboard overview cards and charts.

#### 0.1 Overview Stats

**Endpoint**: `GET /api/stats/overview`  
**Purpose**: Display aggregated metrics for all user's functions on the dashboard.  
**Query Params**: `?period=24h` (options: `1h`, `24h`, `7d`, `30d`)

**Response Format**:

```json
{
  "total_functions": 5,
  "invocations_count": 1250,
  "success_count": 1245,
  "error_count": 5,
  "average_latency_ms": 120,
  "period": "24h"
}
```

#### 0.2 Overview Hourly Stats (Chart Data)

**Endpoint**: `GET /api/stats/overview/hourly`  
**Purpose**: Hourly breakdown for all functions (for charts).  
**Query Params**: `?hours=24` (default: 24, max: 168)

**Response Format**:

```json
{
  "data": [
    {
      "hour": "2024-01-15T10:00:00Z",
      "total_requests": 150,
      "success_count": 148,
      "error_count": 2,
      "average_latency_ms": 120
    }
  ],
  "hours": 24
}
```

#### 0.3 Overview Daily Stats (Chart Data)

**Endpoint**: `GET /api/stats/overview/daily`  
**Purpose**: Daily breakdown for all functions (for charts).  
**Query Params**: `?days=30` (default: 30, max: 90)

**Response Format**:

```json
{
  "data": [
    {
      "day": "2024-01-15T00:00:00Z",
      "total_requests": 1500,
      "success_count": 1495,
      "error_count": 5,
      "average_latency_ms": 115
    }
  ],
  "days": 30
}
```

---

### 1. Per-Function Statistics ✅

**Endpoint**: `GET /api/functions/:uuid/stats`  
**Purpose**: Display metrics for a specific function.  
**Query Params**: `?period=24h` (options: `1h`, `24h`, `7d`, `30d`)

**Response Format**:

```json
{
  "invocations_count": 1250,
  "success_count": 1245,
  "error_count": 5,
  "average_latency_ms": 120,
  "period": "24h"
}
```

### 1.1 Hourly Statistics (Chart Data) ✅

**Endpoint**: `GET /api/functions/:uuid/stats/hourly`  
**Purpose**: Provide hourly breakdown for chart visualization.  
**Query Params**: `?hours=24` (default: 24, max: 168)

**Response Format**:

```json
{
  "data": [
    {
      "hour": "2024-01-15T10:00:00Z",
      "total_requests": 50,
      "success_count": 48,
      "error_count": 2,
      "average_latency_ms": 120
    }
  ],
  "hours": 24
}
```

### 1.2 Daily Statistics (Chart Data) ✅

**Endpoint**: `GET /api/functions/:uuid/stats/daily`  
**Purpose**: Provide daily breakdown for chart visualization.  
**Query Params**: `?days=30` (default: 30, max: 90)

**Response Format**:

```json
{
  "data": [
    {
      "day": "2024-01-15T00:00:00Z",
      "total_requests": 500,
      "success_count": 495,
      "error_count": 5,
      "average_latency_ms": 115
    }
  ],
  "days": 30
}
```

---

## Existing Endpoints (Already Available)

### 2. Function Logs ✅

**Endpoint**: `GET /api/functions/:uuid/logs`  
**Purpose**: Show runtime logs for debugging.  
**Query Params**: `?limit=100&start_time=...`

**Response Format**:

```json
[
  {
    "timestamp": "2023-10-27T10:00:00Z",
    "level": "INFO",
    "message": "Function started processing request",
    "deployment_id": "dep-123"
  }
]
```

### 3. Deployment History ✅

**Endpoint**: `GET /api/functions/:uuid/deployments`  
**Purpose**: List past versions of the function.

**Response Format**:

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

---

## Future Enhancements (Next Stage)

The following features are planned for future implementation:

### Phase 2: Enhanced Monitoring

- [ ] Real-time WebSocket updates for live stats
- [ ] Alert thresholds and notifications
- [ ] Custom metric aggregations

### Phase 3: Advanced Analytics

- [ ] Cost estimation per function
- [ ] Performance comparison across versions
- [ ] Geographic distribution of requests

---

## Mock Data Specifications

For frontend development before backend readiness, use the following mock objects in `cloud_api_client/test/mocks.dart`:

**Mock Function Stats**:

```dart
final mockStats = {
  "invocations_count": 42,
  "success_count": 42,
  "error_count": 0,
  "average_latency_ms": 45,
  "period": "24h"
};
```

**Mock Hourly Stats**:

```dart
final mockHourlyStats = {
  "data": [
    {
      "hour": DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
      "total_requests": 10,
      "success_count": 10,
      "error_count": 0,
      "average_latency_ms": 45
    }
  ],
  "hours": 24
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
