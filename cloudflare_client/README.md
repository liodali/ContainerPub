# Cloudflare DNS Client

A Dart client library for managing Cloudflare DNS records via the Cloudflare API.

## Features

- ✅ Create A and CNAME records
- ✅ List, get, update, and delete DNS records
- ✅ Check subdomain existence
- ✅ Helper methods for user-specific subdomains
- ✅ Full error handling with custom exceptions
- ✅ Support for Cloudflare proxy settings

## Installation

```bash
cd cloudflare_client
dart pub get
```

## Configuration

1. Create a `.env` file:

```bash
cp .env.example .env
```

2. Add your Cloudflare credentials:

```env
CLOUDFLARE_API_TOKEN=your-api-token
CLOUDFLARE_ZONE_ID=your-zone-id
```

## Usage

### Basic Example

```dart
import 'package:cloudflare_client/cloudflare_client.dart';

void main() async {
  final client = CloudflareClient(
    apiToken: 'your-api-token',
    zoneId: 'your-zone-id',
  );

  // Create an A record
  final record = await client.createARecord(
    name: 'api',
    ipAddress: '192.0.2.1',
    proxied: true,
  );

  print('Created: ${record['name']} → ${record['content']}');
}
```

### Run Example

```bash
dart run bin/example.dart
```

## API Reference

See the source code in `lib/cloudflare_client.dart` for full API documentation.
