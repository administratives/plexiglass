' PlayerScene controller: shows elapsed/duration, buffering indicator, quality switch
sub init()
  m.top = m.top
  m.video = m.top.findNode("videoPlayer")
  m.titleLabel = m.top.findNode("titleLabel")
  m.statusLabel = m.top.findNode("statusLabel")
  m.progressLabel = m.top.findNode("progressLabel")
  m.qualityLabel = m.top.findNode("qualityLabel")
  m.qualityToggle = m.top.findNode("qualityToggle")

  m.qualityToggle.observeField("buttonSelected", "onQualityToggle")

  m.contentUrl = m.top.contentUrl
  m.quality = m.top.preferredQuality
  if m.quality = invalid or m.quality = "" then m.quality = "med"

  if m.top.title <> invalid then m.titleLabel.text = m.top.title
  if m.contentUrl <> "" then
    PlayWithQuality(m.contentUrl, m.quality)
  else
    m.titleLabel.text = "No playable URL"
  end if

  ' Start a timer for updating progress
  m.timer = CreateObject("roSGNode", "Task")
  ' This Task implements a simple loop to update progress while the scene is active
  m.timer.setField("run", true)
  m.timer.setField("intervalMs", 1000)
  m.timer.observeField("run", "onTimerRun")
end sub

sub PlayWithQuality(baseUrl, quality)
  ' baseUrl passed in is a ratingKey in previous MainScene usage; if it looks like a URL, use it directly
  if Instr(baseUrl, "http") = 0 then
    ' baseUrl is likely a ratingKey — MainScene previously passed ratingKey into content.url. Build playable url
    playUrl = BuildPlayableUrlForRatingKey(m.top.owner.plexServer ? "", m.top.owner.plexPort ? 32400, m.top.owner.plexToken ? "", baseUrl, quality)
  else
    playUrl = baseUrl
  end if
  m.currentUrl = playUrl
  content = { url: playUrl }
  m.video.content = content
  m.video.control = "play"
  m.isPlaying = true
  m.statusLabel.text = "Playing"
end sub

sub onTimerRun()
  ' Poll Video node for position and duration (best-effort). Some platform fields may differ; use available ones.
  ' This is a best-effort placeholder; real code should observe appropriate fields/events on the Video node.
  pos = m.video.position ? 0
  dur = m.video.duration ? 0
  if pos <> invalid and dur <> invalid and dur > 0 then
    elapsed = Round(pos)
    total = Round(dur)
    m.progressLabel.text = str(elapsed) + " / " + str(total) + "s"
  else
    ' Unknown position/duration — leave placeholder
    m.progressLabel.text = ""
  end if
end sub

sub onQualityToggle(event)
  ' Cycle through presets: low -> med -> high -> direct
  if m.quality = "low" then m.quality = "med" : qualityName = "Med"
  else if m.quality = "med" then m.quality = "high" : qualityName = "High"
  else if m.quality = "high" then m.quality = "direct" : qualityName = "Direct"
  else m.quality = "low" : qualityName = "Low"
  m.qualityLabel.text = "Quality: " + qualityName
  ' Restart playback with new quality by rebuilding playable URL using stored ratingKey or url
  ' If m.currentRatingKey exists, build URL from ratingKey
  if m.currentRatingKey <> invalid and m.currentRatingKey <> "" then
    newUrl = BuildPlayableUrlForRatingKey(m.top.owner.plexServer ? "", m.top.owner.plexPort ? 32400, m.top.owner.plexToken ? "", m.currentRatingKey, m.quality)
  else
    ' fallback: rebuild from currentUrl not possible; just attempt to play currentUrl
    newUrl = BuildPlayableUrlForRatingKey("", 0, "", m.currentUrl, m.quality)
  end if
  if newUrl <> "" then
    m.video.content = { url: newUrl }
    m.video.control = "play"
    m.statusLabel.text = "Playing (" + m.quality + ")"
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
end sub
