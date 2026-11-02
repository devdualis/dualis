import http.server
import subprocess
import urllib.parse
import os
import sys

DEVICE = 'D61209E8-B8D6-4659-8A29-D41921ED5FAE'
OUT_DIR = '/tmp/dualis-mockups'
os.makedirs(OUT_DIR, exist_ok=True)

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        name = query.get('name', ['screen'])[0]
        out_path = os.path.join(OUT_DIR, f'{name}.png')
        try:
            subprocess.run(['xcrun', 'simctl', 'io', DEVICE, 'screenshot', out_path], check=True, capture_output=True)
            print(f'Captured: {out_path}', flush=True)
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'OK')
        except Exception as e:
            print(f'Error capturing {name}: {e}', file=sys.stderr, flush=True)
            self.send_response(500)
            self.end_headers()

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = http.server.HTTPServer(('127.0.0.1', 8999), Handler)
    print('Screenshot server ready on 127.0.0.1:8999', flush=True)
    server.serve_forever()
