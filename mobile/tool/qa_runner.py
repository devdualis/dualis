import subprocess
import time
import os
import re
import xml.etree.ElementTree as ET

SCREENSHOTS_DIR = "/Users/ricardorincon/workspace/dualis/docs/qa-screenshots"
DEVICE_ID = "emulator-5554"

os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

class QARunner:
    def __init__(self):
        self.device = DEVICE_ID
        self.findings = []
        self.step_counter = 1

    def adb(self, *args):
        cmd = ["adb", "-s", self.device] + list(args)
        res = subprocess.run(cmd, capture_output=True, text=True)
        return res.stdout.strip()

    def screenshot(self, name):
        filename = f"{self.step_counter:02d}_{name}.png"
        path = os.path.join(SCREENSHOTS_DIR, filename)
        cmd = f"adb -s {self.device} exec-out screencap -p > '{path}'"
        subprocess.run(cmd, shell=True)
        print(f"📸 Screenshot saved: {filename}")
        self.step_counter += 1
        return filename

    def dump_ui(self):
        self.adb("shell", "uiautomator", "dump", "/sdcard/window_dump.xml")
        raw = subprocess.check_output(
            ["adb", "-s", self.device, "exec-out", "cat", "/sdcard/window_dump.xml"]
        ).decode("utf-8", errors="ignore")
        try:
            return ET.fromstring(raw)
        except Exception as e:
            print(f"Error parsing UI XML: {e}")
            return None

    def find_nodes(self, root, desc_regex=None, text_regex=None, class_name=None):
        if root is None:
            return []
        matches = []
        for node in root.iter("node"):
            desc = node.attrib.get("content-desc", "")
            text = node.attrib.get("text", "")
            cls = node.attrib.get("class", "")

            if desc_regex and not re.search(desc_regex, desc, re.IGNORECASE):
                continue
            if text_regex and not re.search(text_regex, text, re.IGNORECASE):
                continue
            if class_name and cls != class_name:
                continue
            matches.append(node)
        return matches

    def get_center(self, node):
        bounds = node.attrib.get("bounds", "")
        m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
        if m:
            x1, y1, x2, y2 = map(int, m.groups())
            return (x1 + x2) // 2, (y1 + y2) // 2
        return None, None

    def tap(self, x, y, delay=1.0):
        print(f"👉 Tapping ({x}, {y})")
        self.adb("shell", "input", "tap", str(x), str(y))
        time.sleep(delay)

    def tap_node(self, node, delay=1.0):
        cx, cy = self.get_center(node)
        if cx is not None:
            desc = node.attrib.get("content-desc") or node.attrib.get("text") or "node"
            print(f"👉 Tapping [{desc[:30]}] at ({cx}, {cy})")
            self.tap(cx, cy, delay=delay)
            return True
        return False

    def type_text(self, text, delay=0.8):
        # Escape spaces for adb input
        escaped = text.replace(" ", "%s")
        print(f"⌨️ Typing: {text}")
        self.adb("shell", "input", "text", escaped)
        time.sleep(delay)

    def keyevent(self, code, delay=0.5):
        self.adb("shell", "input", "keyevent", str(code))
        time.sleep(delay)

    def swipe(self, x1, y1, x2, y2, duration=300, delay=1.0):
        print(f"👆 Swiping ({x1},{y1}) -> ({x2},{y2})")
        self.adb("shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration))
        time.sleep(delay)

    def log_finding(self, category, title, description, severity="MEDIUM"):
        self.findings.append({
            "category": category,
            "title": title,
            "description": description,
            "severity": severity,
            "step": self.step_counter
        })
        print(f"⚠️ FINDING [{severity}] {category} - {title}: {description}")

print("QARunner loaded successfully.")
