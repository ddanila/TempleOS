#!/usr/bin/env python3
"""Observe actual User input/prompt documents against the pinned original."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = ('6*7;', '1.5+2.25;')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, help='Normal native image; omit for pinned original')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-live-user-prompt/Observer.HC'
    oracle_path = ROOT/'tests/i386/live-user-prompt-reference.json'
    oracle = json.loads(oracle_path.read_text())
    if sha(fixture) != oracle['fixture_sha256']:
        raise ValueError('Fixture differs from pinned reference oracle')
    paths = [Path(__file__).resolve(), fixture, oracle_path] + [ROOT/'tools'/name for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-welcome.py',
        'test-i386-timeclock-reference.py', 'test-i386-answer-prompt-reference.py',
        'build-iso.py', 'package-i386-native-image.py', 'build-i386-kernel.py')]
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    (out/'fixture-source.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    report = dict(result='running', mode='native' if args.disk else 'pinned-original',
                  scope='Physical keyboard into a normal User child; idle prompt task state and complete serialized documents before input and after integer/float commands. No replacement input/prompt loop. Buffers/parent namespace retained for capture; not cleanup, full raster or complete terminal qualification.',
                  commands=list(COMMANDS), input_sha256={str(p):sha(p) for p in paths})
    guest = None

    def save():
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')

    save()
    try:
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        if args.disk:
            source, image = args.disk.resolve(), out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before_files = pack['snapshot'](source.read_bytes())[1]
            additions = {'/Probe/LivePrompt.HC':fixture.read_bytes()}
            report['packaging'] = pack['package'](source, image, additions=additions)
            after_files = pack['snapshot'](image.read_bytes())[1]
            if ({p for p in before_files.keys() | after_files.keys()
                 if before_files.get(p) != after_files.get(p)} != set(additions)):
                raise ValueError('Observer packaging changed unrelated files')
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            reference = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
            report.update(reference_revision=reference['REFERENCE'],
                          repair_revision=reference['REPAIRS'],
                          reference_sha256=reference['restore_reference'](overlay))
            manifest_sha = hashlib.sha256(json.dumps(report['reference_sha256'],
                sort_keys=True, separators=(',', ':')).encode()).hexdigest()
            if (report['reference_revision'] != oracle['reference_revision'] or
                    report['repair_revision'] != oracle['repair_revision'] or
                    manifest_sha != oracle['reference_source_manifest_sha256']):
                raise ValueError('Original provenance differs from oracle')
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+b'\nLPRun;\n')
            image = out/'original.iso'
            subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                            '--output', str(image)], cwd=ROOT, check=True)
        report['image_sha256'] = sha(image)
        save()
        guest = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            guest.wait('DONE native kernel startup\n')
            guest.type('#include "C:/Probe/LivePrompt.HC";LPRun;')
            guest.press('ret')
        guest.wait('LIVE PROMPT 0\n', timeout=300)
        guest.screenshot('prompt-0')
        for phase, command in enumerate(COMMANDS, 1):
            guest.type(command)
            guest.press('ret')
            guest.wait(f'LIVE PROMPT {phase}\n', timeout=180)
            guest.screenshot(f'prompt-{phase}')
        guest.wait('DONE live user prompt\n')
        guest.collect()
        state = list(struct.unpack('<12q', (guest.out/'live-prompt-state.bin').read_bytes()))
        docs = [(guest.out/f'live-prompt-{i}.DD').read_bytes() for i in range(3)]
        cwd = (guest.out/'live-prompt-cwd.bin').read_bytes()
        expected = oracle['expected_state']
        normalized, elapsed_counts = [], []
        for doc in docs:
            normal, count = re.subn(rb'[0-9]+\.[0-9]{6}s', b'<elapsed>s', doc)
            normalized.append(normal.replace(cwd, b'<root>/').hex())
            elapsed_counts.append(count)
        report.update(state=state, cwd_hex=cwd.hex(), observed_hex=[doc.hex() for doc in docs],
                      normalized_hex=normalized, elapsed_field_counts=elapsed_counts,
                      float_allowed_bits=oracle['float_allowed_bits'],
                      float_bits=hex(state[8]), reference_float_bits=hex(expected[8]))
        failures = []
        #Keep the established original decimal/x87 +1 ULP allowance explicit.
        #No raw answer bits are replaced or rounded in the saved observations.
        if (state[:8] != expected[:8] or state[8] not in oracle['float_allowed_bits'] or
                state[9:] != expected[9:]):
            failures.append('Prompt task state differs from original')
        if not re.fullmatch(rb'[A-Z]:/', cwd):
            failures.append('Controlled child directory is not a drive root')
        if cwd+b'>' not in docs[0]:
            failures.append('Initial live prompt lacks original current-directory prefix')
        if not re.search(rb'ans=0x0*2A=42\n', docs[1]):
            failures.append('Live integer prompt lacks original deferred answer format')
        if not re.search(rb'ansf= +3\.7500000\n', docs[2]):
            failures.append('Live float prompt lacks original deferred answer format')
        if elapsed_counts != [1, 2, 3]:
            failures.append('Prompt elapsed-time field counts differ from original')
        if normalized != oracle['normalized_documents_hex']:
            failures.append('Complete prompt documents differ from pinned original')
        report['failures'] = failures
        if failures:
            raise ValueError('; '.join(failures))
        report['result'] = 'pass'
    except BaseException as exc:
        report.update(result='fail', error=str(exc))
        if guest and guest.p.poll() is None:
            try:
                guest.screenshot('failure')
            except Exception as capture_error:
                report['capture_error'] = str(capture_error)
        raise
    finally:
        if guest:
            try:
                guest.close()
            except Exception as cleanup_error:
                report.update(result='fail', cleanup_error=str(cleanup_error))
        report['inputs_unchanged'] = all(p.is_file() and sha(p) == digest
                                         for p, digest in ((Path(p), h) for p, h in report['input_sha256'].items()))
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Observer inputs changed during run')
        save()
    if report['result'] != 'pass':
        raise ValueError(report.get('error', 'Live prompt observation failed'))


if __name__ == '__main__':
    main()
