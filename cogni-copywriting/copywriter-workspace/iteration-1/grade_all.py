#!/usr/bin/env python3
"""Grade all eval outputs against assertions."""
import json
import re
import os

BASE = "/Users/stephandehaas/GitHub/dev/cogni-copywriting/copywriter-workspace/iteration-1"

def read_file(path):
    with open(path) as f:
        return f.read()

def count_citations(text):
    """Count citation markers like [P1-1], [P2-3] etc."""
    return len(re.findall(r'\[P\d+-\d+\]', text))

def check_german_chars(text):
    """Check that no German chars were converted to ASCII."""
    # Check for suspicious patterns that suggest conversion
    ascii_patterns = ['ae ', 'oe ', 'ue ', ' ae', ' oe', ' ue', 'Ae ', 'Oe ', 'Ue ']
    # Check that actual German chars exist
    has_german = bool(re.search(r'[äöüßÄÖÜ]', text))
    return has_german

def check_paragraph_length(text, max_sentences=5):
    """Check no paragraph exceeds max_sentences."""
    paragraphs = [p.strip() for p in text.split('\n\n') if p.strip() and not p.strip().startswith('#') and not p.strip().startswith('|') and not p.strip().startswith('-') and not p.strip().startswith('>') and not p.strip().startswith('```')]
    violations = []
    for p in paragraphs:
        sentences = re.split(r'[.!?]+\s', p)
        sentences = [s for s in sentences if len(s.strip()) > 10]
        if len(sentences) > max_sentences:
            violations.append(f"{len(sentences)} sentences: {p[:80]}...")
    return len(violations) == 0, violations

def check_bold_anchoring(text, keywords):
    """Check that key metrics have bold formatting nearby."""
    found = 0
    for kw in keywords:
        # Check if keyword appears near bold markers
        pattern = rf'\*\*[^*]*{re.escape(kw)}[^*]*\*\*'
        if re.search(pattern, text):
            found += 1
    return found, len(keywords)

def check_h2_headings(text, expected):
    """Check H2 headings match expected list."""
    h2s = re.findall(r'^## (.+)$', text, re.MULTILINE)
    return h2s, expected

def check_frontmatter(text, key, value):
    """Check YAML frontmatter contains key: value."""
    match = re.search(rf'^{key}:\s*(.+)$', text, re.MULTILINE)
    if match:
        return value in match.group(1)
    return False

def check_citations_in_sections(text):
    """Check that citations stay in their original sections (P1-x in Why Change, etc.)."""
    sections = re.split(r'^## ', text, flags=re.MULTILINE)
    issues = []
    for section in sections:
        if section.startswith('Why Change'):
            cites = re.findall(r'\[P(\d+)-\d+\]', section)
            bad = [c for c in cites if c != '1']
            if bad: issues.append(f"Why Change has P{bad[0]}-x citations")
        elif section.startswith('Why Now'):
            cites = re.findall(r'\[P(\d+)-\d+\]', section)
            bad = [c for c in cites if c != '2']
            if bad: issues.append(f"Why Now has P{bad[0]}-x citations")
        elif section.startswith('Why You'):
            cites = re.findall(r'\[P(\d+)-\d+\]', section)
            bad = [c for c in cites if c != '3']
            if bad: issues.append(f"Why You has P{bad[0]}-x citations")
        elif section.startswith('Why Pay'):
            cites = re.findall(r'\[P(\d+)-\d+\]', section)
            bad = [c for c in cites if c != '4']
            if bad: issues.append(f"Why Pay has P{bad[0]}-x citations")
    return len(issues) == 0, issues

def grade_english_memo(variant, text):
    results = []

    # bluf_applied - qualitative, check if first substantial paragraph leads with action
    first_para = text.split('\n\n')[0] if not text.startswith('#') else text.split('\n\n')[1] if len(text.split('\n\n')) > 1 else ""
    # Look through paragraphs to find first non-header, non-metadata content
    paras = [p for p in text.split('\n\n') if p.strip() and not p.strip().startswith('#') and not p.strip().startswith('TO:') and not p.strip().startswith('FROM:') and not p.strip().startswith('DATE:') and not p.strip().startswith('SUBJECT:')]
    first_content = paras[0] if paras else ""
    has_bluf = any(kw in first_content.lower() for kw in ['bottom line', 'bluf', 'approve', 'decision', 'need', 'action required'])
    results.append({"text": "bluf_applied", "passed": has_bluf, "evidence": f"First content paragraph: {first_content[:150]}..."})

    # paragraph_length
    passed, violations = check_paragraph_length(text)
    results.append({"text": "paragraph_length", "passed": passed, "evidence": f"Violations: {violations}" if violations else "All paragraphs within limits"})

    # bold_anchoring
    found, total = check_bold_anchoring(text, ['75%', '450K', 'Q2', '$450'])
    passed = found >= 2
    results.append({"text": "bold_anchoring", "passed": passed, "evidence": f"{found}/{total} key metrics bolded"})

    return results

