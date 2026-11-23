"""Regenerate the Firestore Unicode 16 grapheme functions from pinned UCD files."""

import argparse
from collections import defaultdict
from hashlib import sha256
from pathlib import Path


UNICODE_FILE_HASHES = {
    "GraphemeBreakProperty.txt": "c29360bd6f7132811d701d29069541e827eb44bfc4c8fbde8c370d6982689dc1",
    "DerivedCoreProperties.txt": "39d35161f2954497f69e08bdb9e701493f476a3d30222de20028feda36c1dabd",
    "emoji_data.txt": "f1365a5173eee18e1f98b240cdc492e84a25f1ce7e0c9d1094eb29c41a22696a",
}
START = "    // BEGIN GENERATED UNICODE 16 GRAPHEME FUNCTIONS"
END = "    // END GENERATED UNICODE 16 GRAPHEME FUNCTIONS"
MARKER_START = 0xE000
CHARACTER_CLASS_CONTENT_LIMIT = 1800
REPLACEMENTS_PER_FUNCTION = 6
EMULATOR_REGEX_LENGTH_LIMIT = 4096


def read_verified_unicode_text(path, expected_hash):
    contents = path.read_bytes().replace(b"\r\n", b"\n")
    if sha256(contents).hexdigest() != expected_hash:
        raise ValueError(f"{path.name}: expected the pinned Unicode 16 data")
    return contents.decode("utf-8")


def unicode_property_rows(contents):
    for line in contents.splitlines():
        row = line.split("#", 1)[0].strip()
        if row:
            code_range, *fields = map(str.strip, row.split(";"))
            yield code_range, ":".join(fields)


def includes_grapheme_property(filename, name):
    if filename == "DerivedCoreProperties.txt":
        return name.startswith("InCB:")
    if filename == "emoji_data.txt":
        return name == "Extended_Pictographic"
    return True


def parse_code_point_range(code_range):
    endpoints = [int(code, 16) for code in code_range.split("..")]
    return range(endpoints[0], endpoints[-1] + 1)


def load_properties(directory):
    properties = defaultdict(set)
    for filename, digest in UNICODE_FILE_HASHES.items():
        contents = read_verified_unicode_text(directory / filename, digest)
        for code_range, name in unicode_property_rows(contents):
            if includes_grapheme_property(filename, name):
                properties[name].update(parse_code_point_range(code_range))
    return properties


def contiguous_code_point_ranges(code_points):
    ordered = iter(sorted(code_points))
    start = end = next(ordered)
    for point in ordered:
        if point == end + 1:
            end = point
        else:
            yield start, end
            start = end = point
    yield start, end


def regex_code_point(point):
    return rf"\x{{{point:X}}}"


def regex_code_point_range(start, end):
    return (
        regex_code_point(start)
        if start == end
        else f"{regex_code_point(start)}-{regex_code_point(end)}"
    )


def code_point_character_class(code_points, negate=False):
    parts = (
        regex_code_point_range(start, end)
        for start, end in contiguous_code_point_ranges(code_points)
    )
    prefix = "^" if negate else ""
    return f"[{prefix}{''.join(parts)}]"


def noncapturing_group(pattern):
    return "(?:" + pattern + ")"


def alternate_patterns(*patterns):
    return noncapturing_group("|".join(patterns))


def escape_rules_regex(pattern):
    return pattern.replace("\\", "\\\\")


def index_properties_by_code_point(properties):
    properties_by_point = defaultdict(set)
    for name, points in properties.items():
        for point in points:
            properties_by_point[point].add(name)
    return properties_by_point


def group_code_points_by_signature(properties_by_point):
    points_by_signature = defaultdict(list)
    for point, names in properties_by_point.items():
        points_by_signature[tuple(sorted(names))].append(point)
    return points_by_signature


def assign_markers(signatures):
    return {
        signature: MARKER_START + index
        for index, signature in enumerate(sorted(signatures))
    }


def split_character_classes(code_points):
    parts = []
    size = 0
    for start, end in contiguous_code_point_ranges(code_points):
        part = regex_code_point_range(start, end)
        if size + len(part) > CHARACTER_CLASS_CONTENT_LIMIT:
            yield f"[{''.join(parts)}]"
            parts, size = [], 0
        parts.append(part)
        size += len(part)
    if parts:
        yield f"[{''.join(parts)}]"


