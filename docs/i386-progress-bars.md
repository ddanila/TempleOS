# Progress bar rendering

The original `DrawProgressBars` body is shared through
`Adam/ProgressBarsDrawCore.HC`. The native console renders active progress
records in the final frame stage before the registered final screen callback;
active records also request a managed window refresh. The progress state,
reset hook and their remaining timing/registry limitations are described in
[i386 Logic compatibility](i386-logic-compatibility.md).

An independent pixel fixture checks empty, half-full and full bars on the
pinned original and native image (mask 7, unchanged inputs;
`build/i386-progress-bars-original-v3`, `build/i386-progress-bars-native-v3`).
The original also passes with the extracted renderer and current `Adam/Win.HC`
(`build/i386-progress-bars-shared-original-v1`). Native checks additionally
verify an automatic window-manager update, explicit frame composition and
execution of the existing final callback. The prior native image rejected the
missing draw service (`build/i386-progress-bars-native-red`). These checks do
not establish parity for descriptions, elapsed-time formatting, all values,
concurrent updates, callback failures or every window/focus mode.

Both bootstrap generations and the 386 cross-build/audit pass
(`build/progress-bars-rebuild-v3.log`, `build/i386-progress-bars-cross-v2`).
An 8 MiB ordinary-include and drive-fields smoke check passes with unchanged
inputs (`build/i386-progress-bars-smoke-8m`); it is not a full minimal-profile
or startup-timing gate. C1–C5 remain open.
