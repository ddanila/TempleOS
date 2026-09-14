;Test stages must remain below their first heap arena at 0x40000.
%ifndef BOOT_SECTORS
%define BOOT_SECTORS 128
%endif
%ifdef LEX_LARGE_TEST
;Large fixtures use their first arena at or above 0x50000.
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 512
%error Large lexer test stage must fit below physical 0x50000
%endif
%elifdef LARGE_CORE_TEST
;Task/control fixtures retain their arena at 0x40000.
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 384
%error Compiler-control test stage must fit below physical 0x40000
%endif
%else
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 320
%error Test stage must fit below physical 0x38000
%endif
%endif
%include "tools/i386-bios.inc"
