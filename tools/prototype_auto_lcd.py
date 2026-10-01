#!/usr/bin/env python3
"""Offline prototype: find the Microlife LCD without a framing guide."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import cv2
import numpy as np


REFERENCE_LCD = np.float32(
    [[322, 470], [675, 471], [738, 1033], [353, 1037]]
).reshape(-1, 1, 2)
CANONICAL_LCD = np.float32([[0, 0], [639, 0], [639, 959], [0, 959]])


def _fit_boundary(points, vertical):
    if len(points) < 4:
        return None
    data = np.asarray(points, dtype=np.float64)
    independent = data[:, 1] if vertical else data[:, 0]
    dependent = data[:, 0] if vertical else data[:, 1]
    slope, intercept = np.polyfit(independent, dependent, 1)
    return float(slope), float(intercept)


def _intersection(horizontal, vertical):
    ah, bh = horizontal  # y = ah*x + bh
    av, bv = vertical    # x = av*y + bv
    y = (ah * bv + bh) / (1 - ah * av)
    return [av * y + bv, y]


def refine_lcd(crop):
    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(cv2.GaussianBlur(gray, (5, 5), 0), 40, 120)
    lines = cv2.HoughLinesP(
        edges, 1, np.pi / 180, 55, minLineLength=150, maxLineGap=45
    )
    if lines is None:
        return crop, False
    groups = {"top": [], "bottom": [], "left": [], "right": []}
    for x1, y1, x2, y2 in lines.reshape(-1, 4):
        dx, dy = x2 - x1, y2 - y1
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        if abs(dy) <= 0.18 * max(abs(dx), 1):
            if my < 130:
                groups["top"].extend([(x1, y1), (x2, y2)])
            elif my > 830:
                groups["bottom"].extend([(x1, y1), (x2, y2)])
        elif abs(dx) <= 0.18 * max(abs(dy), 1):
            if mx < 110:
                groups["left"].extend([(x1, y1), (x2, y2)])
            elif mx > 530:
                groups["right"].extend([(x1, y1), (x2, y2)])
    top = _fit_boundary(groups["top"], False)
    bottom = _fit_boundary(groups["bottom"], False)
    left = _fit_boundary(groups["left"], True)
    right = _fit_boundary(groups["right"], True)
    if None in (top, bottom, left, right):
        return crop, False
    quad = np.float32([
        _intersection(top, left),
        _intersection(top, right),
        _intersection(bottom, right),
        _intersection(bottom, left),
    ])
    if cv2.contourArea(quad.astype(np.float32)) < 0.70 * 640 * 960:
        return crop, False
    transform = cv2.getPerspectiveTransform(quad, CANONICAL_LCD)
    return cv2.warpPerspective(crop, transform, (640, 960)), True


def polygon_mask(shape: tuple[int, int], polygon: np.ndarray, margin: int) -> np.ndarray:
    mask = np.full(shape, 255, dtype=np.uint8)
    expanded = cv2.convexHull(polygon.astype(np.int32).reshape(-1, 2))
    lcd_mask = np.zeros(shape, dtype=np.uint8)
    cv2.fillConvexPoly(lcd_mask, expanded, 255)
    if margin:
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (margin, margin))
        lcd_mask = cv2.dilate(lcd_mask, kernel)
    mask[lcd_mask > 0] = 0
    return mask


def locate(
    detector: cv2.SIFT,
    ref_points: list[cv2.KeyPoint],
    ref_desc: np.ndarray,
    target_gray: np.ndarray,
) -> tuple[np.ndarray | None, dict]:
    target_points, target_desc = detector.detectAndCompute(target_gray, None)
    if ref_desc is None or target_desc is None:
        return None, {"reason": "no_descriptors"}

    matcher = cv2.BFMatcher(cv2.NORM_L2)
    pairs = matcher.knnMatch(ref_desc, target_desc, k=2)
    good = [first for first, second in pairs if first.distance < 0.72 * second.distance]
    if len(good) < 12:
        return None, {"matches": len(good), "reason": "too_few_matches"}

    source = np.float32([ref_points[item.queryIdx].pt for item in good])
    destination = np.float32([target_points[item.trainIdx].pt for item in good])
    homography, inlier_mask = cv2.findHomography(
        source, destination, cv2.RANSAC, 4.0, maxIters=4000, confidence=0.999
    )
    if homography is None or inlier_mask is None:
        return None, {"matches": len(good), "reason": "no_homography"}
    inliers = int(inlier_mask.sum())
    ratio = inliers / len(good)
    if inliers < 12 or ratio < 0.30:
        return None, {
            "matches": len(good),
            "inliers": inliers,
            "inlierRatio": round(ratio, 3),
            "reason": "weak_homography",
        }
    projected = cv2.perspectiveTransform(REFERENCE_LCD, homography)
    return projected, {
        "matches": len(good),
        "inliers": inliers,
        "inlierRatio": round(ratio, 3),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, default=Path("diagnostics/auto_lcd"))
    args = parser.parse_args()
    root = args.root.resolve()
    output = (root / args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)

    reference_path = root / "1000056343.jpg"
    reference = cv2.imread(str(reference_path))
    if reference is None:
        raise SystemExit(f"Cannot read {reference_path}")
    ref_gray = cv2.cvtColor(reference, cv2.COLOR_BGR2GRAY)
    ref_mask = polygon_mask(ref_gray.shape, REFERENCE_LCD, margin=55)
    detector = cv2.SIFT_create(nfeatures=3500, contrastThreshold=0.025)
    ref_points, ref_desc = detector.detectAndCompute(ref_gray, ref_mask)

    report = {"reference": reference_path.name, "images": {}}
    for path in sorted(root.glob("100005634*.jpg")):
        target = cv2.imread(str(path))
        if target is None:
            continue
        target_gray = cv2.cvtColor(target, cv2.COLOR_BGR2GRAY)
        quad, metrics = locate(detector, ref_points, ref_desc, target_gray)
        metrics["detected"] = quad is not None
        overlay = target.copy()
        if quad is not None:
            points = np.rint(quad.reshape(-1, 2)).astype(np.int32)
            area = abs(cv2.contourArea(points))
            metrics["lcdAreaFraction"] = round(area / (target.shape[0] * target.shape[1]), 4)
            metrics["quadrilateral"] = points.tolist()
            cv2.polylines(overlay, [points], True, (0, 255, 0), 8, cv2.LINE_AA)
            transform = cv2.getPerspectiveTransform(quad.reshape(4, 2), CANONICAL_LCD)
            crop = cv2.warpPerspective(target, transform, (640, 960))
            crop, refined = refine_lcd(crop)
            metrics["borderRefined"] = refined
            gray_crop = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
            metrics["sharpness"] = round(float(cv2.Laplacian(gray_crop, cv2.CV_64F).var()), 1)
            cv2.imwrite(str(output / f"{path.stem}_lcd.jpg"), crop)
        cv2.imwrite(str(output / f"{path.stem}_overlay.jpg"), overlay)
        report["images"][path.name] = metrics

    (output / "report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    detected = sum(item["detected"] for item in report["images"].values())
    print(f"Detected {detected}/{len(report['images'])}; report: {output / 'report.json'}")
    return 0 if detected == len(report["images"]) else 1


if __name__ == "__main__":
    raise SystemExit(main())
