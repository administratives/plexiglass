# Roku Plex (prototype)

This directory contains an initial scaffold and design notes for a Roku app that turns your Plex metadata into channels, schedules, and music stations without requiring you to run another server — the Roku app talks directly to your Plex server on the LAN using the Plex HTTP API and a user-provided token.

This is a starting point: files here are placeholders and design notes. Implementation work required in BrightScript/SceneGraph to parse Plex responses, handle authentication, and build UI elements.

Goals
- Let users point the Roku app at their Plex server (IP/hostname + port) and supply a Plex token.
- Discover libraries (movies, shows, music) and present them as channels.
- Allow creating schedules (timed playlists) and music stations (artist/genre-driven playback) based on Plex metadata.
- No extra server: the Roku app directly queries Plex API endpoints over HTTP.

Security notes
- Users must provide a Plex token. Store it in device settings or the ROKU registry following Roku best practices for credentials.
- The app assumes local network access to the Plex server.

Next steps
1. Implement a lightweight Plex client in BrightScript (roUrlTransfer wrappers).  
2. Implement JSON/XML parsing and data models for Plex sections, playlists, and items.  
3. Build SceneGraph UI components for channel grids, schedules editor, and music station player.  
4. Add settings screen for Plex server URL, port, and token.  
5. Test on device with a local Plex server.
