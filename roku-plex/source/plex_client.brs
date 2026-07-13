' Very small Plex HTTP helper. Returns raw response string or invalid.
function PlexFetchRaw(url as String, token as String) as Object
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

' Parse a single XML tag's attributes into an associative array.
function ParseTagAttributes(tag as String) as Object
  attrs = CreateObject("roAssociativeArray")
  pattern = "(\w+)=\"([^\"]*)\""
  ' RegexFindAll returns an array of matches where each match is an array; workaround using xml parsing via regex
  matches = RegexFindAll(pattern, tag)
  for each m in matches
    key = m[1]
    val = m[2]
    attrs[key] = val
  end for
  return attrs
end function

' Extract Directory elements (libraries) from a /library/sections response (XML string)
function ParseSectionsFromXml(xmlStr as String) as Object
  sections = []
  if xmlStr = invalid then return sections
  ' find each <Directory ... />
  pattern = "<Directory\s+([^>]+)/?>"
  matches = RegexFindAll(pattern, xmlStr)
  for each m in matches
    tagBody = m[1]
    attrs = ParseTagAttributes(tagBody)
    ' normalize keys
    section = {
      title: attrs.title ? "",
      key: attrs.key ? "",
      type: attrs.type ? ""
    }
    sections.Push(section)
  end for
  return sections
end function

' Extract Metadata items (Video/Track/Directory) from section /all response
function ParseMetadataItemsFromXml(xmlStr as String) as Object
  items = []
  if xmlStr = invalid then return items
  ' match <Video ... /> or <Track ... /> or <Directory .../>
  pattern = "<(Video|Track|Directory)\s+([^>]+?)(?:/>|>.*?)</(?:Video|Track|Directory)>"
  matches = RegexFindAll(pattern, xmlStr)
  if matches.Count() = 0 then
    ' try self-closing tags
    pattern2 = "<(Video|Track|Directory)\s+([^>]+?)/>"
    matches = RegexFindAll(pattern2, xmlStr)
  end if
  for each m in matches
    tagType = m[1]
    tagBody = m[2]
    attrs = ParseTagAttributes(tagBody)
    item = {
      type: tagType,
      title: attrs.title ? attrs.grandparentTitle ? "" : (attrs.title ? "" : "" ),
      year: (attrs.year ? Val(attrs.year) : 0),
      thumb: attrs.thumb ? attrs.thumb : (attrs.banner ? attrs.banner : ""),
      rating: (attrs.rating ? Val(attrs.rating) : 0),
      ratingKey: attrs.ratingKey ? attrs.ratingKey : attrs.key ? attrs.key : "",
      key: attrs.key ? attrs.key : "",
      summary: attrs.summary ? attrs.summary : "",
      genre: attrs.genre ? attrs.genre : "",
      ' raw attributes for more advanced checks
      _attrs: attrs
    }
    items.Push(item)
  end for
  return items
end function

' Convenience: fetch sections list
function PlexGetSections(host as String, port as Integer, token as String) as Object
  base = BuildPlexBaseUrl(host, port)
  if base = "" then return []
  url = base + "/library/sections?X-Plex-Token=" + token
  xml = PlexFetchRaw(url, token)
  if xml = invalid then return []
  return ParseSectionsFromXml(xml)
end function

' Fetch items for a section (type param optional: 1=movie,2=show,10=track)
function PlexGetSectionAll(host as String, port as Integer, token as String, sectionKey as String, typeNum as Integer) as Object
  base = BuildPlexBaseUrl(host, port)
  if base = "" then return []
  url = base + "/library/sections/" + sectionKey + "/all?X-Plex-Token=" + token
  if typeNum <> 0 then url = url + "&type=" + str(typeNum)
  xml = PlexFetchRaw(url, token)
  if xml = invalid then return []
  return ParseMetadataItemsFromXml(xml)
end function

' Fetch detailed metadata for a single item to find Media/Part info
function PlexGetMetadata(host as String, port as Integer, token as String, ratingKey as String) as Object
  base = BuildPlexBaseUrl(host, port)
  if base = "" then return invalid
  url = base + "/library/metadata/" + ratingKey + "?X-Plex-Token=" + token
  xml = PlexFetchRaw(url, token)
  if xml = invalid then return invalid
  ' Try to find Part key or file
  ' match <Part .*?key="([^"]+)".*?> or file="..."
  pKeyPattern = "<Part[^>]*key=\"([^\"]+)\""
  matches = RegexFindAll(pKeyPattern, xml)
  if matches.Count() > 0 then
    partKey = matches[0][1]
    return { partKey: partKey, raw: xml }
  end if
  pFilePattern = "<Part[^>]*file=\"([^\"]+)\""
  matches2 = RegexFindAll(pFilePattern, xml)
  if matches2.Count() > 0 then
    filePath = matches2[0][1]
    return { filePath: filePath, raw: xml }
  end if
  return { raw: xml }
end function

' Build a playable URL for a ratingKey. Prefers direct Plex part key (server proxied), otherwise attempts a transcoder start URL.
function BuildPlayableUrlForRatingKey(host as String, port as Integer, token as String, ratingKey as String) as String
  base = BuildPlexBaseUrl(host, port)
  if base = "" then return ""
  meta = PlexGetMetadata(host, port, token, ratingKey)
  if meta = invalid then return ""
  if meta.partKey <> invalid and meta.partKey <> "" then
    ' partKey is usually like "/library/parts/12345/file.mp4" or "/library/parts/12345"
    playUrl = base + meta.partKey
    if Instr(playUrl, "X-Plex-Token=") = 0 then
      playUrl = playUrl + "?X-Plex-Token=" + token
    end if
    return playUrl
  end if
  if meta.filePath <> invalid and meta.filePath <> "" then
    ' filePath is local file system path; not accessible remotely. Fall back to transcoder using "url" param with encoded resource
    source = base + "/library/metadata/" + ratingKey + "/poster.jpg?X-Plex-Token=" + token
    encoded = UrlEncode(base + "/library/metadata/" + ratingKey + "?X-Plex-Token=" + token)
    transcoder = base + "/video/:/transcode/universal/start?url=" + encoded + "&protocol=http&container=mp4&videoCodec=h264&X-Plex-Token=" + token
    return transcoder
  end if
  ' as a last resort, return metadata URL
  return base + "/library/metadata/" + ratingKey + "?X-Plex-Token=" + token
end function
