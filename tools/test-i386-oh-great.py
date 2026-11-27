#!/usr/bin/env python3
"""Run the bundled OhGreat song on both guests and capture PC-speaker output."""
import argparse
import array
import hashlib
from itertools import groupby
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import time
import wave

ROOT = Path(__file__).resolve().parents[1]
SONG = 'Demo/Snd/OhGreat.HC'


def score_frequencies(source):
    """Interpret octave changes and natural notes in this song's score."""
    semitones = dict(zip(b'ABCDEFG', (0, 2, -9, -7, -5, -4, -2)))
    octave = 4
    notes = []
    for phrase in re.findall(rb'Play\("([^"]+)"', source):
        for char in phrase:
            if ord('0') <= char <= ord('9'):
                octave = char - ord('0')
            elif char in semitones:
                note = 12 * (octave - 4) + semitones[char]
                notes.append(440 * 2 ** (note / 12))
    # Frequency alone cannot distinguish consecutive notes at the same pitch.
    return tuple(hz for hz, _ in groupby(notes))


def pitches(path, expected):
    with wave.open(str(path), 'rb') as stream:
        rate = stream.getframerate()
        if (stream.getnchannels(), stream.getsampwidth(), rate) != (1, 2, 44100):
            raise ValueError('Expected 44.1 kHz, 16-bit mono speaker output')
        samples = array.array('h', stream.readframes(stream.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    width = rate // 40
    windows = []
    frequencies = sorted(set(expected))
    for offset in range(0, len(samples) - width + 1, width):
        values = samples[offset:offset + width]
        if max(values) - min(values) < 500:
            windows.append(None)
            continue
        mean = sum(values) / width
        rising = sum(a <= mean < b for a, b in zip(values, values[1:]))
        measured = rising * rate / width
        nearest = min(frequencies, key=lambda hz: abs(hz - measured))
        windows.append(nearest if abs(nearest - measured) <= 30 else None)
    observed = [hz for hz, group in groupby(windows)
                if hz is not None and sum(1 for _ in group) >= 2]
    next_note = 0
    for hz in observed:
        if hz == expected[next_note]:
            next_note += 1
            if next_note == len(expected):
                break
    if next_note != len(expected):
        raise ValueError(f'Pitch order differs in {path}: matched {next_note} of {len(expected)}')
    return {'matched_pitch_changes': next_note, 'stable_pitch_runs': len(observed),
            'pcm_seconds': len(samples) / rate}


def run(image, out, native, expected):
    guest_type = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
    audio = out/'speaker.wav'
    guest = guest_type(image, out, native, audio_wav=audio, reference_cpus=1)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.type('#include "C:/Probe/OhGreatTest.HC"')
            guest.press('ret')
        guest.wait('SONG BEGIN\n')
        deadline = time.monotonic() + 15
        while not audio.exists() or audio.stat().st_size < 8192:
            log = guest.collect()
            if 'INPUT REJECT ' in log:
                raise ValueError(f'Song command rejected: {log[-1200:]}')
            if time.monotonic() >= deadline or guest.p.poll() is not None:
                raise ValueError('No speaker output during the opening phrase')
            time.sleep(.05)
        guest.press('x')
        guest.wait('SONG DONE\n', timeout=120)
        time.sleep(.4)
        settled = audio.stat().st_size
        if native:
            guest.command('6*7;')
            guest.result_pixels()
        else:
            time.sleep(1.5)
        if audio.stat().st_size != settled:
            raise ValueError('Speaker output continued after song exit')
    finally:
        guest.close()
    report = pitches(audio, expected)
    report['wav_sha256'] = hashlib.sha256(audio.read_bytes()).hexdigest()
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    sha = lambda data: hashlib.sha256(data).hexdigest()
    disk = args.disk.resolve()
    disk_sha = sha(disk.read_bytes())
    report = {'result': 'running', 'disk_sha256': disk_sha}
    try:
        batch = runpy.run_path(str(ROOT/'tools/test-i386-demo-batch.py'))
        script = batch['FIXTURE'] + r'''
DemoBatchLog("SONG BEGIN\n");
DemoBatchRun("::/Demo/Snd/OhGreat.HC","song.DD");
DemoBatchLog("SONG DONE\n");
'''
        overlay = out/'original-source'
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
        original = (overlay/SONG).read_bytes()
        expected = score_frequencies(original)
        if len(expected) != 84:
            raise ValueError('Unexpected reference score')
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        delivered = pack['snapshot'](disk.read_bytes())[1]
        native_source = (ROOT/SONG).read_bytes()
        if delivered['/'+SONG][2] != native_source:
            raise ValueError('Native song source differs from the checked-out port')
        report['source_sha256'] = sha(original)
        report['native_source_sha256'] = sha(native_source)
        (overlay/'Once.HC').write_text(script)
        ref_image = out/'original.iso'
        subprocess.run(['python3', str(ROOT/'tools/build-iso.py'), '--overlay', str(overlay),
                        '--output', str(ref_image)], cwd=ROOT, check=True)
        native_image = out/'native.img'
        pack['package'](disk, native_image, additions={'/Probe/OhGreatTest.HC': script.encode()})
        for name, image, native in [('original', ref_image, False), ('native', native_image, True)]:
            report[name] = run(image, out/name, native, expected)
        ref = (out/'original/song.DD').read_bytes()
        observed = (out/'native/song.DD').read_bytes()
        if observed != ref or len(ref) != 198:
            raise ValueError('Full song DolDoc differs from the original')
        report.update(result='pass', document_sha256=sha(ref), document_bytes=len(ref))
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = sha(disk.read_bytes()) == disk_sha
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if not report['inputs_unchanged']:
        raise ValueError('Input disk changed')


if __name__ == '__main__':
    main()
