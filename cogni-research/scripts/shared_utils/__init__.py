"""
Claude Code Plugin Python Utilities (Bundled)
==============================================

Bundled version of shared utilities for plugin cache compatibility.
This package is a copy of cogni-workplace/python for standalone operation.

Modules:
    script_output  - JSON output contract helpers
    file_ops       - Cross-platform file operations
    cross_platform - General utilities (UUID, URL, YAML, etc.)
    logging_utils  - Enhanced logging with DEBUG_MODE/QUIET_MODE
    entity_lock    - Directory-based advisory locks
    entity_index   - Entity index management
    entity_ops     - Entity creation and validation
"""

# Script output (JSON contract)
from .script_output import (
    ExitCode,
    output_success,
    output_error,
    output_json,
    parse_json_arg,
    success,  # alias
    error,    # alias
)

# File operations
from .file_ops import (
    file_size,
    file_mtime,
    file_mtime_iso,
    file_exists,
    dir_exists,
    ensure_dir,
    temp_file,
    temp_dir,
    atomic_write,
    atomic_write_bytes,
    read_file,
    replace_in_file,
    FileLock,
    working_directory,
    normalize_path,
    relative_path,
)

# Cross-platform utilities
from .cross_platform import (
    generate_uuid,
    normalize_url,
    extract_domain,
    now_iso,
    now_date,
    parse_frontmatter,
    format_frontmatter,
    env_get,
    env_bool,
    slugify,
    truncate,
    plugin_root,
    cogni_research_root,
)

# Logging utilities
from .logging_utils import (
    log_conditional,
    log_phase,
    log_metric,
    get_timestamp,
    reset_mode_cache,
    debug,
    info,
    warn,
    error as log_error,
    trace,
)

# Entity lock utilities
from .entity_lock import (
    acquire_entity_lock,
    release_entity_lock,
    acquire_lock,
    release_lock,
    cleanup_stale_locks,
    EntityLock,
    Lock,
)

# Entity index utilities
from .entity_index import (
    VALID_ENTITY_TYPES,
    initialize_index,
    normalize_entity_name,
    lookup_entity_by_url,
    lookup_entity_by_name,
    add_entity_to_index,
    remove_entity_from_index,
    verify_entity_in_index,
    is_valid_entity_type,
    get_index_path,
)

# Entity operations
from .entity_ops import (
    DEDUPE_TYPES,
    REQUIRED_FIELDS,
    TYPE_PREFIXES,
    validate_entity_type,
    validate_frontmatter,
    validate_batch_ref,
    needs_deduplication,
    get_type_prefix,
    generate_entity_id,
    generate_yaml_frontmatter,
    prepare_frontmatter,
    create_entity_content,
)

# Entity configuration (central schema)
from .entity_config import (
    load_entity_config,
    get_valid_entity_types,
    get_type_prefixes,
    get_dedupe_types,
    get_required_fields,
    get_data_subdir,
    get_entity_data_path,
    get_special_directories,
    get_entity_config_by_directory,
    get_wikilink_pattern,
    get_schema_version,
)

__version__ = "2.1.0"
__all__ = [
    # script_output
    "ExitCode",
    "output_success",
    "output_error",
    "output_json",
    "parse_json_arg",
    "success",
    "error",
    # file_ops
    "file_size",
    "file_mtime",
    "file_mtime_iso",
    "file_exists",
    "dir_exists",
    "ensure_dir",
    "temp_file",
    "temp_dir",
    "atomic_write",
    "atomic_write_bytes",
    "read_file",
    "replace_in_file",
    "FileLock",
    "working_directory",
    "normalize_path",
    "relative_path",
    # cross_platform
    "generate_uuid",
    "normalize_url",
    "extract_domain",
    "now_iso",
    "now_date",
    "parse_frontmatter",
    "format_frontmatter",
    "env_get",
    "env_bool",
    "slugify",
    "truncate",
    "plugin_root",
    "cogni_research_root",
    # logging_utils
    "log_conditional",
    "log_phase",
    "log_metric",
    "get_timestamp",
    "reset_mode_cache",
    "debug",
    "info",
    "warn",
    "log_error",
    "trace",
    # entity_lock
    "acquire_entity_lock",
    "release_entity_lock",
    "acquire_lock",
    "release_lock",
    "cleanup_stale_locks",
    "EntityLock",
    "Lock",
    # entity_index
    "VALID_ENTITY_TYPES",
    "initialize_index",
    "normalize_entity_name",
    "lookup_entity_by_url",
    "lookup_entity_by_name",
    "add_entity_to_index",
    "remove_entity_from_index",
    "verify_entity_in_index",
    "is_valid_entity_type",
    "get_index_path",
    # entity_ops
    "DEDUPE_TYPES",
    "REQUIRED_FIELDS",
    "TYPE_PREFIXES",
    "validate_entity_type",
    "validate_frontmatter",
    "validate_batch_ref",
    "needs_deduplication",
    "get_type_prefix",
    "generate_entity_id",
    "generate_yaml_frontmatter",
    "prepare_frontmatter",
    "create_entity_content",
    # entity_config
    "load_entity_config",
    "get_valid_entity_types",
    "get_type_prefixes",
    "get_dedupe_types",
    "get_required_fields",
    "get_data_subdir",
    "get_entity_data_path",
    "get_special_directories",
    "get_entity_config_by_directory",
    "get_wikilink_pattern",
    "get_schema_version",
]
