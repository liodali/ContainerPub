# Your First Function

Learn to create, test, and deploy your first Dart function with ContainerPub. This guide walks you through the complete development workflow.

## Function Structure

A ContainerPub function is a simple Dart file with special annotations:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// All functions must have the @function annotation
@function
Future<String> hello(Map<String, dynamic> input) async {
  final name = input['name'] ?? 'World';
  return 'Hello, $name!';
}

@function
Future<String> fetchWeather(Map<String, dynamic> input) async {
  final city = input['city'] ?? 'London';
  final apiKey = input['apiKey'] ?? '';
  
  if (apiKey.isEmpty) {
    return 'Error: API key required';
  }
  
  final response = await http.get(
    Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey')
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final temp = data['main']['temp'];
    return 'Current temperature in $city: ${temp - 273.15}°C';
  } else {
    return 'Failed to fetch weather data';
  }
}
```

## Step 1: Create Your Function

### Initialize Function Directory
```bash
# Create a new directory for your function
mkdir my_first_function
cd my_first_function

# Create pubspec.yaml
cat > pubspec.yaml << EOF
name: my_first_function
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  http: ^1.1.0
EOF

# Get dependencies
dart pub get
```

### Write Your Function
```bash
# Create the main function file
cat > function.dart << EOF
import 'dart:convert';
import 'package:http/http.dart' as http;

@function
Future<String> greetUser(Map<String, dynamic> input) async {
  final name = input['name'] ?? 'there';
  final time = DateTime.now().hour;
  
  String greeting;
  if (time < 12) {
    greeting = 'Good morning';
  } else if (time < 18) {
    greeting = 'Good afternoon';
  } else {
    greeting = 'Good evening';
  }
  
  return '$greeting, $name! The time is ${DateTime.now()}';
}

@function
Future<String> calculateSum(Map<String, dynamic> input) async {
  final numbers = input['numbers'] as List?;
  if (numbers == null || numbers.isEmpty) {
    return 'Error: Please provide a list of numbers';
  }
  
  try {
    final sum = numbers.fold<double>(0, (prev, num) => prev + double.parse(num.toString()));
    return 'Sum of $numbers is $sum';
  } catch (e) {
    return 'Error: Invalid numbers provided';
  }
}

@function
Future<String> getJoke(Map<String, dynamic> input) async {
  try {
    final response = await http.get(
      Uri.parse('https://official-joke-api.appspot.com/random_joke')
    );
    
    if (response.statusCode == 200) {
      final joke = jsonDecode(response.body);
      return '${joke['setup']} - ${joke['punchline']}';
    } else {
      return 'Why did the programmer quit? Because they didn\'t get arrays!';
    }
  } catch (e) {
    return 'Why do programmers prefer dark mode? Because light attracts bugs!';
  }
}
EOF
```

## Step 2: Test Locally

### Create Test Script
```bash
# Create a test runner
cat > test_function.dart << EOF
import 'dart:io';
import 'function.dart';

void main() async {
  print('Testing functions locally...\n');
  
  // Test greetUser
  print('Testing greetUser:');
  final greeting = await greetUser({'name': 'Alice'});
  print('Result: $greeting\n');
  
  // Test calculateSum
  print('Testing calculateSum:');
  final sum = await calculateSum({'numbers': [1, 2, 3, 4, 5]});
  print('Result: $sum\n');
  
  // Test getJoke
  print('Testing getJoke:');
  final joke = await getJoke({});
  print('Result: $joke\n');
  
  print('All tests completed!');
}
EOF

# Run tests
dart run test_function.dart
```

### Expected Output
```
Testing functions locally...

Testing greetUser:
Result: Good afternoon, Alice! The time is 2024-01-15 14:30:00.000

Testing calculateSum:
Result: Sum of [1, 2, 3, 4, 5] is 15.0

Testing getJoke:
Result: Why did the programmer quit? Because they didn't get arrays!

All tests completed!
```

## Step 3: Deploy to ContainerPub

### Security Analysis
Before deploying, ContainerPub analyzes your function for security:

```bash
# Deploy your function
dart_cloud deploy ./my_first_function
```

**Expected Security Analysis:**
```
🔍 Analyzing function...
✓ @function annotation found
✓ No dangerous imports detected
✓ No Process.run calls found
✓ No shell access detected
✓ HTTP-only operations confirmed
✓ Function signature valid

📦 Packaging function...
✓ Dependencies resolved
✓ Function packaged successfully

🚀 Deploying to ContainerPub...
✓ Function uploaded
✓ Deployment complete
```

### If Security Issues Found
```bash
# Example of blocked code
@function
Future<String> badFunction(Map<String, dynamic> input) async {
  // This would be blocked!
  final result = await Process.run('ls', ['-la']);
  return result.stdout;
}

