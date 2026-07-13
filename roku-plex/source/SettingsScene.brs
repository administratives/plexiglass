' SettingsScene controller: load/save Plex settings using settings_store.brs
sub init()
  m.top = m.top
  m.serverField = m.top.findNode("serverField")
  m.portField = m.top.findNode("portField")
  m.tokenField = m.top.findNode("tokenField")
  m.saveButton = m.top.findNode("saveButton")
  m.cancelButton = m.top.findNode("cancelButton")
  m.statusLabel = m.top.findNode("statusLabel")

  ' Observe button presses
  m.saveButton.observeField("buttonSelected", "onSavePressed")
  m.cancelButton.observeField("buttonSelected", "onCancelPressed")

  ' Load existing settings if present
  settings = LoadSettings()
  if settings <> invalid then
    if m.serverField <> invalid then m.serverField.text = settings.plexServer
    if m.portField <> invalid then m.portField.text = str(settings.plexPort)
    if m.tokenField <> invalid then m.tokenField.text = settings.plexToken
  end if
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

  settings = {
    plexServer: server,
    plexPort: port,
    plexToken: token
  }
  ok = SaveSettings(settings)
  if ok then
    m.statusLabel.text = "Settings saved"
    ' Close this scene to return to main
    m.top.close = true
  else
    m.statusLabel.text = "Failed to save settings"
  end if
end sub

sub onCancelPressed(event)
  m.top.close = true
end sub
