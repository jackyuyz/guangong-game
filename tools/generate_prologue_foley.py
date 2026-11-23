#!/usr/bin/env python3
"""Rebuild original quiet prologue foley; no credentials or network required."""
from pathlib import Path
import math, random, wave, struct
A = Path(__file__).resolve().parents[1] / "godot/assets/prologue"
# Quiet, deterministic original foley. Wind is a seamless two-second loop.
random.seed(27)
for name,duration in [('wind',2),('paper',0.6),('seal',0.4),('wheels',2.2),('gate',1.6)]:
    rate=22050; samples=[]; low=0
    for i in range(int(rate*duration)):
        t=i/rate; low=.94*low+.06*random.uniform(-1,1)
        if name=='wind': v=low*(.7+.2*math.sin(2*math.pi*t/2))
        elif name=='paper': v=random.uniform(-1,1)*.2*math.sin(math.pi*t/duration)**2
        elif name=='seal': v=(math.sin(2*math.pi*280*t)+low*2)*math.exp(-22*t)*.22
        elif name=='wheels': v=low*.5+math.sin(2*math.pi*94*t)*math.exp(-40*(t%0.42))*.12
        else: v=(math.sin(2*math.pi*56*t)*.4+low)*math.exp(-3*t)*min(1,t*30)
        samples.append(int(max(-1,min(1,v))*32767))
    with wave.open(str(A/'audio'/f'{name}.wav'),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
