;Test stages must remain below their first heap arena at 0x40000.
%ifndef BOOT_SECTORS
%define BOOT_SECTORS 128
%endif
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 320
%error Test stage must fit below physical 0x38000
%endif
%include "tools/i386-bios.inc"
