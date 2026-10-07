#!/usr/bin/env python3
"""Check that native-build rejection detection cannot consume stale/partial logs."""
from pathlib import Path
import runpy
import unittest

check = runpy.run_path(str(Path(__file__).with_name('i386-kernel-input.py')))['command_rejection']

class RejectionTests(unittest.TestCase):
    def test_current_complete_rejection(self):
        self.assertEqual(check('progress\nBUILD MODULE REJECT 3 0 OutMem\n', 0,
                               ('BUILD MODULE REJECT ',)), 'BUILD MODULE REJECT 3 0 OutMem')

    def test_historical_and_partial_lines(self):
        old = 'BUILD MODULE REJECT old\n'
        self.assertIsNone(check(old + 'progress\n', len(old), ('BUILD MODULE REJECT ',)))
        self.assertIsNone(check('BUILD MODULE REJECT partial', 0, ('BUILD MODULE REJECT ',)))

    def test_opt_in_and_line_boundary(self):
        self.assertIsNone(check('BUILD MODULE REJECT 3\n', 0, ()))
        self.assertIsNone(check('source: BUILD MODULE REJECT 3\n', 0, ('BUILD MODULE REJECT ',)))
        self.assertIsNone(check('BUILD MODULE SOURCE file\n', 0, ('BUILD MODULE REJECT ',)))

if __name__ == '__main__':
    unittest.main()