# Security analysis would show:
❌ SECURITY VIOLATION DETECTED:
   - Process.run() is not allowed
   - Functions must use HTTP-only operations
   
Deployment rejected. Please review security guidelines.
```

## Step 4: Use Your Function

### Invoke via CLI
```bash
# List deployed functions
dart_cloud list

# Invoke greetUser function
dart_cloud invoke <function-id> --data '{"name": "Bob"}'

# Invoke calculateSum function
dart_cloud invoke <function-id> --data '{"numbers": [10, 20, 30]}'

# Invoke getJoke function
dart_cloud invoke <function-id>
```

### Invoke via HTTP
```bash
# Get your auth token
TOKEN=$(cat ~/.dart_cloud/config.json | jq -r '.token')

# Invoke via curl
curl -X POST http://localhost:8080/api/functions/<function-id>/invoke \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Charlie"}'
```

## Step 5: Monitor and Debug

### View Logs
```bash
# View recent logs
dart_cloud logs <function-id>

# Follow logs in real-time
dart_cloud logs <function-id> --follow

# View logs with timestamps
dart_cloud logs <function-id> --timestamps
```

### Check Function Metrics
```bash
# View invocation history
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/functions/<function-id>/invocations

# View performance metrics
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/functions/<function-id>/metrics
```

## Function Examples

### HTTP API Function
```dart
@function
Future<String> getUserInfo(Map<String, dynamic> input) async {
  final userId = input['userId'] ?? '1';
  
  final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/users/$userId')
  );
  
  if (response.statusCode == 200) {
    final user = jsonDecode(response.body);
    return 'User: ${user['name']} (${user['email']})';
  } else {
    return 'User not found';
  }
}
```

### Data Processing Function
```dart
@function
Future<String> processData(Map<String, dynamic> input) async {
  final data = input['data'] as List?;
  if (data == null) return 'No data provided';
  
  final processed = data.map((item) {
    return {
      'original': item,
      'length': item.toString().length,
      'uppercase': item.toString().toUpperCase(),
    };
  }).toList();
  
  return 'Processed ${processed.length} items: ${jsonEncode(processed)}';
}
```

### Error Handling Function
```dart
@function
Future<String> safeOperation(Map<String, dynamic> input) async {
  try {
    final url = input['url'] ?? '';
    if (url.isEmpty) {
      return 'Error: URL is required';
    }
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return 'Success: ${response.body.length} bytes received';
    } else {
      return 'HTTP Error: ${response.statusCode}';
    }
  } catch (e) {
    return 'Exception: $e';
  }
}
```

## Best Practices

### 1. Input Validation
```dart
@function
Future<String> validatedFunction(Map<String, dynamic> input) async {
  // Validate required fields
  if (!input.containsKey('email')) {
    return 'Error: Email is required';
  }
  
  final email = input['email'] as String;
  if (!email.contains('@')) {
    return 'Error: Invalid email format';
  }
  
  // Process valid input
  return 'Email $email is valid';
}
```

### 2. Error Handling
```dart
@function
Future<String> robustFunction(Map<String, dynamic> input) async {
  try {
    final response = await http.get(Uri.parse(input['url']));
    return response.body;
  } on SocketException {
    return 'Network error: Unable to connect';
  } on TimeoutException {
    return 'Request timeout: Please try again';
  } catch (e) {
    return 'Unexpected error: $e';
  }
}
```

### 3. Resource Management
```dart
@function
Future<String> efficientFunction(Map<String, dynamic> input) async {
  // Set timeouts
  final response = await http.get(
    Uri.parse(input['url']),
  ).timeout(Duration(seconds: 5));
  
  // Check response size
  if (response.body.length > 1000000) {
    return 'Error: Response too large';
  }
  
  return 'Success: Processed ${response.body.length} bytes';
}
```

## Next Steps

1. **[Function Templates](../user-guide/function-templates.md)** - More examples
2. **[Database Access](../user-guide/database-access.md)** - Connect to databases
3. **[Security Guidelines](../user-guide/security-guidelines.md)** - Understand restrictions
4. **[Testing & Debugging](../user-guide/testing-debugging.md)** - Advanced testing

## Troubleshooting

### Deployment Failed
```bash
# Check function syntax
dart analyze function.dart

# Check dependencies
dart pub deps

# Review security analysis output
dart_cloud deploy ./my_first_function --verbose
```

### Function Not Working
```bash
# Check function logs
dart_cloud logs <function-id>

# Test with different input
dart_cloud invoke <function-id> --data '{"test": "value"}'

# Verify function is deployed
dart_cloud list
```

---

**Congratulations!** You've successfully created and deployed your first ContainerPub function. Check out our [User Guide](../user-guide/) to explore more advanced features!
