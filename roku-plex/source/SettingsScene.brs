' SettingsScene controller: load/save Plex settings using settings_store.brs and verify registry persistence
sub init()
  m.top = m.top
  m.serverField = m.top.findNode("serverField")
  m.portField = m.top.findNode("portField")
  m.tokenField = m.top.findNode("tokenField")
  m.verifyButton = m.top.findNode("verifyButton")
  m.saveButton = m.top.findNode("saveButton")
  m.cancelButton = m.top.findNode("cancelButton")
  m.statusLabel = m.top.findNode("statusLabel")

  ' Observe button presses
  m.verifyButton.observeField("buttonSelected", "onVerifyPressed")
  m.saveButton.observeField("buttonSelected", "onSavePressed")
  m.cancelButton.observeField("buttonSelected", "onCancelPressed")

  ' Track last verification state so Save can require a verification
  m.lastVerificationPassed = false
  m.lastVerifiedServer = ""
  m.lastVerifiedPort = 0
  m.lastVerifiedToken = ""

  ' Load existing settings if present
  settings = LoadSettings()
  if settings <> invalid then
    if m.serverField <> invalid then m.serverField.text = settings.plexServer
    if m.portField <> invalid then m.portField.text = str(settings.plexPort)
    if m.tokenField <> invalid then m.tokenField.text = settings.plexToken
  end if
end sub

sub onVerifyPressed(event)
  server = m.serverField.text
  portText = m.portField.text
  token = m.tokenField.text

  if server = invalid or server = "" then
    m.statusLabel.text = "Server is required to verify"
    m.lastVerificationPassed = false
    return
  end if
  if portText = invalid or portText = "" then
    port = 32400
  else
    port = Val(portText)
    if port = 0 then port = 32400
  end if

  m.statusLabel.text = "Verifying..."
  ' Call PlexGetSections (defined in plex_client.brs)
  sections = PlexGetSections(server, port, token)
  if sections = invalid then
    m.statusLabel.text = "Verification failed: no response from server"
    m.lastVerificationPassed = false
    return
  end if
  if sections.Count() = 0 then
    m.statusLabel.text = "Verification failed: no libraries found (check token or server)"
    m.lastVerificationPassed = false
    return
  end if

  ' success
  m.statusLabel.text = "Verified: " + str(sections.Count()) + " libraries"
  m.lastVerificationPassed = true
  m.lastVerifiedServer = server
  m.lastVerifiedPort = port
  m.lastVerifiedToken = token
end sub

sub onSavePressed(event)
  server = m.serverField.text
  portText = m.portField.text
  token = m.tokenField.text

  if server = invalid or server = "" then
    m.statusLabel.text = "Server is required"
    return
  end if
  if portText = invalid or portText = "" then
    port = 32400
  else
    port = Val(portText)
    if port = 0 then port = 32400
  end if

  ' Require verification for these exact credentials before saving
  if not (m.lastVerificationPassed and m.lastVerifiedServer = server and m.lastVerifiedPort = port and m.lastVerifiedToken = token) then
    ' perform verification synchronously
    onVerifyPressed(event)
    if not m.lastVerificationPassed then
      ' verification failed
      return
    end if
  end if

  settings = {
    plexServer: server,
    plexPort: port,
    plexToken: token
  }
  ok = SaveSettings(settings)
  if ok then
    ' Verify by re-loading from registry
    reloaded = LoadSettings()
    if reloaded <> invalid and reloaded.plexServer = settings.plexServer then
      m.statusLabel.text = "Settings saved to registry"
      ' Close this scene to return to main
      m.top.close = true
      return
    else
      m.statusLabel.text = "Saved, but registry verification failed"
      ' still close as tmp:/ fallback may exist
      m.top.close = true
      return
    end if
  else
    m.statusLabel.text = "Failed to save settings"
  end if
end sub

sub onCancelPressed(event)
  m.top.close = true
end sub
