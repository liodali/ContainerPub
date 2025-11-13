# Request Size Limits

## Overview

Function invocations have a configurable maximum request size limit to prevent resource exhaustion and ensure fair usage. By default, requests are limited to **5MB**.

## Configuration

### Environment Variable

```bash
FUNCTION_MAX_REQUEST_SIZE_MB=5
```

### Default Value

- **5 MB** (5,242,880 bytes)

### Valid Range

- Minimum: 1 MB
- Maximum: Depends on your infrastructure (recommended max: 10 MB)

## How It Works

When a function is invoked via `POST /api/functions/{id}/invoke`, the backend:

1. Reads the request body as a string
2. Calculates the size in bytes
3. Compares against the configured limit
4. Returns HTTP 413 (Payload Too Large) if exceeded
5. Proceeds with execution if within limit

## Error Response

When request size exceeds the limit:

```json
HTTP 413 Payload Too Large

{
  "error": "Request size exceeds maximum allowed size of 5MB",
  "requestSizeMb": "6.24",
  "maxSizeMb": 5
}
```

## Example Usage

### Valid Request (Within Limit)

```bash
curl -X POST http://localhost:8080/api/functions/abc-123/invoke \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "body": {
      "data": "small payload"
    },
    "query": {}
  }'
```

Response:

```json
{
  "success": true,
  "result": {...},
  "duration_ms": 150
}
```

### Invalid Request (Exceeds Limit)

```bash
curl -X POST http://localhost:8080/api/functions/abc-123/invoke \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d @large-payload.json  # 6MB file
```

Response:

```json
HTTP 413 Payload Too Large

{
  "error": "Request size exceeds maximum allowed size of 5MB",
  "requestSizeMb": "6.00",
  "maxSizeMb": 5
}
```

## Best Practices

### 1. Keep Payloads Small

- Design functions to accept minimal input
- Use references instead of embedding large data
- Consider pagination for large datasets

### 2. Use External Storage

For large data:

- Upload to S3 first
- Pass S3 key/URL to function
- Function downloads from S3 if needed

Example:

```json
{
  "body": {
    "dataUrl": "https://s3.amazonaws.com/bucket/large-file.json",
    "action": "process"
  }
}
```

### 3. Compress Data

- Use gzip compression for text data
- Send compressed data, decompress in function
- Can reduce size by 70-90% for text

### 4. Stream Processing

For very large data:

- Break into chunks
- Process incrementally
- Use multiple function invocations

## Adjusting the Limit

### Increase Limit (Carefully)

```bash
# In .env file
FUNCTION_MAX_REQUEST_SIZE_MB=10
```

**Considerations:**

- Higher limits increase memory usage
- May impact concurrent execution capacity
- Network transfer time increases
- Consider infrastructure limits

### Decrease Limit

```bash
# In .env file
FUNCTION_MAX_REQUEST_SIZE_MB=2
```

**Use cases:**

- Enforce stricter resource usage
- Prevent abuse
- Optimize for high-concurrency scenarios

## Monitoring

### Check Request Sizes

Monitor function invocation logs to see typical request sizes:

```sql
-- View average request sizes (if logged)
SELECT
  f.name,
  AVG(LENGTH(fi.request_body)) / 1024 / 1024 as avg_size_mb
FROM function_invocations fi
JOIN functions f ON fi.function_id = f.id
GROUP BY f.name;
```

### Alert on Rejections

Set up alerts for HTTP 413 responses to detect:

- Clients sending oversized requests
- Need to adjust limits
- Potential abuse attempts

## Comparison with Other Limits

| Limit Type            | Default   | Purpose                        |
| --------------------- | --------- | ------------------------------ |
| Request Size          | 5 MB      | Prevent large payloads         |
| Execution Timeout     | 5 seconds | Prevent long-running functions |
| Memory Limit          | 128 MB    | Container memory cap           |
| Concurrent Executions | 10        | Prevent resource exhaustion    |

## Technical Details

### Size Calculation

```dart
// Size is calculated from the JSON string length
final bodyString = await request.readAsString();
final requestSizeBytes = bodyString.length;
final maxSizeBytes = Config.functionMaxRequestSizeMb * 1024 * 1024;

if (requestSizeBytes > maxSizeBytes) {
  // Return 413 error
}
```

### Why String Length?

- Measures actual bytes transmitted
- Includes JSON formatting overhead
- Accurate representation of network usage
- Simple and fast to calculate

## Troubleshooting

### "Request size exceeds maximum"

**Solutions:**

1. Reduce payload size
2. Remove unnecessary data
3. Use external storage for large data
4. Compress data before sending
5. Increase limit if justified

### Limit Not Applied

**Check:**

1. Environment variable set correctly
2. Backend restarted after config change
3. Using correct endpoint (POST /api/functions/{id}/invoke)

### Performance Impact

**Large requests (near limit):**

- Longer network transfer time
- More memory usage during parsing
- Slower JSON deserialization
- Consider optimizing payload structure

## Security Considerations

### DoS Prevention

Request size limits help prevent:

- Denial of Service attacks
- Resource exhaustion
- Memory overflow
- Network congestion

### Rate Limiting

Combine with rate limiting for better protection:

- Limit requests per minute
- Limit total data per hour
- Block repeated large requests

## Future Enhancements

Potential improvements:

1. **Per-function limits**: Different limits per function
2. **Streaming uploads**: Handle larger data via streaming
3. **Compression support**: Auto-decompress gzipped requests
4. **Multipart uploads**: Support chunked uploads
5. **Usage metrics**: Track request size patterns
