#!/usr/bin/env bash
# Nightly full Forgejo backup: repos, database (as SQL), app.ini with its secrets,
# attachments, avatars, LFS. Run by forgejo-dump.timer as thai; safe to run by hand.
# Output: /srv/forgejo/dumps/forgejo-dump-<timestamp>.zip. Copy these off the box (README.md).
set -euo pipefail

KEEP_DAYS=14
DUMPS=/srv/forgejo/dumps
ts=$(date +%Y%m%d-%H%M%S)
name="forgejo-dump-$ts.zip"
partial=".forgejo-dump-$ts.partial.zip"   # must end in .zip, or `forgejo dump` appends it

# Write under a hidden name and rename only on success, so a failed run never
# leaves a file that looks like a backup (and never counts toward retention).
trap 'rm -f "$DUMPS/$partial"' EXIT
docker exec -u git forgejo forgejo dump \
  --config /data/gitea/conf/app.ini \
  --type zip \
  --skip-log \
  --tempdir /tmp \
  --file "/dumps/$partial"
mv "$DUMPS/$partial" "$DUMPS/$name"
chmod 600 "$DUMPS/$name"

find "$DUMPS" -maxdepth 1 -name 'forgejo-dump-*.zip' -mtime +"$KEEP_DAYS" -delete
ls -lh "$DUMPS/$name"
