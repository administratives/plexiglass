' PlayerScene controller. Sets the video content to the Video node and handles basic events and controls
sub init()
  m.top = m.top
  m.video = m.top.findNode("videoPlayer")
  m.titleLabel = m.top.findNode("titleLabel")
  m.statusLabel = m.top.findNode("statusLabel")
  m.progressLabel = m.top.findNode("progressLabel")
  m.contentUrl = m.top.contentUrl
  m.isPlaying = false
  m.positionSeconds = 0
  m.durationSeconds = 0

  if m.top.title <> invalid then m.titleLabel.text = m.top.title
  if m.contentUrl <> "" then
    content = { url: m.contentUrl, title: m.top.title }
    m.video.content = content
    m.video.control = "play"
    m.isPlaying = true
    m.statusLabel.text = "Playing"
  else
    m.titleLabel.text = "No playable URL"
  end if
end sub

sub onKeyEvent(key as String, press as Boolean)
  if press = false then return
  keyLower = LCase(key)
  if keyLower = "back" or keyLower = "backspace" or keyLower = "escape" then
    m.top.close = true
    return
  end if
  if keyLower = "play" or keyLower = "play/pause" then
    if m.isPlaying then
      m.video.control = "pause"
      m.isPlaying = false
      m.statusLabel.text = "Paused"
    else
      m.video.control = "play"
      m.isPlaying = true
      m.statusLabel.text = "Playing"
    end if
    return
  end if
  if keyLower = "pause" then
    m.video.control = "pause"
    m.isPlaying = false
    m.statusLabel.text = "Paused"
    return
  end if
  ' Fast forward / rewind handling (best-effort)
  if keyLower = "forward" or keyLower = ">" then
    ' try to seek forward 30s if supported
    m.video.control = "skipForward"
    m.statusLabel.text = "Skipping forward"
    return
  end if
  if keyLower = "reverse" or keyLower = "<" then
    m.video.control = "skipBack"
    m.statusLabel.text = "Skipping back"
    return
  end if
end sub

sub onFieldChanged(fieldName as String)
  ' placeholder to react to videoPlayer state/position fields if available
end sub
