' Settings storage: prefer RORegistrySection for persistence; fallback to tmp:/ file for older devices
function LoadSettings() as Object
  ' Try registry first
  reg = CreateObject("roRegistrySection", "roku-plex")
  if reg <> invalid then
    server = reg.Read("plexServer", "")
    port = reg.Read("plexPort", "")
    token = reg.Read("plexToken", "")
    if server <> "" or token <> "" then
      settings = CreateObject("roAssociativeArray")
      settings.plexServer = server
      if port = "" or port = invalid then
        settings.plexPort = 32400
      else
        settings.plexPort = Val(port)
      end if
      settings.plexToken = token
      return settings
    end if
  end if

  ' Fallback to tmp:/ file
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
  success = true
  ' Try registry first
  reg = CreateObject("roRegistrySection", "roku-plex")
  if reg <> invalid then
    ok1 = reg.Write("plexServer", settings.plexServer)
    ok2 = reg.Write("plexPort", str(settings.plexPort))
    ok3 = reg.Write("plexToken", settings.plexToken)
    success = success and ok1 and ok2 and ok3
  else
    success = false
  end if

  ' Also write tmp:/ fallback for compatibility
  fs = CreateObject("roFileSystem")
  path = "tmp:/roku-plex-config.txt"
  content = "plexServer=" + (settings.plexServer ? "") + "\n"
  content = content + "plexPort=" + str((settings.plexPort ? 32400)) + "\n"
  content = content + "plexToken=" + (settings.plexToken ? "") + "\n"
  okf = fs.WriteAsciiFile(path, content)
  success = success and okf

  return success
end function
