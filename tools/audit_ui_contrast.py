#!/usr/bin/env python3
"""Measure authored text colors against captured, composited Godot backgrounds.
Run capture_ui_visual_audit.gd with a native renderer first. PIL and NumPy required.
This is a targeted UI audit, not an accessibility conformance certification.
"""
import argparse
import json
from pathlib import Path
import numpy as np
from PIL import Image


def luminance(rgb):
    linear = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    return linear @ np.array([0.2126, 0.7152, 0.0722])


def ratio(a, b):
    la, lb = luminance(a), luminance(b)
    return (np.maximum(la, lb) + 0.05) / (np.minimum(la, lb) + 0.05)


def audit(directory):
    results = []
    for manifest in sorted(directory.glob('*.json')):
        if manifest.name == 'contrast-report.json':
            continue
        data = json.loads(manifest.read_text())
        if 'text' not in data:
            continue
        on = np.asarray(Image.open(manifest.with_suffix('.png')).convert('RGB'), dtype=float) / 255
        off = np.asarray(Image.open(manifest.with_name(manifest.stem + '-background.png')).convert('RGB'), dtype=float) / 255
        glyphs = np.asarray(Image.open(manifest.with_name(manifest.stem + '-mask.png')).convert('RGB'), dtype=float) / 255
        height, width = on.shape[:2]
        for row in data['text']:
            x, y, w, h = row['rect']
            sx, sy = width / 960, height / 540
            x0, y0 = max(0, int(x * sx)), max(0, int(y * sy))
            x1, y1 = min(width, int(np.ceil((x + w) * sx))), min(height, int(np.ceil((y + h) * sy)))
            if x1 <= x0 or y1 <= y0:
                continue
            foreground = np.array(row['color'][:3])
            alpha = row['color'][3]
            background = off[y0:y1, x0:x1]
            actual = on[y0:y1, x0:x1]
            magenta = np.array([1., 0., 1.])
            delta = magenta - background
            glyph = glyphs[y0:y1, x0:x1]
            coverage = np.sum((glyph - background) * delta, axis=2) / np.maximum(np.sum(delta * delta, axis=2), 1e-7)
            reconstructed = background + delta * coverage[..., None]
            mask = (coverage >= 0.85) & (np.max(np.abs(glyph - reconstructed), axis=2) < 0.04)
            if not np.any(mask):
                results.append({'page': manifest.stem, **row, 'status': 'review-no-core'})
                continue
            samples = background[mask]
            # Wide text halos are local backgrounds (W3C SC1.4.3 note5).
            # Their actual alpha is composited over every underlying sampled pixel.
            outline = np.array(row['outline'][:3])
            oa = row['outline'][3]
            backing = 'composited scene'
            if row['outline_size'] >= 2 and oa > 0:
                samples = outline * oa + samples * (1 - oa)
                backing = 'wide local text halo'
            effective = foreground * alpha + samples * (1 - alpha)
            values = ratio(effective, samples)
            minimum = float(values.min())
            exempt = row['disabled'] or row['decorative']
            results.append({'page': manifest.stem, **row, 'minimum': minimum, 'pixels': int(len(values)), 'backing': backing, 'status': 'exempt' if exempt else ('pass' if minimum >= 4.5 else 'fail')})
        if data.get('markers'):
            marker_off = np.asarray(Image.open(manifest.with_name(manifest.stem + '-markers-background.png')).convert('RGB'), dtype=float) / 255
            for row in data['markers']:
                x, y, w, h = row['rect']
                x0, y0 = max(0, int(x * sx)), max(0, int(y * sy))
                x1, y1 = min(width, int(np.ceil((x + w) * sx))), min(height, int(np.ceil((y + h) * sy)))
                actual, backing = on[y0:y1, x0:x1], marker_off[y0:y1, x0:x1]
                difference = np.linalg.norm(actual - backing, axis=2)
                peak = float(difference.max())
                mask = difference >= max(0.1, peak * 0.85)
                minimum = float(ratio(actual[mask], backing[mask]).min()) if mask.any() else 0
                results.append({'page': manifest.stem, **row, 'text': '(state marker)', 'minimum': minimum, 'pixels': int(mask.sum()), 'target': 3, 'status': 'pass' if minimum >= 3 else 'fail'})
    report = {'method': 'W3C sRGB relative luminance; authored foreground against sampled fully composited backgrounds at stroke cores; wide halos composited locally. AA pixels are not foreground colors. Target4.5 for all required text regardless of size; disabled/decorative separately listed.', 'rows': results}
    (directory / 'contrast-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    for row in results:
        if row['status'] not in {'pass', 'exempt'}:
            print(row['status'], row['page'], row['path'].split('/Root/')[-1], repr(row['text']), round(row.get('minimum', 0), 3))
    summary = {status: sum(r['status'] == status for r in results) for status in ['pass', 'fail', 'exempt', 'review-no-core']}
    print(json.dumps(summary))
    return summary


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    summary = audit(args.directory)
    raise SystemExit(1 if summary['fail'] or summary['review-no-core'] else 0)
