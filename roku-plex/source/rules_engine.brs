' Rules engine to evaluate simple rules and build channel feeds from Plex metadata
function ItemMatchesRule(item as Object, rule as Object) as Boolean
  if item = invalid or rule = invalid then return false
  filters = rule.filters
  if filters = invalid then return true

  results = []
  ' genre: rule.filters.genre is array
  if filters.genre <> invalid then
    ok = false
    for each g in filters.genre
      if item._attrs.genre <> invalid then
        if Instr(LCase(item._attrs.genre), LCase(g)) > 0 then ok = true : exit for
      else
        ' sometimes genre tags are separate; try attr 'type' or 'tag'
        if item._attrs.tag <> invalid and Instr(LCase(item._attrs.tag), LCase(g)) > 0 then ok = true : exit for
      end if
    end for
    results.Push(ok)
  end if

  if filters.min_rating <> invalid then
    val = item.rating
    results.Push(val >= filters.min_rating)
  end if

  if filters.collections <> invalid then
    ok = false
    ' collection may be in attribute 'collection' or 'parentTitle' or 'grandparentTitle'
    for each c in filters.collections
      if item._attrs.collection <> invalid and Instr(LCase(item._attrs.collection), LCase(c)) > 0 then ok = true : exit for
      if item._attrs.parentTitle <> invalid and Instr(LCase(item._attrs.parentTitle), LCase(c)) > 0 then ok = true : exit for
      if item._attrs.grandparentTitle <> invalid and Instr(LCase(item._attrs.grandparentTitle), LCase(c)) > 0 then ok = true : exit for
    end for
    results.Push(ok)
  end if

  if filters.title_regex <> invalid then
    matched = RegexMatch(filters.title_regex, item.title)
    results.Push(matched)
  end if

  if filters.year <> invalid then
    results.Push(item.year = filters.year)
  end if

  ' Evaluate match mode
  matchMode = rule.match
  if matchMode = "all" then
    for each r in results
      if r = false then return false
    end for
    return true
  else
    ' any
    for each r in results
      if r = true then return true
    end for
    ' if no filters were present, default true
    if results.Count() = 0 then return true
    return false
  end if
end function

function SortItemsByRule(items as Object, sortSpec as Object) as Void
  if sortSpec = invalid then return
  field = sortSpec.field
  order = LCase(sortSpec.order ? "desc")
  items.Sort( function(a,b)
    av = a[field] ? a.title
    bv = b[field] ? b.title
    if field = "rating" or field = "year" then
      av = Val(a[field])
      bv = Val(b[field])
    end if
    if av = bv then return 0
    if order = "asc" then
      return (av < bv) ? -1 : 1
    else
      return (av > bv) ? -1 : 1
    end if
  end function )
end function

function BuildChannelFromRule(rule as Object, plexHost as String, plexPort as Integer, plexToken as String) as Object
  items = []
  if rule = invalid then return items
  sections = PlexGetSections(plexHost, plexPort, plexToken)
  for each s in sections
    ' map rule.type to Plex type number (movies=1, shows=2, music tracks=10)
    typeNum = 0
    if rule.type = "movie" then typeNum = 1
    if rule.type = "show" then typeNum = 2
    if rule.type = "music" or rule.type = "track" then typeNum = 10

    secItems = PlexGetSectionAll(plexHost, plexPort, plexToken, s.key, typeNum)
    for each it in secItems
      if ItemMatchesRule(it, rule) then
        ' convert item to Roku feed entry
        thumbUrl = ""
        if it.thumb <> "" then
          ' Plex gives thumb paths like /library/metadata/123/thumb/456
          thumbUrl = BuildPlexBaseUrl(plexHost, plexPort) + it.thumb
          if Instr(thumbUrl, "X-Plex-Token=") = 0 then
            thumbUrl = thumbUrl + ((Instr(thumbUrl, "?") = 0) ? "?X-Plex-Token=" + plexToken : "&X-Plex-Token=" + plexToken)
          end if
        end if
        items.Push({
          title: it.title,
          summary: it.summary,
          thumb: thumbUrl,
          ratingKey: it.ratingKey,
          year: it.year,
          rating: it.rating,
          _attrs: it._attrs
        })
        if rule.limit <> invalid and items.Count() >= rule.limit then exit for
      end if
    end for
    if rule.limit <> invalid and items.Count() >= rule.limit then exit for
  end for
  ' sort
  SortItemsByRule(items, rule.sort)
  return items
end function
