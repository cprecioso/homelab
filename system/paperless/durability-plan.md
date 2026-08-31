# Paperless: data durability notes

Written after the Aug 2026 SQLite corruption incident. Read this before
touching the Paperless setup. Sections: current setup and how to restore,
then the incident history for context.

## Current setup (since 2026-08-31, on turing)

- Paperless-ngx runs on **turing**; all paperless units are masked on tuareg
  (per-host masking convention, see below). Media (`originals/`, `archive/`,
  thumbnails) stays on the rclone VFS mount `var-mnt-paperless-media.mount`
  (`paperless-backend:media`, alias for `b2-eu:cpd-paperless`).
- The **data dir** (`db.sqlite3`, `index/`, `classification_model.pickle`,
  `celerybeat-schedule.db`, `log/`) lives on local disk in the podman volume
  `systemd-paperless-data` (quadlet `paperless-data.volume`), host path
  `/var/lib/containers/storage/volumes/systemd-paperless-data/_data`, owned by
  uid/gid 1000 (the in-container `paperless` user).
- **Hourly DB backups**: `paperless-db-backup.timer` -> `paperless-db-backup.service`
  (quadlet `paperless-db-backup.container`). It runs `db-dump.py` inside the
  Paperless image as uid 1000: `VACUUM INTO` (a consistent snapshot even while
  Paperless writes), `PRAGMA integrity_check`, doc count, atomic rename to
  `_data/backup/db.sqlite3`. Then, on the host, `rclone copyto` uploads it as
  `paperless-backend:backups/db/db-<UTC timestamp>.sqlite3` and prunes copies
  older than 14 days. A failed snapshot fails the unit (visible in
  `systemctl --failed`) and skips the upload. Note: the schema has a CHECK
  constraint using Django's `REGEXP`; any plain-sqlite tool that copies or
  checks this DB (`VACUUM INTO`, `integrity_check`) must register a
  deterministic `regexp(pattern, value)` function first, as `db-dump.py` does.
- Why not Litestream: evaluated 2026-08-31; 0.5.x still had an open
  restore-corruption issue (benbjohnson/litestream#1164) and fresh 0.5.16
  bugs. For an ~9 MB household DB, hourly snapshots are nearly as good and
  have no third-party correctness risk.
- Not backed up by design: `index/` and the classifier (rebuildable),
  `log/`, the broker volume (task queue only).

### Restore procedure

1. Pick a snapshot: `rclone lsl paperless-backend:backups/db/` (needs
   `--config /etc/credstore/rclone-podman.conf` as root).
2. `systemctl stop paperless-webserver.service paperless-pod.service`.
3. In `/var/lib/containers/storage/volumes/systemd-paperless-data/_data/`:
   move the current `db.sqlite3` aside, delete any `db.sqlite3-wal` /
   `db.sqlite3-shm`, `rclone copyto paperless-backend:backups/db/<file> db.sqlite3`,
   `chown 1000:1000 db.sqlite3`.
4. `systemctl start paperless-webserver.service`.
5. Health check: `curl -sI -H 'Host: turing.turtle-bebop.ts.net' http://127.0.0.1:8023/`
   must return 302 (without the Host header Django answers 400, that is normal).
6. If the index is missing or stale:
   `podman exec systemd-paperless-webserver document_index reindex`. The
   classifier retrains on its own schedule. Run the sanity checker; documents
   consumed after the snapshot show up as orphan media files and can be
   re-consumed from B2 `media/originals/`.

On a brand-new host: install credstore files per `system/readme.md`, boot the
image, stop paperless, restore as above into the (empty) volume, start.

### Per-host masking

Only one host may run Paperless (it owns the media mount and the backups).
On the idle host (tuareg today) these are masked (`/dev/null` symlinks in
`/etc/systemd/system/`): `paperless-{pod,webserver,broker,gotenberg,tika}
[-image].service`, `paperless-broker-data-volume.service`,
`paperless-data-volume.service`, `paperless-db-backup.{service,timer}`,
`var-mnt-paperless-media.mount`. The mount file is a real file in the image,
so `systemctl mask` refuses; replace it with a `/dev/null` symlink by hand.

### Host-only config not in this repo

`/etc/containers/systemd/paperless-webserver.container.d/` on turing holds
drop-ins (localization, no-duplicates, oidc, secret, tailscale) that exist only
in host `/etc`. bootc merges `/etc`, so they survive image updates. tsidp runs
on a dedicated `idp` tailnet node; `tsidp.service` is masked on both hosts.
Tailscale Service `svc:paperless` is served from turing
(`tailscale serve --service=svc:paperless --https=443 http://127.0.0.1:8023`).

### Cleanup TODO (after a couple of weeks healthy, i.e. mid-September 2026)

- Delete the superseded `data/` prefix on B2: `rclone purge paperless-backend:data`
  (keep `media/` and `backups/`).
- Remove `/root/paperless-rescue/` on tuareg and `/root/restore-test/` on turing.

## Incident history (Aug 2026)

- The DB used to live on an rclone VFS mount (`var-mnt-paperless-data.mount`
  -> `paperless-backend:data`). The nightly bootc-update reboot on
  **2026-08-13 05:02** corrupted `db.sqlite3` ("database disk image is
  malformed"). Paperless limped on until the **2026-08-29** reboot, after which
  the webserver crashed at startup.
- The B2 bucket keeps only the latest version of each file and the rclone
  remote has `hard_delete = true`, so there were no historical DB copies.
- Recovery (2026-08-30, on tuareg) rebuilt the DB from three sources: the
  readable parts of the corrupted DB (250 of 258 document rows had corrupted
  overflow chains), the **tantivy search index** (`data/index/`, which stores
  per doc: id, title, full OCR content, sha256, original filename, dates,
  page count, custom field values, correspondent/type/owner ids; a complete
  snapshot as of Jul 26), and the intact media tree (storage filenames plus
  recomputed sha256). Remember: **the tantivy index is a de-facto metadata
  backup** for any future paperless-ngx disaster.
- Genuinely lost (minor): task history, ~174 audit log rows, sessions,
  workflow trigger filter lists (1 workflow existed, recheck it in the UI),
  at most 1 custom field value, and the version link between doc 456 and its
  root doc 439 (456 restored standalone; file `originals/0000439_v1.pdf`).
- Known-benign sanity-checker leftovers: ~11 orphan-file warnings (`.bzEmpty`
  markers, deleted doc 436's files, superseded pre-version files
  `originals/0000437.pdf`, `originals+archive/0000438.pdf`).
- Rescue artefacts (corrupted db, rebuild scripts, `final.db`,
  `media-sha256.txt`) are in `/root/paperless-rescue/` on tuareg.
- 2026-08-31 morning: Paperless moved from tuareg to turing (same quadlets and
  image, data still on the B2 mounts at that point, db sha256 verified
  identical). Same day, later: data dir moved to the local volume and hourly
  backups added (commits be2042c, 374738b), deployed via `bootc upgrade` +
  reboot at 12:17 CEST; first snapshot `db-20260831T102016Z.sqlite3` restored
  and verified the same day.
