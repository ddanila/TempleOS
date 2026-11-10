#!/usr/bin/env python3
"""Exercise the narrowly declared Kernel-date reproducibility exception."""
import importlib.util
from pathlib import Path
import struct
import unittest

spec = importlib.util.spec_from_file_location('generations', Path(__file__).with_name('audit-i386-generations.py'))
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


def fixture(timestamp):
    name = b'kernel_compile_time'
    module = bytearray(80 + len(name))
    module[:4] = b'T32M'
    struct.pack_into('<5I', module, 12, len(module), 32, 1, 64, 80)
    struct.pack_into('<q', module, 40, timestamp)
    struct.pack_into('<4I', module, 64, 3, 8, 80, len(name))
    module[80:] = name
    flat = bytes(8) + module[32:64]
    return bytes(module), flat


class DateScope(unittest.TestCase):
    def test_only_date_normalized(self):
        first = audit.normalize_kernel_date(*fixture(123))
        second = audit.normalize_kernel_date(*fixture(456))
        self.assertEqual(first[:2], second[:2])
        self.assertEqual((first[2], second[2]), (123, 456))

    def test_other_bytes_survive(self):
        module, flat = fixture(123)
        changed = bytearray(module)
        changed[52] = 1
        self.assertNotEqual(audit.normalize_kernel_date(module, flat)[0],
                            audit.normalize_kernel_date(changed, flat)[0])
        changed_flat = bytearray(flat)
        changed_flat[28] = 1
        self.assertNotEqual(audit.normalize_kernel_date(module, flat)[1],
                            audit.normalize_kernel_date(module, changed_flat)[1])

    def test_flat_date_must_match(self):
        with self.assertRaisesRegex(ValueError, 'differs from module'):
            audit.normalize_kernel_date(fixture(123)[0], fixture(456)[1])

    def test_missing_export_rejected(self):
        module, flat = fixture(123)
        with self.assertRaisesRegex(ValueError, 'one Kernel build date'):
            audit.normalize_kernel_date(module.replace(b'kernel_compile_time', b'other_compile_time_'), flat)

    def test_date_outside_payload_rejected(self):
        module, flat = fixture(123)
        changed = bytearray(module)
        struct.pack_into('<I', changed, 68, 28)
        with self.assertRaisesRegex(ValueError, 'exceeds payload'):
            audit.normalize_kernel_date(changed, flat)


if __name__ == '__main__':
    unittest.main()
