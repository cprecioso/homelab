#!/usr/bin/env python3
"""Take a consistent, verified snapshot of the Paperless SQLite DB.

Runs inside the Paperless image as the paperless user (see
paperless-db-backup.container). Writes /data/backup/db.sqlite3, replaced
atomically only after the copy passes an integrity check, and exits non-zero
on any failure so the systemd unit fails visibly and skips the upload.
"""

import os
import sqlite3
import sys

SRC = sys.argv[1] if len(sys.argv) > 1 else "/data/db.sqlite3"
DST = sys.argv[2] if len(sys.argv) > 2 else "/data/backup/db.sqlite3"
TMP = DST + ".tmp"


def main() -> None:
    os.makedirs(os.path.dirname(DST), exist_ok=True)
    if os.path.exists(TMP):
        os.remove(TMP)

    # mode=rw: fail if the DB is missing instead of creating an empty one.
    src = sqlite3.connect(f"file:{SRC}?mode=rw", uri=True, timeout=30)
    try:
        # VACUUM INTO runs in a single read transaction, so the copy is a
        # consistent snapshot even while Paperless keeps writing (WAL mode).
        src.execute("VACUUM INTO ?", (TMP,))
    finally:
        src.close()

    copy = sqlite3.connect(TMP)
    try:
        (result,) = copy.execute("PRAGMA integrity_check").fetchone()
        if result != "ok":
            sys.exit(f"integrity_check failed on snapshot: {result}")
        (count,) = copy.execute("SELECT count(*) FROM documents_document").fetchone()
    finally:
        copy.close()

    os.replace(TMP, DST)
    print(f"ok, {count} documents")


if __name__ == "__main__":
    main()
