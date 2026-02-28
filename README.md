# cPanel/WHM Email Password Auto-Changer 🔐

Readme: [BR](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/cpanel-changemail-pass) ![Shell Script](https://img.shields.io/badge/shell-script-green)

<img width="700" src="cp-changemail-pass-cover.webp" />

A simple and efficient Bash script to automate changing email account passwords directly via command line (SSH) on WHM/cPanel servers.

Developed to streamline the routine of infrastructure administrators and N2/N3 support, enabling quick password changes without the need to navigate through the cPanel graphical interface.

## 🚀 Features

* **Secure Password Generation:** Uses `openssl` to generate strong 16-character passwords.
* **Alphanumeric Formatting:** The generated password contains only letters and numbers, avoiding formatting and login issues in older email clients or those incompatible with special characters.
* **Input Validation:** Automatically checks whether the email format is valid and not blank.
* **Domain and User Verification:** Checks whether the domain resolves locally, if it is registered on the server (`/etc/trueuserdomains`), and automatically identifies the owner via `/scripts/whoowns`.
* **Native API Usage:** Uses the official cPanel `uapi` command, ensuring the change is performed cleanly and without failures (avoiding fragile parsing of internal files).

## 🛠️ Prerequisites

For the script to work correctly, you need:

* SSH access to the server with `root` privileges (required to read `/etc/trueuserdomains` and execute `/scripts/whoowns`).
* A server running **WHM/cPanel**.
* The `openssl` package installed (native on most Linux distributions).

## 📥 Installation [Hosted Mode]

1. **Download the file on the server:**

```bash
curl -O https://raw.githubusercontent.com/sr00t3d/cpanel-changemail-pass/refs/heads/main/cp-changemail-pass.sh
```

2. **Grant execution permission:**

```bash
chmod +x cp-changemail-pass.sh
```

3. **Run the script:**

```bash
./cp-changemail-pass.sh
```

## 💻 How to Use

### Hosted Mode

Run the script by passing the full email address as a parameter:

```bash
./cp-changemail-pass.sh mail@domain.com
```

### Direct Mode

```bash
bash <(curl -fsSL 'https://raw.githubusercontent.com/sr00t3d/cpanel-changemail-pass/refs/heads/main/cp-changemail-pass.sh') mail@domain.com
```

Successful Output Example:

```bash
Domain yourdomain.com.br is registered on the server

Password for the email address mail@domain.com successfully changed, see the details below:

Email: mail@domain.com
Password: aB3dE5fG7hI9jK1l
```

Error Output Example:

```bash
If the email does not exist or the format is invalid, the script will stop execution with a clear alert:

[!] - The email mail@domain.com does not exist on the server.
```

## ⚠️ Legal Notice

> [!WARNING]
> This software is provided "as is." Always ensure you have explicit permission before executing it. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

## 📚 Detailed Tutorial

For a complete, step-by-step guide, check out my full article:

👉 [**Quick change of cPanel email password**](https://perciocastelo.com.br/blog/quick-change-cpanel-email-password.html)

## License 📄

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.