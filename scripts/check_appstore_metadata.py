#!/usr/bin/env python3
"""Check that fastlane's listing metadata matches APPSTORE-METADATA.md."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
SOURCE_PATH = ROOT / "APPSTORE-METADATA.md"
METADATA_ROOT = ROOT / "fastlane" / "metadata"


def section(source: str, title: str) -> str:
    marker = f"## {title}\n"
    try:
        body = source.split(marker, 1)[1].split("\n---", 1)[0]
    except IndexError as error:
        raise ValueError(f"could not find section {title!r}") from error
    return body.strip("\n")


def fenced_value(source: str, title: str) -> str:
    body = section(source, title)
    try:
        return body.split("```\n", 1)[1].split("\n```", 1)[0]
    except IndexError as error:
        raise ValueError(f"could not find fenced value in {title!r}") from error


def table_value(source: str, field: str) -> str:
    match = re.search(rf"\| \*\*{re.escape(field)}\*\* \| (.*?) \|", source)
    if not match:
        raise ValueError(f"could not find {field!r} in the identity table")
    return match.group(1)


def expected_fields(source: str) -> dict[str, str]:
    return {
        "fastlane/metadata/en-US/name.txt": table_value(source, "Name"),
        "fastlane/metadata/en-US/subtitle.txt": table_value(source, "Subtitle"),
        "fastlane/metadata/en-US/description.txt": section(source, "Description"),
        "fastlane/metadata/en-US/keywords.txt": fenced_value(source, "Keywords"),
        "fastlane/metadata/en-US/promotional_text.txt": fenced_value(
            source, "Promotional Text"
        ),
        "fastlane/metadata/en-US/support_url.txt": section(source, "Support URL"),
        "fastlane/metadata/en-US/privacy_url.txt": section(
            source, "Privacy Policy URL"
        ),
        "fastlane/metadata/en-US/release_notes.txt": "Initial release.",
        "fastlane/metadata/default/copyright.txt": section(source, "Copyright"),
    }


def main() -> int:
    source = SOURCE_PATH.read_text(encoding="utf-8")
    fields = expected_fields(source)
    failures = []

    actual_text_files = {
        path.relative_to(ROOT).as_posix()
        for path in METADATA_ROOT.rglob("*.txt")
    }
    unexpected = actual_text_files - fields.keys()
    missing = fields.keys() - actual_text_files
    if unexpected:
        failures.append(f"unmapped metadata text files: {', '.join(sorted(unexpected))}")
    if missing:
        failures.extend(f"missing {path}" for path in sorted(missing))

    for relative_path, value in fields.items():
        path = ROOT / relative_path
        if not path.exists():
            continue
        expected = (value + "\n").encode("utf-8")
        actual = path.read_bytes()
        if actual != expected:
            failures.append(f"mismatch: {relative_path}")
        else:
            print(f"MATCH {relative_path}")

    if failures:
        for failure in failures:
            print(f"FAIL {failure}", file=sys.stderr)
        return 1
    print(f"PASS: {len(fields)} metadata files match APPSTORE-METADATA.md byte-for-byte")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
