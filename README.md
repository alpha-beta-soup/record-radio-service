## Requirements

- systemd (user units)
- ffmpeg

## Quick start

1) Create a label env file in shows/ (example: `shows/testshow.env`):

```bash
RADIO_URL=http://219.88.73.120:88/broadwave.mp3
RADIO_DURATION_SECONDS=10
# optional overrides:
# RADIO_CODEC=aac   # or mp3
# RADIO_BITRATE=192k
# RADIO_OUTDIR=~/Music/radio-recordings
```

2) Create a timer for that label in shows/ (example: `shows/testshow.timer`):

```ini
[Unit]
Description=Test: record 10 seconds every 1 minute (testshow)

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Persistent=true
Unit=radio-record@testshow.service

[Install]
WantedBy=timers.target
```

3) Install the label:

```bash
./scripts/install-radio-label.sh testshow
```

This installs:

- `~/.config/systemd/user/radio-record@.service`
- `~/.config/systemd/user/radio-record@testshow.timer`
- `~/.config/radio-record/testshow.env`
- `~/bin/record-radio.sh`

4) Enable and start the timer:

```bash
systemctl --user daemon-reload
systemctl --user enable --now radio-record@testshow.timer
```

## Running a one-off recording

```bash
systemctl --user start radio-record@testshow.service
```

## Logs

```bash
journalctl --user -u radio-record@testshow.service
```

## Output location

Default: `~/radio-recordings`

Override per label via `RADIO_OUTDIR` in the label env file. `~` is supported.

## Uninstall a label

```bash
./scripts/uninstall-radio-label.sh testshow
systemctl --user daemon-reload
```

## Run without logging in

```bash
sudo loginctl enable-linger $USER
```

## Check installed timers

```bash
systemctl --user list-timers
```

```
NEXT                         LEFT        LAST PASSED UNIT                           ACTIVATES                       
Tue 2026-04-21 18:55:00 NZST 30min left  n/a  n/a    radio-record@SnowmanShow.timer radio-record@SnowmanShow.service
Thu 2026-04-23 18:55:00 NZST 2 days left n/a  n/a    radio-record@BackInTime.timer  radio-record@BackInTime.service

2 timers listed.
Pass --all to see loaded but inactive timers, too.
```

## Check a specific timer

```bash
systemctl --user status radio-record@testshow.timer
systemctl --user list-timers --all | grep radio-record@testshow
```

To inspect what it activated last:

```bash
systemctl --user status radio-record@testshow.service
```

## After changing a show config

If you edit `shows/<label>.env` or `shows/<label>.timer`, run install again for that label:

```bash
./scripts/install-radio-label.sh testshow
systemctl --user daemon-reload
systemctl --user restart radio-record@testshow.timer
```

For env-only changes, restarting the timer is optional, but useful to immediately test:

```bash
systemctl --user start radio-record@testshow.service
```

## Troubleshooting

- If a run fails, check both timer and service logs:

	```bash
	journalctl --user -u radio-record@testshow.timer -n 50 --no-pager
	journalctl --user -u radio-record@testshow.service -n 50 --no-pager
	```

- If using `RADIO_CODEC=mp3`, your ffmpeg build must include `libmp3lame`.
- Output filenames are sanitized from the label (`A-Za-z0-9._+-` kept; others become `_`).
- Uninstall removes shared files (`radio-record@.service`, `~/bin/record-radio.sh`) only when no labels remain.


## Notes

- Each label uses its own env file at `~/.config/radio-record/<label>.env`.
- Repo layout: scripts/ for executables, shows/ for label configs.
- Timers should refer to `radio-record@<label>.service` (no hard-coded paths).
