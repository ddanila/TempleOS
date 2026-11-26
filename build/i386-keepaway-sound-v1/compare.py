"""Compare emulated KeepAway speaker profiles in the timed finish fixture."""
import array
import hashlib
import json
from pathlib import Path
import statistics
import sys
import wave

ROOT = Path(__file__).resolve().parent
EXPECTED = (493.88, 1975.53)


def read_tones(path):
    with wave.open(str(path), 'rb') as stream:
        rate = stream.getframerate()
        if (rate, stream.getnchannels(), stream.getsampwidth()) != (44100, 1, 2):
            raise ValueError(f'Unexpected audio format: {path}')
        samples = array.array('h', stream.readframes(stream.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    width = rate // 100
    observed = []
    for offset in range(0, len(samples) - width + 1, width):
        window = samples[offset:offset + width]
        if max(window)-min(window)<100:
            continue
        mean = statistics.mean(window)
        edges = [i for i,(a,b) in enumerate(zip(window, window[1:])) if a <= mean < b]
        if len(edges)<2:
            continue
        frequency=(len(edges)-1)*rate/(edges[-1]-edges[0])
        note = next((i for i,f in enumerate(EXPECTED) if abs(frequency-f)<.05*f), None)
        if note is not None:
            observed.append((note,frequency))
    return {'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'tones':[{'expected_hz':target,
                      'median_hz':statistics.median(capture),
                      'active_seconds':len(capture)/100}
                     for i,target in enumerate(EXPECTED)
                     if (capture := [f for tone,f in observed if tone==i])],
            'tone_order':[note for i,(note,_) in enumerate(observed)
                          if not i or observed[i-1][0]!=note]}


def main():
    recordings = {mode: read_tones(ROOT / mode / 'speaker.wav')
                  for mode in ('original', 'native')}
    first, second = recordings.values()
    pitch_and_order = (first['tone_order'] == second['tone_order'] == [1, 0, 1, 0]
                       and len(first['tones']) == len(second['tones']) == 2
                       and all(abs(a['median_hz'] - b['median_hz']) <= 5
                               for a, b in zip(first['tones'], second['tones'])))
    duration = all(abs(a['active_seconds'] - b['active_seconds']) <= .10
                   for a, b in zip(first['tones'], second['tones']))
    print(json.dumps({'result': 'pass' if pitch_and_order and duration else 'fail',
                      'pitch_and_order_match': pitch_and_order,
                      'active_durations_within_100_ms': duration,
                      'scope': 'Emulated PC speaker, scored finish and weaker restart. Window-sampled active time; does not identify the timer or scheduler cause.',
                      'recordings': recordings}, indent=2))


if __name__=='__main__':
    main()
