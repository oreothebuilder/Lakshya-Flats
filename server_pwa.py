import http.server
import socketserver
import os
import sys

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")

class PWAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Allow cross-origin requests for testing and service workers
        self.send_header('Access-Control-Allow-Origin', '*')
        # Disable cache on index.html during development/testing
        if self.path == '/' or self.path.endswith('index.html'):
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def guess_type(self, path):
        if path.endswith('.json') or path.endswith('manifest.json'):
            return 'application/manifest+json'
        if path.endswith('.js'):
            return 'application/javascript'
        if path.endswith('.wasm'):
            return 'application/wasm'
        return super().guess_type(path)

if __name__ == '__main__':
    os.chdir(DIRECTORY)
    # Allow port reuse
    socketserver.TCPServer.allow_reuse_address = True
    try:
        with socketserver.TCPServer(("0.0.0.0", PORT), PWAHandler) as httpd:
            print(f"LAKSHYA_PWA_SERVER_RUNNING on port {PORT}", flush=True)
            print(f"Local URL: http://localhost:{PORT}", flush=True)
            print(f"Network URL for iPhone testing: http://10.55.123.120:{PORT}", flush=True)
            httpd.serve_forever()
    except Exception as e:
        print(f"Error starting server: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
