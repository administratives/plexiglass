' Settings storage: saves to tmp:/roku-plex-config.txt (simple key=value format)
function LoadSettings() as Object
  fs = CreateObject("roFileSystem")
  path = "tmp:/roku-plex-config.txt"
  if not fs.FileExists(path) then return invalid
  data = fs.ReadAsciiFile(path)
  if data = invalid or data = "" then return invalid
  lines = Split(data, "\n")
  settings = CreateObject("roAssociativeArray")
  settings.plexServer = ""
  settings.plexPort = 32400
  settings.plexToken = ""
  for each l in lines
    if l = "" then continue
    parts = Split(l, "=")
    if parts.Count() < 2 then continue
    key = Trim(parts[0])
    val = Trim(parts[1])
    if key = "plexServer" then settings.plexServer = val
    if key = "plexPort" then settings.plexPort = Val(val)
    if key = "plexToken" then settings.plexToken = val
  end for
  return settings
end function

function SaveSettings(settings as Object) as Boolean
  if settings = invalid then return false
  fs = CreateObject("roFileSystem")
  path = "tmp:/roku-plex-config.txt"
  content = "plexServer=" + (settings.plexServer ? "") + "\n"
  content = content + "plexPort=" + str((settings.plexPort ? 32400)) + "\n"
  content = content + "plexToken=" + (settings.plexToken ? "") + "\n"
  ok = fs.WriteAsciiFile(path, content)
  return ok
end function
