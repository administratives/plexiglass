' Plex client helpers: pagination support and improved transcoder URL generation
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
  pattern = "<Directory\s+([^>]+)/?>"
  matches = RegexFindAll(pattern, xmlStr)
  for each m in matches
    tagBody = m[1]
    attrs = ParseTagAttributes(tagBody)
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
  ' match self-closing tags first
  pattern2 = "<(Video|Track|Directory)\s+([^>]+?)/>"
  matches = RegexFindAll(pattern2, xmlStr)
  for each m in matches
    tagType = m[1]
    tagBody = m[2]
    attrs = ParseTagAttributes(tagBody)
    item = {
      type: tagType,
      title: (attrs.title ? (attrs.grandparentTitle ? attrs.title : attrs.title)),
      year: (attrs.year ? Val(attrs.year) : 0),
      thumb: attrs.thumb ? attrs.thumb : (attrs.banner ? attrs.banner : ""),
      rating: (attrs.rating ? Val(attrs.rating) : 0),
      ratingKey: attrs.ratingKey ? attrs.ratingKey : attrs.key ? attrs.key : "",
      key: attrs.key ? attrs.key : "",
      summary: attrs.summary ? attrs.summary : "",
      genre: attrs.genre ? attrs.genre : "",
      _attrs: attrs
    }
    items.Push(item)
  end for

  ' also try non-self-closing matches (fallback)
  pattern = "<(Video|Track|Directory)\s+([^>]+?)(?:/>|>.*?)</(?:Video|Track|Directory)>"
  matches = RegexFindAll(pattern, xmlStr)
  for each m in matches
    tagType = m[1]
    tagBody = m[2]
    attrs = ParseTagAttributes(tagBody)
    item = {
      type: tagType,
      title: (attrs.title ? attrs.title : ""),
      year: (attrs.year ? Val(attrs.year) : 0),
      thumb: attrs.thumb ? attrs.thumb : (attrs.banner ? attrs.banner : ""),
      rating: (attrs.rating ? Val(attrs.rating) : 0),
      ratingKey: attrs.ratingKey ? attrs.ratingKey : attrs.key ? attrs.key : "",
      key: attrs.key ? attrs.key : "",
      summary: attrs.summary ? attrs.summary : "",
      genre: attrs.genre ? attrs.genre : "",
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

' Fetch items for a section with pagination support. Returns an array of item objects.
function PlexGetSectionAllPaged(host as String, port as Integer, token as String, sectionKey as String, typeNum as Integer, pageSize as Integer, maxItems as Integer) as Object
  items = []
  if pageSize <= 0 then pageSize = 200
  start = 0
  while true
    base = BuildPlexBaseUrl(host, port)
    url = base + "/library/sections/" + sectionKey + "/all?X-Plex-Token=" + token
    if typeNum <> 0 then url = url + "&type=" + str(typeNum)
    url = url + "&start=" + str(start) + "&size=" + str(pageSize)
    xml = PlexFetchRaw(url, token)
    if xml = invalid then exit while
    pageItems = ParseMetadataItemsFromXml(xml)
    if pageItems.Count() = 0 then exit while
    for each it in pageItems
      items.Push(it)
      if maxItems <> 0 and items.Count() >= maxItems then exit for
    end for
    if maxItems <> 0 and items.Count() >= maxItems then exit while
    if pageItems.Count() < pageSize then exit while
    start = start + pageSize
  end while
  return items
end function

' Fetch detailed metadata for a single item to find Media/Part info
function PlexGetMetadata(host as String, port as Integer, token as String, ratingKey as String) as Object
  base = BuildPlexBaseUrl(host, port)
  if base = "" then return invalid
  url = base + "/library/metadata/" + ratingKey + "?X-Plex-Token=" + token
  xml = PlexFetchRaw(url, token)
  if xml = invalid then return invalid
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

' Build a playable URL for a ratingKey. Prefers direct part key (server proxied), otherwise attempts a transcoder start URL.
' quality: "direct" | "low" | "med" | "high"
function BuildPlayableUrlForRatingKey(host as String, port as Integer, token as String, ratingKey as String, quality as String) as String
  base = BuildPlexBaseUrl(host, port)
  if base = "" then return ""
  meta = PlexGetMetadata(host, port, token, ratingKey)
  if meta = invalid then return ""
  ' prefer partKey direct access
  if meta.partKey <> invalid and meta.partKey <> "" then
    playUrl = base + meta.partKey
    if Instr(playUrl, "X-Plex-Token=") = 0 then
      playUrl = playUrl + ((Instr(playUrl, "?") = 0) ? ("?X-Plex-Token=" + token) : ("&X-Plex-Token=" + token))
    end if
    if quality = "direct" then return playUrl
    ' If user requested transcoding despite direct, fall through to transcoder construction
  end if

  ' If file path is present but not directly accessible, use transcoder
  ' Fallback: encode the metadata URL
  encoded = UrlEncode(base + "/library/metadata/" + ratingKey + "?X-Plex-Token=" + token)
  ' Choose bitrate/resolution by quality
  maxBitrate = 1500
  vres = 720
  if quality = "low" then
    maxBitrate = 800
    vres = 480
  else if quality = "med" then
    maxBitrate = 1500
    vres = 720
  else if quality = "high" then
    maxBitrate = 4000
    vres = 1080
  end if
  transcoder = base + "/video/:/transcode/universal/start?url=" + encoded + "&protocol=http&container=mp4&videoResolution=" + str(vres) + "&maxVideoBitrate=" + str(maxBitrate) + "&X-Plex-Token=" + token
  return transcoder
end function
