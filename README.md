# 🔥 TorProxyManager

<div align="center">

![Version](https://img.shields.io/badge/version-4.1-blue)
![Bash](https://img.shields.io/badge/bash-5.0+-green)
![License](https://img.shields.io/badge/license-MIT-yellow)
![Tor](https://img.shields.io/badge/Tor-SOCKS5-purple)

**Professional Tor SOCKS5 Proxy Manager with Auto-Rotation**

[Installation](#-installation) • [Features](#-features) • [Usage](#-usage) • [Commands](#-commands) • [License](#-license)

</div>

---

## 📋 Table of Contents

* [Features](#-features)
* [Requirements](#-requirements)
* [Installation](#-installation)
* [Quick Start](#-quick-start)
* [Usage Guide](#-usage-guide)
* [Commands](#-commands)
* [Configuration](#-configuration)
* [Troubleshooting](#-troubleshooting)
* [Project Structure](#-project-structure)
* [Screenshots](#-screenshots)
* [Contributing](#-contributing)
* [License](#-license)
* [Owner](#-owner)

---

## ✨ Features

| Feature                   | Description                                       |
| ------------------------- | ------------------------------------------------- |
| 🚀 **One-Click Install**  | Automatic Tor installation and configuration      |
| 🌍 **Country Selection**  | Choose specific exit countries (e.g., US, DE, FR) |
| 🔄 **Auto-Rotation**      | Automatic IP rotation at custom intervals         |
| 🎯 **Manual Switch**      | Change location manually with country selection   |
| 📊 **Real-Time Status**   | Check Tor service and proxy status instantly      |
| 🛠 **Debug Tools**        | Built-in troubleshooting and error fixing         |
| 🎨 **Beautiful UI**       | Colorful, professional terminal interface         |
| 📝 **Logging**            | Comprehensive logging for debugging               |
| 🔌 **SOCKS5 Proxy**       | Ready-to-use SOCKS5 proxy endpoint                |
| ⚙️ **Easy Configuration** | Simple interactive configuration menu             |

---

## 📦 Requirements

| Requirement  | Minimum Version                               |
| ------------ | --------------------------------------------- |
| **OS**       | Linux (Debian/Ubuntu based)                   |
| **Bash**     | 4.0+                                          |
| **Sudo**     | Any version                                   |
| **Internet** | Required for downloading Tor and dependencies |

### Automatic Dependencies

The installer automatically installs required dependencies:

* Tor
* curl
* netcat-openbsd
* net-tools

---

# 🔧 Installation

## Method 1: Quick Install (Recommended)

Run the following command:

```bash
curl -sSL https://raw.githubusercontent.com/aily-dev/TorProxyManager/main/tor_pro_manager.sh | bash
```

After installation, launch the manager:

```bash
torproxy
```

---

## Method 2: Clone Repository

```bash
git clone https://github.com/aily-dev/TorProxyManager.git
```

Navigate to the project directory:

```bash
cd TorProxyManager
```

Make the script executable:

```bash
chmod +x tor_pro_manager.sh
```

Run the script:

```bash
sudo ./tor_pro_manager.sh
```

---

## ⚡ Quick Start

After installation, simply run:

```bash
torproxy
```

You will see the interactive management menu.

The proxy will be available on:

```text
Host: 127.0.0.1
Port: 9050
Protocol: SOCKS5
```

Example:

```text
socks5://127.0.0.1:9050
```

---

# 📖 Usage Guide

## 🌍 Selecting an Exit Country

TorProxyManager allows you to configure preferred exit countries.

Example supported country codes:

| Country             | Code |
| ------------------- | ---- |
| 🇺🇸 United States  | US   |
| 🇩🇪 Germany        | DE   |
| 🇫🇷 France         | FR   |
| 🇳🇱 Netherlands    | NL   |
| 🇮🇹 Italy          | IT   |
| 🇹🇷 Turkey         | TR   |
| 🇬🇧 United Kingdom | GB   |
| 🇨🇦 Canada         | CA   |
| 🇨🇭 Switzerland    | CH   |
| 🇸🇪 Sweden         | SE   |

> Availability depends on the Tor network and currently available exit relays.

---

## 🔄 Auto IP Rotation

You can configure automatic identity rotation.

Example intervals:

```text
5 Minutes
10 Minutes
30 Minutes
1 Hour
Custom Interval
```

The manager handles Tor service reloads automatically when rotation is enabled.

---

## 🎯 Manual IP Change

You can manually request a new Tor identity directly from the interactive menu.

This is useful when you need to refresh your current Tor circuit without waiting for the automatic rotation interval.

---

# 🖥 Commands

After installation, the following command is available:

```bash
torproxy
```

### Available Actions

| Option          | Description               |
| --------------- | ------------------------- |
| 🚀 Start        | Start Tor proxy service   |
| 🛑 Stop         | Stop Tor proxy service    |
| 🔄 Restart      | Restart Tor service       |
| 🌍 Country      | Configure exit country    |
| 🎯 New Identity | Request a new Tor circuit |
| ⏱ Rotation      | Configure auto-rotation   |
| 📊 Status       | Display service status    |
| 🔍 Check IP     | Show current public IP    |
| 🛠 Debug        | Run diagnostics           |
| 📝 Logs         | View application logs     |
| 🗑 Uninstall    | Remove TorProxyManager    |

---

# ⚙️ Configuration

TorProxyManager manages the Tor configuration automatically.

Main Tor configuration file:

```text
/etc/tor/torrc
```

Default SOCKS proxy configuration:

```text
SocksPort 9050
```

The proxy endpoint:

```text
127.0.0.1:9050
```

Example usage with curl:

```bash
curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip
```

---

# 🧪 Testing the Proxy

You can verify that the proxy is working correctly:

```bash
curl --socks5-hostname 127.0.0.1:9050 https://api.ipify.org
```

Or check Tor connectivity:

```bash
curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip
```

Expected response:

```json
{
  "IsTor": true,
  "IP": "YOUR_TOR_EXIT_IP"
}
```

---

# 📊 Check Service Status

Check whether Tor is running:

```bash
systemctl status tor
```

Or use the built-in manager:

```bash
torproxy
```

Then select:

```text
[Status]
```

---

# 📝 Logs

TorProxyManager stores useful logs for debugging.

To view Tor logs:

```bash
journalctl -u tor -f
```

View recent logs:

```bash
journalctl -u tor --since "10 minutes ago"
```

---

# 🛠 Troubleshooting

## Tor Service Won't Start

Try restarting the service:

```bash
sudo systemctl restart tor
```

Check the service status:

```bash
sudo systemctl status tor
```

---

## Proxy Connection Failed

Check whether port `9050` is listening:

```bash
ss -lntp | grep 9050
```

You should see Tor listening on the configured SOCKS port.

---

## Check Tor Configuration

Verify the configuration file:

```bash
sudo nano /etc/tor/torrc
```

After making changes:

```bash
sudo systemctl restart tor
```

---

## Permission Denied

Make sure the script has execution permissions:

```bash
chmod +x tor_pro_manager.sh
```

Then run:

```bash
sudo ./tor_pro_manager.sh
```

---

# 📁 Project Structure

```text
TorProxyManager/
│
├── tor_pro_manager.sh
├── README.md
├── LICENSE
│
├── logs/
│   └── torproxy.log
│
└── config/
    └── settings.conf
```

---

# 🎨 Screenshots

> Screenshots will be added soon.

Example interface:

```text
╔══════════════════════════════════════════╗
║         🔥 TorProxyManager v4.1          ║
║   Professional Tor Proxy Management      ║
╚══════════════════════════════════════════╝

 [1] 🚀 Start Tor Proxy
 [2] 🛑 Stop Tor Proxy
 [3] 🔄 Restart Service
 [4] 🌍 Select Exit Country
 [5] 🎯 Request New Identity
 [6] ⏱ Configure Auto Rotation
 [7] 📊 Check Status
 [8] 🌐 Check Current IP
 [9] 🛠 Debug Tools
 [0] ❌ Exit

 Select an option:
```

---

# 🔐 Privacy Notice

TorProxyManager is designed to simplify the management of a local Tor SOCKS5 proxy.

Please remember:

* Tor improves privacy but does not guarantee complete anonymity.
* Your browsing behavior can still affect your privacy.
* Always keep your system updated.
* Avoid exposing sensitive information unnecessarily.
* Exit node availability may vary depending on the Tor network.

For more information about Tor, visit the official Tor Project website.

---

# 🤝 Contributing

Contributions are welcome! 🎉

If you'd like to improve TorProxyManager:

1. Fork the repository
2. Create a new branch

```bash
git checkout -b feature/amazing-feature
```

3. Make your changes
4. Commit your changes

```bash
git commit -m "Add amazing feature"
```

5. Push to your branch

```bash
git push origin feature/amazing-feature
```

6. Open a Pull Request

---

# 🐛 Bug Reports

Found a bug?

Please open an issue and include:

* Linux distribution and version
* Bash version
* Error message
* Steps to reproduce the problem
* Relevant logs

---

# 🗺 Roadmap

Future improvements planned:

* [ ] Multi-port SOCKS proxy support
* [ ] Improved configuration profiles
* [ ] Docker support
* [ ] Better logging system
* [ ] IPv6 support
* [ ] Automatic health checks
* [ ] Web-based dashboard
* [ ] Configuration backup and restore
* [ ] More interactive UI improvements

---

# 📄 License

This project is licensed under the MIT License.

```text
MIT License

Copyright (c) 2026 Aily Dev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files, to deal in the Software
without restriction, including the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software.
```

See the [LICENSE](LICENSE) file for more information.

---

# 👨‍💻 Owner

Developed and maintained by:

**Aily Dev**

* GitHub: [@aily-dev](https://github.com/aily-dev)
* Repository: [TorProxyManager](https://github.com/aily-dev/TorProxyManager)

---

<div align="center">

### ⭐ If you find this project useful, consider giving it a star!

Made with ❤️ and Bash

**TorProxyManager © 2026 — Aily Dev**

</div>
