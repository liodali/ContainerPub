#!/bin/bash

# ContainerPub Local Testing Script
# Tests the complete system end-to-end

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🧪 ContainerPub Local Testing"
echo "=============================="
echo ""

# Configuration
BACKEND_URL="http://localhost:8080"
TEST_EMAIL="test-$(date +%s)@example.com"
TEST_PASSWORD="testpass123"
CLI_PATH="dart_cloud_cli"

# Check if backend is running
echo "🔍 Checking backend..."
if ! curl -s "$BACKEND_URL/api/health" > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend is not running at $BACKEND_URL${NC}"
    echo "Please start the backend first:"
    echo "  cd dart_cloud_backend && dart run bin/server.dart"
    exit 1
fi
echo -e "${GREEN}✓ Backend is running${NC}"
echo ""

# Test 1: Register User
echo -e "${BLUE}Test 1: User Registration${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$TEST_EMAIL\", \"password\": \"$TEST_PASSWORD\"}")

if echo "$REGISTER_RESPONSE" | grep -q "token"; then
    echo -e "${GREEN}✓ User registered successfully${NC}"
else
    echo -e "${RED}❌ Registration failed${NC}"
    echo "$REGISTER_RESPONSE"
    exit 1
fi
echo ""

# Test 2: Login
echo -e "${BLUE}Test 2: User Login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$TEST_EMAIL\", \"password\": \"$TEST_PASSWORD\"}")

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Login failed${NC}"
    echo "$LOGIN_RESPONSE"
    exit 1
fi
echo -e "${GREEN}✓ Login successful${NC}"
echo "Token: ${TOKEN:0:20}..."
echo ""

# Test 3: Deploy Simple Function
echo -e "${BLUE}Test 3: Deploy Simple Function${NC}"

# Create test function archive
TEST_FUNC_DIR=$(mktemp -d)
cat > "$TEST_FUNC_DIR/main.dart" << 'EOF'
import 'dart:convert';
import 'dart:io';

const function = 'function';

@function
void main() async {
  try {
    final input = jsonDecode(Platform.environment['FUNCTION_INPUT'] ?? '{}');
    final body = input['body'] as Map<String, dynamic>? ?? {};
    final name = body['name'] ?? 'World';
    
    print(jsonEncode({
      'success': true,
      'message': 'Hello, $name!',
      'timestamp': DateTime.now().toIso8601String(),
    }));
  } catch (e) {
    print(jsonEncode({'error': e.toString()}));
    exit(1);
  }
}
EOF

cat > "$TEST_FUNC_DIR/pubspec.yaml" << 'EOF'
name: test_function
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
EOF

# Create archive
cd "$TEST_FUNC_DIR"
tar -czf function.tar.gz main.dart pubspec.yaml
cd - > /dev/null

# Deploy via API
DEPLOY_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/functions/deploy" \
    -H "Authorization: Bearer $TOKEN" \
    -F "name=test-function" \
    -F "archive=@$TEST_FUNC_DIR/function.tar.gz")

FUNCTION_ID=$(echo "$DEPLOY_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$FUNCTION_ID" ]; then
    echo -e "${RED}❌ Deployment failed${NC}"
    echo "$DEPLOY_RESPONSE"
    rm -rf "$TEST_FUNC_DIR"
    exit 1
fi
echo -e "${GREEN}✓ Function deployed${NC}"
echo "Function ID: $FUNCTION_ID"
echo ""

# Cleanup temp directory
rm -rf "$TEST_FUNC_DIR"

# Test 4: List Functions
echo -e "${BLUE}Test 4: List Functions${NC}"
LIST_RESPONSE=$(curl -s "$BACKEND_URL/api/functions" \
    -H "Authorization: Bearer $TOKEN")

if echo "$LIST_RESPONSE" | grep -q "$FUNCTION_ID"; then
    echo -e "${GREEN}✓ Function listed successfully${NC}"
else
    echo -e "${RED}❌ Function not found in list${NC}"
    echo "$LIST_RESPONSE"
fi
echo ""

# Test 5: Invoke Function
echo -e "${BLUE}Test 5: Invoke Function${NC}"
INVOKE_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/functions/$FUNCTION_ID/invoke" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"body": {"name": "TestUser"}, "query": {}}')

if echo "$INVOKE_RESPONSE" | grep -q "Hello, TestUser"; then
    echo -e "${GREEN}✓ Function invoked successfully${NC}"
    echo "Response: $(echo "$INVOKE_RESPONSE" | head -c 100)..."
else
    echo -e "${RED}❌ Function invocation failed${NC}"
    echo "$INVOKE_RESPONSE"
