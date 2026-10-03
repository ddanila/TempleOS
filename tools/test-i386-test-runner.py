#!/usr/bin/env python3
"""Check mutation verdicts and persistence acceptance source-disk protection."""
import contextlib
import array
import hashlib
import io
import json
import math
from pathlib import Path
import runpy
import tempfile
import unittest
import wave
from unittest.mock import Mock, patch

MODULE=runpy.run_path(str(Path(__file__).with_name('test-i386-mutations.py')))


class VerdictTests(unittest.TestCase):
    def run_case(self,results):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); disk=root/'disk.img'; disk.write_bytes(b'fixture')
            with patch.dict(MODULE['HARNESS'],run_input=Mock(side_effect=results)), \
                 patch('sys.argv',['test',str(disk),'--out',str(root/'out'),'--mutation','control-hit-test']), \
                 contextlib.redirect_stdout(io.StringIO()):
                code=MODULE['main']()
            return code,json.loads((root/'out/result.json').read_text())

    def test_exact_behavioral_failure_is_detected(self):
        code,report=self.run_case([{'result':'pass'},MODULE['HARNESS']['MutationDetected']('wrong answer')])
        self.assertEqual(code,0)
        self.assertEqual(report['mutations']['control-hit-test']['result'],'detected')

    def test_timeout_is_inconclusive(self):
        code,report=self.run_case([{'result':'pass'},TimeoutError('no VGA')])
        self.assertEqual(code,1)
        self.assertEqual(report['mutations']['control-hit-test']['result'],'inconclusive')

    def test_unchanged_assertion_passing_is_survival(self):
        code,report=self.run_case([{'result':'pass'},{'result':'pass'}])
        self.assertEqual(code,1)
        self.assertEqual(report['mutations']['control-hit-test']['result'],'survived')

    def test_baseline_failure_prevents_mutations(self):
        code,report=self.run_case([RuntimeError('boot failed')])
        self.assertEqual(code,1)
        self.assertEqual(report['mutations'],{})
        self.assertEqual(report['result'],'inconclusive')


class PersistenceVerdictTests(unittest.TestCase):
    def run_case(self, change_source):
        module=runpy.run_path(str(Path(__file__).with_name('test-i386-doldoc-session.py')))
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); disk=root/'disk.img'; disk.write_bytes(b'fixture')
            def boot(*args, **kwargs):
                if change_source: disk.write_bytes(b'changed')
                return {'result':'pass'}
            with patch.dict(module['main'].__globals__, INPUT=boot,
                            verify_redsea_project=Mock(return_value={'result':'mocked'})), \
                 patch('sys.argv',['test',str(disk),'--out',str(root/'out')]), \
                 contextlib.redirect_stdout(io.StringIO()):
                code=module['main']()
            return code,json.loads((root/'out/result.json').read_text())

    def test_unchanged_source_allows_passing_sessions(self):
        code,report=self.run_case(False)
        self.assertEqual(code,0)
        self.assertTrue(report['source_disk_unchanged'])

    def test_source_change_fails_even_when_both_sessions_pass(self):
        code,report=self.run_case(True)
        self.assertEqual(code,1)
        self.assertEqual(report['result'],'fail')
        self.assertFalse(report['source_disk_unchanged'])


