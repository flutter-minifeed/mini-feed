"""Regenerate the Firestore Unicode 16 grapheme functions from pinned UCD files."""

import argparse
from collections import defaultdict
from hashlib import sha256
from pathlib import Path


SOURCES = {
    "GraphemeBreakProperty.txt": "c29360bd6f7132811d701d29069541e827eb44bfc4c8fbde8c370d6982689dc1",
    "DerivedCoreProperties.txt": "39d35161f2954497f69e08bdb9e701493f476a3d30222de20028feda36c1dabd",
    "emoji_data.txt": "f1365a5173eee18e1f98b240cdc492e84a25f1ce7e0c9d1094eb29c41a22696a",
}
START = "    // BEGIN GENERATED UNICODE 16 GRAPHEME FUNCTIONS"
END = "    // END GENERATED UNICODE 16 GRAPHEME FUNCTIONS"
MARKER_START = 0xE000


def load_properties(directory):
    properties = defaultdict(set)
    for name, digest in SOURCES.items():
        contents = (directory / name).read_bytes().replace(b"\r\n", b"\n")
        if sha256(contents).hexdigest() != digest:
            raise ValueError(f"{name}: expected the pinned Unicode 16 data")
        for line in contents.decode("utf-8").splitlines():
            row = line.split("#", 1)[0].strip()
            if not row:
                continue
            code_range, *fields = map(str.strip, row.split(";"))
            key = ":".join(fields)
            if name == "DerivedCoreProperties.txt" and not key.startswith("InCB:"):
                continue
            if name == "emoji_data.txt" and key != "Extended_Pictographic":
                continue
            endpoints = [int(code, 16) for code in code_range.split("..")]
            properties[key].update(range(endpoints[0], endpoints[-1] + 1))
    return properties


def ranges(code_points):
    ordered = iter(sorted(code_points))
    start = end = next(ordered)
    for point in ordered:
        if point == end + 1:
            end = point
        else:
            yield start, end
            start = end = point
    yield start, end


def escaped(point):
    return rf"\x{{{point:X}}}"


def range_expression(start, end):
    return escaped(start) if start == end else f"{escaped(start)}-{escaped(end)}"


def charset(code_points, negate=False):
    parts = (range_expression(start, end) for start, end in ranges(code_points))
    return "[" + ("^" if negate else "") + "".join(parts) + "]"


def alternatives(*patterns):
    return "(?:" + "|".join(patterns) + ")"


def group(pattern):
    return "(?:" + pattern + ")"


def rules_string(pattern):
    return pattern.replace("\\", "\\\\")


def build_mapping(properties):
    properties_by_point = defaultdict(set)
    for name, points in properties.items():
        for point in points:
            properties_by_point[point].add(name)

    points_by_signature = defaultdict(list)
    for point, names in properties_by_point.items():
        points_by_signature[tuple(sorted(names))].append(point)

    markers = {
        names: MARKER_START + index
        for index, names in enumerate(sorted(points_by_signature))
    }
    other = MARKER_START + len(markers)
    reserved = range(MARKER_START, other + 1)
    assert not any(point in properties_by_point for point in reserved)

    # Original private-use markers all have the Other property. Map them first
    # so input text cannot be confused with markers produced by the classifier.
    mapping = [(charset(reserved), other)]
    for names, marker in markers.items():
        parts = []
        size = 0
        for start, end in ranges(points_by_signature[names]):
            part = range_expression(start, end)
            if size + len(part) > 1800:
                mapping.append(("[" + "".join(parts) + "]", marker))
                parts, size = [], 0
            parts.append(part)
            size += len(part)
        if parts:
            mapping.append(("[" + "".join(parts) + "]", marker))
    mapping.append((charset(reserved, negate=True), other))
    return mapping, markers


def grapheme_pattern(markers):
    def char(*names, negate=False):
        selected = {
            marker for signature, marker in markers.items()
            if any(name in signature for name in names)
        }
        return charset(selected, negate)

    # UAX #29 Unicode 16, Tables 1b and 1c. Ordered alternatives and greedy
    # repetitions select the next complete grapheme from a known boundary.
    lead, vowel, tail, lv, lvt = (char(name) for name in ("L", "V", "T", "LV", "LVT"))
    hangul = alternatives(
        lead + "*" + alternatives(vowel + "+", lv + vowel + "*", lvt) + tail + "*",
        lead + "+",
        tail + "+",
    )
    flag = char("Regional_Indicator") + "{2}"
    emoji = char("Extended_Pictographic")
    joined_emoji = emoji + group(char("Extend") + "*" + char("ZWJ") + emoji) + "*"
    consonant, linker = char("InCB:Consonant"), char("InCB:Linker")
    modifier = char("InCB:Extend", "InCB:Linker")
    indic = consonant + group(modifier + "*" + linker + modifier + "*" + consonant) + "+"
    controls = ("CR", "LF", "Control")
    core = alternatives(hangul, flag, joined_emoji, indic, char(*controls, negate=True))
    return alternatives(
        char("CR") + char("LF"),
        char(*controls),
        char("Prepend") + "*" + core + char("Extend", "ZWJ", "SpacingMark") + "*",
    )


def generate(directory):
    mapping, markers = build_mapping(load_properties(directory))
    pattern = grapheme_pattern(markers)
    if any(len(regex) >= 4096 for regex in [pattern, *(key for key, _ in mapping)]):
        raise ValueError("A generated expression exceeds the emulator regex limit")

    functions = [START, "    // Regenerate with tests/firestore/generate_grapheme_rules.py."]
    body = "body"
    for index in range(0, len(mapping), 6):
        name = f"mapGraphemeClasses{index // 6}"
        functions.extend([f"    function {name}(body) {{", "      return body"])
        for regex, marker in mapping[index:index + 6]:
            functions.append(f"        .replace('{rules_string(regex)}', '\\u{marker:04X}')")
        functions[-1] += ";"
        functions.append("    }")
        body = f"{name}({body})"
    functions.extend([
        "    function countGraphemes(body) {",
        f"      let symbols = {body};",
        f"      return symbols.replace('{rules_string(pattern)}', 'x').size();",
        "    }",
        END,
    ])
    return "\n".join(functions)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("unicode_dir", type=Path, help="directory containing the three Unicode 16 files")
    parser.add_argument("--check", action="store_true", help="verify the generated section without writing")
    args = parser.parse_args()
    rules = Path(__file__).resolve().parents[2] / "firestore.rules"
    existing = rules.read_text(encoding="utf-8")
    left, start, remainder = existing.partition(START)
    _, end, right = remainder.partition(END)
    if not start or not end:
        parser.error("generated section markers are missing")
    updated = left + generate(args.unicode_dir) + right
    if args.check:
        if updated != existing:
            parser.error("firestore.rules is out of date")
    elif updated != existing:
        rules.write_text(updated, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
