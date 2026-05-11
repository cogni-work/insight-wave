# Local cron / launchd / systemd-timer drainer

The honest scheduled-drainer shape when the wiki is on-box only — no
GitHub, no cloud service, no external scheduler. Just an OS scheduler
firing `claude -p --bare "/cogni-wiki:wiki-ingest --next"` on a cadence.

## When to pick this shape

- **Corporate-banned from GitHub**, and Cloud Routine is also restricted
  or unavailable.
- **Air-gapped or restricted-network environment** where outbound calls
  to Anthropic infrastructure are allowed (the CLI still needs API access)
  but cloud-managed schedulers are not.
- **Privacy / sovereignty preference** — keep the scheduler local even
  when remote options exist.
- **Single-user, single-machine wiki** — you don't need multi-runner
  coordination, so the file-lock-only contract is sufficient.

The queue files are already portable (plain JSON under `.cogni-wiki/queue/`)
and `_wiki_lock` is a local-filesystem `fcntl.flock`. Nothing has to leave
the box for the queue to work correctly.

## Trade-offs vs other shapes

| | GitHub Actions | Cloud Routine | Local cron |
|---|---|---|---|
| Survives laptop sleep | Yes (cloud) | Yes (cloud) | **No** — only ticks when the machine is on |
| Survives machine reboot | Yes | Yes | Yes (scheduler restarts the timer) |
| Audit trail | Commit log | Routine history | Whatever you redirect logs to |
| Setup complexity | Workflow YAML | One `/schedule` call | One crontab/plist/timer file |
| Multi-runner safe | Yes (git push) | Single routine | Single host = single runner |
| Requires GitHub | Yes | No | No |
| Requires external service | GitHub | Anthropic Routines | **No** |

The trade-off is real: local cron does not tick while the machine is
asleep. For a laptop user who closes the lid at 18:00, the drainer is
effectively off-duty until the machine wakes again. For a always-on
workstation or a personal server, it's fine.

## macOS — launchd

Launchd is the macOS native scheduler. Create
`~/Library/LaunchAgents/ai.cogni-work.wiki-drain.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>ai.cogni-work.wiki-drain</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>cd /Users/YOU/path/to/your/wiki && /usr/local/bin/claude -p --bare "/cogni-wiki:wiki-ingest --next" >> /tmp/wiki-drain.log 2>&1</string>
  </array>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Minute</key>
    <integer>0</integer>
  </dict>

  <key>RunAtLoad</key>
  <false/>

  <key>StandardOutPath</key>
  <string>/tmp/wiki-drain.stdout.log</string>

  <key>StandardErrorPath</key>
  <string>/tmp/wiki-drain.stderr.log</string>
</dict>
</plist>
```

Load and start:

```bash
launchctl load  ~/Library/LaunchAgents/ai.cogni-work.wiki-drain.plist
launchctl start ai.cogni-work.wiki-drain  # one-shot test fire
```

Verify it's scheduled:

```bash
launchctl list | grep wiki-drain
```

Stop and unload:

```bash
launchctl unload ~/Library/LaunchAgents/ai.cogni-work.wiki-drain.plist
```

Adjust the schedule by editing `StartCalendarInterval` (one `<dict>` per
fire time, or use `StartInterval` for "every N seconds"). Adjust the
`claude` path if `which claude` returns a different location.

## Linux — systemd timer

Two unit files. `~/.config/systemd/user/wiki-drain.service`:

```ini
[Unit]
Description=cogni-wiki drainer — one --next per fire

[Service]
Type=oneshot
WorkingDirectory=/home/YOU/path/to/your/wiki
ExecStart=/usr/bin/env claude -p --bare "/cogni-wiki:wiki-ingest --next"
StandardOutput=append:/tmp/wiki-drain.log
StandardError=append:/tmp/wiki-drain.log
```

`~/.config/systemd/user/wiki-drain.timer`:

```ini
[Unit]
Description=cogni-wiki drainer — hourly

[Timer]
OnCalendar=hourly
Persistent=true
Unit=wiki-drain.service

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
systemctl --user daemon-reload
systemctl --user enable --now wiki-drain.timer
```