class SpeakerWaveformTests(unittest.TestCase):
    assess = staticmethod(runpy.run_path(str(Path(__file__).with_name(
        'test-i386-speaker-output.py')))['assess_wav'])

    def waveform(self, notes, emission=None):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'speaker.wav'
            samples = array.array('h')
            for note in notes:
                samples.extend(0 if note == 0 else
                               (12000 if math.sin(2*math.pi*note*i/44100) > 0 else -12000)
                               for i in range(44100*2))
            import sys
            if sys.byteorder != 'little': samples.byteswap()
            with wave.open(str(path), 'wb') as stream:
                stream.setparams((1, 2, 44100, 0, 'NONE', 'not compressed'))
                stream.writeframes(samples.tobytes())
            return self.assess(path, emission)

    def test_tones_and_both_silence_transitions(self):
        self.assertEqual(self.waveform([0, 440, 0, 880, 0])['result'], 'pass')

    def test_capture_rejects_disk_as_audio_destination(self):
        runner = runpy.run_path(str(Path(__file__).with_name('i386-kernel-input.py')))['run_input']
        with tempfile.TemporaryDirectory() as tmp:
            disk = Path(tmp) / 'source.img'
            disk.write_bytes(b'preserve this disk')
            with self.assertRaisesRegex(ValueError, 'overwrite a disk'):
                runner(disk, Path(tmp)/'out', groups=('sound',), audio_wav=disk)
            self.assertEqual(disk.read_bytes(), b'preserve this disk')

    def test_faulty_output_is_rejected(self):
        for notes in ([0, 0, 0, 0, 0], [0, 220, 0, 880, 0],
                      [0, 440, 440, 880, 880], [0, 880, 0, 440, 0],
                      [0, 440, 0, 880], [0, 440, 0, 880, 0, 220]):
            with self.subTest(notes=notes):
                self.assertEqual(self.waveform(notes)['result'], 'fail')

    def test_backend_silence_requires_independent_emission_observations(self):
        import copy
        emission = {
            'tone_440': {'before_bytes': 44, 'after_bytes': 132344, 'observation_seconds': 1.51},
            'off': {'before_bytes': 132344, 'after_bytes': 132344, 'observation_seconds': 1.51},
            'tone_880': {'before_bytes': 132344, 'after_bytes': 264644, 'observation_seconds': 1.51},
            'reset': {'before_bytes': 264644, 'after_bytes': 264644, 'observation_seconds': 1.51}}
        self.assertEqual(self.waveform([440, 880], emission)['result'], 'pass')
        for phase, field, value in (
                ('off', 'after_bytes', 132346), ('reset', 'after_bytes', 264646),
                ('tone_440', 'after_bytes', 44), ('tone_880', 'observation_seconds', 0.5),
                ('off', 'before_bytes', True), ('reset', 'observation_seconds', float('nan'))):
            changed = copy.deepcopy(emission)
            changed[phase][field] = value
            with self.subTest(phase=phase, field=field):
                self.assertEqual(self.waveform([440, 880], changed)['result'], 'fail')
        self.assertEqual(self.waveform([440, 880], {})['result'], 'fail')


class DevelopmentBuildProvenanceTests(unittest.TestCase):
    def test_changed_inputs_reject_before_qemu_and_clear_old_verdict(self):
        for fault, message in (('disk', 'cross-built disk'),
                               ('module', 'retained input differs'),
                               ('source', 'source changed')):
            with self.subTest(fault=fault), tempfile.TemporaryDirectory() as tmp:
                module = runpy.run_path(str(Path(__file__).with_name('test-i386-selfhost-install.py')))
                root = Path(tmp)
                disk = root / 'input.img'
                disk.write_bytes(bytes(2048*512+512))
                out = root / 'out'
                out.mkdir()
                (out / 'result.json').write_text('{"result":"pass"}')
                build = root / 'build/i386-kernel'
                (build / 'exports').mkdir(parents=True)
                retained = {}
                for name in module['RETAINED']:
                    retained[f'/Modules/I386/{name}.t32m'] = b'module'
                    (build / f'exports/{name}.t32m').write_bytes(b'module')
                source = root / 'Kernel/I386/fixture.HC'
                source.parent.mkdir(parents=True)
                source.write_bytes(b'source')
                digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
                manifest = {'disk_sha256': digest(disk),
                            'source_sha256': {'Kernel/I386/fixture.HC': digest(source)}}
                if fault == 'disk': manifest['disk_sha256'] = 'stale'
                if fault == 'module': (build / 'exports/Startup.t32m').write_bytes(b'changed')
                if fault == 'source': source.write_bytes(b'changed')
                (build / 'result.json').write_text(json.dumps(manifest))
                with patch.dict(module['main'].__globals__, ROOT=root), \
                     patch('runpy.run_path', return_value={'mutated_file_contents': lambda *args: retained}) as load, \
                     patch('sys.argv', ['test', '--disk', str(disk), '--out', str(out), '--cross-retained']):
                    with self.assertRaisesRegex(ValueError, message): module['main']()
                self.assertEqual(load.call_count, 1, 'QEMU runner must not be loaded')
                self.assertFalse((out / 'result.json').exists(), 'Old pass must not survive rejection')


