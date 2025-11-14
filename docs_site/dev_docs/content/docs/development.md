---
title: Development Guide
description: Get started with ContainerPub development
---

# Development Guide

Learn how to develop, build, and deploy Dart functions with ContainerPub.

## Getting Started

### Prerequisites

- Dart SDK 3.x or higher
- Bun or pub for package management
- Podman (for local testing)

### Installation

**Automated Installation (Recommended):**

```dart
curl -fsSL https://raw.githubusercontent.com/liodali/ContainerPub/main/scripts/install.sh | bash
```

**Or compile from source:**
```dart
./scripts/install-cli.sh
```

## CLI Usage

### Login
```dart
dart_cloud login
```

### Deploy a Function
```dart
dart_cloud deploy ./my_function
```

### List Functions
```dart
dart_cloud list
```

### View Logs
```dart
dart_cloud logs <function-id>
```

### Delete Function
```dart
dart_cloud delete <function-id>
```

## Function Structure

A ContainerPub function requires:

```dart
my_function/
├── main.dart          # Entry point with main() function
├── pubspec.yaml       # Dependencies
└── lib/               # Additional code (optional)
```

### Example Function

```dart
// main.dart
void main() {
  print('Hello from ContainerPub!');
}
```

## Building Functions

### Local Build
```dart
cd my_function
dart pub get
dart run main.dart
```

### Build Process

1. Upload function archive
2. Extract to container
3. Build Docker/Podman image
4. Store metadata
5. Ready for execution

## Environment Variables

Configure environment variables in your function:

```dart
dart_cloud deploy ./my_function \
  --env DATABASE_URL=postgresql://... \
  --env API_KEY=secret
```

## Monitoring

### View Function Metrics
```dart
dart_cloud metrics <function-id>
```

### Check Function Status
```dart
dart_cloud status <function-id>
```

### Stream Logs
```dart
dart_cloud logs <function-id> --follow
```

## Best Practices

### Security
- Never hardcode secrets
- Use environment variables
- Validate all inputs
- Keep dependencies updated

### Performance
- Minimize cold start time
- Optimize dependencies
- Use efficient algorithms
- Cache when possible

### Reliability
- Handle errors gracefully
- Use proper logging
- Test thoroughly
- Monitor in production

## Troubleshooting

### Function Won't Deploy
1. Check Dart SDK version
2. Verify pubspec.yaml
3. Ensure main() exists
4. Check network connectivity

### Slow Execution
1. Optimize dependencies
2. Reduce function size
3. Check resource limits
4. Profile your code

### Build Failures
1. Check build logs
2. Verify dependencies
3. Test locally first
4. Check Podman status

## Next Steps

- Read the [Architecture Overview](/docs/architecture)
- Explore [CLI Commands](/docs/api)
- Check [Best Practices](/docs/development/best-practices)