def grade_german_citations(variant, text):
    results = []

    # german_chars_preserved
    has_german = check_german_chars(text)
    results.append({"text": "german_chars_preserved", "passed": has_german, "evidence": f"German chars present: {has_german}"})

    # citations_preserved - check all 6 with URLs
    expected_citations = ['P1-1', 'P1-2', 'P1-3', 'P2-1', 'P2-2', 'P2-3']
    found_cites = []
    missing_cites = []
    for c in expected_citations:
        pattern = rf'\[{c}\]\(https?://[^\)]+\)'
        if re.search(pattern, text):
            found_cites.append(c)
        else:
            missing_cites.append(c)
    passed = len(missing_cites) == 0
    results.append({"text": "citations_preserved", "passed": passed, "evidence": f"Found: {found_cites}, Missing: {missing_cites}"})

    # no_citation_loss
    cite_count = count_citations(text)
    passed = cite_count >= 6
    results.append({"text": "no_citation_loss", "passed": passed, "evidence": f"Citation count: {cite_count} (expected >= 6)"})

    # paragraph_length
    passed, violations = check_paragraph_length(text)
    results.append({"text": "paragraph_length", "passed": passed, "evidence": f"Violations: {violations}" if violations else "All paragraphs within limits"})

    return results

def grade_arc_aware(variant, text):
    results = []

    # h2_headings_unchanged
    h2s, expected = check_h2_headings(text, ['Why Change', 'Why Now', 'Why You', 'Why Pay', 'Further Reading'])
    passed = h2s == expected
    results.append({"text": "h2_headings_unchanged", "passed": passed, "evidence": f"Found H2s: {h2s}, Expected: {expected}"})

    # citations_preserved
    expected_citations = ['P1-1', 'P1-2', 'P2-1', 'P2-2', 'P2-3', 'P3-1', 'P3-2', 'P4-1']
    found_cites = []
    missing_cites = []
    for c in expected_citations:
        pattern = rf'\[{c}\]\(https?://[^\)]+\)'
        if re.search(pattern, text):
            found_cites.append(c)
        else:
            missing_cites.append(c)
    passed = len(missing_cites) == 0
    results.append({"text": "citations_preserved", "passed": passed, "evidence": f"Found: {found_cites}, Missing: {missing_cites}"})

    # no_content_migration
    passed, issues = check_citations_in_sections(text)
    results.append({"text": "no_content_migration", "passed": passed, "evidence": f"Issues: {issues}" if issues else "All citations in correct sections"})

    # frontmatter_preserved
    passed = check_frontmatter(text, 'arc_id', 'corporate-visions')
    results.append({"text": "frontmatter_preserved", "passed": passed, "evidence": f"arc_id: corporate-visions found: {passed}"})

    return results

# Grade all runs
evals = [
    ("eval-english-memo-polish", "polished-memo.md", grade_english_memo),
    ("eval-german-citation-polish", "polished-german.md", grade_german_citations),
    ("eval-arc-aware-polish", "polished-arc.md", grade_arc_aware),
]

for eval_name, filename, grader in evals:
    for variant in ["with_skill", "without_skill"]:
        path = f"{BASE}/{eval_name}/{variant}/outputs/{filename}"
        if not os.path.exists(path):
            print(f"SKIP: {path} not found")
            continue

        text = read_file(path)
        results = grader(variant, text)

        grading = {
            "eval_name": eval_name,
            "variant": variant,
            "expectations": results,
            "pass_rate": sum(1 for r in results if r["passed"]) / len(results) if results else 0
        }

        out_path = f"{BASE}/{eval_name}/{variant}/grading.json"
        with open(out_path, 'w') as f:
            json.dump(grading, f, indent=2)

        passed = sum(1 for r in results if r["passed"])
        total = len(results)
        print(f"{eval_name}/{variant}: {passed}/{total} passed ({grading['pass_rate']:.0%})")
        for r in results:
            status = "PASS" if r["passed"] else "FAIL"
            print(f"  [{status}] {r['text']}: {r['evidence'][:120]}")
