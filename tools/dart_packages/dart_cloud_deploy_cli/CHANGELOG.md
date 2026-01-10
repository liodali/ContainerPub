## 0.2.0

- **AppRole Authentication**: Added support for OpenBao/Vault AppRole authentication.
- **Token Management**: Implemented secure token storage using Hive (LazyBox) with automatic expiration and renewal.
- **Configuration**: Added `role_id` and `role_name` fields to `TokenManagerConfig` for AppRole support.
- **Dependency**: Added `hive_ce` dependency for local token caching.
- **Token Renewal**: Tokens are now automatically checked for validity (1h TTL) and refreshed transparently.

## 1.0.0

- Initial version.
