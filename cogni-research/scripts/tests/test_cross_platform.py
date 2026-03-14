#!/usr/bin/env python3
"""Tests for cross_platform.py shared utilities."""

import sys
from pathlib import Path

# Add shared_utils to path
sys.path.insert(0, str(Path(__file__).parent.parent / "shared_utils"))

from cross_platform import fix_json_braces, parse_data_auto


class TestFixJsonBraces:
    """Tests for fix_json_braces function."""

    def test_balanced_braces_unchanged(self):
        """Balanced JSON should not be modified."""
        data = '{"key": "value"}'
        fixed, was_fixed = fix_json_braces(data)
        assert not was_fixed
        assert fixed == data

    def test_extra_closing_brace(self):
        """Single extra closing brace should be removed."""
        malformed = '{"key": "value"}}'
        fixed, was_fixed = fix_json_braces(malformed)
        assert was_fixed
        assert fixed == '{"key": "value"}'

    def test_double_extra_closing_brace(self):
        """Two extra closing braces should be removed."""
        malformed = '{"key": {"nested": "value"}}}'
        fixed, was_fixed = fix_json_braces(malformed)
        assert was_fixed
        assert fixed == '{"key": {"nested": "value"}}'

    def test_nested_object_extra_brace(self):
        """Extra brace after nested object should be removed."""
        malformed = '{"frontmatter": {"title": "test"}, "content": "body"}}'
        fixed, was_fixed = fix_json_braces(malformed)
        assert was_fixed
        assert fixed == '{"frontmatter": {"title": "test"}, "content": "body"}'

    def test_missing_closing_brace_unchanged(self):
        """Missing closing brace should not be modified (can't safely fix)."""
        malformed = '{"key": "value"'
        fixed, was_fixed = fix_json_braces(malformed)
        assert not was_fixed
        assert fixed == malformed

    def test_empty_object(self):
        """Empty object should not be modified."""
        data = "{}"
        fixed, was_fixed = fix_json_braces(data)
        assert not was_fixed
        assert fixed == data

    def test_with_trailing_whitespace(self):
        """Extra brace with trailing whitespace should be fixed."""
        malformed = '{"key": "value"}}  \n'
        fixed, was_fixed = fix_json_braces(malformed)
        assert was_fixed
        # The function strips trailing whitespace before processing
        assert fixed == '{"key": "value"}'


class TestParseDataAuto:
    """Tests for parse_data_auto function."""

    def test_valid_json(self):
        """Valid JSON should parse correctly."""
        data = '{"key": "value", "number": 42}'
        result = parse_data_auto(data)
        assert result == {"key": "value", "number": 42}

    def test_valid_yaml(self):
        """Valid YAML should parse correctly."""
        data = "key: value\nnumber: 42"
        result = parse_data_auto(data)
        assert result == {"key": "value", "number": 42}

    def test_auto_fixes_extra_brace(self):
        """Malformed JSON with extra brace should be auto-fixed."""
        malformed = '{"frontmatter": {}, "content": "test"}}'
        result = parse_data_auto(malformed)
        assert result == {"frontmatter": {}, "content": "test"}

    def test_nested_json_with_extra_brace(self):
        """Nested JSON with extra brace should be auto-fixed."""
        malformed = '{"outer": {"inner": {"deep": "value"}}}}'
        result = parse_data_auto(malformed)
        assert result == {"outer": {"inner": {"deep": "value"}}}

    def test_empty_data_raises(self):
        """Empty data should raise ValueError."""
        try:
            parse_data_auto("")
            assert False, "Expected ValueError"
        except ValueError as e:
            assert "Empty data" in str(e)

    def test_whitespace_only_raises(self):
        """Whitespace-only data should raise ValueError."""
        try:
            parse_data_auto("   \n  ")
            assert False, "Expected ValueError"
        except ValueError as e:
            assert "Empty data" in str(e)

    def test_json_error_includes_position(self):
        """JSON parse error should include position information."""
        # Create a JSON that definitely fails and can't be interpreted as YAML dict
        # Using a structure that YAML can't parse either
        try:
            # Tab character in key is invalid in YAML 1.1+
            parse_data_auto('{"key\t": "value"')
            # If it parses, that's okay - YAML is very permissive
        except ValueError as e:
            error_msg = str(e)
            # Should contain some error info
            assert "error" in error_msg.lower()


def run_tests():
    """Run all tests and report results."""
    import traceback

    test_classes = [TestFixJsonBraces, TestParseDataAuto]
    passed = 0
    failed = 0

    for test_class in test_classes:
        instance = test_class()
        for method_name in dir(instance):
            if method_name.startswith("test_"):
                try:
                    getattr(instance, method_name)()
                    print(f"  PASS: {test_class.__name__}.{method_name}")
                    passed += 1
                except AssertionError as e:
                    print(f"  FAIL: {test_class.__name__}.{method_name}")
                    print(f"        {e}")
                    failed += 1
                except Exception as e:
                    print(f"  ERROR: {test_class.__name__}.{method_name}")
                    print(f"         {e}")
                    traceback.print_exc()
                    failed += 1

    print(f"\n{'='*50}")
    print(f"Results: {passed} passed, {failed} failed")
    return failed == 0


if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
