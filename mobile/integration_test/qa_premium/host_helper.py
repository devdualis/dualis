#!/usr/bin/env python3
"""Host-side helper for the Premium QA integration tests.

The app under test runs on the iOS Simulator, which shares the Mac's
network, so the test calls http://127.0.0.1:8999/... to ask the Mac to:

  /shot?name=X           save a screenshot as <out>/X.png
  /face?r=match|nomatch  simulate a Face ID match / no-match
  /enroll?v=1|0          enroll / un-enroll Face ID
  /video/start?name=X    start recording <out>/X.mp4 (one at a time)
  /video/stop            stop the recording (SIGINT)
  /bg?secs=N             send the app to the background (opens Settings),
                         then bring it back after N seconds
  /log?msg=...           print a line in this helper's log

Add delay=<ms> to run the action later in a thread (the request returns
at once). Usage: host_helper.py <udid> <bundle-id> <out-dir> [port]
"""
import os
import signal
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

UDID, BUNDLE, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
PORT = int(sys.argv[4]) if len(sys.argv) > 4 else 8999
os.makedirs(OUT, exist_ok=True)
video = {"proc": None}


def sim(*args):
    return subprocess.run(["xcrun", "simctl", *args], capture_output=True, text=True)


def log(msg):
    print(time.strftime("%H:%M:%S"), msg, flush=True)


def shot(name):
    r = sim("io", UDID, "screenshot", os.path.join(OUT, f"{name}.png"))
    log(f"shot {name} rc={r.returncode} {r.stderr.strip()[-120:]}")


def face(result):
    key = "match" if result == "match" else "nomatch"
    sim("spawn", UDID, "notifyutil", "-p", f"com.apple.BiometricKit_Sim.pearl.{key}")
    log(f"face {key}")


def enroll(v):
    sim("spawn", UDID, "notifyutil", "-s", "com.apple.BiometricKit.enrollmentChanged", v)
    sim("spawn", UDID, "notifyutil", "-p", "com.apple.BiometricKit.enrollmentChanged")
    log(f"enroll {v}")


def video_start(name):
    video_stop()
    path = os.path.join(OUT, f"{name}.mp4")
    if os.path.exists(path):
        os.remove(path)
    video["proc"] = subprocess.Popen(
        ["xcrun", "simctl", "io", UDID, "recordVideo", "--codec=h264", "--force", path],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1.5)  # recorder needs a moment before the first frame
    log(f"video start {name} pid={video['proc'].pid}")


def video_stop():
    p = video["proc"]
    if p is None:
        return
    p.send_signal(signal.SIGINT)
    try:
        p.wait(timeout=15)
    except subprocess.TimeoutExpired:
        p.kill()
    video["proc"] = None
    log("video stop")


def background(secs):
    sim("launch", UDID, "com.apple.Preferences")
    log(f"app in background for {secs}s")
    time.sleep(secs)
    sim("launch", UDID, BUNDLE)
    log("app back in foreground")


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_GET(self):
        u = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(u.query).items()}
        actions = {
            "/shot": lambda: shot(q["name"]),
            "/face": lambda: face(q.get("r", "match")),
            "/enroll": lambda: enroll(q.get("v", "1")),
            "/video/start": lambda: video_start(q["name"]),
            "/video/stop": video_stop,
            "/bg": lambda: background(float(q.get("secs", "5"))),
            "/log": lambda: log("app: " + q.get("msg", "")),
        }
        action = actions.get(u.path)
        if action is None:
            self.send_response(404)
            self.end_headers()
            return
        delay = float(q.get("delay", "0")) / 1000
        if delay > 0 or u.path == "/bg":
            def later():
                time.sleep(max(delay, 0.3))
                action()
            threading.Thread(target=later, daemon=True).start()
        else:
            action()
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")


log(f"host helper on :{PORT} udid={UDID} out={OUT}")
try:
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
finally:
    video_stop()
