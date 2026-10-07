;Each test stage must remain below its selected first heap arena.
%ifndef BOOT_SECTORS
%define BOOT_SECTORS 128
%endif
%ifdef COMPILER_GRAPH_TEST
%define BOOT_SECTORS_LIMIT 832
;Compiler graph fixture uses its first arena at 0x78000.
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 832
%error Compiler graph test stage must fit below physical 0x78000
%endif
%elifdef LEX_MACRO_TEST
;Definition/token/task fixtures use their first arena at physical 0x60000.
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 640
%error Macro lexer test stage must fit below physical 0x60000
%endif
%elifdef TASK_HEAP_TEST
;Selected-parent task heap fixture starts its first arena at physical 0x48000.
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 448
%error Task heap test stage must fit below physical 0x48000
%endif
%elifdef LEX_LARGE_TEST
;Large fixtures use their first arena at or above 0x50000.
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 512
%error Large lexer test stage must fit below physical 0x50000
%endif
%elifdef INPUT_TEST
; Input corpus scratch heap begins at 0x48000; loaded code must stay below it.
%if BOOT_SECTORS > 448
%error Input test stage must fit below physical 0x48000
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
