# OpenBao API Client for Dart

A Dart client library for interacting with OpenBao (and HashiCorp Vault) servers.

## Features

- **AppRole Authentication**: Native support for AppRole login flow.
- **Token Management**: Automatic token caching and renewal using Hive.
- **Secret Management**: Read, list, and manage secrets (KV v1/v2).
- **Secure Storage**: Securely stores access tokens locally.

## Usage

```dart
import 'package:openbao_api/openbao_api.dart';

void main() async {
  // Initialize storage
  final storage = TokenStorage(
    storagePath: '/path/to/storage',
  );
  await storage.initialize();

  // Create client
  final client = OpenBaoClient(
    address: 'https://vault.example.com',
    roleId: 'your-role-id',
    secretId: 'your-secret-id', // Or provide a way to generate it
    tokenStorage: storage,
  );

  // Read secrets
  final secrets = await client.readSecrets('secret/data/my-app');
  print(secrets);
}
```
