# Native reboot

The native console publishes `Reboot`, using the original PC reset sequence:
interrupts are disabled, the BIOS warm-boot flag is cleared, the CMOS reset
registers are set, and the system-control port requests a reset. The native
runtime is single-core, so the original multiprocessor halt step is not used.
If the reset does not occur, the caller remains halted.

The pinned original and native tests run in disposable QEMU PC instances with
reboot disabled. The original guest invokes `Reboot` and QEMU exits after the
reset (`build/i386-reboot-original-v4`). The native guest invokes the public
command and QMP reports `SHUTDOWN` with reason `guest-reset`
(`build/i386-reboot-native-v2`; runner `tools/test-i386-reboot.py`). Inputs
remain unchanged. The prior native image rejects the missing command
(`build/i386-reboot-native-red-v1`). These tests do not qualify physical
hardware, SMP shutdown, warm reset variants or persistence after reboot.

Both bootstrap generations and the 386 cross-build/audit pass
(`build/reboot-rebuild-v1.log`, `build/i386-reboot-cross-v1`). An 8 MiB
ordinary-include and drive-fields smoke check passes with unchanged inputs
(`build/i386-reboot-smoke-8m`); it does not measure startup timing or qualify
the full minimal profile. C1–C5 remain open.
