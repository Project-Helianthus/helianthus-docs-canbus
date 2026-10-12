#!/usr/bin/env python3
"""Check relative Markdown links and heading anchors in the given files."""
import re
import sys
from pathlib import Path

HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)\)")


def lines_outside_fences(path):
    in_fence = False
    for number, line in enumerate(Path(path).read_text(encoding="utf-8").splitlines(), 1):
        if line.startswith("```") or line.startswith("~~~"):
            in_fence = not in_fence
            continue
        if not in_fence:
            yield number, line


def anchors(path):
    seen = {}
    found = set()
    for _, line in lines_outside_fences(path):
        match = HEADING.match(line)
        if not match:
            continue
        text = re.sub(r"[`*]", "", match.group(2)).strip().lower()
        slug = re.sub(r"[^\w\- ]", "", text).replace(" ", "-")
        count = seen.get(slug, 0)
        seen[slug] = count + 1
        found.add(slug if count == 0 else "%s-%d" % (slug, count))
    return found


def main(paths):
    failures = []
    cache = {}
    for name in paths:
        source = Path(name)
        for number, line in lines_outside_fences(source):
            for target in LINK.findall(line):
                if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target):
                    continue
                path_part, _, fragment = target.partition("#")
                resolved = source if not path_part else (source.parent / path_part)
                if not resolved.exists():
                    failures.append("%s:%d: missing link target %s" % (name, number, target))
                    continue
                if fragment and resolved.suffix == ".md":
                    if resolved not in cache:
                        cache[resolved] = anchors(resolved)
                    if fragment not in cache[resolved]:
                        failures.append("%s:%d: missing anchor %s" % (name, number, target))
    for failure in failures:
        print(failure, file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