Verify:

```bash
systemctl --user list-timers wiki-drain.timer
systemctl --user status wiki-drain.service
```

Stop:

```bash
systemctl --user disable --now wiki-drain.timer
```

`Persistent=true` means a missed run (e.g. machine was off when the timer
should have fired) is run on the next boot, which is usually what you
want for a queue drainer.

## Linux / macOS / WSL — plain cron

For environments that have neither systemd nor launchd, or where you just
want the simplest possible setup:

```bash
crontab -e
```

Add a line:

```cron
# Drain the wiki ingest queue once an hour.
0 * * * * cd /path/to/your/wiki && /usr/local/bin/claude -p --bare "/cogni-wiki:wiki-ingest --next" >> /tmp/wiki-drain.log 2>&1
```

Pin the absolute path to `claude` (cron's `PATH` is minimal). Redirect
both stdout and stderr to a log file so you can audit failures.

Multiple wikis: one crontab line per wiki.

```cron
0 * * * *  cd /path/to/research-wiki   && /usr/local/bin/claude -p --bare "/cogni-wiki:wiki-ingest --next" >> /tmp/wiki-drain-research.log   2>&1
15 * * * * cd /path/to/consulting-wiki && /usr/local/bin/claude -p --bare "/cogni-wiki:wiki-ingest --next" >> /tmp/wiki-drain-consulting.log 2>&1
```

Stagger the minutes to avoid two ingests starting at exactly the same
second (harmless but wasteful if they contend for the same API quota).

## Picking a cadence

Same trade-off as the other shapes:

| Cadence | When | Notes |
|---|---|---|
| `*/5 * * * *` | High-volume wiki | Faster drain, more invocations. |
| `0 * * * *` | **Default**, sane for most wikis | Recommended starting point. |
| `0 */6 * * *` | Low-volume | Lower frequency; up to 6h backlog. |
| `0 9 * * *` | Very low volume | Daily-batch style. |

Over-ticking is harmless — `--next` exits 0 on `noop`.

## Authentication

The Claude Code CLI reads `ANTHROPIC_API_KEY` from the environment. For
cron, you either need to set it in the crontab itself (visible to anyone
who can read the crontab — usually only the owning user, but still
fingerprintable) or rely on `claude login` having been performed
interactively at least once so the CLI has a stored credential.

For systemd, put the key in a unit-level `EnvironmentFile=`:

```ini
[Service]
EnvironmentFile=%h/.config/systemd/user/wiki-drain.env
```

with `~/.config/systemd/user/wiki-drain.env`:

```
ANTHROPIC_API_KEY=sk-ant-xxx
```

Make sure the file is mode `0600`. Same advice for launchd — use the
plist's `EnvironmentVariables` dict, but be aware launchd plists are
world-readable by default; prefer the interactive-login path on macOS
unless you have a specific reason not to.

## Monitoring and recovery

There is no central dashboard. You have:

- The log file you redirected stdout/stderr to.
- `wiki-resume`, which surfaces `queue.pending / running / failed`
  counts plus the drainer hint (`queue.last_next_at` recency check).

If you suspect the drainer has stalled (logs show repeated `running_busy`
or you see a non-empty `running/` for hours): `wiki-resume` will surface
the stuck job, then use `wiki-ingest --queue-retry <id>` to recycle it.

## When **not** to use local cron / launchd / timer

- The wiki is in a GitHub repo. → GitHub Actions has free durability and
  audit trail.
- You want the drainer to keep ticking while the laptop is closed. →
  Cloud Routine is the right answer.
- You want to iterate on ingest config in real time. → Use `/loop` for the
  iteration phase.

## References

- `cogni-wiki/skills/wiki-ingest/SKILL.md` — Mode D dispatcher contract
- `cogni-wiki/references/scheduled-drainer/README.md` — selector + rationale
- `man 5 crontab`, `man systemd.timer`, `man launchd.plist` — OS-level docs
