# rpi-internet-restart

Use systemd service instead (more reliable than cron on reboot)
Create a service file:
```bash
sudo nano /etc/systemd/system/internet-watchdog.service
```
Paste this:
```
ini[Unit]
Description=Internet Watchdog
After=network.target

[Service]
ExecStart=/usr/local/bin/check_internet.sh
Restart=always
RestartSec=300        # Re-runs every 5 minutes

[Install]
WantedBy=multi-user.target
```

Then enable it:
```bash
sudo systemctl daemon-reload
sudo systemctl enable internet-watchdog
sudo systemctl start internet-watchdog
```