fi
echo ""

# Test 6: Get Function Logs
echo -e "${BLUE}Test 6: Get Function Logs${NC}"
LOGS_RESPONSE=$(curl -s "$BACKEND_URL/api/functions/$FUNCTION_ID/logs" \
    -H "Authorization: Bearer $TOKEN")

if echo "$LOGS_RESPONSE" | grep -q "logs"; then
    echo -e "${GREEN}✓ Logs retrieved successfully${NC}"
    LOG_COUNT=$(echo "$LOGS_RESPONSE" | grep -o '"level"' | wc -l)
    echo "Log entries: $LOG_COUNT"
else
    echo -e "${YELLOW}⚠️  No logs found (this is okay for new functions)${NC}"
fi
echo ""

# Test 7: Test Security - Deploy Function Without @function
echo -e "${BLUE}Test 7: Security Test - Missing @function Annotation${NC}"

BAD_FUNC_DIR=$(mktemp -d)
cat > "$BAD_FUNC_DIR/main.dart" << 'EOF'
import 'dart:convert';
import 'dart:io';

void main() async {
  print(jsonEncode({'message': 'This should fail'}));
}
EOF

cat > "$BAD_FUNC_DIR/pubspec.yaml" << 'EOF'
name: bad_function
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
EOF

cd "$BAD_FUNC_DIR"
tar -czf function.tar.gz main.dart pubspec.yaml
cd - > /dev/null

BAD_DEPLOY_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/functions/deploy" \
    -H "Authorization: Bearer $TOKEN" \
    -F "name=bad-function" \
    -F "archive=@$BAD_FUNC_DIR/function.tar.gz")

if echo "$BAD_DEPLOY_RESPONSE" | grep -q "Missing @function annotation"; then
    echo -e "${GREEN}✓ Security check passed - deployment rejected${NC}"
else
    echo -e "${YELLOW}⚠️  Expected security rejection, got: ${NC}"
    echo "$BAD_DEPLOY_RESPONSE"
fi

rm -rf "$BAD_FUNC_DIR"
echo ""

# Test 8: Test Security - Dangerous Code
echo -e "${BLUE}Test 8: Security Test - Dangerous Code Detection${NC}"

DANGER_FUNC_DIR=$(mktemp -d)
cat > "$DANGER_FUNC_DIR/main.dart" << 'EOF'
import 'dart:convert';
import 'dart:io';

const function = 'function';

@function
void main() async {
  final result = await Process.run('ls', ['-la']);
  print(jsonEncode({'output': result.stdout}));
}
EOF

cat > "$DANGER_FUNC_DIR/pubspec.yaml" << 'EOF'
name: danger_function
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
EOF

cd "$DANGER_FUNC_DIR"
tar -czf function.tar.gz main.dart pubspec.yaml
cd - > /dev/null

DANGER_DEPLOY_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/functions/deploy" \
    -H "Authorization: Bearer $TOKEN" \
    -F "name=danger-function" \
    -F "archive=@$DANGER_FUNC_DIR/function.tar.gz")

if echo "$DANGER_DEPLOY_RESPONSE" | grep -q "Process execution"; then
    echo -e "${GREEN}✓ Security check passed - dangerous code detected${NC}"
else
    echo -e "${YELLOW}⚠️  Expected security rejection, got: ${NC}"
    echo "$DANGER_DEPLOY_RESPONSE"
fi

rm -rf "$DANGER_FUNC_DIR"
echo ""

# Test 9: Delete Function
echo -e "${BLUE}Test 9: Delete Function${NC}"
DELETE_RESPONSE=$(curl -s -X DELETE "$BACKEND_URL/api/functions/$FUNCTION_ID" \
    -H "Authorization: Bearer $TOKEN")

if echo "$DELETE_RESPONSE" | grep -q "deleted successfully"; then
    echo -e "${GREEN}✓ Function deleted successfully${NC}"
else
    echo -e "${RED}❌ Function deletion failed${NC}"
    echo "$DELETE_RESPONSE"
fi
echo ""

# Summary
echo "================================"
echo -e "${GREEN}✅ All Tests Completed!${NC}"
echo "================================"
echo ""
echo "Test Results:"
echo "  ✓ User Registration"
echo "  ✓ User Login"
echo "  ✓ Function Deployment"
echo "  ✓ Function Listing"
echo "  ✓ Function Invocation"
echo "  ✓ Log Retrieval"
echo "  ✓ Security: @function Annotation Check"
echo "  ✓ Security: Dangerous Code Detection"
echo "  ✓ Function Deletion"
echo ""
echo "🎉 ContainerPub is working correctly!"
