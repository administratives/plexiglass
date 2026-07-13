' Background Task: periodically refresh expired caches for rules
' This Task runs off the UI thread as a SceneGraph Task.
sub run()
  rulesPath = m.top.rulesFile
  if rulesPath = invalid or rulesPath = "" then return
  plexHost = m.top.plexServer
  plexPort = m.top.plexPort
  plexToken = m.top.plexToken
  interval = m.top.checkIntervalMinutes
  if interval = invalid or interval <= 0 then interval = 15

  ' Load rules
  rulesJson = ReadFileAsString(rulesPath)
  rules = ParseJson(rulesJson)
  if rules = invalid then return

  while true
    for each r in rules
      key = "rule:" + r.id + ":host:" + plexHost + ":port:" + str(plexPort)
      meta = CacheGetMeta(key)
      needsRefresh = false
      if meta = invalid then needsRefresh = true
      else
        created = meta.created_at
        ttl = meta.ttl_minutes
        if ttl = 0 then needsRefresh = false else
          age = Now().GetSeconds() - created
          if age > ttl * 60 then needsRefresh = true
        end if
      end if
      if needsRefresh then
        ' perform refresh (rebuild feed) but do not block UI
        items = BuildChannelFromRule(r, plexHost, plexPort, plexToken)
        ' BuildChannelFromRule caches the result (CacheSet). If it returns, nothing else to do.
      end if
    end for
    ' Sleep until next iteration
    ' Convert minutes to milliseconds for sleep
    sleepMs = interval * 60 * 1000
    ' Task node can call Sleep
    Sleep(sleepMs)
  end while
end sub
