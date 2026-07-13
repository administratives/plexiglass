' Cache: prefer registry-backed persistence and keep a rehydration index for quick startup
function CacheKeyToRegistryKey(key as String) as String
  return "cache:" + UrlEncode(key)
end function

function CacheMetaKey(key as String) as String
  return "cachemeta:" + UrlEncode(key)
end function

function CacheSet(key as String, value as Object, ttlMinutes as Integer) as Boolean
  ' Save to RORegistrySection (persistent across reboots)
  reg = CreateObject("roRegistrySection", "roku-plex-cache")
  if reg <> invalid then
    payload = CreateObject("roAssociativeArray")
    payload.created_at = Now().GetSeconds()
    payload.ttl_minutes = ttlMinutes
    payload.data = value
    json = FormatJson(payload)
    ok = reg.Write(CacheKeyToRegistryKey(key), json)
    if not ok then
      ' fallback to tmp:
      fs = CreateObject("roFileSystem")
      path = "tmp:/roku-plex-cache-" + UrlEncode(key) + ".json"
      fs.WriteAsciiFile(path, json)
    end if
    ' also write metadata to index key for quick rehydration
    meta = CreateObject("roAssociativeArray")
    meta.created_at = payload.created_at
    meta.ttl_minutes = ttlMinutes
    reg.Write(CacheMetaKey(key), FormatJson(meta))
    return true
  else
    ' registry not available: fallback to tmp:
    fs = CreateObject("roFileSystem")
    path = "tmp:/roku-plex-cache-" + UrlEncode(key) + ".json"
    payload = CreateObject("roAssociativeArray")
    payload.created_at = Now().GetSeconds()
    payload.ttl_minutes = ttlMinutes
    payload.data = value
    json = FormatJson(payload)
    ok = fs.WriteAsciiFile(path, json)
    return ok
  end if
end function

function CacheGet(key as String) as Object
  reg = CreateObject("roRegistrySection", "roku-plex-cache")
  if reg <> invalid then
    stored = reg.Read(CacheKeyToRegistryKey(key), "")
    if stored <> "" then
      obj = ParseJson(stored)
      if obj <> invalid then
        created = obj.created_at
        ttl = obj.ttl_minutes
        if ttl = 0 then return obj.data
        ageSeconds = Now().GetSeconds() - created
        if ageSeconds > ttl * 60 then
          return invalid
        end if
        return obj.data
      end if
    end if
  end if
  ' registry miss: try tmp:
  fs = CreateObject("roFileSystem")
  path = "tmp:/roku-plex-cache-" + UrlEncode(key) + ".json"
  if not fs.FileExists(path) then return invalid
  txt = fs.ReadAsciiFile(path)
  if txt = invalid or txt = "" then return invalid
  obj = ParseJson(txt)
  if obj = invalid then return invalid
  created = obj.created_at
  ttl = obj.ttl_minutes
  if ttl = 0 then return obj.data
  ageSeconds = Now().GetSeconds() - created
  if ageSeconds > ttl * 60 then return invalid
  return obj.data
end function

function CacheGetMeta(key as String) as Object
  reg = CreateObject("roRegistrySection", "roku-plex-cache")
  if reg <> invalid then
    s = reg.Read(CacheMetaKey(key), "")
    if s <> "" then return ParseJson(s)
  end if
  return invalid
end function

function CacheListKeys() as Object
  ' Return approximate list of cache keys from registry metadata values. RORegistrySection has no enumeration API in BrightScript,
  ' so we rely on a single index key if available.
  reg = CreateObject("roRegistrySection", "roku-plex-cache")
  if reg <> invalid then
    index = reg.Read("index", "")
    if index <> "" then
      return ParseJson(index)
    end if
  end if
  return []
end function

function CacheSetIndex(indexObj as Object) as Void
  reg = CreateObject("roRegistrySection", "roku-plex-cache")
  if reg <> invalid then
    reg.Write("index", FormatJson(indexObj))
  end if
end function
