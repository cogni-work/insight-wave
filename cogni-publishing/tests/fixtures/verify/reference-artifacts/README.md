# Static verifier regression artifacts

These historical bytes are immutable test inputs. They are not current platform proof, a rendering implementation, or an available fallback. The independent verifier suite reads and mutates them to test copy, geometry, editability, review and specimen contracts. Object inventories are optional historical inputs. Plans and writer provenance have been removed; the test manifest indexes only the artifacts and their frozen compositions.

The separate `artifact-samples/` directory supports a test-only bridge that selects exact input digests and copies bytes. It never generates an artifact. Actual host proof lives under `docs/design-verify-proof/`.
