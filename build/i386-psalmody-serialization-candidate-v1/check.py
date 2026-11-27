"""Compare the guest candidate against the original formatter at each slider position."""
from pathlib import Path

HERE = Path(__file__).resolve().parent


def read_rows(trace):
    rows = [line.split() for line in trace.read_text().splitlines()]
    assert len(rows) == 80
    for setting, row in enumerate(rows):
        assert row[:3] == ['PSM', 'SWEEP', str(setting)], (trace, row)
    return rows


if __name__ == '__main__':
    tempo = read_rows(HERE.parent / 'i386-psalmody-tempo-v1/original.txt')
    staccato = read_rows(HERE.parent / 'i386-psalmody-staccato-v4/original.txt')
    expected = [[t[-1], s[-1]] for t, s in zip(tempo, staccato)]
    for target in ('original', 'native'):
        actual = [row[3:] for row in read_rows(HERE / f'{target}.txt')]
        assert actual == expected, target
    print('Both guests match original tempo and staccato text at all 80 positions.')
