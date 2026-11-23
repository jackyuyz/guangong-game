#!/usr/bin/env python3
"""Reproduce the two quiet, original menu plucks; no external recording."""
import math
from pathlib import Path
import struct
import wave

DESTINATION = Path(__file__).resolve().parents[1] / "godot/assets/main-menu"
RATE = 44100


def write_pluck(name, duration, frequency):
    samples = bytearray()
    for frame in range(round(duration * RATE)):
        time = frame / RATE
        attack = min(1.0, time / 0.004)
        decay = math.exp(-time * 38) * (1 - time / duration) ** 2
        tone = (math.sin(math.tau * frequency * time)
                + .24 * math.sin(math.tau * frequency * 2.01 * time)
                + .08 * math.sin(math.tau * frequency * 3.97 * time))
        samples.extend(struct.pack("<h", round(tone * attack * decay * .24 * 32767)))
    with wave.open(str(DESTINATION / name), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(samples)


if __name__ == "__main__":
    DESTINATION.mkdir(parents=True, exist_ok=True)
    write_pluck("hover.wav", .095, 740)
    write_pluck("confirm.wav", .16, 494)
