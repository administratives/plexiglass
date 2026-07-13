' MainScene BrightScript controller. Loads libraries and shows them in PosterGrid
function init()
  m.top = m.top
  m.port = CreateObject("roMessagePort")
  m.libraryGrid = m.top.findNode("libraryGrid")
  m.titleLabel = m.top.findNode("titleLabel")
  m.settingsButton = m.top.findNode("settingsButton")
  m.settingsButton.observeField("buttonSelected", "onSettingsPressed")

  ' Load saved settings if available (RORegistry or settings storage can be added later)
  m.plexServer = ""
  m.plexPort = 32400
  m.plexToken = ""

  ' Simple: attempt to load libraries if server/token provided
  if m.plexServer <> "" and m.plexToken <> "" then
    fetchLibraries()
  else
    m.titleLabel.text = "Roku Plex — Configure in Settings"
  end if
end function

sub fetchLibraries()
  url = BuildPlexBaseUrl(m.plexServer, m.plexPort) + "/library/sections?X-Plex-Token=" + m.plexToken
  res = PlexFetch(url, m.plexToken)
  if res = invalid then
    m.titleLabel.text = "Failed to contact Plex server"
    return
  end if
  ' Plex returns XML by default; try to parse common fields from XML string if received as string
  ' If res is an associative array (JSON) with MediaContainer.Directory, use that.
  sections = []
  if Type(res) = "roAssociativeArray" and res.Lookup("MediaContainer", invalid) <> invalid then
    mc = res.MediaContainer
    if mc.Lookup("Directory", invalid) <> invalid then
      sections = mc.Directory
    end if
  else
    ' If Plex returned XML (string), attempt to parse minimally for directory names using regex
    xmlStr = res
    if Type(xmlStr) = "string" then
      ' crude regex to find Directory key and title attributes
      pattern = "<Directory .*?title=\"(.*?)\" .*?key=\"(\d+)\""
      matches = RegexFindAll(pattern, xmlStr)
      if matches.Count() > 0 then
        for each mItem in matches
          sections.Push({ title: mItem[1], key: mItem[2] })
        end for
      end if
    end if
  end if

  ' Build PosterGrid content
  content = []
  for each s in sections
    title = s.title
    key = s.key
    item = { title: title, hdPosterUrl: "", content: { url: "" }, extras: { sectionKey: key } }
    content.Push(item)
  end for
  m.libraryGrid.content = content
  m.titleLabel.text = "Libraries"
end sub

function onSettingsPressed(event)
  ' open settings scene - simple placeholder
  screen = CreateObject("roSGScreen")
  settingsScene = screen.CreateScene("SettingsScene")
  screen.Show()
end function
