#!/usr/bin/env python3
"""Ensure compatibility discovery cannot silently drop reference files or pass gaps."""
import json
import runpy
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT/'tools/inventory-i386-compatibility.py'
INVENTORY = ROOT/'docs/i386-compatibility-inventory.json'


class InventoryGuards(unittest.TestCase):
    def check_inventory(self, transform=None, qualified=False):
        data = json.loads(INVENTORY.read_text())
        if transform:
            transform(data)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)/'inventory.json'
            path.write_text(json.dumps(data))
            return subprocess.run([sys.executable, str(TOOL), '--check', '--output', str(path)] +
                                  (['--require-qualified'] if qualified else []),
                                  text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def test_complete_discovery(self):
        self.assertEqual(self.check_inventory().returncode, 0)

    def test_missing_original_file_rejected(self):
        self.assertNotEqual(self.check_inventory(lambda d:d['entries'].pop()).returncode, 0)

    def test_changed_reference_digest_rejected(self):
        def corrupt(d):
            d['entries'][0]['reference_sha256'] = '0'*64
        self.assertNotEqual(self.check_inventory(corrupt).returncode, 0)

    def test_unrepaired_reference_rejected(self):
        def corrupt(d):
            d['repair_revision'] = d['reference_revision']
        self.assertNotEqual(self.check_inventory(corrupt).returncode, 0)

    def test_workflow_coverage_and_exclusion(self):
        gaps = runpy.run_path(str(TOOL))['qualification_gaps']
        direct = dict(path='Demo/Example.HC', compatibility='qualified',
                      reference_workflow='Run the example', oracle='Expected output',
                      tests=[dict(result='pass', evidence='example.json')])
        shared = dict(path='Kernel/Shared.HC', qualification=dict(
            mode='covered', workflows=[direct['path']]))
        substitute = dict(path='Demo/Legacy.HC', qualification=dict(
            mode='substitute', workflows=[direct['path']], reason='Uses the native entry point'))
        excluded = dict(path='Linux/Tool', qualification=dict(
            mode='excluded', reason='Runs on the host'))
        entries = [direct, shared, substitute, excluded]
        self.assertEqual(gaps(entries), [])
        direct['tests'][0]['result'] = 'fail'
        self.assertEqual(gaps(entries), [direct['path'], shared['path'], substitute['path']])
        shared['qualification']['workflows'] = [substitute['path']]
        direct['tests'][0]['result'] = 'pass'
        self.assertEqual(gaps(entries), [shared['path']])
        excluded['qualification']['reason'] = ' '
        self.assertEqual(gaps(entries), [shared['path'], excluded['path']])

    def test_discovery_does_not_qualify_runtime(self):
        result = self.check_inventory(qualified=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('qualification gaps remain', result.stderr)


if __name__ == '__main__':
    unittest.main()
