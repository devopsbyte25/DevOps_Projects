# 01 — Automated Backup Script

> Beginner | Project 1/N

A production-quality shell script that backs up any directory to a compressed, checksummed archive — with cron scheduling, retention-based rotation, and optional email alerts on failure.

---

## Features

- Compressed `.tar.gz` archives with `SHA-256` checksum verification
- Configurable retention policy (auto-delete backups older than N days)
- Structured timestamped logging to `logs/`
- Email alert on backup failure (requires `mail`)
- Pre-flight checks: source existence, read permissions, disk space
- One-command cron installer (`install_cron.sh`)
- Full test suite (`tests/test_backup.sh`)
- GitHub Actions CI: shellcheck lint + integration tests

---

## Project Structure

```
01-automated_backup/
├── scripts/
│   ├── backup.sh          # Main backup script
│   └── install_cron.sh    # Cron job installer
├── tests/
│   └── test_backup.sh     # Integration test suite
├── logs/                  # Auto-created at runtime
├── docs/
│   └── architecture.md    # Design notes
├── .github/
│   └── workflows/
│       └── ci.yml         # GitHub Actions pipeline
├── .gitignore
└── README.md
```

---

## Prerequisites

| Tool         | Purpose                 | Check                  |
| ------------ | ----------------------- | ---------------------- |
| `bash` 4.0+  | Script runtime          | `bash --version`       |
| `tar`        | Archive creation        | `tar --version`        |
| `sha256sum`  | Checksum generation     | `sha256sum --version`  |
| `cron`       | Scheduling (optional)   | `crontab -l`           |
| `mail`       | Email alerts (optional) | `which mail`           |
| `shellcheck` | Linting in CI           | `shellcheck --version` |

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/devopsbyte25/DevOps_Projects/devops-projects-lab/01-automated_backup.git
cd 01-automated_backup

# 2. Make scripts executable
chmod +x scripts/*.sh tests/*.sh

# 3. Run a manual backup
./scripts/backup.sh --source /path/to/source --dest /path/to/dest

# 4. Run with all options
./scripts/backup.sh \
  --source /var/www/html \
  --dest   /mnt/backups \
  --retain 14 \
  --email  ops@example.com

# 5. Install daily cron job (runs at 2:00 AM)
./scripts/install_cron.sh --email ops@example.com

# 6. Run tests
bash tests/test_backup.sh
```

---

## Options

| Flag       | Short | Default        | Description              |
| ---------- | ----- | -------------- | ------------------------ |
| `--source` | `-s`  | `$HOME`        | Directory to back up     |
| `--dest`   | `-d`  | `/tmp/backups` | Where to store archives  |
| `--retain` | `-r`  | `7`            | Days to keep old backups |
| `--email`  | `-e`  | _(none)_       | Alert email on failure   |
| `--help`   | `-h`  | —              | Show usage               |

---

## Output

Each run produces:

```
/path/to/dest/
  backup_hostname_20240616_020001.tar.gz
  backup_hostname_20240616_020001.tar.gz.sha256

logs/
  backup_20240616.log
```

Sample log output:

```
[2024-06-16 02:00:01] [INFO]  === Backup started on myhost ===
[2024-06-16 02:00:01] [INFO]  Running pre-flight checks...
[2024-06-16 02:00:01] [OK]    Pre-flight checks passed
[2024-06-16 02:00:01] [INFO]  Creating archive: /mnt/backups/backup_myhost_20240616_020001.tar.gz
[2024-06-16 02:00:04] [OK]    Archive created: backup_myhost_20240616_020001.tar.gz (142M)
[2024-06-16 02:00:04] [INFO]  Verifying integrity...
[2024-06-16 02:00:05] [OK]    Integrity check passed
[2024-06-16 02:00:05] [INFO]  Rotating backups older than 7 days...
[2024-06-16 02:00:05] [OK]    Rotated 1 backup(s)
[2024-06-16 02:00:05] [OK]    Done in 4s
```

---

## CI/CD Pipeline

GitHub Actions runs on every push and pull request:

1. **Lint** — `shellcheck` on all `.sh` files
2. **Test** — full integration test suite (8 tests)

[![CI](https://github.com/YOUR_USERNAME/day01-automated-backup/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/day01-automated-backup/actions/workflows/ci.yml)

---

## What I Learned

- `set -euo pipefail` and why it matters for safe shell scripts
- Using `trap ERR` for cleanup and alerting on unexpected failures
- `tar` flags for exclusions, compression, and integrity testing
- `sha256sum` for verifying archive integrity post-transfer
- `find -mtime` for date-based file rotation
- `crontab` syntax and automating its installation
- `shellcheck` for catching common shell script bugs before they hit production

---

## Possible Improvements

- [ ] Add S3/GCS upload support (`aws s3 cp` or `gsutil cp`)
- [ ] Encrypt archives with GPG before storing
- [ ] Support incremental backups with `rsync --link-dest`
- [ ] Add Slack webhook notification alongside email
- [ ] Build a small dashboard to visualise backup history

---

## License

MIT