class RequiredServiceObservationTests(unittest.TestCase):
    module = runpy.run_path(str(Path(__file__).with_name('test-i386-required-services.py')))

    def test_missing_functions_are_failures_with_working_controls(self):
        log = ''.join(f'M7 SERVICE {name} 1\n' for name in self.module['CONTROLS'])
        log += ''.join(f'M7 SERVICE {name} 0\n' for name in self.module['REQUIRED'])
        result = self.module['assess'](log)
        self.assertEqual(result['result'], 'fail')
        self.assertEqual(result['missing'], list(self.module['REQUIRED']))

    def test_all_names_present_only_proves_publication(self):
        log = ''.join(f'M7 SERVICE {name} 1\n' for name in
                      self.module['CONTROLS'] + self.module['REQUIRED'])
        result = self.module['assess'](log)
        self.assertEqual(result['result'], 'pass')
        self.assertIn('publication only', result['scope'])
        for bad in ('', log + 'M7 SERVICE Spawn 1\n',
                    log.replace('MAlloc 1', 'MAlloc 0'), log.replace('Sleep 1', 'Sleep 2')):
            with self.subTest(log=bad):
                self.assertEqual(self.module['assess'](bad)['result'], 'invalid')


class PublicDelayObservationTests(unittest.TestCase):
    module = runpy.run_path(str(Path(__file__).with_name('test-i386-public-delay.py')))

    def test_missing_delay_is_failure_and_broken_controls_are_inconclusive(self):
        names = self.module['PUBLIC']['CONTROLS'] + self.module['DELAYS']
        log = ''.join(f'M7 SERVICE {name} 1\n' for name in names)
        self.assertEqual(self.module['delay_presence'](log)['result'], 'pass')
        for name in self.module['DELAYS']:
            failed = self.module['delay_presence'](log.replace(f'{name} 1', f'{name} 0'))
            self.assertEqual(failed['result'], 'fail')
            self.assertEqual(failed['missing'], [name])
        for bad in ('', log + 'M7 SERVICE Sleep 1\n',
                    log.replace('MAlloc 1', 'MAlloc 0'), log.replace('Yield 1', 'Yield 2')):
            with self.subTest(log=bad):
                self.assertEqual(self.module['delay_presence'](bad)['result'], 'invalid')


class PublicTaskObservationTests(unittest.TestCase):
    module = runpy.run_path(str(Path(__file__).with_name('test-i386-public-tasks.py')))

    def test_missing_lifecycle_and_unreliable_observations_cannot_pass(self):
        names = self.module['PUBLIC']['CONTROLS'] + self.module['REQUIRED']
        log = ''.join(f'M7 SERVICE {name} 1\n' for name in names)
        self.assertEqual(self.module['assess_presence'](log)['result'], 'pass')
        missing = log.replace('Spawn 1', 'Spawn 0').replace('Exit 1', 'Exit 0')
        verdict = self.module['assess_presence'](missing)
        self.assertEqual(verdict['result'], 'fail')
        self.assertEqual(verdict['missing'], ['Spawn', 'Exit'])
        for bad in ('', log + 'M7 SERVICE Spawn 1\n',
                    log.replace('Dir 1', 'Dir 0'), log.replace('Exit 1', 'Exit 2')):
            with self.subTest(log=bad):
                self.assertEqual(self.module['assess_presence'](bad)['result'], 'invalid')


class RetainedInstallProtectionTests(unittest.TestCase):
    def test_output_alias_rejects_before_qemu_and_clears_stale_verdict(self):
        module = runpy.run_path(str(Path(__file__).with_name('test-i386-retained-install.py')))
        for name in ('candidate.img', 'boot.img'):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                out = Path(tmp)
                source = out / name
                source.write_bytes(b'preserve native image')
                (out / 'result.json').write_text('{"result":"pass"}')
                with patch('sys.argv', ['test', '--source', str(source), '--out', str(out)]), \
                     patch('runpy.run_path') as load:
                    with self.assertRaisesRegex(ValueError, 'overwrite the source'):
                        module['main']()
                    load.assert_not_called()
                self.assertEqual(source.read_bytes(), b'preserve native image')
                self.assertFalse((out / 'result.json').exists())


if __name__=='__main__': unittest.main()
