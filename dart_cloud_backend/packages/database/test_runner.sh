#!/bin/bash

# Test runner script for database package
# This script runs all tests and provides formatted output

set -e

echo "🧪 Running Database Package Tests"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to package directory
cd "$(dirname "$0")"

# Check if dart is installed
if ! command -v dart &> /dev/null; then
    echo -e "${RED}❌ Dart is not installed${NC}"
    exit 1
fi

echo "📦 Package: database"
echo "📍 Location: $(pwd)"
echo ""

# Run tests based on arguments
if [ "$1" == "coverage" ]; then
    echo "🔍 Running tests with coverage..."
    echo ""
    
    # Run tests with coverage
    dart test --coverage=coverage
    
    # Check if coverage tools are installed
    if ! dart pub global list | grep -q coverage; then
        echo ""
        echo -e "${YELLOW}⚠️  Coverage tools not installed. Installing...${NC}"
        dart pub global activate coverage
    fi
    
    # Format coverage
    dart pub global run coverage:format_coverage \
        --lcov \
        --in=coverage \
        --out=coverage/lcov.info \
        --report-on=lib
    
    echo ""
    echo -e "${GREEN}✅ Coverage report generated: coverage/lcov.info${NC}"
    
elif [ "$1" == "query-builder" ]; then
    echo "🔨 Running QueryBuilder tests only..."
    echo ""
    dart test test/query_builder_test.dart --reporter=expanded
    
elif [ "$1" == "entity" ]; then
    echo "📋 Running Entity tests only..."
    echo ""
    dart test test/entity_test.dart --reporter=expanded
    
elif [ "$1" == "manager" ]; then
    echo "🗄️  Running DatabaseManagerQuery tests only..."
    echo ""
    dart test test/database_manager_query_test.dart --reporter=expanded
    
elif [ "$1" == "watch" ]; then
    echo "👀 Running tests in watch mode..."
    echo ""
    dart test --reporter=expanded --watch
    
else
    echo "🚀 Running all tests..."
    echo ""
    
    # Run all tests with expanded reporter
    dart test --reporter=expanded
    
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
fi

echo ""
echo "=================================="
echo "Test run complete"
echo ""

# Show usage if no arguments
if [ -z "$1" ]; then
    echo "💡 Usage:"
    echo "  ./test_runner.sh              # Run all tests"
    echo "  ./test_runner.sh coverage     # Run with coverage"
    echo "  ./test_runner.sh query-builder # Run QueryBuilder tests only"
    echo "  ./test_runner.sh entity       # Run Entity tests only"
    echo "  ./test_runner.sh manager      # Run Manager tests only"
    echo "  ./test_runner.sh watch        # Run in watch mode"
    echo ""
fi
