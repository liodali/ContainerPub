---
title: Statistics & Monitoring
description: Function statistics, metrics, and dashboard monitoring
---

# Statistics & Monitoring

ContainerPub provides comprehensive statistics and monitoring capabilities for tracking function performance, invocations, and health metrics across your serverless functions.

## Overview

The statistics system provides:

- **User Overview Stats** - Aggregated metrics across all user's functions
- **Per-Function Stats** - Detailed metrics for individual functions
- **Hourly Charts** - Request distribution by hour (up to 168 hours)
- **Daily Charts** - Request distribution by day (up to 90 days)
- **Real-time Metrics** - Invocation counts, success/error rates, latency

## User Overview Statistics

Get aggregated statistics for **all functions** owned by the authenticated user. Perfect for dashboard overview cards.

### GET /api/stats/overview

Display aggregated metrics for all user's functions.

**Query Parameters:**

- `period` - Time period: `1h`, `24h`, `7d`, `30d` (default: `24h`)

**Response:**

```dart
{
  "total_functions": 5,
  "invocations_count": 1250,
  "success_count": 1245,
  "error_count": 5,
  "average_latency_ms": 120,
  "period": "24h"
}
```

**Example:**

```dart
curl -H "Authorization: Bearer <token>" \
  "https://api.containerpub.com/api/stats/overview?period=24h"
```

### GET /api/stats/overview/hourly

Get hourly request distribution for all functions (for chart visualization).

**Query Parameters:**

- `hours` - Number of hours to retrieve (default: 24, max: 168)

**Response:**

```dart
{
  "data": [
    {
      "hour": "2024-01-15T10:00:00Z",
      "total_requests": 150,
      "success_count": 148,
      "error_count": 2,
      "average_latency_ms": 120
    },
    {
      "hour": "2024-01-15T11:00:00Z",
      "total_requests": 165,
      "success_count": 163,
      "error_count": 2,
      "average_latency_ms": 118
    }
  ],
  "hours": 24
}
```

**Features:**

- Automatically fills missing hours with zero values
- Sorted chronologically
- Includes success/error breakdown per hour
- Average latency for each hour

### GET /api/stats/overview/daily

Get daily request distribution for all functions (for chart visualization).

**Query Parameters:**

- `days` - Number of days to retrieve (default: 30, max: 90)

**Response:**

```dart
{
  "data": [
    {
      "day": "2024-01-15T00:00:00Z",
      "total_requests": 1500,
      "success_count": 1495,
      "error_count": 5,
      "average_latency_ms": 115
    },
    {
      "day": "2024-01-16T00:00:00Z",
      "total_requests": 1620,
      "success_count": 1615,
      "error_count": 5,
      "average_latency_ms": 117
    }
  ],
  "days": 30
}
```

**Features:**

- Automatically fills missing days with zero values
- Sorted chronologically
- Includes success/error breakdown per day
- Average latency for each day

## Per-Function Statistics

Get detailed statistics for a specific function.

### GET /api/functions/:uuid/stats

Display metrics for a specific function.

**Parameters:**

- `uuid` - Function UUID (path parameter)
- `period` - Time period: `1h`, `24h`, `7d`, `30d` (default: `24h`)

**Response:**

```dart
{
  "invocations_count": 250,
  "success_count": 248,
  "error_count": 2,
  "average_latency_ms": 125,
  "period": "24h"
}
```

### GET /api/functions/:uuid/stats/hourly

Get hourly breakdown for a specific function.

**Parameters:**

- `uuid` - Function UUID (path parameter)
- `hours` - Number of hours (default: 24, max: 168)

**Response:**

```dart
{
  "data": [
    {
      "hour": "2024-01-15T10:00:00Z",
      "total_requests": 25,
      "success_count": 24,
      "error_count": 1,
      "average_latency_ms": 125
    }
  ],
  "hours": 24
}
```

### GET /api/functions/:uuid/stats/daily

Get daily breakdown for a specific function.

**Parameters:**

- `uuid` - Function UUID (path parameter)
- `days` - Number of days (default: 30, max: 90)

