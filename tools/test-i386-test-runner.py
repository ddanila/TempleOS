#!/usr/bin/env python3
"""Check mutation verdicts and persistence acceptance source-disk protection."""
import contextlib
import array
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


if __name__=='__main__': unittest.main()
