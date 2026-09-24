#!/usr/bin/env python3
"""Check mutation verdicts and persistence acceptance source-disk protection."""
import contextlib
import io
import json
from pathlib import Path
import runpy
import tempfile
import unittest
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


if __name__=='__main__': unittest.main()
