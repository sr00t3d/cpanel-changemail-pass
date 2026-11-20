# cPanel Email Password Auto-Changer (`cp-changemail-pass.sh`)

![cPanel Email Password Auto-Changer Cover](./cp-changemail-pass-cover.webp)

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](./cp-changemail-pass.sh)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](./LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20cPanel%20%2F%20WHM%20%7C%20UAPI-orange.svg)](#requirements)

> 🇧🇷 **[Leia em Português (README-ptbr.md)](./README-ptbr.md)**

**cPanel Email Password Auto-Changer** (`cp-changemail-pass.sh` v2.0.0) is a Bash CLI tool that automates single or bulk email password rotations directly on cPanel/WHM servers via UAPI `Email passwd_pop`. It features cryptographically secure password generation (CSPRNG), batch file processing, domain-wide rotation, dry-run simulation, password masking, and structured outputs in aligned `table`, `json`, or `csv`.

---

## Features

- **Single or Bulk Rotation:** Target a single email (`-e`), rotate all emails from a file list (`-f`), or rotate every email under a domain (`-d`).
- **CSPRNG Password Generation:** Generates 16-character (configurable via `-l`) secure passwords using OpenSSL or `/dev/urandom`, avoiding characters that break email clients. Or provide a custom password with `-p`.
- **Dry-Run Simulation (`-n, --dry-run`):** Validates email format, domain ownership, and user accounts without changing credentials.
- **Security & Privacy First:** Supports password masking (`--mask-passwords`) for presentations and secure CSV export (`-s, --save-csv`) with restrictive `chmod 600` permissions.
- **Structured Outputs & Automation:** Export reports in `table` (default), `json`, or `csv` format. Returns exit code `0` on success and `2` if any password change fails.

---

## Requirements

- Linux with Bash 4.0+ and Python 3.6+
- cPanel & WHM server with `/usr/bin/uapi` and `/scripts/whoowns`
- Root or cPanel account privileges

---

## Installation

```bash
git clone https://github.com/sr00t3d/cpanel-changemail-pass.git
cd cpanel-changemail-pass
chmod +x cp-changemail-pass.sh
```

---

## Usage

```bash
# Rotate a single email with auto-generated secure password:
sudo ./cp-changemail-pass.sh -e admin@example.com

# Dry-run simulate a batch rotation from a file:
sudo ./cp-changemail-pass.sh -f emails.txt --dry-run

# Rotate all emails in a domain and save credentials securely to CSV:
sudo ./cp-changemail-pass.sh -d example.com -s /root/passwords.csv

# Mask passwords on terminal display:
sudo ./cp-changemail-pass.sh -e admin@example.com --mask-passwords

# Export report as JSON:
sudo ./cp-changemail-pass.sh -f emails.txt -o json
```

### CLI Options

| Flag | Description |
| :--- | :--- |
| `-e, --email <addr>` | Target single email address |
| `-f, --file <path>` | Batch file with list of email addresses |
| `-d, --domain <dom>` | Rotate all email accounts under a domain |
| `-u, --user <name>` | Explicit cPanel username (skips auto-detection) |
| `-p, --password <pwd>` | Fixed password to set for all processed accounts |
| `-l, --length <int>` | Auto-generated password length (default: 16, min: 12) |
| `-n, --dry-run` | Simulation mode (no live changes made) |
| `--mask-passwords` | Mask passwords in terminal display (`********`) |
| `-s, --save-csv <path>` | Save email:password mapping to a secure file (`chmod 600`) |
| `-o, --output <fmt>` | Output format: `table` (default), `json`, `csv` |
| `-q, --quiet` | Suppress progress messages |
| `--no-color` | Disable ANSI colors |
| `-V, --version` | Show version and exit |
| `-h, --help` | Show help message and exit |

---

## Real Output Example

Captured on an AlmaLinux 8.10 / cPanel test container running a dry-run batch rotation over 4 test accounts (2 valid simulated, 1 invalid syntax, 1 unregistered domain):

```text
================================================================================================================
 CPANEL EMAIL PASSWORD CHANGER v2.0.0 | Mode: DRY-RUN | Targets: 4
================================================================================================================
EMAIL                            | USER         | PASSWORD                 | STATUS     | NOTE
----------------------------------------------------------------------------------------------------------------
admin@example.com                | cpaneluser   | GPCeCALKgzn6mGFP         | SIMULATED  | Dry-run (no changes made)
support@example.com              | cpaneluser   | CUgcSf16aBEoYgeV         | SIMULATED  | Dry-run (no changes made)
invalid-email-format             | none         | 9gLnu9VfvR6IJCsg         | FAILED     | Invalid email format
billing@unregistered-domain-999. | none         | 8YhVEdfUdWnSbOFJ         | FAILED     | Domain not registered on server
================================================================================================================
 Summary: 4 processed | Success/Simulated: 2 | Failed: 2
================================================================================================================
```

---

## License

Licensed under the [Apache-2.0 License](./LICENSE).