def build_mapping(properties):
    properties_by_point = index_properties_by_code_point(properties)
    points_by_signature = group_code_points_by_signature(properties_by_point)
    markers = assign_markers(points_by_signature)
    other = MARKER_START + len(markers)
    reserved = range(MARKER_START, other + 1)
    assert not any(point in properties_by_point for point in reserved)

    # Literal private-use characters have the Other property, so map them
    # before these same code points are used as classification markers.
    mapping = [(code_point_character_class(reserved), other)]
    for signature, marker in markers.items():
        for pattern in split_character_classes(points_by_signature[signature]):
            mapping.append((pattern, marker))
    mapping.append((code_point_character_class(reserved, negate=True), other))
    return mapping, markers


def hangul_pattern(marker_class):
    lead, vowel, tail, lv, lvt = (
        marker_class(name) for name in ("L", "V", "T", "LV", "LVT")
    )
    medial = alternate_patterns(vowel + "+", lv + vowel + "*", lvt)
    return alternate_patterns(lead + "*" + medial + tail + "*", lead + "+", tail + "+")


def joined_emoji_pattern(marker_class):
    emoji = marker_class("Extended_Pictographic")
    join = marker_class("Extend") + "*" + marker_class("ZWJ") + emoji
    return emoji + noncapturing_group(join) + "*"


def indic_conjunct_pattern(marker_class):
    consonant = marker_class("InCB:Consonant")
    linker = marker_class("InCB:Linker")
    modifier = marker_class("InCB:Extend", "InCB:Linker")
    join = modifier + "*" + linker + modifier + "*" + consonant
    return consonant + noncapturing_group(join) + "+"


def grapheme_pattern(markers):
    def marker_character_class(*names, negate=False):
        selected = {
            marker for signature, marker in markers.items()
            if any(name in signature for name in names)
        }
        return code_point_character_class(selected, negate)

    # UAX #29 Unicode 16, Tables 1b and 1c. Ordered alternatives and greedy
    # repetitions select the next complete grapheme from a known boundary.
    flag = marker_character_class("Regional_Indicator") + "{2}"
    controls = ("CR", "LF", "Control")
    core = alternate_patterns(
        hangul_pattern(marker_character_class),
        flag,
        joined_emoji_pattern(marker_character_class),
        indic_conjunct_pattern(marker_character_class),
        marker_character_class(*controls, negate=True),
    )
    prepend = marker_character_class("Prepend") + "*"
    trailing = marker_character_class("Extend", "ZWJ", "SpacingMark") + "*"
    return alternate_patterns(
        marker_character_class("CR") + marker_character_class("LF"),
        marker_character_class(*controls),
        prepend + core + trailing,
    )


def check_emulator_regex_lengths(mapping, pattern):
    expressions = [pattern, *(regex for regex, _ in mapping)]
    if any(len(regex) >= EMULATOR_REGEX_LENGTH_LIMIT for regex in expressions):
        raise ValueError("A generated expression exceeds the emulator regex limit")


def render_mapping_function(name, replacements):
    lines = [f"    function {name}(body) {{", "      return body"]
    for regex, marker in replacements:
        lines.append(f"        .replace('{escape_rules_regex(regex)}', '\\u{marker:04X}')")
    lines[-1] += ";"
    return [*lines, "    }"]


def render_classification_function(mapping_function_names):
    lines = ["    function classifyGraphemeSymbols(body) {"]
    source = "body"
    for index, name in enumerate(mapping_function_names[:-1], start=1):
        result = f"symbolsAfterPass{index}"
        lines.append(f"      let {result} = {name}({source});")
        source = result
    lines.append(f"      return {mapping_function_names[-1]}({source});")
    return [*lines, "    }"]


def render_count_function(pattern):
    return [
        "    function countGraphemes(body) {",
        "      let symbols = classifyGraphemeSymbols(body);",
        f"      let graphemeMarkers = symbols.replace('{escape_rules_regex(pattern)}', 'x');",
        "      return graphemeMarkers.size();",
        "    }",
    ]


def render_rules(mapping, pattern):
    lines = [START, "    // Regenerate with tests/firestore/generate_grapheme_rules.py."]
    mapping_function_names = []
    for index in range(0, len(mapping), REPLACEMENTS_PER_FUNCTION):
        name = f"mapGraphemeClasses{index // REPLACEMENTS_PER_FUNCTION}"
        replacements = mapping[index:index + REPLACEMENTS_PER_FUNCTION]
        lines.extend(render_mapping_function(name, replacements))
        mapping_function_names.append(name)
    lines.extend(render_classification_function(mapping_function_names))
    lines.extend(render_count_function(pattern))
    return "\n".join([*lines, END])


def generate(directory):
    mapping, markers = build_mapping(load_properties(directory))
    pattern = grapheme_pattern(markers)
    check_emulator_regex_lengths(mapping, pattern)
    return render_rules(mapping, pattern)


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
