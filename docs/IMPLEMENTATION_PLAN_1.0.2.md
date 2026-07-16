# Implementation Plan — v1.0.2 Milestones

Continues the milestone numbering from `docs/IMPLEMENTATION_PLAN.md`, which is frozen at
Milestone 1–7 (v1.0.0) and not updated further. See `CLAUDE.md`'s Git workflow section
for the full git-flow conventions (branch naming, commit splitting, doc-commit ordering)
these milestones follow — not restated here.

---

## Proposed Milestones

### Milestone 8: Wi-Fi Credential Exposure — Documented Threat Model
* **Branch**: `feature/provisioning-threat-model`
* **Commit Message**: `docs(wire): document plaintext-credential threat model in GATT_SPEC.md`
* **Rationale**: The provisioning packet is length-prefixed UTF-8 with no encryption,
  key exchange, or peripheral authentication — this project's most severe accepted
  trade-off, and currently an *undocumented* one. A PoC is allowed to ship this; it is
  not allowed to ship it silently.
* **Decision**: document-and-defer. The provisioning characteristic stays plain
  `.writeable` for this PoC rather than requiring BLE pairing
  (`.writeEncryptionRequired`/`.notifyEncryptionRequired`) — pairing alone wouldn't
  authenticate the peripheral either, so it would add demo-UX friction (a system
  pairing prompt on every fresh provision) without closing the actual gap. Real
  mitigation is deferred to a future encrypted-provisioning spec revision.
* **Changes**:
  * Add a "Threat Model" section to `GATT_SPEC.md` stating explicitly: credentials
    cross the air in plaintext; neither side requires BLE pairing/bonding today, so the
    ATT link is unencrypted; any central in range can write its own credentials or read
    telemetry (no authorized-client concept); the central does not verify peripheral
    identity beyond the advertised service UUID, so a spoofed peripheral could harvest
    credentials.
  * Record the document-and-defer decision above in that same section, so the trade-off
    reads as deliberate rather than an oversight.

### Milestone 9: Provisioning Handshake Hardening — Stale Timeout & Failure State Restore
* **Branch**: `feature/provisioning-handshake-hardening`
* **Commit Message**: `fix(service): scope provisioning timeout to its attempt and restore state on failure`
* **Scope**: Two bugs sharing a root cause — `provision()`'s failure paths are less
  carefully engineered than its success path. Same branch, split into two commits by
  the specific defect.
* **Commit 1 — `fix(service): give ProvisioningCoordinator an attempt-generation token`**:
  * `ProvisioningCoordinator` gains a monotonically increasing `attemptToken`; `begin()`
    returns the token for the attempt it just armed, `finish(with:token:)` ignores any
    result carrying a stale token instead of resuming whatever continuation happens to
    be live.
  * `BluetoothCentralService` stores the fire-and-forget 10s timeout task as
    `provisioningTimeoutTask`, cancels it inside `finishProvisioning`, and passes the
    token captured when the timeout was armed — without this, a stale timer from a
    prior attempt can resume the *next* attempt's continuation and fail a handshake
    that would otherwise have succeeded moments later.
  * Both changes are independently sufficient; together they're defense in depth, and
    the token logic is pure and unit-testable without a real timer.
* **Commit 2 — `fix(service): restore connected/provisioned state on provision() failure`**:
  * Wrap the awaited continuation in `do/catch`: on any throw (`writeFailed`,
    `timedOut`, malformed-response `invalidResponse`), if `activePeripheral` is still
    set, send `.connected` (or `.provisioned` when `provisioning.isProvisioned`) before
    rethrowing — today every throwing path skips the restore and leaves
    `statePublisher` reporting `.provisioning` indefinitely until the link drops.
* **Tests**: `ProvisioningCoordinatorTests` — stale-token result ignored, fresh token
  resumes exactly once, double-finish still guarded. Service-level test (mock
  transport): a failure path leaves state `.connected`, never stuck on `.provisioning`.
* **Verification**: Against the simulator, submit malformed credentials (immediate
  `0x01`), tap "Try Again", resubmit within 10s of the first attempt — the second
  attempt must not fail with `.timedOut` at the first attempt's original deadline, and
  state must land on a provisioned/connected dashboard on eventual success.

### Milestone 10: Unprovisioned-Drop Teardown
* **Branch**: `feature/unprovisioned-drop-teardown`
* **Commit Message**: `fix(service): only enter reconnect back-off for a provisioned link`
* **Scope**: An unexpected disconnect currently starts the reconnection back-off loop
  regardless of provisioning status. For a link that was never provisioned (e.g. dropped
  while the credentials form is still up), this shows a dimmed "Reconnecting…" dashboard
  for a device that never had one — and if the reconnect then succeeds, nothing maps
  `.connected` back out of the reconnecting phase, so the banner spins indefinitely over
  a live, healthy link.
* **Commit 1 — `fix(service): gate the reconnect loop on provisioning.isProvisioned`**:
  * `handleUnexpectedDisconnect` enters `.reconnecting` only when
    `provisioning.isProvisioned` is true; an unprovisioned drop now runs the terminal
    teardown straight to `.disconnected`, matching the provisioning flow's own
    "device is gone → rescan" recovery.
  * This has a second-order fix for free: the credentials form's dead-link detection
    already listens for `.disconnected` — today that only arrives after the full
    back-off budget (~62s) exhausts; after this change it fires immediately at drop
    time.
* **Commit 2 — `fix(dashboard): map .reconnecting → .connected out of the reconnecting phase`**:
  * Defense in depth in `HomeModelBuilder.makePhase`: even if a future regression
    re-introduces an unprovisioned link entering `.reconnecting`, a subsequent
    `.connected` must not leave the dashboard stranded in the reconnecting phase. Add
    the missing row to the exhaustive `BluetoothState → Phase` test table.
* **Tests**: Phase-table row for `.connected` following `.reconnecting`; service test
  that an unprovisioned drop publishes `.disconnected` with no reconnect attempt
  scheduled; existing provisioned-drop behavior (enters `.reconnecting`, re-enters
  `.provisioned` on success) re-pinned, not just left to pass incidentally.
* **Verification**: Trigger a drop (simulator `d` command) while the credentials sheet
  is up on a never-provisioned link — app must show the form's dead-link recovery, not
  a reconnecting dashboard. Trigger a drop on a provisioned link — banner must appear
  and clear correctly on reconnect.

### Milestone 11: Provisioning Sheet Dismissal Policy
* **Branch**: `feature/provisioning-sheet-dismissal-policy`
* **Commit Message**: `fix(provisioning): prevent interactive dismissal from misreporting outcome`
* **Scope**: The provisioning sheet has no `isModalInPresentation` guard anywhere, so it
  can be swiped away at two moments where that reads as a false failure: (a) while a
  credential write is in flight (the device may finish provisioning while the app
  reports nothing was added), and (b) during the success screen's ~1.5s linger before
  `.done` fires (a swipe here runs `.scan`-mode teardown and disconnects the device the
  user just successfully added).
* **Changes**:
  * Set `isModalInPresentation = true` at the flow level whenever dismissal would
    misrepresent the outcome: while submitting/handshake in flight, and during the
    success linger.
  * `ResultViewModel` marks the flow finished (`hasFinished = true`, or an
    `outcomeIsSuccess` check inside `cancel()`) the moment the success screen is shown
    — not when `.done` fires ~1.5s later — so any dismissal path that slips through
    cannot call `disconnect()` on a freshly provisioned device.
  * While in there: guard against emitting two terminal `.finished` steps from one flow
    (benign today, but worth closing — the success linger's `.done` currently fires a
    second one after `cancel()`'s guard would already have marked the flow finished).
* **Tests**: ViewModel-level — showing the success screen immediately sets the finished
  flag; `cancel()` called after that point does not request a disconnect.
  Sheet-interaction itself (verifying the interactive-dismiss gesture is actually
  blocked) is manual until a UI-test seam exists for this app.
* **Verification**: Provision successfully, immediately swipe the checkmark screen down
  — dashboard must stay connected. Attempt to swipe mid-submit — sheet must not
  dismiss.

---

## Verification Plan

For each feature branch before merging to `develop` (per `CLAUDE.md`):
1. Compile all targets to ensure zero build errors.
2. Run the full Xcode unit test suite.
3. For service-layer changes (Milestones 9–10): validate against the macOS peripheral
   simulator over a real connection, per each milestone's specific verification note
   above.
4. Update `GATT_SPEC.md`/`ARCHITECTURE.md` where behavior or the wire contract changed,
   and add a `CHANGELOG.md` entry under `[Unreleased]`, as separate trailing doc
   commits per `CLAUDE.md`'s commit-ordering convention.
