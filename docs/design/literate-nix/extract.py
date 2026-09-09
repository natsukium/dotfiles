import json
import re
import sys

from tree_sitter_language_pack import get_parser

src = open(sys.argv[1], "rb").read()
tree = get_parser("nix").parse(src)


def text(n):
    return src[n.start_byte : n.end_byte].decode()


def strip_doc(c):
    lines = c[3:-2].splitlines()
    indent = min((len(l) - len(l.lstrip()) for l in lines if l.strip()), default=0)
    return "\n".join(l[indent:] for l in lines).strip()


def path_of(n):
    parts = []
    while n is not None:
        if n.type == "binding":
            parts.append(text(n.child_by_field_name("attrpath")))
        n = n.parent
    return ".".join(reversed(parts))


def dedent(s):
    lines = s.splitlines()
    indent = min((len(l) - len(l.lstrip()) for l in lines if l.strip()), default=0)
    return "\n".join(l[indent:] for l in lines).strip("\n").rstrip()


def heading(doc):
    m = re.match(r"#+\s*(.+)", doc)
    return m.group(1).strip() if m else None


def docs(n):
    prev = None
    for c in n.children:
        if prev is not None and prev.type == "comment":
            body = text(prev)
            if body.startswith("/*!"):
                yield {"kind": "free", "comment": prev, "target": None}
            elif body.startswith("/**"):
                t = c
                while t.type == "binding_set":
                    t = t.children[0]
                yield {"kind": "attached", "comment": prev, "target": t}
        yield from docs(c)
        prev = c


found = sorted(docs(tree.root_node), key=lambda d: d["comment"].start_byte)
for i, d in enumerate(found):
    d["id"] = i
    d["doc"] = strip_doc(text(d["comment"]))
    d["title"] = heading(d["doc"]) or (path_of(d["target"]) if d["target"] is not None else "")


def elided_code(d):
    t = d["target"]
    holes = []
    for o in found:
        if o is d:
            continue
        lo = o["comment"].start_byte
        hi = o["target"].end_byte if o["target"] is not None else o["comment"].end_byte
        if lo >= t.start_byte and hi <= t.end_byte:
            holes.append((lo, hi, o))
    holes.sort()
    line_start = src.rfind(b"\n", 0, t.start_byte) + 1
    lead = src[line_start : t.start_byte]
    out, cursor = (lead if not lead.strip() else b""), t.start_byte
    for lo, hi, o in holes:
        if lo < cursor:
            continue
        out += src[cursor:lo]
        if o["kind"] == "attached":
            out += f"⟦{o['id']}⟧".encode()
        cursor = hi
    out += src[cursor : t.end_byte]
    return dedent(out.decode())


for d in found:
    t = d["target"]
    print(
        json.dumps(
            {
                "id": d["id"],
                "kind": d["kind"],
                "title": d["title"],
                "doc": d["doc"],
                "path": path_of(t) if t is not None else None,
                "is_binding": t is not None and t.type == "binding",
                "line": t.start_point[0] + 1 if t is not None else d["comment"].start_point[0] + 1,
                "code": elided_code(d) if t is not None else None,
            },
            ensure_ascii=False,
        )
    )
