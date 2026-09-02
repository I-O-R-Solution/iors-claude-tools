#!/usr/bin/env python
# ---------------------------------------------------------------------------
# T8-Mock-Server: minimaler Anthropic-Messages-Endpunkt fuer den Offline-Test
# t8-resume-thinking.sh. Er beantwortet jede /v1/messages-Anfrage mit einer
# festen Antwort, die einen Thinking-Block mit eindeutigem Marker enthaelt,
# und protokolliert JEDEN Request-Body als eine JSONL-Zeile.
#
# Kein Netz, kein Key, kein Moonshot: gemessen wird ausschliesslich, WAS der
# Claude-Code-Client bei --resume zurueckschickt.
#
# Aufruf: python t8-mock-server.py <requests.jsonl> <port-datei>
#   - bindet 127.0.0.1:0 (freier Port), schreibt den Port in <port-datei>
#   - laeuft bis SIGTERM/Prozessende
# ---------------------------------------------------------------------------
import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REQ_LOG = sys.argv[1]
PORT_FILE = sys.argv[2]

THINKING_MARKER = "T8-THINKING-MARKER-8f3a1c"
SIGNATURE = "T8SIG-8f3a1c"
ANSWER_TEXT = "T8-ANTWORT: verstanden."

LOG_LOCK = threading.Lock()


def sse(event, data):
    return f"event: {event}\ndata: {json.dumps(data)}\n\n".encode("utf-8")


def build_message(msg_id):
    return {
        "id": msg_id,
        "type": "message",
        "role": "assistant",
        "model": "k3",
        "content": [
            {"type": "thinking", "thinking": THINKING_MARKER, "signature": SIGNATURE},
            {"type": "text", "text": ANSWER_TEXT},
        ],
        "stop_reason": "end_turn",
        "stop_sequence": None,
        "usage": {"input_tokens": 25, "output_tokens": 12},
    }


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "T8Mock/1.0"

    def log_message(self, fmt, *args):  # Konsole still halten
        pass

    def handle(self):
        # Der Client schliesst Keep-Alive-Verbindungen hart - das ist normal
        # und kein Testfehler; ohne diesen Fang spammt jeder Lauf Tracebacks.
        try:
            super().handle()
        except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError):
            pass

    def _json(self, code, obj):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.rstrip("/").endswith("/health"):
            self._json(200, {"ok": True})
        else:
            # z.B. Modell-Listen o.ae. - freundlich leer beantworten
            self._json(200, {"data": []})

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length) if length else b""
        try:
            body = json.loads(raw.decode("utf-8")) if raw else {}
        except Exception:
            body = {"_unparsed": raw.decode("utf-8", "replace")}

        path = self.path.split("?")[0].rstrip("/")

        with LOG_LOCK:
            with open(REQ_LOG, "a", encoding="utf-8") as f:
                f.write(json.dumps({"path": path, "body": body}, ensure_ascii=False) + "\n")

        if path.endswith("/count_tokens"):
            self._json(200, {"input_tokens": 100})
            return

        if not path.endswith("/messages"):
            self._json(200, {"ok": True})
            return

        msg_id = "msg_t8_%d" % threading.get_ident()
        message = build_message(msg_id)

        if not body.get("stream"):
            self._json(200, message)
            return

        # SSE-Stream: message_start -> thinking-Block -> text-Block -> stop
        chunks = b"".join([
            sse("message_start", {"type": "message_start", "message": {
                "id": msg_id, "type": "message", "role": "assistant", "model": "k3",
                "content": [], "stop_reason": None, "stop_sequence": None,
                "usage": {"input_tokens": 25, "output_tokens": 1},
            }}),
            sse("content_block_start", {"type": "content_block_start", "index": 0,
                "content_block": {"type": "thinking", "thinking": "", "signature": ""}}),
            sse("content_block_delta", {"type": "content_block_delta", "index": 0,
                "delta": {"type": "thinking_delta", "thinking": THINKING_MARKER}}),
            sse("content_block_delta", {"type": "content_block_delta", "index": 0,
                "delta": {"type": "signature_delta", "signature": SIGNATURE}}),
            sse("content_block_stop", {"type": "content_block_stop", "index": 0}),
            sse("content_block_start", {"type": "content_block_start", "index": 1,
                "content_block": {"type": "text", "text": ""}}),
            sse("content_block_delta", {"type": "content_block_delta", "index": 1,
                "delta": {"type": "text_delta", "text": ANSWER_TEXT}}),
            sse("content_block_stop", {"type": "content_block_stop", "index": 1}),
            sse("message_delta", {"type": "message_delta",
                "delta": {"stop_reason": "end_turn", "stop_sequence": None},
                "usage": {"output_tokens": 12}}),
            sse("message_stop", {"type": "message_stop"}),
        ])
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Content-Length", str(len(chunks)))
        self.end_headers()
        self.wfile.write(chunks)


def main():
    srv = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    with open(PORT_FILE, "w", encoding="utf-8") as f:
        f.write(str(srv.server_address[1]))
    srv.serve_forever()


if __name__ == "__main__":
    main()
