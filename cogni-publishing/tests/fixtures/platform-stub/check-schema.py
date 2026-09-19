#!/usr/bin/env python3
"""Offline validator for the JSON Schema vocabulary used by provenance records.

Deliberately independent from design-render's field checker; no runtime packages.
"""
import json
import re
import sys


def validate(value, schema, root, path='$'):
    if '$ref' in schema:
        node = root
        for part in schema['$ref'].removeprefix('#/').split('/'):
            node = node[part]
        validate(value, node, root, path)
    types = {'object': dict, 'array': list, 'string': str, 'boolean': bool, 'integer': int, 'null': type(None)}
    if 'type' in schema:
        assert isinstance(value, types[schema['type']]), path + ': type'
        assert schema['type'] != 'integer' or type(value) is int, path + ': integer'
    if 'const' in schema:
        assert value == schema['const'] and type(value) is type(schema['const']), path + ': const'
    if 'enum' in schema:
        assert value in schema['enum'], path + ': enum'
    for branch in schema.get('allOf', []):
        validate(value, branch, root, path)
    if 'if' in schema:
        try:
            validate(value, schema['if'], root, path)
        except AssertionError:
            validate(value, schema.get('else', {}), root, path)
        else:
            validate(value, schema.get('then', {}), root, path)
    for kind in ('anyOf', 'oneOf'):
        if kind in schema:
            passing = 0
            for branch in schema[kind]:
                try:
                    validate(value, branch, root, path)
                    passing += 1
                except AssertionError:
                    pass
            assert passing > 0 if kind == 'anyOf' else passing == 1, path + ': ' + kind
    if isinstance(value, dict):
        assert all(k in value for k in schema.get('required', [])), path + ': required'
        for key, item in value.items():
            child = schema.get('properties', {}).get(key, schema.get('additionalProperties', {}))
            assert child is not False, path + ': additionalProperties'
            if isinstance(child, dict):
                validate(item, child, root, path + '.' + key)
    if isinstance(value, list):
        assert len(value) >= schema.get('minItems', 0), path + ': minItems'
        assert len(value) <= schema.get('maxItems', len(value)), path + ': maxItems'
        for i, item in enumerate(value):
            validate(item, schema.get('items', {}), root, path + '[' + str(i) + ']')
    if isinstance(value, str):
        assert len(value) >= schema.get('minLength', 0), path + ': minLength'
        if 'pattern' in schema:
            assert re.search(schema['pattern'], value), path + ': pattern'
    if type(value) is int:
        assert value >= schema.get('minimum', value), path + ': minimum'
        assert value <= schema.get('maximum', value), path + ': maximum'


if __name__ == '__main__':
    schema = json.load(open(sys.argv[1]))
    for source in sys.argv[2:]:
        validate(json.load(open(source)), schema, schema)
