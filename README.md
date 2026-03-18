# qBittorrent Excluded Files Auto-Remover

This script automatically deletes torrents in **qBittorrent** when they contain files that match a predefined exclusion list.

It is designed to run using qBittorrent’s **"Run external program on torrent added"** feature and acts as a safeguard against unwanted content such as samples, executables, archives, or any custom patterns you define.

---

## 🚀 Features

- 🔍 Inspects torrent file list via qBittorrent Web API
- ⏳ Waits for metadata (works with magnet links)
- 🧠 Supports glob-style pattern matching (`*.exe`, `*sample*`, etc.)
- 🗑️ Automatically deletes torrent **and files**
- 📄 Fully customizable exclusion list
- 🐳 Works well in Docker environments

---

## ⚙️ Requirements

- `bash`
- `curl`
- `jq`
- qBittorrent with WebUI enabled (port **9090**)

Install dependencies (Debian/Ubuntu):

```bash
apt-get update && apt-get install -y curl jq

📁 Files
.
├── checker.sh
└── excluded-files.txt

🧾 Exclusion List

The file excluded-files.txt contains patterns of files you want to block.

Example:
# Ignore comments and empty lines

*.exe
*.iso
*.zip
*.rar

*sample*
*trailer*

*.nfo
*.txt
Pattern Rules

Uses Bash glob matching

Case-insensitive

Examples:

*.exe → any executable

*sample* → anything containing "sample"

trailer.* → files starting with "trailer"

*vostfr* → matches anywhere in filename

🔧 Configuration
1. Place the script

Example (Docker/qBittorrent container):

/config/checker.sh
/config/excluded-files.txt

Make it executable:

chmod +x /config/checker.sh
2. Enable qBittorrent WebUI

Ensure WebUI is enabled and running on:

http://127.0.0.1:9090
3. Configure qBittorrent hook

Go to:

Tools → Options → Downloads

Enable:

☑ Run external program on torrent added

Command:

/config/checker.sh "%I"

%I = torrent hash (required)

⚠️ Important Behavior
Metadata Delay (Magnet Links)

When adding torrents (especially magnets), file lists are not immediately available.

This script:

retries API calls

waits until files are available

avoids false negatives

🧪 How It Works

Torrent is added

Script is triggered with torrent hash

Script queries:

/api/v2/torrents/files

Waits until file list is populated

Compares each file against exclusion patterns

If a match is found:

Torrent is deleted

Files are deleted

🧾 Example Logs
Got file list for torrent abc123 after 3 attempt(s) (12 file(s))
Matched excluded pattern: *.exe -> movie.exe
Torrent abc123 deleted because of excluded file: movie.exe
No excluded files found in torrent def456
🐛 Troubleshooting
❌ "No excluded files found" but should match

Ensure patterns are correct (*.iso, not .iso)

Use *text* for substring matching

❌ "Could not get valid file list"

qBittorrent may not be ready yet

Increase retries:

MAX_TRIES=60
❌ Script works manually but not automatically

Ensure %I is used (torrent hash)

Confirm script path is correct inside container

Check permissions (chmod +x)

❌ Connection errors

Ensure correct URL:

http://127.0.0.1:9090
🔒 Notes

This script deletes torrents permanently

Use with caution

Recommended to test with a limited exclusion list first

💡 Future Improvements (optional ideas)

Regex support

Whitelist support

Logging to file

Notification (Telegram, Discord, etc.)

Dry-run mode

📄 License

MIT License (or your choice)

🤝 Contributing

Pull requests and improvements are welcome!


---
