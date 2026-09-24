#!/usr/bin/env python3
"""Mutation checks for the 16/32-bit BIOS boot instruction gate."""
from pathlib import Path
import runpy
import unittest


AUDIT=runpy.run_path(str(Path(__file__).with_name('audit-i386-boot.py')))


class BootInstructionAuditTests(unittest.TestCase):
    def test_386_instructions_pass_in_both_modes(self):
        self.assertEqual(AUDIT['audit_code'](b'\xfa\xf4',16),2)
        self.assertEqual(AUDIT['audit_code'](b'\x0f\x20\xc0\xf4',32),2)

    def test_later_cpu_and_fpu_instructions_fail(self):
        for bits in (16,32):
            for code in (b'\x0f\xc8', # BSWAP: 486+
                         b'\x0f\xa2', # CPUID: Pentium+
                         b'\xd9\xe8'): # FLD1: requires an FPU
                with self.subTest(bits=bits,code=code.hex()):
                    with self.assertRaisesRegex(ValueError,'Non-386 boot instruction'):
                        AUDIT['audit_code'](code,bits)

    def test_unplaced_boundary_is_rejected(self):
        with self.assertRaisesRegex(ValueError,'Expected one placed drive label'):
            AUDIT['label_offset']('drive: db 0','drive')

    def test_complete_image_rejects_mutated_boot_regions(self):
        image=bytearray(512+4096)
        image[:2]=b'\xfa\xf4'
        image[510:512]=b'\x55\xaa'
        image[512:514]=b'\xfc\xf4'
        listing=('1 00000002 00 drive: db 0\n'
                 '2 00000002 00 early_idt: times 256 dq 0\n')
        self.assertEqual(AUDIT['audit'](image,listing)['result'],'pass')
        for offset,opcode in ((0,b'\x0f\xc8'),(512,b'\x0f\xa2')):
            changed=bytearray(image);changed[offset:offset+2]=opcode
            with self.subTest(offset=offset):
                with self.assertRaisesRegex(ValueError,'Non-386 boot instruction'):
                    AUDIT['audit'](changed,listing)


if __name__=='__main__': unittest.main()
