' PlayerScene controller. Sets the video content to the Video node and handles basic events
sub init()
  m.top = m.top
  m.video = m.top.findNode("videoPlayer")
  m.titleLabel = m.top.findNode("titleLabel")
  m.contentUrl = m.top.contentUrl
  if m.top.title <> invalid then m.titleLabel.text = m.top.title
  if m.contentUrl <> "" then
    content = { url: m.contentUrl, title: m.top.title }
    m.video.content = content
    m.video.control = "play"
  else
    m.titleLabel.text = "No playable URL"
  end if
end sub

sub onKeyEvent(key as String, press as Boolean)
  if press = false then return
  if key = "back" or key = "backspace" or key = "escape" then
    m.top.close = true
  end if
end sub
