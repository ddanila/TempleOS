# i386 QEMU manual observation

This is an optional exploratory record, not an M7 completion gate. Use a writable
copy of the current verified guest-built candidate. Follow the
commands in [i386-test-workflow.md](i386-test-workflow.md#manual-self-hosted-workstation-session).
Fill this record with what you actually observed; leave an untried item open.

| Environment | Observed value |
| --- | --- |
| Date and observer | |
| Source revision and image SHA-256 | |
| Host and QEMU version | |
| QEMU command and CPU/RAM profile | |
| Time from launch to HolyC prompt | |

| Manual step | Pass/fail/untried | Observation or discrepancy |
| --- | --- | --- |
| Normal boot reaches the HolyC prompt without startup diagnostics | | |
| Open the command-line help, follow a link, and return | | |
| Create and browse `C:/Project/Sub` in `EdDir` | | |
| Edit a multiline HolyC program, run it with F5, and see `42` | | |
| Introduce an error, follow its source location, repair it, and rerun | | |
| Interrupt a loop with Ctrl+Alt+C; editor and console remain usable | | |
| Save, reboot the same writable disk, reopen the program, and run it | | |
| Use the PC speaker and inspect display, keyboard, mouse and window response | | |
| Scroll and edit a document longer than the editor viewport | | |
| At 16 MiB, rebuild the kernel and five boot helpers on a fresh target | | |
| Install the new boot image and boot the target disk alone | | |
| Reopen the project and rebuild `LexNumber.HC` on the target | | |

Observed worst-case editing, interrupt and disk-response delays:

Other input/display differences or failures:

Paths or hashes of retained writable source and target images:
