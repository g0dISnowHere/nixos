# Strato VNC Console Access

Quick operator reference for accessing the emergency provider VNC / Remote
Console on Strato VPS (`albaldah`) during network, Tailscale, or boot outages.

## 1. Fresh Console Token & Credential Handling

- Generate a fresh Remote Console session directly from the Strato customer
  portal / Cloud panel for the VM.
- Treat the resulting console URL as a **sensitive credential**: the query token
  grants direct, unauthenticated interactive display access to the guest tty.
- **Never commit, log, or persist the token URL** into Git, dotfiles, issue
  trackers, or documentation.

## 2. Connecting & Display Rendering

- Open the console URL in a modern browser tab.
- Initial state often shows a blank or black canvas with a `Connecting ...`
  status banner while the noVNC WebSocket handshake completes.
- Wait until the top bar confirms `Connected to <console-uuid>`.
- The web DOM only contains the surrounding console chrome (`Options`, `Send
  Keys`, `Toggle Fullscreen`). Terminal output is rendered exclusively onto an
  HTML5 `<canvas>` element and cannot be selected as page text.

## 3. Verifying Live Shell vs. Stale / Frozen Screen

- Inspect visual output before typing.
- A functional login or shell prompt (e.g. `albaldah login:` or `[djoolz@albaldah:~]$`)
  indicates the kernel and init system are running.
- **Distinguishing frozen vs. live tty**:
  - Click directly on the canvas area (role `Canvas`) to focus keyboard input.
  - A static screenshot or displayed prompt can be a **stale canvas frame**
    from an earlier session. Verify live responsiveness with a single benign key
    (e.g., `Enter` to redraw the prompt or cursor) rather than assuming the
    terminal is currently active.
  - In automated browser environments, high-level helpers like `tab.type`
    time out because the canvas is not an HTML text input. Lower-level
    `page.keyboard` calls can deliver keystrokes to the focused canvas, but
    timing and modifier translation into the noVNC protocol can garble input
    or trigger shell auto-completion.
  - If an earlier session or automated attempt left unsubmitted, partial, or
    garbled text on the prompt (e.g. malformed flags or shell glob errors),
    do not press `Enter`. Cancel the line cleanly with `Ctrl+C` before typing.
  - Never press `Enter` on unrecognized or half-typed commands. If keystrokes
    appear delayed or garbled, stop typing immediately and re-verify visual
    state via screenshot or fresh frame inspection.
  - Input transmission errors or unexecuted commands do not prove a guest kernel
    hang; noVNC protocol latency or automation helper mismatches frequently
    drop or misorder key events even while the VM remains operational.
  - Do not spam keystrokes if the guest seems slow to respond.
## 4. Minimal Read-Only Outage Diagnostics

Once an interactive shell is available, run minimal, non-destructive commands to
triage host state without adding load:

```bash
# Check memory & swap pressure
free -m

# System load and uptime
uptime

# Quick storage / root disk fill state
df -h /

# Tailscale and network daemon state
systemctl status tailscale --no-pager
ip a

# Recent critical kernel errors or OOM kills
dmesg -T | grep -iE 'oom|out of memory|killed process|error' | tail -n 20
```

## 5. Reboot Path & Ctrl+Alt+Del Handling

- **Authorization requirement**: Only trigger a reboot if explicitly authorized
  by an operator.
- **Verified reboot path via VNC**:
  - When reboot is intentionally authorized and CLI commands cannot be entered,
    use the top bar menu: `Send Keys` > `CTRL + ALT + DEL`.
  - **Send only one orderly request**. Do not repeatedly spam keystrokes or
    retry immediately; systemd takes time to cleanly stop services, flush
    buffers, and unmount filesystems.
  - **Do not confuse key sent with reboot completed**: triggering the menu item
    only delivers the ACPI / key signal to PID 1.
  - **Visual verification**: Monitor the console canvas for shutdown progress,
    the subsequent boot loader screen (`Booting NixOS ...`), kernel startup
    messages, and the appearance of a fresh `albaldah login:` prompt.
  - **Service recovery verification**: After the login prompt appears, verify
    operational recovery independently via SSH / Tailscale and public HTTPS
    endpoints.
  - **Diagnostic note**: Successful reboot recovery is not proof of an OOM or
    specific root cause; preserve post-boot logs and incident boot IDs for
    retrospective analysis.
  - Avoid provider hard power-cycling / reset unless the guest kernel is
    completely unrecoverable, as abrupt power cuts risk filesystem corruption.
## 6. Closing the Session

- When finished, cleanly close the browser tab to sever the VNC WebSocket.
- Do not leave open remote console sessions running unattended.

## 7. Automated Inspection Note (Browser / OMP)

When inspecting the console via automated tools (such as browser automation):
- Rely on visual frame/screenshot capture to evaluate guest health and screen
  content. Canvas text cannot be extracted from DOM nodes
  (`document.body.innerText` only reflects surrounding menu chrome and the
  connection UUID header).
- High-level DOM typing tools (`tab.type`) fail/timeout against the HTML5
  `<canvas>`. While raw `page.keyboard` events reach the canvas once focused,
  keystroke transmission is sensitive to timing and protocol latency.
  Programmatic injection of compound commands (e.g. chained shell commands
  with semicolons and flags) is not verified reliable and frequently arrives
  mangled (e.g. generating shell globbing errors like `zsh: bad pattern: -Is`).
  Do not attempt automated compound command typing.
- Read-only visual inspection via screenshots is the only reliable automated
  technique. An operator taking over interactive access must visually check the
  prompt and clear any pending or leftover input with `Ctrl+C` before typing.
- Always explicitly close the managed browser tab or session (`browser.close()`)
  once inspection concludes to disconnect the VNC session.
