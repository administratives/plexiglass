' MainScene BrightScript controller. Loads libraries and shows them in PosterGrid; opens player for selected items
function init()
  m.top = m.top
  m.port = CreateObject("roMessagePort")
  m.libraryGrid = m.top.findNode("libraryGrid")
  m.titleLabel = m.top.findNode("titleLabel")
  m.settingsButton = m.top.findNode("settingsButton")
  ' Observe selection
  m.libraryGrid.ObserveField("itemFocused", "onItemFocused")
  m.libraryGrid.ObserveField("itemSelected", "onItemSelected")

  ' Load saved settings if available
  m.plexServer = ""
  m.plexPort = 32400
  m.plexToken = ""

  ' If not configured, show prompt
  if m.plexServer = "" or m.plexToken = "" then
    m.titleLabel.text = "Configure Plex in Settings"
    return
  end if

  ' Load example rules
  rulesJson = ReadFileAsString("pkg:/roku-plex/rules/example_rules.json")
  rules = ParseJson(rulesJson)
  allContent = []
  for each r in rules
    if r.enabled then
      feed = BuildChannelFromRule(r, m.plexServer, m.plexPort, m.plexToken)
      for each item in feed
        ' attach rule id so we can show channels grouped - for now just push everything
        item._ruleId = r.id
        item._ruleName = r.name
        allContent.Push(item)
      end for
    end if
  end for

  ' Map to PosterGrid content entries
  gridContent = []
  for each it in allContent
    entry = { title: it.title, hdPosterUrl: it.thumb, content: { url: it.ratingKey }, extras: { ratingKey: it.ratingKey, ruleId: it._ruleId, ruleName: it._ruleName } }
    gridContent.Push(entry)
  end for
  m.libraryGrid.content = gridContent
  m.titleLabel.text = "Channels"
end function

sub onSettingsPressed(event)
  screen = CreateObject("roSGScreen")
  settingsScene = screen.CreateScene("SettingsScene")
  screen.Show()
end sub

sub onItemFocused(event)
  ' placeholder for focus behavior
end sub

sub onItemSelected(event)
  ' event.Data contains the selected item's content.url because we set it above to ratingKey
  ratingKey = event.GetData()
  if ratingKey = invalid or ratingKey = "" then return
  ' Build playable URL then open player scene
  playUrl = BuildPlayableUrlForRatingKey(m.plexServer, m.plexPort, m.plexToken, ratingKey)
  if playUrl = "" then
    m.titleLabel.text = "Unable to build playable URL"
    return
  end if
  screen = CreateObject("roSGScreen")
  playerScene = screen.CreateScene("PlayerScene")
  playerScene.contentUrl = playUrl
  ' set title if available
  playerScene.title = "Playing"
  screen.Show()
end sub
