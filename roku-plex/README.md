# Roku Plex — README

This README documents the Roku Plex SceneGraph application scaffold in this repository. It explains architecture, features, how to build/sideload, and how the caching/refresh/quality/player systems work.

Overview

Roku Plex is a standalone Roku SceneGraph app that queries a local Plex Media Server (PMS) on the LAN and exposes your libraries as in-app "channels" using declarative rules. The app talks directly to Plex's HTTP API using the user's X-Plex-Token and does not require an external server.

Key features

- Rule-based channels: JSON rules describe how to derive channels/stations from Plex metadata (genre, collections, min_rating, sorting, limit, refresh intervals).
- Plex connectivity verification: Settings -> Verify fetches /library/sections and displays discovered libraries before you save credentials.
- Persistent settings: Plex host, port and token are saved in the Roku registry (RORegistrySection) and survive reboots; tmp:/ fallback kept for compatibility.
- Pagination & caching: Large libraries are fetched in pages and feeds are cached with TTL to avoid repeated heavy requests.
- Background refresh worker: a SceneGraph Task periodically refreshes expired caches off the UI thread (low-frequency default) to keep feeds fresh.
- Playback with quality presets: Player prefers direct part URLs but can request transcoded streams tuned for low/med/high quality.
- Player OSD: basic status, progress (elapsed/duration), buffering indicator, play/pause and quality switch that restarts playback mid-stream.
- Debug/diagnostics screen: see cache age, last refresh times, and last verification results for debugging.

Directory layout (relevant)

- roku-plex/
  - manifest
  - README.md (this file)
  - components/
    - MainScene.xml
    - SettingsScene.xml
    - PlayerScene.xml
    - DebugScene.xml
    - BackgroundTask.xml
  - source/
    - app_main.brs
    - MainScene.brs
    - SettingsScene.brs
    - PlayerScene.brs
    - DebugScene.brs
    - plex_client.brs
    - rules_engine.brs
    - settings_store.brs
    - cache.brs
    - background_task.brs
  - rules/
    - example_rules.json

Quick start (sideload)

1. Package the roku-plex folder into a zip with the manifest at the package root.
2. Enable Developer Mode on your Roku device and open the dev web server (http://<ROKU_IP>:8060).
3. Upload the package zip and install the app.
4. Launch the app on the device -> open Settings.
   - Enter your Plex server host/IP, port (default 32400), and X-Plex-Token.
   - Press "Verify" to ensure the token and server are reachable and to view discovered libraries.
   - Press "Save" to persist credentials to the device registry.
5. Return to the Main scene. The app will populate channels using cached feeds or fetch fresh feeds if needed.

How channel rules and caching work

- Rules are JSON objects (see rules/example_rules.json) describing type (movie/show/music), filters, sort, limit and refresh_interval_minutes.
- When a rule is requested, the rules engine first checks the cache.
  - Cache lookup uses a registry-backed store (RORegistrySection "roku-plex-cache") and a tmp:/ file as fallback. Cached items are stored along with created_at and TTL metadata.
  - If an unexpired cache entry exists, it's returned immediately for fast UI rendering.
  - On cache miss or expired entry, the engine pages through Plex section(s) using /library/sections/{key}/all?start=X&size=Y and applies filters locally. The result is cached with TTL = rule.refresh_interval_minutes.
- Background refresh: a SceneGraph Task (BackgroundTask) wakes periodically (low frequency) and proactively refreshes any expired caches so feeds are likely fresh when the user opens the app.

Cache persistence and rehydration

- Cache data is stored in the Roku registry (RORegistrySection "roku-plex-cache") under keys derived from the rule and host; this survives reboots.
- For faster local read/write we also write a tmp:/ file as a fallback and for debug visibility. On startup, the app will prefer registry cache entries and will rehydrate the in-memory index for quick lookups.

Playback and quality presets

- BuildPlayableUrlForRatingKey(host, port, token, ratingKey, quality)
  - Attempts to find a direct partKey in metadata and returns a server-proxied URL with X-Plex-Token appended.
  - If direct access is unavailable, constructs a /video/:/transcode/universal/start URL tuned for the requested quality preset (low/med/high) and requests an MP4 container.
- Player OSD
  - Shows title, a status label (Playing/Paused/Buffering), and a progress label (elapsed/duration).
  - Play/Pause/Skip buttons supported; quality switch button restarts playback with the new quality.

Debug and diagnostics

- Debug scene exposes cache metadata (created_at, ttl, age), last verification results (server, libraries found), and the registry keys used by the app. Useful when troubleshooting connectivity or caching behavior.

Security notes

- The X-Plex-Token is stored in the device registry in plaintext. This is the same as many Roku apps that require locally-stored credentials. For production consider minimizing token privileges, prompting for short-lived tokens, or adding an on-device encryption layer.

Limitations & next steps

- The Player OSD and seeking are basic and may need improvements for precise seeking, buffering state, and closed captions.
- Transcoder parameters may need tuning per Plex server. Consider exposing quality presets in the Settings UI for advanced tuning.
- Very large libraries still require careful UX (lazy-loaded channel detail pages, per-channel pagination). The current approach caches feeds and supports paging to limit single requests.
- Background tasks must be careful with CPU/time on Roku devices; defaults are intentionally low-frequency.

Contributing

- This scaffold aims to be a starting point. If you want to contribute:
  - Implement more robust XML->JSON mapping and handle variations in Plex server versions.
  - Add per-rule UI for including/excluding specific libraries (from the verified list).
  - Add unit tests or integration tests for parsing, transcoder URL generation, and cache behavior.

Contact/Support

- For quick help: open an issue in this repository describing your device model, Plex server version, and example logs (use the Debug screen to gather cache and verification info).
