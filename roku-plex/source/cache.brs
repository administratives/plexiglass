' Simple disk cache using tmp:/ with TTL. Keys are turned into filenames.
function CacheFilePath(key as String) as String
  enc = UrlEncode(key)
  return "tmp:/roku-plex-cache-" + enc + ".json"
end function

function CacheSet(key as String, value as Object, ttlMinutes as Integer) as Boolean
  fs = CreateObject("roFileSystem")
  path = CacheFilePath(key)
  payload = CreateObject("roAssociativeArray")
  payload.created_at = Now().GetSeconds()
  payload.ttl_minutes = ttlMinutes
  payload.data = value
  json = FormatJson(payload)
  ok = fs.WriteAsciiFile(path, json)
  return ok
end function

function CacheGet(key as String) as Object
  fs = CreateObject("roFileSystem")
  path = CacheFilePath(key)
  if not fs.FileExists(path) then return invalid
  txt = fs.ReadAsciiFile(path)
  if txt = invalid or txt = "" then return invalid
  obj = ParseJson(txt)
  if obj = invalid then return invalid
  created = obj.created_at
  ttl = obj.ttl_minutes
  if ttl = 0 then return obj.data
  ageSeconds = Now().GetSeconds() - created
  if ageSeconds > ttl * 60 then
    ' expired
    return invalid
  end if
  return obj.data
end function
