# ContainerPub - Dart Serverless Cloud Platform

A modern serverless platform for deploying and managing Dart functions with comprehensive security and developer-friendly tooling.

## What is ContainerPub?

ContainerPub is a complete serverless solution that allows developers to deploy Dart functions without worrying about infrastructure, scaling, or security. It combines a powerful CLI tool with a robust backend platform to provide a seamless development experience.

## Key Features

### 🚀 **Easy Deployment**
- Deploy functions with a single command
- Automatic dependency management
- Zero-downtime deployments

### 🔒 **Security-First**
- Client-side static code analysis
- Sandboxed function execution
- Resource limits and timeouts
- Database access with connection pooling

### 📊 **Monitoring & Logging**
- Real-time execution metrics
- Comprehensive logging
- Performance analytics
- Error tracking

### 🌐 **Developer Friendly**
- Simple function templates
- Local development support
- Rich CLI experience
- HTTP-based function interface

## Architecture Overview

ContainerPub consists of two main components:

### CLI Tool (`dart_cloud_cli/`)
Command-line interface for developers that provides:
- Function deployment and management
- Security analysis and validation
- Authentication and configuration
- Log viewing and monitoring

### Backend Platform (`dart_cloud_backend/`)
Server platform that handles:
- Function storage and execution
- User authentication and authorization
- Database management and monitoring
- API endpoints and scaling

## Why Choose ContainerPub?

### For Developers
- **Simple API**: Write functions with standard Dart HTTP libraries
- **Local Testing**: Develop and test functions locally before deployment
- **Rich Tooling**: Comprehensive CLI for all operations
- **Security Feedback**: Get instant security analysis during development

### For Teams
- **Consistent Environment**: Same runtime for development and production
- **Security Controls**: Built-in security scanning and execution limits
- **Monitoring**: Track function performance and usage
- **Scalability**: Handle from 10 to 10,000+ function invocations

### For Operations
- **Easy Deployment**: Single-command deployment with Docker/Podman
- **Resource Management**: Configurable limits for memory, CPU, and execution time
- **Monitoring**: Built-in health checks and metrics
- **Security**: Sandboxed execution with comprehensive logging

## Technology Stack

- **Language**: Dart 3.x
- **Backend**: Shelf HTTP framework
- **Database**: PostgreSQL with connection pooling
- **Containerization**: Docker/Podman support
- **Authentication**: JWT-based security
- **CLI**: Dart-based command-line tool

## Quick Example

Here's a simple ContainerPub function:

```dart
import 'package:http/http.dart' as http;

@function
Future<String> hello(Map<String, dynamic> input) async {
  final name = input['name'] ?? 'World';
  return 'Hello, $name!';
}

@function
Future<String> fetchWeather(Map<String, dynamic> input) async {
  final city = input['city'] ?? 'London';
  final response = await http.get(
    Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$city')
  );
  
  if (response.statusCode == 200) {
    return 'Weather data for $city fetched successfully';
  } else {
    return 'Failed to fetch weather for $city';
  }
}
```

Deploy it with:
```bash
dart_cloud deploy ./my_function
```

## What's Next?

1. **[Quick Start Guide](quick-start.md)** - Get running in 3 steps
2. **[Installation Guide](installation.md)** - Detailed setup instructions  
3. **[First Function](first-function.md)** - Create and deploy your first function
4. **[User Guide](../user-guide/)** - Complete development documentation

## Community & Support

- **Documentation**: Complete guides and API reference
- **Examples**: Ready-to-use function templates
- **Issues**: Report bugs and request features
- **Contributing**: Help improve ContainerPub

---

Ready to get started? Check out our [Quick Start Guide](quick-start.md) to deploy your first function in minutes!
