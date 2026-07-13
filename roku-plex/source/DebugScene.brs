' Debug scene controller: show cache meta and verification state
sub init()
  m.top = m.top
  m.debugList = m.top.findNode("debugList")
  listContent = []
  ' Show settings
  settings = LoadSettings()
  if settings <> invalid then
    listContent.Push({ title: "Plex Server: " + settings.plexServer, description: "Port: " + str(settings.plexPort) })
  else
    listContent.Push({ title: "No saved settings", description: "" })
  end if
  ' Show cached keys via CacheListKeys
  keys = CacheListKeys()
  if keys.Count() = 0 then
    listContent.Push({ title: "No cache index found", description: "Cache may be empty or index not created" })
  else
    for each k in keys
      meta = CacheGetMeta(k)
      if meta <> invalid then
        created = meta.created_at
        ttl = meta.ttl_minutes
        ageMins = Round((Now().GetSeconds() - created) / 60)
        listContent.Push({ title: "Key: " + k, description: "TTL: " + str(ttl) + " min, Age: " + str(ageMins) + " min" })
      else
        listContent.Push({ title: "Key: " + k, description: "No metadata" })
      end if
    end for
  end if
  m.debugList.content = listContent
end sub
