# Architecture Notes — Day 01 Backup Script

## Flow

```
backup.sh
    │
    ├── preflight()       — validate source, create dest, check disk space
    │
    ├── create_backup()   — tar + gzip → .tar.gz + .sha256
    │
    ├── verify_backup()   — tar --test-file (integrity check)
    │
    ├── rotate_backups()  — find + delete archives older than N days
    │
    └── send_alert()      — optional email via mail(1)
```

## Key Design Decisions

**`set -euo pipefail`** — exits immediately on any error (`-e`), treats unset variables as errors (`-u`), and ensures pipes propagate failures (`-o pipefail`). This prevents silent failures where backup continues after a partial error.

**`trap ERR`** — registers a handler that fires if any command exits non-zero after the trap is set. Used to send failure emails and print a summary even when the script aborts unexpectedly.

**SHA-256 checksum** — written alongside the archive so that after a restore or transfer you can verify the file was not corrupted (`sha256sum -c archive.tar.gz.sha256`).

**Exclusion list** — `.git`, `node_modules`, `__pycache__`, `.DS_Store` are excluded by default to avoid backing up large generated/derived files that can be recreated.

**Logging to file + stdout** — `tee -a` sends every log line to both the terminal and a daily log file, making it easy to grep history and also see live output when running manually.
