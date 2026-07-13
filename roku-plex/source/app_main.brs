' Minimal SceneGraph app entry for Roku Plex
sub Main()
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  scene = screen.CreateScene("MainScene")
  screen.Show()

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" then
      if msg.isScreenClosed() then
        exit while
      end if
    end if
  end while
end sub
