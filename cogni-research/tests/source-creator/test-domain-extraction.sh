#!/usr/bin/env bash
# test-domain-extraction.sh
# Purpose: Test domain extraction patterns for source-creator
# Sprint: 226 - Fix Source-Creator Domain Extraction Bug
# Usage: ./test-domain-extraction.sh

set -eo pipefail

echo "Testing domain extraction patterns (Sprint 226 fix)"
echo "=================================================="
echo ""

# Test function
test_domain_extraction() {
  local url="$1"
  local expected="$2"
  local description="$3"

  # Use the exact same pattern as script.sh line 242
  local actual="$(echo "$url" | awk -F/ '{print $3}' | sed -E 's/:.*$//' | tr '[:upper:]' '[:lower:]')"

  if [ "$actual" = "$expected" ]; then
    echo "✓ PASS: $description"
    echo "  Input:    $url"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    echo ""
    return 0
  else
    echo "✗ FAIL: $description"
    echo "  Input:    $url"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    echo ""
    return 1
  fi
}

# Run tests
FAILURES=0
TOTAL=0

# Test 1: Basic HTTPS URL
TOTAL=$((TOTAL + 1))
test_domain_extraction "https://a16z.com/13-metrics-for-marketplace-companies/" "a16z.com" "Basic HTTPS URL" || FAILURES=$((FAILURES + 1))

# Test 2: HTTP URL
TOTAL=$((TOTAL + 1))
test_domain_extraction "http://blog.example.org/article" "blog.example.org" "HTTP with subdomain" || FAILURES=$((FAILURES + 1))

# Test 3: WWW subdomain
TOTAL=$((TOTAL + 1))
test_domain_extraction "https://www.cloudflare.com/" "www.cloudflare.com" "WWW subdomain" || FAILURES=$((FAILURES + 1))

# Test 4: Port number stripping
TOTAL=$((TOTAL + 1))
test_domain_extraction "https://example.com:8080/path" "example.com" "Port number stripped" || FAILURES=$((FAILURES + 1))

# Test 5: Multiple subdomains
TOTAL=$((TOTAL + 1))
test_domain_extraction "https://sub.domain.co.uk/page" "sub.domain.co.uk" "Multiple subdomains" || FAILURES=$((FAILURES + 1))

# Test 6: Uppercase URL
TOTAL=$((TOTAL + 1))
test_domain_extraction "HTTPS://UPPERCASE.COM/PATH" "uppercase.com" "Uppercase normalization" || FAILURES=$((FAILURES + 1))

# Test 7: Trailing slash only
TOTAL=$((TOTAL + 1))
test_domain_extraction "https://nature.com/" "nature.com" "Root path with trailing slash" || FAILURES=$((FAILURES + 1))

# Test 8: Long path
TOTAL=$((TOTAL + 1))
test_domain_extraction "https://pubmed.ncbi.nlm.nih.gov/12345678/some/long/path" "pubmed.ncbi.nlm.nih.gov" "Long path with deep subdomain" || FAILURES=$((FAILURES + 1))

# Test 9: Query parameters
TOTAL=$((TOTAL + 1))
test_domain_extraction "https://search.example.com/results?q=test&page=1" "search.example.com" "URL with query parameters" || FAILURES=$((FAILURES + 1))

# Test 10: IPv4 address (edge case)
TOTAL=$((TOTAL + 1))
test_domain_extraction "http://192.168.1.1/admin" "192.168.1.1" "IPv4 address" || FAILURES=$((FAILURES + 1))

# Summary
echo "=================================================="
echo "Test Summary: $((TOTAL - FAILURES))/$TOTAL passed"

if [ $FAILURES -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ $FAILURES test(s) failed"
  exit 1
fi
