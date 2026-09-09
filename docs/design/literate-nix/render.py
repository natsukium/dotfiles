import html
import json
import subprocess
import sys

import markdown

path = sys.argv[1]
segments = [
    json.loads(l)
    for l in subprocess.run(
        [sys.executable, "extract.py", path], capture_output=True, text=True, check=True
    ).stdout.splitlines()
]
titles = {s["id"]: s["title"] for s in segments}


def code_html(code):
    return html.escape(code)


rows = []
for s in segments:
    prose = markdown.markdown(s["doc"])
    if s["kind"] == "free":
        rows.append(
            f'<section class="row free" id="seg-{s["id"]}"><div class="prose">{prose}</div><div class="code"></div></section>'
        )
        continue
    label = s["path"] if s["is_binding"] else f"in {s['path']}"
    rows.append(f"""
<section class="row" id="seg-{s["id"]}">
  <div class="prose">{prose}</div>
  <div class="code"><span class="label">{html.escape(label)} · line {s["line"]}</span>
  <pre><code class="language-nix">{code_html(s["code"])}</code></pre></div>
</section>""")

refs = json.dumps({str(k): v for k, v in titles.items()}, ensure_ascii=False)

page = f"""<title>Literate Nix Preview</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Newsreader:ital,opsz,wght@0,6..72,400;0,6..72,500;1,6..72,400&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
:root {{
  --ground: #f7f6f2; --ink: #22262c; --muted: #6d7380; --rule: #dedbd2;
  --code-bg: #eceef2; --accent: #4a6fb5; --label: #5f6e8a; --ref-bg: #dfe6f3;
  --hl-kw: #7a4bb5; --hl-str: #1d7a5b; --hl-num: #b5581a; --hl-attr: #2c5aa8; --hl-cmt: #8a8f9a;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{
  --ground: #16191e; --ink: #e4e6ea; --muted: #9aa1ad; --rule: #2c313a;
  --code-bg: #1e232b; --accent: #7ebae4; --label: #9fb4d6; --ref-bg: #2a3a52;
  --hl-kw: #c39be8; --hl-str: #7fd1b0; --hl-num: #f0a56b; --hl-attr: #8fb4f0; --hl-cmt: #6f7684;
}} }}
:root[data-theme="dark"] {{
  --ground: #16191e; --ink: #e4e6ea; --muted: #9aa1ad; --rule: #2c313a;
  --code-bg: #1e232b; --accent: #7ebae4; --label: #9fb4d6; --ref-bg: #2a3a52;
  --hl-kw: #c39be8; --hl-str: #7fd1b0; --hl-num: #f0a56b; --hl-attr: #8fb4f0; --hl-cmt: #6f7684;
}}
body {{ background: var(--ground); color: var(--ink); font-family: "Newsreader", Georgia, serif; font-size: 17px; line-height: 1.55; }}
a {{ color: var(--accent); }}
header {{ max-width: 1180px; margin: 0 auto; padding: 40px 32px 16px; display: flex; align-items: baseline; gap: 16px; border-bottom: 1px solid var(--rule); }}
header h1 {{ margin: 0; font-size: 22px; font-weight: 500; }}
header .file {{ font-family: "IBM Plex Mono", ui-monospace, monospace; font-size: 13px; color: var(--muted); }}
main {{ max-width: 1180px; margin: 0 auto; padding: 0 32px 64px; }}
.row {{ display: grid; grid-template-columns: minmax(0, 36ch) minmax(0, 1fr); gap: 32px; padding: 28px 0; border-bottom: 1px solid var(--rule); }}
.row:last-child {{ border-bottom: 0; }}
.free {{ padding-top: 36px; }}
.prose h1 {{ font-size: 30px; font-weight: 500; margin: 0 0 10px; line-height: 1.2; text-wrap: balance; }}
.prose h2 {{ font-size: 23px; font-weight: 500; margin: 0 0 8px; line-height: 1.25; text-wrap: balance; }}
.prose h3 {{ font-size: 18px; font-weight: 500; margin: 0 0 6px; color: var(--label); }}
.prose p {{ margin: 0 0 10px; }}
.prose p:last-child {{ margin-bottom: 0; }}
.prose code {{ font-family: "IBM Plex Mono", ui-monospace, monospace; font-size: 0.82em; background: var(--code-bg); padding: 1px 4px; border-radius: 3px; }}
.code {{ min-width: 0; display: flex; flex-direction: column; gap: 6px; }}
.label {{ font-family: "IBM Plex Mono", ui-monospace, monospace; font-size: 12px; letter-spacing: 0.04em; color: var(--label); }}
pre {{ margin: 0; background: var(--code-bg); border-radius: 4px; padding: 12px 14px; overflow-x: auto; font-family: "IBM Plex Mono", ui-monospace, monospace; font-size: 13px; line-height: 1.5; }}
a.ref {{ background: var(--ref-bg); color: var(--accent); text-decoration: none; padding: 0 6px; border-radius: 3px; font-style: italic; }}
a.ref:hover, a.ref:focus-visible {{ text-decoration: underline; outline: none; }}
.hljs-keyword, .hljs-built_in {{ color: var(--hl-kw); }}
.hljs-string {{ color: var(--hl-str); }}
.hljs-number, .hljs-literal {{ color: var(--hl-num); }}
.hljs-attr {{ color: var(--hl-attr); }}
.hljs-comment {{ color: var(--hl-cmt); font-style: italic; }}
@media (max-width: 720px) {{ .row {{ grid-template-columns: 1fr; gap: 12px; }} }}
</style>
<header><h1>Literate Nix</h1><span class="file">{html.escape(path)}</span></header>
<main>{"".join(rows)}
</main>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/nix.min.js"></script>
<script>
const refs = {refs};
for (const el of document.querySelectorAll("code.language-nix")) {{
  const out = hljs.highlight(el.textContent, {{ language: "nix" }}).value;
  el.innerHTML = out.replace(/⟦(\\d+)⟧/g, (_, id) => `<a class="ref" href="#seg-${{id}}">‹${{refs[id]}}›</a>`);
}}
</script>
"""
open("preview.html", "w").write(page)
