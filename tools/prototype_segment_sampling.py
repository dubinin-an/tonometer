#!/usr/bin/env python3
"""Print seven-segment darkness scores for rectified diagnostic LCD crops."""

import json
from pathlib import Path

import cv2
import numpy as np


SEGMENTS = {
    "a": (0.20, 0.00, 0.80, 0.17),
    "b": (0.35, 0.12, 0.90, 0.42),
    "c": (0.28, 0.60, 0.88, 0.90),
    "d": (0.12, 0.82, 0.74, 1.00),
    "e": (0.00, 0.60, 0.32, 0.90),
    "f": (0.00, 0.12, 0.32, 0.42),
    "g": (0.18, 0.40, 0.76, 0.58),
}

DIGITS = {
    frozenset("ab cdef".replace(" ", "")): "0",
    frozenset("bc"): "1",
    frozenset("abdeg"): "2",
    frozenset("abcdg"): "3",
    frozenset("bcfg"): "4",
    frozenset("acdfg"): "5",
    frozenset("acdefg"): "6",
    frozenset("abc"): "7",
    frozenset("abcdefg"): "8",
    frozenset("abcdfg"): "9",
}


def main():
    profile = json.loads(Path("microlife_test_tonometer.profile.json").read_text())
    for path in sorted(Path("diagnostics/auto_lcd").glob("*_lcd.jpg")):
        gray = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
        print(path.name)
        for field in profile["fields"]:
            values = []
            fy = int(field["rect"]["y"] * 960)
            fh = int(field["rect"]["height"] * 960)
            fx = int(field["rect"]["x"] * 640)
            fw = int(field["rect"]["width"] * 640)
            _, field_mask = cv2.threshold(
                gray[fy:fy+fh, fx:fx+fw], 0, 255,
                cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU,
            )
            mask = np.zeros_like(gray)
            mask[fy:fy+fh, fx:fx+fw] = field_mask
            for slot in field["digitSlots"]:
                x = int(slot["x"] * 640); y = int(slot["y"] * 960)
                w = int(slot["width"] * 640); h = int(slot["height"] * 960)
                roi = gray[y:y+h, x:x+w]
                background = float(np.percentile(roi, 80))
                scores = {}
                for name, (l, t, r, b) in SEGMENTS.items():
                    sample = roi[int(t*h):int(b*h), int(l*w):int(r*w)]
                    scores[name] = round(background - float(np.percentile(sample, 10)), 1)
                values.append(scores)
            predictions = []
            for threshold in (.08, .11, .14, .17, .20, .24, .28, .32):
                text = ""
                for slot in field["digitSlots"]:
                    x = int(slot["x"] * 640); y = int(slot["y"] * 960)
                    w = int(slot["width"] * 640); h = int(slot["height"] * 960)
                    active = set()
                    for name, (l, t, r, b) in SEGMENTS.items():
                        sample = mask[y+int(t*h):y+int(b*h), x+int(l*w):x+int(r*w)]
                        if np.count_nonzero(sample) / max(sample.size, 1) >= threshold:
                            active.add(name)
                    text += DIGITS.get(frozenset(active), "" if not active else "?")
                predictions.append((threshold, text))
            print(" ", field["id"], predictions)


if __name__ == "__main__":
    main()
