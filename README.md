# qBittorrent Excluded Files Auto-Remover

This script automatically checks newly added torrents in **qBittorrent** and deletes them when they contain files that match a predefined exclusion list.

It can also integrate with:

- **Radarr** → mark release as failed / blocklisted
- **Sonarr** → mark release as failed / blocklisted
- **Auto re-search** → optionally trigger a new search in Radarr/Sonarr
- **Local cache** → avoid processing the same torrent hash repeatedly

The script is designed to run from qBittorrent’s **Run external program on torrent added** hook.

---

## Features

- Checks torrent file list through qBittorrent Web API
- Supports glob-style exclusion patterns
- Deletes torrent and data when an excluded file is found
- Optional Radarr failed-download integration
- Optional Sonarr failed-download integration
- Optional Radarr auto re-search
- Optional Sonarr auto re-search
- Optional processed-hash cache
- Handles metadata delay by retrying file-list lookups
- Works well in Docker/containerized setups

---

## Requirements

- `bash`
- `curl`
- `jq`
- qBittorrent WebUI enabled on port `9090`

Install dependencies on Debian/Ubuntu:

```bash
apt-get update && apt-get install -y curl jq
Files

Example layout:

/config/
├── checker.sh
├── excluded-files.txt
└── excluded-processed-hashes.txt
Exclusion List

The file excluded-files.txt contains patterns that should cause the torrent to be deleted.

Example
# comments are ignored

*.exe
*.iso
*.zip
*.rar
*.nfo
*.txt

*sample*
*trailer*
*vostfr*
Pattern matching rules

Case-insensitive

Uses Bash glob matching

Examples:

*.exe → any executable

*.iso → any ISO

*sample* → anything containing sample

trailer.* → anything starting with trailer

How It Works

qBittorrent adds a torrent

qBittorrent runs the external program and passes the torrent hash

Script queries qBittorrent for the file list

Script compares every file against excluded-files.txt

If a match is found:

torrent is deleted from qBittorrent

files are deleted

optional Radarr/Sonarr integration runs

optional auto re-search is triggered

optional cache is updated

qBittorrent Setup
1. Copy the script and exclusion file

Example:

/config/checker.sh
/config/excluded-files.txt

Make it executable:

chmod +x /config/checker.sh
2. Ensure WebUI is enabled

The script expects qBittorrent WebUI at:

http://127.0.0.1:9090
3. Configure the external program hook

In qBittorrent:

Tools → Options → Downloads

Enable:

Run external program on torrent added

Command:

/config/checker.sh "%I"

%I is the torrent hash and is required.

Environment Variables
Core
QBT_URL=http://127.0.0.1:9090
EXCLUDED_LIST_FILE=/config/excluded-files.txt
MAX_TRIES=30
SLEEP_SECONDS=2
ARR_PAGE_SIZE=1000
ARR_HISTORY_PAGES=5
Cache
ENABLE_CACHE=true
HASH_CACHE_FILE=/config/excluded-processed-hashes.txt
Radarr
ENABLE_RADARR=true
RADARR_URL=http://192.168.0.244:8990
RADARR_API_KEY=your_radarr_api_key
ENABLE_RADARR_RESEARCH=false
Sonarr
ENABLE_SONARR=true
SONARR_URL=http://192.168.0.244:8989
SONARR_API_KEY=your_sonarr_api_key
ENABLE_SONARR_RESEARCH=false
Feature Flags

You can independently enable or disable each feature:

ENABLE_CACHE=true
ENABLE_RADARR=true
ENABLE_SONARR=true
ENABLE_RADARR_RESEARCH=false
ENABLE_SONARR_RESEARCH=false

Accepted enabled values:

true

1

yes

on

Anything else is treated as disabled.

Docker Compose Example
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Fortaleza

      - QBT_URL=http://127.0.0.1:9090
      - EXCLUDED_LIST_FILE=/config/excluded-files.txt
      - MAX_TRIES=30
      - SLEEP_SECONDS=2
      - ARR_PAGE_SIZE=1000
      - ARR_HISTORY_PAGES=5

      - ENABLE_CACHE=true
      - HASH_CACHE_FILE=/config/excluded-processed-hashes.txt

      - ENABLE_RADARR=true
      - RADARR_URL=http://192.168.0.244:8990
      - RADARR_API_KEY=your_radarr_api_key
      - ENABLE_RADARR_RESEARCH=true

      - ENABLE_SONARR=true
      - SONARR_URL=http://192.168.0.244:8989
      - SONARR_API_KEY=your_sonarr_api_key
      - ENABLE_SONARR_RESEARCH=true

    volumes:
      - /path/to/config:/config
      - /path/to/downloads:/downloads
    ports:
      - 9090:9090
Radarr / Sonarr Integration

When enabled, the script tries to find the torrent in Radarr or Sonarr using the torrent hash (downloadId) and then marks the matching history item as failed.

Radarr behavior

Finds the newest matching grab history item

Calls:

POST /api/v3/history/failed/{id}

If that succeeds, the release is treated as failed / blocklisted

If enabled, can then trigger a new movie search

Sonarr behavior

Finds the newest matching grab history item

Calls:

POST /api/v3/history/failed/{id}

If that succeeds, the release is treated as failed / blocklisted

If enabled, can then trigger a new series search

Queue fallback

If no matching history entry is found, the script attempts queue lookup and removal with blocklisting enabled.

Auto Re-search

Optional re-search can be enabled separately for Radarr and Sonarr.

Radarr
ENABLE_RADARR_RESEARCH=true

If a release is marked as failed or removed from queue with blocklist, the script tries to trigger a new movie search.

Sonarr
ENABLE_SONARR_RESEARCH=true

If a release is marked as failed or removed from queue with blocklist, the script tries to trigger a new series search.

Cache

When enabled:

ENABLE_CACHE=true

the script stores processed torrent hashes in:

/config/excluded-processed-hashes.txt

This helps avoid processing the same torrent hash repeatedly.

If needed, disable cache temporarily:

ENABLE_CACHE=false

or manually remove:

/config/excluded-processed-hashes.txt
Example Output
Match found
Got file list for torrent 82f791975f6bc5a927684faf0c114f17db43b9d1 after 3 attempt(s) (1 file(s))
Matched: *.exe -> Project Hail Mary 2026 1080p HD X264 1080p.exe
Torrent 82f791975f6bc5a927684faf0c114f17db43b9d1 deleted because of excluded file: Project Hail Mary 2026 1080p HD X264 1080p.exe
Cached processed hash: 82f791975f6bc5a927684faf0c114f17db43b9d1
Checking Radarr...
Radarr newest history match: 11438
Radarr history/failed/{id} HTTP: 200
Radarr marked as failed for history id 11438
Radarr auto re-search for movie id 401
Radarr re-search HTTP: 201
Checking Sonarr...
Sonarr: no history grab match found
Sonarr: fallback queue...
Sonarr: no match found
No excluded file
No excluded files
Cached hash
Hash already processed and cached: 82f791975f6bc5a927684faf0c114f17db43b9d1
Troubleshooting
qBittorrent: no excluded file found

check that the exclusion pattern is correct

use glob patterns like *.exe or *sample*

confirm the file list is actually populated

qBittorrent: could not get file list

magnet metadata may not be ready yet

increase:

MAX_TRIES=60
SLEEP_SECONDS=2
Radarr/Sonarr: no match found

torrent may not have originated from that app

history may not yet exist

queue entry may already be gone

hash may belong only to Radarr or only to Sonarr

Radarr/Sonarr: integration enabled, but nothing happens

verify API key

verify URL

confirm that the hash is present in the app history or queue

confirm the release was grabbed by that app

Cache causing skipped runs

Disable cache temporarily:

ENABLE_CACHE=false

or manually remove:

/config/excluded-processed-hashes.txt
Notes

The script deletes torrents permanently from qBittorrent when a match is found.

Use carefully and test with a limited exclusion list first.

Radarr and Sonarr blocklisting are handled in the correct place: inside Radarr/Sonarr themselves.

Prowlarr is intentionally not part of this version.

Future Ideas

notifications via Telegram / Discord

structured file logging

dry-run mode

smarter file heuristics by size / extension / keyword

whitelist mode instead of blacklist mode

License

MIT License

Contributing

Pull requests and improvements are welcome.
