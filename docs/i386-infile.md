# File input through the task filter

The original `InFile` body is shared through `Kernel/JobInFileCore.HC` and
exported by native ConsoleRuntime 177. It adds the original default `IN.Z`
extension, constructs the current-drive/current-directory include command, and
uses the existing `InStr` input-filter path. The original `Kernel/Job.HC`
includes that same body; it has not been replaced with a stub or a partial
file reader.

`tools/test-i386-infile.py` packages a real source file and executes it through
`InFile` with both default and explicit extensions. The fixture checks the
resulting key messages, filter links and flags after retirement, and current
directory preservation. The pinned original passes mask 15 with unchanged
inputs (`build/i386-infile-original-v1`). The previous native image rejects
at `InFile` before the fixture executes, also with unchanged inputs
(`build/i386-infile-native-red-v1`). The candidate passes the same mask and
three commands at 64 MiB (`build/i386-infile-native-v2`), with unchanged
inputs. Both bootstrap rebuild generations and the minimal and full-content
cross-builds with 386 audits pass (`build/i386-infile-rebuild-v2.log`,
`build/i386-infile-cross-v1`, `build/i386-infile-full-cross-v2`); the
full-content build also audits the new retained export. A 16 MiB startup
diagnostic passes on the earlier image, whose only later source change was
removing a trailing blank line in the public header
(`build/i386-infile-diagnostics-v1`).

The 8 MiB fixture reached its contract but failed with an `OutMem` exception
while creating the input-filter task, with unchanged inputs. An isolated repeat
on the final-source full image failed in the same way
(`build/i386-infile-native-8m-v1`, `build/i386-infile-native-8m-v2`). The
logged callers map to `I386TaskCreateWithFiles` and `Spawn`. At failure the
bootstrap arena had 242,680 bytes free for a 267,527-byte request, and its
largest free payload was 193,632 bytes. Total free capacity was therefore
insufficient for that request; fragmentation further reduced the largest
available span. The 8 MiB resource gap remains open. A post-unwind heap and firmware-map
audit is recorded in [low-memory evidence](i386-low-arena.md).

These checks do not qualify arbitrary input files, cancellation, exceptional
cleanup, the complete task/job API, or the terminal right-click workflow.
The latter still needs its other file operations, mounting and full terminal
startup. C1–C5 remain open.

The auxiliary task arena now allows the previously failing 8 MiB InFile
contract to pass; both successive input-filter tasks used and reused the
low-memory slot with unchanged inputs (`build/i386-low-task-infile-8m-v2`).
The earlier failures remain useful baselines. This functional check does not
pass the separate 60-second startup gate or qualify the full desktop. See
[low-memory integration](i386-low-arena.md).
