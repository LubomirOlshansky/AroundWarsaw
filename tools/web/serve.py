"""Serve build/web locally with the headers the threaded web build needs (COOP/COEP).

Usage: python3 -I tools/web/serve.py [port]   (default 8060), then http://localhost:8060
"""

import functools
import http.server
import sys
from pathlib import Path

WEB = Path(__file__).resolve().parent.parent.parent / "build" / "web"


class Handler(http.server.SimpleHTTPRequestHandler):
	def end_headers(self) -> None:
		self.send_header("Cross-Origin-Opener-Policy", "same-origin")
		self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
		self.send_header("Cache-Control", "no-cache")
		super().end_headers()


if __name__ == "__main__":
	port = int(sys.argv[1]) if len(sys.argv) > 1 else 8060
	handler = functools.partial(Handler, directory=str(WEB))
	print(f"serving {WEB} at http://localhost:{port}")
	http.server.ThreadingHTTPServer(("127.0.0.1", port), handler).serve_forever()
