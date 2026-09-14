;Test stages must remain below their first heap arena at 0x40000.
%ifndef BOOT_SECTORS
%define BOOT_SECTORS 128
%endif
%ifdef LEX_NUMBER_TEST
;The numeric oracle fixture uses its first arena at 0x60000.
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 512
%error Numeric test stage must fit below physical 0x50000
%endif
%else
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 320
%error Test stage must fit below physical 0x38000
%endif
%endif
%include "tools/i386-bios.inc"
