# Platform HTML layout contract

The platform HTML leg writes the same observable structure that `scripts/verify_checks.py` reads. This is an artifact contract, not a layout prescription: the renderer remains free to choose composition and CSS inside these markers.

| Artifact fact | Required HTML |
|---|---|
| Unit identity and order | One `section[data-unit][data-pattern]` per composition unit, in composition order |
| Slot reading order | Descendants carrying `data-slot`, ordered as the unit's pattern slots |
| Frozen copy | One element carrying `data-copy="<record-id>#<field>"` for each bound field; its text is the frozen string |
| Dataset values | An element carrying `data-value="<dataset-ref>"` for each rendered value |
| Citation identity | Each citation link carries `data-source="<source-id>"` and an `href` equal to the source URL byte for byte |
| Source register | The sources unit contains one `li[data-source]` per source, in source order |

Use theme custom properties for painted colors and typefaces. Keep the compiled theme token block intact so the verifier can resolve aliases. Include no hidden copy, clamp, script, remote asset, font download, or file reference. `design-verify verify --target html` remains the admission gate; conformance to this page does not itself establish a passing verdict.
