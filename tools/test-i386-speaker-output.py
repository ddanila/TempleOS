#!/usr/bin/env python3
"""Verify emitted PC-speaker tone, octave and silence on an installed QEMU disk."""
import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import runpy
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]


def assess_wav(path, emission=None):
    with wave.open(str(path), 'rb') as stream:
        rate = stream.getframerate()
        if (stream.getnchannels(), stream.getsampwidth(), stream.getcomptype()) != (1, 2, 'NONE'):
            raise ValueError('Expected mono signed 16-bit PCM')
        if rate != 44100:
            raise ValueError('Expected 44100 Hz capture')
        samples = array.array('h', stream.readframes(stream.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    # Classify 100 ms windows independently of guest status and PIT registers.
    width = rate // 10
    windows = []
    for start in range(0, len(samples) - width + 1, width):
        values = samples[start:start + width]
        rms = math.sqrt(sum(value * value for value in values) / width)
        mean = sum(values) / width
        crossings = sum(a <= mean < b for a, b in zip(values, values[1:]))
        frequency = crossings * rate / width
        label = 'silence' if rms <= 8 else 'other'
        if rms >= 100:
            if abs(frequency - 440) <= 15: label = '440Hz'
            elif abs(frequency - 880) <= 25: label = '880Hz'
        windows.append({'start_seconds': start / rate, 'rms': rms,
                        'frequency_hz': frequency, 'label': label})
    runs = []
    for window in windows:
        if runs and runs[-1]['label'] == window['label']:
            runs[-1]['windows'] += 1
        else:
            runs.append({'label': window['label'], 'start_seconds': window['start_seconds'],
                         'windows': 1})
    wanted = ['silence', '440Hz', 'silence', '880Hz', 'silence'] if emission is None else ['440Hz', '880Hz']
    stable = [run for run in runs if run['windows'] >= 10]
    observed = [run['label'] for run in stable]
    # Reject unexpected sustained output as well as missing tones or off/reset silence.
    errors = []
    if emission is not None:
        for name in ('tone_440', 'off', 'tone_880', 'reset'):
            phase = emission.get(name, {})
            before, after = phase.get('before_bytes'), phase.get('after_bytes')
            duration = phase.get('observation_seconds')
            if (type(before) is not int or type(after) is not int or before < 0 or after < before
                    or type(duration) not in (float, int) or not math.isfinite(duration) or duration < 1.5):
                errors.append(f'{name}: missing or invalid emission observation')
                continue
            growth = after - before
            if name.startswith('tone_') and growth < rate * 2:
                errors.append(f'{name}: fewer than one second of emitted PCM')
            if name in ('off', 'reset') and growth != 0:
                errors.append(f'{name}: emitted {growth} bytes while silent')
    passed = observed == wanted and not errors
    return {'result': 'pass' if passed else 'fail', 'expected_sequence': wanted,
            'observed_sequence': observed, 'minimum_stable_seconds': 1.0,
            'duration_seconds': len(samples) / rate, 'sample_rate': rate,
            'runs': runs, 'windows': windows, 'emission_errors': errors,
            'silence_oracle': 'no new WAV bytes during settled off/reset intervals' if emission is not None else 'PCM amplitude'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    digest = hashlib.sha256(args.disk.read_bytes()).hexdigest()
    runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    wav_path = out / 'speaker.wav'
    console = runner(args.disk, out / 'console', groups=('sound',), cpu='486,-fpu',
                     qmp_stdio=True, audio_wav=wav_path)
    report = assess_wav(wav_path, console.get('audio_emission', {}))
    report.update(cpu='486,-fpu', ram_mib=8, accel='tcg', disk_sha256=digest,
                  wav_sha256=hashlib.sha256(wav_path.read_bytes()).hexdigest(),
                  checker_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  input_runner_sha256=hashlib.sha256((ROOT / 'tools/i386-kernel-input.py').read_bytes()).hexdigest(),
                  console_result=console,
                  scope='Emulated PC-speaker waveform; physical audio hardware remains deferred')
    if hashlib.sha256(args.disk.read_bytes()).hexdigest() != digest:
        raise ValueError('Audio test changed source disk')
    report['source_disk_unchanged'] = True
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({key: report[key] for key in
                     ('result', 'observed_sequence', 'duration_seconds')}, indent=2))
    raise SystemExit(0 if report['result'] == 'pass' else 1)


if __name__ == '__main__':
    main()
