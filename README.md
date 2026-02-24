## Test a recording

```bash
~/bin/record-radio.sh 20 testlabel http://219.88.73.120:88/broadwave.mp3
```

## Service

Create `~/.config/systemd/user/radio-record@.service`

```
[Unit]
Description=Record internet radio show (%i)

[Service]
Type=oneshot

# Per-label config. Must define RADIO_URL and RADIO_DURATION_SECONDS
EnvironmentFile=%h/.config/radio-record.env

# %i is the "instance" (label) from radio-record@LABEL.service
ExecStart=%h/bin/record-radio.sh %i
```

Create the env file `~/.config/radio-record.env`

```bash
RADIO_URL=http://219.88.73.120:88/broadwave.mp3
RADIO_DURATION_SECONDS=7500
# optional overrides:
# RADIO_CODEC=aac
# RADIO_BITRATE=192k
# RADIO_OUTDIR=~/Music/radio-recordings
```

Create `~/.config/systemd/user/radio-record@myshow.timer`

```
[Unit]
Description=Run radio recording (myshow) every Tuesday at 18:55

[Timer]
OnCalendar=Tue *-*-* 18:55:00
Persistent=true
Unit=radio-record@myshow.service

[Install]
WantedBy=timers.target
```

Enable it:

```bash
systemctl --user daemon-reload
systemctl --user enable --now radio-record@SnowmanShow.timer
systemctl --user list-timers --all | grep radio-record
```

Logs:

```bash
journalctl --user -u radio-record@SnowmanShow.service
```

Run without logging in:

```
sudo loginctl enable-linger $USER
```


Notes
- This assumes you already have the shared template service ~/.config/systemd/user/radio-record@.service and your ~/bin/record-radio.sh in place.
- Your {label}.timer should not include a hard-coded path; it’s installed as radio-record@{label}.timer and will trigger radio-record@{label}.service.
