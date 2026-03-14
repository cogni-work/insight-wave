#!/usr/bin/env python3
"""
Index PDFs into a RAG store by converting them to searchable Markdown files.

Usage:
    python index-pdfs.py <store-path> [--force]

Arguments:
    store-path  Path to the RAG store (e.g., /path/to/rag-store/smarter-service)
    --force     Re-index all PDFs even if markdown already exists

Store Structure Expected:
    {store-path}/
    ├── config.yaml      # Store configuration (required)
    ├── sources/         # PDF files to index
    │   └── *.pdf
    └── documents/       # Generated markdown (created by this script)
        └── *.md

Requirements:
    pip install pdfplumber pyyaml
"""

import argparse
import hashlib
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    import pdfplumber
except ImportError:
    print("Error: pdfplumber not installed. Run: pip install pdfplumber", file=sys.stderr)
    sys.exit(1)

try:
    import yaml
except ImportError:
    print("Error: pyyaml not installed. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


def slugify(text: str) -> str:
    """Convert text to a URL-friendly slug."""
    text = text.lower()
    text = re.sub(r'[^a-z0-9\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    text = re.sub(r'-+', '-', text)
    return text.strip('-')[:60]


def extract_title_from_pdf(pdf_path: Path, first_page_text: str) -> str:
    """Extract title from PDF metadata or first page content."""
    try:
        with pdfplumber.open(pdf_path) as pdf:
            metadata = pdf.metadata or {}
            if metadata.get('Title') and len(metadata['Title'].strip()) > 3:
                return metadata['Title'].strip()
    except Exception:
        pass

    # Fallback: Use first significant line from first page
    lines = [l.strip() for l in first_page_text.split('\n') if l.strip()]
    for line in lines[:5]:
        if len(line) > 10 and len(line) < 200:
            return line

    # Final fallback: Use filename
    return pdf_path.stem.replace('-', ' ').replace('_', ' ').title()


def extract_keywords(text: str, max_keywords: int = 10) -> list:
    """Extract potential keywords from text using simple frequency analysis."""
    # Common stop words to filter out
    stop_words = {
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
        'of', 'with', 'by', 'from', 'is', 'are', 'was', 'were', 'be', 'been',
        'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
        'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'this',
        'that', 'these', 'those', 'it', 'its', 'as', 'if', 'than', 'so',
        'such', 'no', 'not', 'only', 'own', 'same', 'too', 'very', 'just',
        'also', 'now', 'here', 'there', 'when', 'where', 'why', 'how', 'all',
        'each', 'every', 'both', 'few', 'more', 'most', 'other', 'some', 'any',
        'die', 'der', 'das', 'den', 'dem', 'des', 'ein', 'eine', 'einer',
        'und', 'oder', 'aber', 'mit', 'von', 'zu', 'bei', 'aus', 'nach',
        'für', 'über', 'unter', 'durch', 'ist', 'sind', 'war', 'wird', 'werden',
        'hat', 'haben', 'kann', 'können', 'nicht', 'auch', 'noch', 'nur', 'schon'
    }

    # Extract words (3+ chars, alphabetic)
    words = re.findall(r'\b[a-zA-ZäöüßÄÖÜ]{3,}\b', text.lower())

    # Count frequencies
    freq = {}
    for word in words:
        if word not in stop_words:
            freq[word] = freq.get(word, 0) + 1

    # Sort by frequency and return top keywords
    sorted_words = sorted(freq.items(), key=lambda x: x[1], reverse=True)
    return [word for word, _ in sorted_words[:max_keywords]]


def convert_pdf_to_markdown(pdf_path: Path) -> dict:
    """Convert a PDF file to markdown with metadata."""
    text_parts = []
    page_count = 0

    try:
        with pdfplumber.open(pdf_path) as pdf:
            page_count = len(pdf.pages)
            for i, page in enumerate(pdf.pages):
                page_text = page.extract_text() or ""
                if page_text.strip():
                    text_parts.append(f"<!-- Page {i + 1} -->\n{page_text}")
    except Exception as e:
        return {"error": str(e)}

    full_text = "\n\n".join(text_parts)
    first_page_text = text_parts[0] if text_parts else ""

    # Extract metadata
    title = extract_title_from_pdf(pdf_path, first_page_text)
    keywords = extract_keywords(full_text)

    # Calculate content hash for change detection
    content_hash = hashlib.md5(full_text.encode()).hexdigest()[:8]

    return {
        "title": title,
        "source_file": pdf_path.name,
        "page_count": page_count,
        "keywords": keywords,
        "content_hash": content_hash,
        "word_count": len(full_text.split()),
        "content": full_text
    }


def create_markdown_document(data: dict, indexed_at: str) -> str:
    """Create a markdown document with YAML frontmatter."""
    frontmatter = {
        "title": data["title"],
        "source_file": data["source_file"],
        "indexed_at": indexed_at,
        "page_count": data["page_count"],
        "word_count": data["word_count"],
        "content_hash": data["content_hash"],
        "keywords": data["keywords"]
    }

    yaml_str = yaml.dump(frontmatter, default_flow_style=False, allow_unicode=True, sort_keys=False)

    return f"""---
{yaml_str.strip()}
---

# {data["title"]}

{data["content"]}
"""


def index_store(store_path: Path, force: bool = False) -> dict:
    """Index all PDFs in a RAG store."""
    sources_dir = store_path / "sources"
    documents_dir = store_path / "documents"
    config_path = store_path / "config.yaml"

    # Validate store structure
    if not store_path.exists():
        return {"success": False, "error": f"Store path does not exist: {store_path}"}

    if not config_path.exists():
        return {"success": False, "error": f"config.yaml not found in {store_path}"}

    if not sources_dir.exists():
        return {"success": False, "error": f"sources/ directory not found in {store_path}"}

    # Create documents directory if needed
    documents_dir.mkdir(exist_ok=True)

    # Find all PDFs
    pdf_files = list(sources_dir.glob("*.pdf"))
    if not pdf_files:
        return {"success": True, "indexed": 0, "skipped": 0, "message": "No PDF files found in sources/"}

    indexed = 0
    skipped = 0
    errors = []
    indexed_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    for pdf_path in pdf_files:
        # Output markdown path
        md_filename = pdf_path.stem + ".md"
        md_path = documents_dir / md_filename

        # Skip if already indexed (unless force)
        if md_path.exists() and not force:
            skipped += 1
            continue

        # Convert PDF
        print(f"Indexing: {pdf_path.name}...", file=sys.stderr)
        result = convert_pdf_to_markdown(pdf_path)

        if "error" in result:
            errors.append({"file": pdf_path.name, "error": result["error"]})
            continue

        # Write markdown
        md_content = create_markdown_document(result, indexed_at)
        md_path.write_text(md_content, encoding="utf-8")
        indexed += 1
        print(f"  -> {md_filename} ({result['word_count']} words, {result['page_count']} pages)", file=sys.stderr)

    return {
        "success": True,
        "indexed": indexed,
        "skipped": skipped,
        "errors": errors if errors else None,
        "documents_dir": str(documents_dir)
    }


def init_store(store_path: Path) -> dict:
    """Initialize a new RAG store with default structure."""
    if store_path.exists():
        return {"success": False, "error": f"Store already exists: {store_path}"}

    # Create directories
    store_path.mkdir(parents=True)
    (store_path / "sources").mkdir()
    (store_path / "documents").mkdir()

    # Create default config
    config = {
        "name": store_path.name,
        "website_url": "https://example.com/publications",
        "source_reliability": 0.65,
        "description": "RAG document store"
    }

    config_path = store_path / "config.yaml"
    config_path.write_text(yaml.dump(config, default_flow_style=False, allow_unicode=True), encoding="utf-8")

    return {
        "success": True,
        "message": f"Store initialized at {store_path}",
        "next_steps": [
            f"1. Edit {config_path} to set website_url and description",
            f"2. Add PDF files to {store_path}/sources/",
            "3. Run indexer again to convert PDFs to searchable markdown"
        ]
    }


def main():
    parser = argparse.ArgumentParser(
        description="Index PDFs into a RAG store for semantic search",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Initialize a new store
    python index-pdfs.py /path/to/rag-store/my-store --init

    # Index all PDFs in a store
    python index-pdfs.py /path/to/rag-store/my-store

    # Force re-index all PDFs
    python index-pdfs.py /path/to/rag-store/my-store --force
        """
    )
    parser.add_argument("store_path", type=Path, help="Path to RAG store directory")
    parser.add_argument("--force", action="store_true", help="Re-index all PDFs even if markdown exists")
    parser.add_argument("--init", action="store_true", help="Initialize a new store")
    parser.add_argument("--json", action="store_true", help="Output result as JSON")

    args = parser.parse_args()

    if args.init:
        result = init_store(args.store_path)
    else:
        result = index_store(args.store_path, force=args.force)

    if args.json:
        import json
        print(json.dumps(result, indent=2))
    else:
        if result.get("success"):
            if args.init:
                print(f"\n{result['message']}")
                print("\nNext steps:")
                for step in result.get("next_steps", []):
                    print(f"  {step}")
            else:
                print(f"\nIndexing complete:")
                print(f"  Indexed: {result.get('indexed', 0)} documents")
                print(f"  Skipped: {result.get('skipped', 0)} (already indexed)")
                if result.get("errors"):
                    print(f"  Errors: {len(result['errors'])}")
                    for err in result["errors"]:
                        print(f"    - {err['file']}: {err['error']}")
        else:
            print(f"Error: {result.get('error')}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