**Response:**

```dart
{
  "data": [
    {
      "day": "2024-01-15T00:00:00Z",
      "total_requests": 250,
      "success_count": 248,
      "error_count": 2,
      "average_latency_ms": 125
    }
  ],
  "days": 30
}
```

## Metrics Explained

### Invocations Count

Total number of function invocations during the period.

### Success Count

Number of successful function executions (status = success).

### Error Count

Number of failed function executions (status = error or null).

### Average Latency (ms)

Average execution time in milliseconds. Calculated from `duration_ms` field of invocations.

### Period

Time period for the aggregation: `1h`, `24h`, `7d`, or `30d`.

## Data Points

Each data point in hourly/daily charts includes:

- **hour/day** - ISO 8601 timestamp (start of hour/day in UTC)
- **total_requests** - Total invocations in that period
- **success_count** - Successful invocations
- **error_count** - Failed invocations
- **average_latency_ms** - Average execution time

## Usage Examples

### Dashboard Overview

Get overall stats for the last 24 hours:

```dart
curl -H "Authorization: Bearer <token>" \
  "https://api.containerpub.com/api/stats/overview?period=24h"
```

### Weekly Trend

Get daily stats for the last 7 days:

```dart
curl -H "Authorization: Bearer <token>" \
  "https://api.containerpub.com/api/stats/overview/daily?days=7"
```

### Function Performance

Get specific function stats for the last hour:

```dart
curl -H "Authorization: Bearer <token>" \
  "https://api.containerpub.com/api/functions/{uuid}/stats?period=1h"
```

### Hourly Chart Data

Get hourly breakdown for chart visualization:

```dart
curl -H "Authorization: Bearer <token>" \
  "https://api.containerpub.com/api/stats/overview/hourly?hours=24"
```

## Implementation Details

### Data Collection

Statistics are collected automatically from the `function_invocations` table:

- Each function invocation creates a record with:
  - `function_id` - Reference to the function
  - `timestamp` - Invocation time
  - `success` - Boolean success status
  - `duration_ms` - Execution time

### Aggregation

Statistics are computed on-demand using PostgreSQL aggregation:

```dart
SELECT
  COUNT(*) as total_invocations,
  COUNT(*) FILTER (WHERE success = true) as success_count,
  COUNT(*) FILTER (WHERE success = false OR success IS NULL) as error_count,
  AVG(duration_ms) as avg_latency_ms
FROM function_invocations
WHERE function_id = $1
  AND timestamp >= NOW() - INTERVAL '24 hours'
```

### Chart Data

Hourly and daily data automatically fills missing periods with zero values to ensure continuous charts:

- **Hourly**: Fills all hours in the requested range
- **Daily**: Fills all days in the requested range

## Performance Considerations

### Query Optimization

- Indexes on `function_id` and `timestamp` for fast queries
- Aggregation queries are optimized with PostgreSQL's FILTER clause
- Results are computed on-demand (no pre-aggregation)

### Caching

For frequently accessed statistics, consider client-side caching:

```dart
// Example: Cache for 5 minutes
final stats = await _getStats();
_statsCache = stats;
_statsCacheTime = DateTime.now();
```

### Rate Limiting

Statistics endpoints are subject to standard rate limiting:

- Authenticated requests: 100 requests per minute
- Consider caching results to reduce API calls

## Error Handling

### Common Errors

**401 Unauthorized**

- Missing or invalid authentication token
- Solution: Provide valid Bearer token in Authorization header

**404 Not Found**

- Function UUID doesn't exist or doesn't belong to user
- Solution: Verify function UUID and ownership

**400 Bad Request**

- Invalid query parameters (period, hours, days out of range)
- Solution: Use valid values (1h/24h/7d/30d for period, 1-168 for hours, 1-90 for days)

**500 Internal Server Error**

- Database or server error
- Solution: Retry after a delay or contact support

## Next Steps

- Read [API Reference](./api-reference.md) for complete endpoint documentation
- Check [Function Execution](./function-execution.md) for execution details
- Review [Architecture](./architecture.md) for system design details
