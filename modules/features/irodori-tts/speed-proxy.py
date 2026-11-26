import json
import os
import subprocess
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LISTEN_HOST = os.environ["LISTEN_HOST"]
LISTEN_PORT = int(os.environ["LISTEN_PORT"])
UPSTREAM = os.environ["UPSTREAM"]
FFMPEG = os.environ["FFMPEG"]

# Encoder arguments per OpenAI response_format.
FORMATS = {
    "mp3": (["-f", "mp3"], "audio/mpeg"),
    "opus": (["-c:a", "libopus", "-f", "ogg"], "audio/ogg"),
    "aac": (["-c:a", "aac", "-f", "adts"], "audio/aac"),
    "flac": (["-f", "flac"], "audio/flac"),
    "wav": (["-f", "wav"], "audio/wav"),
    "pcm": (["-f", "s16le", "-c:a", "pcm_s16le"], "audio/pcm"),
}


def atempo_chain(speed):
    # Each atempo stage is only exact between 0.5 and 2.0.
    stages = []
    while speed > 2.0:
        stages.append(2.0)
        speed /= 2.0
    while speed < 0.5:
        stages.append(0.5)
        speed /= 0.5
    stages.append(speed)
    return ",".join(f"atempo={s:.6f}" for s in stages)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        pass

    def forward(self, body):
        headers = {
            k: v
            for k, v in self.headers.items()
            if k.lower() in ("content-type", "authorization", "accept")
        }
        req = urllib.request.Request(
            UPSTREAM + self.path, data=body, headers=headers, method=self.command
        )
        try:
            with urllib.request.urlopen(req, timeout=600) as resp:
                return resp.status, resp.headers.get("Content-Type"), resp.read()
        except urllib.error.HTTPError as e:
            return e.code, e.headers.get("Content-Type"), e.read()

    def reply(self, status, content_type, body):
        self.send_response(status)
        if content_type:
            self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def handle_any(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        if self.command == "POST" and self.path.split("?")[0] == "/v1/audio/speech":
            try:
                payload = json.loads(body)
            except (TypeError, ValueError):
                payload = None
            speed = float(payload.get("speed", 1.0)) if isinstance(payload, dict) else 1.0
            fmt = payload.get("response_format", "mp3") if isinstance(payload, dict) else None
            if speed != 1.0 and fmt in FORMATS and not payload.get("stream_format"):
                payload["speed"] = 1.0
                payload["response_format"] = "wav"
                status, ctype, audio = self.forward(json.dumps(payload).encode())
                if status != 200:
                    return self.reply(status, ctype, audio)
                args, ctype = FORMATS[fmt]
                proc = subprocess.run(
                    [
                        FFMPEG,
                        "-loglevel",
                        "error",
                        "-i",
                        "pipe:0",
                        "-filter:a",
                        atempo_chain(speed),
                        *args,
                        "pipe:1",
                    ],
                    input=audio,
                    capture_output=True,
                    check=False,
                )
                if proc.returncode != 0:
                    return self.reply(502, "text/plain", proc.stderr)
                return self.reply(200, ctype, proc.stdout)
        self.reply(*self.forward(body))

    do_GET = do_POST = do_PUT = do_DELETE = handle_any


ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler).serve_forever()
