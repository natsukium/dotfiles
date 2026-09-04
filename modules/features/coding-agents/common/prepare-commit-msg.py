import json
import os
import pathlib
import subprocess
import sys

MODEL_OVERRIDES = {
    "gpt-5.6-luna": "GPT 5.6 Luna",
    "gpt-5.6-sol": "GPT 5.6 Sol",
    "muse-spark-1.2-contributor-free": "Muse Spark 1.2",
    "muse-spark-1.3-contributor-free": "Muse Spark 1.3",
}


def display_name(model):
    for key in (model, model.rsplit("/", 1)[-1]):
        if key in MODEL_OVERRIDES:
            return MODEL_OVERRIDES[key]

    # Claude IDs follow "claude-<family>-<version>[-<date>]", so they parse
    # mechanically instead of needing a per-release table entry.
    parts = model.split("-")
    if parts and parts[0] == "claude":
        rest = parts[1:]
        # Dated snapshots like claude-opus-5-20251101 fold into their base
        # alias.
        if rest and rest[-1].isdigit() and len(rest[-1]) >= 8:
            rest = rest[:-1]
        if rest:
            version = ".".join(p for p in rest[1:] if p.isdigit())
            return f"{rest[0].capitalize()} {version}".strip()

    return model


def claude_model():
    session_id = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if not session_id:
        return None
    # Claude Code derives its project directory from $PWD by replacing
    # "/", "." and "_" with "-".
    slug = os.getcwd().replace("/", "-").replace(".", "-").replace("_", "-")
    transcript = pathlib.Path.home() / ".claude" / "projects" / slug / f"{session_id}.jsonl"
    model = None
    try:
        with transcript.open(encoding="utf-8") as fh:
            for line in fh:
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                value = entry.get("message", {}).get("model")
                if value:
                    model = value
    except OSError:
        return None
    return model


def main():
    msg_file, source = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else ""

    # merge, squash, and amend keep their original message untouched; amend
    # already carries the trailer from the original commit.
    if source in ("merge", "squash", "commit"):
        return

    if os.environ.get("PI_CODING_AGENT"):
        agent = f"Pi Coding Agent:{display_name(os.environ.get('PI_MODEL', 'unknown'))}"
    elif os.environ.get("CLAUDECODE"):
        model = claude_model()
        # A missing transcript degrades to a bare agent name rather than
        # failing the commit.
        agent = ("Claude Code:" + display_name(model)) if model else "Claude Code"
    else:
        return

    subprocess.run(
        [
            "git",
            "interpret-trailers",
            "--in-place",
            "--trailer",
            f"Assisted-by: {agent}",
            msg_file,
        ],
        check=True,
    )


main()
