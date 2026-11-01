#!/usr/bin/env python3
"""Applies the Thundermist name to a copy of the source, just before it is built.

The repository keeps upstream's text, so merging upstream stays clean and new
upstream text is renamed automatically. Only string literals change, and only
where "Crest" is a standalone word; type names, comments, resource markers and
dotted identifiers such as "Crest.ReaderMode" keep their spelling.

usage: thundermist-rebrand.py <source-root>           rewrite the copy in place
       thundermist-rebrand.py <source-root> --report  print what would change
"""
import json
import pathlib
import re
import sys

OLD = "Crest"
NEW = "Thundermist"
CODE_ROOTS = ("CrestShared", "CrestMac", "CrestAgents", "CrestAgentHelper", "CrestDockTilePlugin", "CrestCore/src",
              "CrestEngines")
CATALOG = "CrestShared/Resources/Localizable.xcstrings"
RELEASE_NOTES = "Documentation/ReleaseNotes.json"

# A standalone word: not part of a longer name, a dotted or hyphenated identifier,
# or a path.
WORD = re.compile(r"(?<![\w.\-/])Crest(?![\w\-/]|\.[A-Za-z_])")
LITERAL = re.compile(r'"(?:[^"\\\n]|\\.)*"')

# Text about the medieval emblem rather than the product. These stay until the
# theming work removes or rewords them.
EMBLEM_TEXT = {
    "Crest",
    "Crest colors",
    "Crest Studio",
    "Crest Studio step",
    "Choose Crest under Emblem to color the crest",
    "A simplified Crest branding preview",
    "Every change appears in the Crest branding preview.",
    "Edit Crest…",
    "Crest preview",
}
# Literals the program itself reads or matches, or test data, not text a person sees.
NOT_DISPLAY_TEXT = {
    "Crest session storage",
    "Crest sync staging",
    "Crest Adoption",
    "^Crest[A-Z][a-z]{1,20}$",
}
# Sample content that only showcase launches and previews show.
FIXTURE_FILES = ("Fixture", "Showcase")
# A bare "Crest" that does name the product, in the files where it does.
PRODUCT_WORD_FILES = {"BrowserGettingStartedPracticeWindow.swift"}


def renamed(text, path_name=""):
    """The text with the product renamed, or the same text when it must stay."""
    if text in EMBLEM_TEXT and not (text == OLD and path_name in PRODUCT_WORD_FILES):
        return text
    if text in NOT_DISPLAY_TEXT or not WORD.search(text):
        return text
    return WORD.sub(NEW, text)


def rewrite_code(path):
    changes = []
    if any(part in path.name for part in FIXTURE_FILES):
        return None, changes
    out = []
    in_block = False
    for line in path.read_text(encoding="utf-8").splitlines(keepends=True):
        stripped = line.lstrip()
        opens_or_closes = line.count('"""') % 2 == 1
        if in_block:
            # A multi-line literal: its lines hold text without their own quotes.
            new = renamed(line.rstrip("\n"), path.name) + ("\n" if line.endswith("\n") else "")
            if new != line:
                changes.append((line.strip(), new.strip()))
            out.append(new)
            in_block = not opens_or_closes
            continue
        if stripped.startswith(("//", "*", "/*")):
            out.append(line)
            continue
        if opens_or_closes:
            in_block = True
            out.append(line)
            continue

        def replace(match):
            body = match.group(0)[1:-1]
            new = renamed(body, path.name)
            if new != body:
                changes.append((body, new))
            return f'"{new}"'

        out.append(LITERAL.sub(replace, line))
    return "".join(out), changes


def rename_catalog_value(node):
    """Renames every stringUnit value below this catalog node."""
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "value" and isinstance(value, str):
                node[key] = renamed(value)
            else:
                rename_catalog_value(value)
    elif isinstance(node, list):
        for item in node:
            rename_catalog_value(item)


def rewrite_catalog(path):
    catalog = json.loads(path.read_text(encoding="utf-8"))
    strings = {}
    changes = 0
    for key, entry in catalog["strings"].items():
        new_key = renamed(key)
        changes += new_key != key
        rename_catalog_value(entry)
        strings[new_key] = entry
    catalog["strings"] = strings
    return json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", changes


def rewrite_release_notes(path):
    notes = json.loads(path.read_text(encoding="utf-8"))
    changes = 0
    for entry in notes["entries"].values():
        new = renamed(entry["message"])
        changes += new != entry["message"]
        entry["message"] = new
    return json.dumps(notes, ensure_ascii=False, indent=2) + "\n", changes


def main():
    root = pathlib.Path(sys.argv[1]).resolve()
    report = "--report" in sys.argv[2:]
    seen = {}
    files = 0
    for folder in CODE_ROOTS:
        base = root / folder
        if not base.is_dir():
            continue
        for path in sorted([*base.rglob("*.swift"), *base.rglob("*.cs")]):
            if {"bin", "obj"}.intersection(path.parts):
                continue
            text, changes = rewrite_code(path)
            if not changes:
                continue
            files += 1
            for body, _ in changes:
                seen.setdefault(body, path.name)
            if not report:
                path.write_text(text, encoding="utf-8")

    catalog_text, catalog_changes = rewrite_catalog(root / CATALOG)
    notes_text, notes_changes = rewrite_release_notes(root / RELEASE_NOTES)
    if report:
        for body, name in sorted(seen.items()):
            print(f"{name[:44]:44} {body[:110]}")
    else:
        (root / CATALOG).write_text(catalog_text, encoding="utf-8")
        (root / RELEASE_NOTES).write_text(notes_text, encoding="utf-8")
    print(f"{NEW}: {files} code files ({len(seen)} distinct literals), "
          f"{catalog_changes} catalog keys, {notes_changes} release notes.")


if __name__ == "__main__":
    main()
