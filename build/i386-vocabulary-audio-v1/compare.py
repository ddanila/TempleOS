"""Check the durations and frequencies of Vocabulary's two feedback tones."""
import array
import hashlib
import json
import math
from pathlib import Path
import statistics
import sys
import wave

ROOT = Path(__file__).resolve().parent
EXPECTED = (987.77, 196.0)


def capture(path):
    with wave.open(str(path), 'rb') as stream:
        rate = stream.getframerate()
        if rate != 44100 or stream.getnchannels() != 1 or stream.getsampwidth() != 2:
            raise ValueError(f'Unexpected audio format: {path}')
        samples = array.array('h', stream.readframes(stream.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    width = rate // 50
    tones = []
    for offset in range(0, len(samples) - width + 1, width):
        window = samples[offset:offset + width]
        rms = math.sqrt(sum(value * value for value in window) / width)
        if rms < 100:
            continue
        mean = statistics.mean(window)
        transitions = [index for index, (a, b) in enumerate(zip(window, window[1:]))
                       if a <= mean < b]
        if len(transitions) < 2:
            continue
        frequency = (len(transitions) - 1) * rate / (transitions[-1] - transitions[0])
        label = next((index for index, expected in enumerate(EXPECTED)
                      if abs(frequency - expected) <= 25), None)
        if label is None:
            continue
        if not tones or tones[-1]['note'] != label:
            tones.append({'note': label, 'windows': []})
        tones[-1]['windows'].append(frequency)
    matched = [tone for tone in tones if len(tone['windows']) >= 5]
    if [tone['note'] for tone in matched] != [0, 1]:
        raise ValueError(f'Expected 988 Hz then 196 Hz: {path} {matched}')
    return {
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'tones': [{'median_hz': statistics.median(tone['windows']),
                   'active_seconds': len(tone['windows']) / 50} for tone in matched],
    }


captures = {mode: capture(ROOT / mode / 'speaker.wav') for mode in ('original', 'native')}
for original, native in zip(captures['original']['tones'], captures['native']['tones']):
    if (abs(original['median_hz'] - native['median_hz']) > 5 or
            abs(original['active_seconds'] - native['active_seconds']) > .06):
        raise ValueError('Native audio differs from the original feedback')
print(json.dumps({'result': 'pass', 'pcm': captures}, indent=2))
