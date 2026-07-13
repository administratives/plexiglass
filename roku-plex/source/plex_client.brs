' Very small Plex HTTP helper. Returns raw response string or invalid.
function PlexFetch(url as String, token as String) as Object
  tr = CreateObject("roUrlTransfer")
  tr.SetUrl(url)
  if token <> "" then
    tr.AddHeader("X-Plex-Token", token)
  end if
  tr.SetCertificatesFile("") ' use OS defaults
  response = tr.GetToString()
  if response = invalid then return invalid
  return response
end function

function BuildPlexBaseUrl(host as String, port as Integer) as String
  if host = "" then return ""
  if port = 0 then
    return "http://" + host
  else
    return "http://" + host + ":" + str(port)
  end if
end function
