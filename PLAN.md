# TempleOS portability plan

Make TempleOS usable on more machines while preserving its character as a small,
offline, personal programming environment. Start with portability of the virtual
machine distribution, then assess native hardware support separately.

## Scope and design constraints

The original `Doc/Charter.DD` explicitly specifies x86-64 PCs, minimal abstraction,
and limited drivers. Supporting other CPU architectures requires an explicit
amendment to those constraints, even when the broader philosophy is preserved.
Keep `archive` unchanged as the reference. All development takes place in our fork,
currently on `main`.

Preserve these core requirements:

- HolyC as the interactive shell and implementation language, including
  self-hosted compilation.
- One shared address space, with applications enjoying the same privileges and
  access as the kernel.
- Direct function calls, inspectable internals, and access to low-level hardware
  facilities.
- DolDoc executable documents and embedded graphics.
- Software-rendered 640×480 graphics, 16 colors, and simple sound.
- An offline, personal programming environment with guest networking disabled.
- A small, understandable system and the existing multicore programming model.

For virtualized execution, unrestricted access refers to the guest machine.
Emulation does not give guest applications unrestricted access to the host.

## Options assessed

| Approach | Benefit | Effect on core concepts | Decision |
| --- | --- | --- | --- |
| Portable QEMU distribution | Runs the same OS across host platforms | Preserves guest architecture and behavior | First priority |
| Modern x86-64 hardware support | UEFI boot and selected newer devices | Preserves most concepts but adds driver complexity | Consider as a bounded second phase |
| Native ARM64 or RISC-V port | Removes dependence on x86 execution | Preserves philosophy but changes assembly and hardware interfaces | Defer; substantial compiler/kernel project |
| Hosted application on Linux/macOS | Convenient desktop integration | Loses unrestricted machine access and actual kernel privilege | Possible companion, not the primary portability path |

QEMU system emulation can provide the guest CPU and devices on different host
architectures through TCG. Host performance and integration still need testing.
Reference: https://www.qemu.org/docs/master/system/introduction.html

## Phase 1: Establish a stronger baseline

Current verified baseline:

- Bootable RedSea image packaged from the checkout.
- Graphical startup and both terminals under QEMU 10.2.1 with TCG on this machine.
- Keyboard input and HolyC evaluation (`6*7;` returns `42`).
- Image metadata, all 686 packaged file contents, and embedded DolDoc record
  lengths checked by `tools/verify-iso.py`.

Before architectural changes, verify:

- Compiler and kernel rebuilding inside TempleOS, followed by booting and using
  the rebuilt system.
- Guest installation and persistent file writes surviving a restart.
- Representative graphics and audio demos.
- Multicore job execution using the existing programming model.

Record exact configurations, procedures, outcomes, and limitations. Current boot
and expression checks do not establish these additional capabilities.

## Phase 2: Make launching portable

- Add launchers for Linux, macOS, and Windows.
- Specify tested virtual hardware and QEMU configurations.
- Package reproducible images and document dependencies and launch procedures.
- Test x86-64 and ARM64 hosts, distinguishing emulation from hardware-assisted
  virtualization and recording performance limitations.
- Keep guest networking disabled.

Acceptance: the same guest system launches on the declared host matrix and passes
baseline checks, with documented persistence and input/display behavior. Do not
claim support for untested hosts.

## Phase 3: Introduce only necessary hardware boundaries

Begin this phase only when a specific second target has been selected.

Separate boot information, display presentation, input, block access, and timing
from their current hardware implementations. Prefer small functions and concrete
structures over a general driver framework. Keep low-level access available and
avoid speculative hooks for targets we are not implementing.

Acceptance: the original QEMU target remains functional, and each new boundary is
justified by a concrete implementation for the selected target.

## Phase 4: Support one native target

Select one machine or tightly defined platform, rather than promising arbitrary
modern hardware support.

For modern x86-64, begin with UEFI boot and framebuffer output while retaining the
logical 640×480, 16-color canvas and software rendering. USB input and modern
storage are separate substantial tasks. UEFI boot alone does not make arbitrary
laptops usable.

Acceptance: the selected machine can boot, accept input, run the programming
workflow, and access the chosen storage configuration. Document unsupported
hardware explicitly.

## Phase 5: Reassess another CPU architecture

A native ARM64 or RISC-V port is a separate architectural project. Assess at least:

- HolyC compiler code generation and the inline assembler.
- Bootstrapping the compiler and kernel for the new architecture.
- Startup, exceptions, task switching, atomics, and memory setup.
- Device access and the architecture's equivalent privileged execution model.
- Compatibility rules for assembly-heavy applications and demos.
- Self-hosted rebuilds and preservation of the interactive programming workflow.

Do not assume that introducing hardware boundaries makes the compiler or kernel
CPU-independent.

## Priority and decision gates

Proceed with phases 1 and 2 as the proposed next work. Phase 3 is conditional on a
specific second target; phases 4 and 5 require separate scope decisions informed
by the earlier results.

The immediate objective is practical portability without a large abstraction
layer that undermines the system's simplicity. Recording this plan does not mark
its unverified milestones complete or start implementation of the later phases.
