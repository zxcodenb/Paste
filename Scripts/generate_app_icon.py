#!/usr/bin/env python3
"""Generate a 1024x1024 PNG app icon inspired by Bootstrap Icons clipboard-check."""

from __future__ import annotations

import math
from pathlib import Path

SIZE = 1024
OUT_PAM = Path('Resources/Icons/app-icon.pam')


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def clamp(v: float, low: float, high: float) -> float:
    return max(low, min(high, v))


def dist_to_segment(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
    abx, aby = bx - ax, by - ay
    apx, apy = px - ax, py - ay
    ab2 = abx * abx + aby * aby
    if ab2 == 0:
        return math.hypot(px - ax, py - ay)
    t = clamp((apx * abx + apy * aby) / ab2, 0.0, 1.0)
    cx, cy = ax + t * abx, ay + t * aby
    return math.hypot(px - cx, py - cy)


def in_rounded_rect(px: float, py: float, x: float, y: float, w: float, h: float, r: float) -> bool:
    nx = clamp(px, x + r, x + w - r)
    ny = clamp(py, y + r, y + h - r)
    return (px - nx) ** 2 + (py - ny) ** 2 <= r * r


def blend(src: tuple[int, int, int], dst: tuple[int, int, int], a: float) -> tuple[int, int, int]:
    return (
        int(src[0] * (1 - a) + dst[0] * a),
        int(src[1] * (1 - a) + dst[1] * a),
        int(src[2] * (1 - a) + dst[2] * a),
    )


def main() -> None:
    OUT_PAM.parent.mkdir(parents=True, exist_ok=True)

    bg_top = (38, 99, 235)
    bg_bot = (75, 170, 255)
    shadow = (22, 45, 110)
    paper = (248, 251, 255)
    paper_low = (231, 239, 255)
    clip = (215, 227, 252)
    check = (36, 193, 120)

    data = bytearray()

    # Icon geometry
    card_x, card_y, card_w, card_h, card_r = 205.0, 176.0, 614.0, 700.0, 120.0
    head_x, head_y, head_w, head_h, head_r = 344.0, 106.0, 336.0, 180.0, 72.0
    tick_a = (380.0, 560.0)
    tick_b = (486.0, 665.0)
    tick_c = (666.0, 470.0)
    tick_width = 54.0

    # Precompute for speed
    for y in range(SIZE):
        ty = y / (SIZE - 1)
        base = (
            int(lerp(bg_top[0], bg_bot[0], ty)),
            int(lerp(bg_top[1], bg_bot[1], ty)),
            int(lerp(bg_top[2], bg_bot[2], ty)),
        )

        for x in range(SIZE):
            col = base

            # soft vignette
            dx = (x - SIZE / 2) / (SIZE / 2)
            dy = (y - SIZE / 2) / (SIZE / 2)
            vignette = clamp((dx * dx + dy * dy - 0.2) * 0.45, 0.0, 0.38)
            if vignette > 0:
                col = blend(col, shadow, vignette)

            # card drop shadow
            if in_rounded_rect(x - 20, y - 26, card_x, card_y, card_w, card_h, card_r):
                col = blend(col, shadow, 0.20)

            # main card
            if in_rounded_rect(x, y, card_x, card_y, card_w, card_h, card_r):
                gy = clamp((y - card_y) / card_h, 0.0, 1.0)
                card_col = (
                    int(lerp(paper[0], paper_low[0], gy)),
                    int(lerp(paper[1], paper_low[1], gy)),
                    int(lerp(paper[2], paper_low[2], gy)),
                )
                col = card_col

                # subtle horizontal lines on paper
                rel = y - card_y
                if rel > 210 and int(rel) % 68 < 4:
                    col = blend(col, (193, 210, 245), 0.45)

            # clipboard head
            if in_rounded_rect(x, y, head_x, head_y, head_w, head_h, head_r):
                gy = clamp((y - head_y) / head_h, 0.0, 1.0)
                col = (
                    int(lerp(clip[0], paper[0], gy * 0.8)),
                    int(lerp(clip[1], paper[1], gy * 0.8)),
                    int(lerp(clip[2], paper[2], gy * 0.8)),
                )

            # checkmark (two thick segments)
            d1 = dist_to_segment(x, y, tick_a[0], tick_a[1], tick_b[0], tick_b[1])
            d2 = dist_to_segment(x, y, tick_b[0], tick_b[1], tick_c[0], tick_c[1])
            d = min(d1, d2)
            if d <= tick_width / 2:
                edge = clamp((tick_width / 2 - d) / 2.2, 0.0, 1.0)
                col = blend(col, check, 0.85 + 0.15 * edge)

            data.extend((col[0], col[1], col[2], 255))

    with OUT_PAM.open('wb') as f:
        f.write(
            (
                'P7\n'
                f'WIDTH {SIZE}\n'
                f'HEIGHT {SIZE}\n'
                'DEPTH 4\n'
                'MAXVAL 255\n'
                'TUPLTYPE RGB_ALPHA\n'
                'ENDHDR\n'
            ).encode('ascii')
        )
        f.write(data)


if __name__ == '__main__':
    main()
