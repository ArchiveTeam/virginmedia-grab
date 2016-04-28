dofile("urlcode.lua")
dofile("table_show.lua")

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')
local item_dir = os.getenv('item_dir')

local downloaded = {}
local addedtolist = {}
local fromjs = {}

local status_code = nil

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local html = urlpos["link_expect_html"]
 
  if downloaded[url] ~= true and addedtolist[url] ~= true and (string.match(url, "^https?://[^/]*webspace%.virginmedia%.com") or string.match(url, "^https?://[^/]*pwp%.blueyonder%.co%.uk") or string.match(url, "^https?://[^/]*freespace%.virgin%.net") or string.match(url, "^https?://[^/]*homepage%.ntlworld%.com") or html == 0) then
    addedtolist[url] = true
    return true
  else
    return false
  end
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil

  downloaded[url] = true
  
  local function check(urla)
    local oldurl = url
    local url = string.match(urla, "^([^#]+)")
    if string.match(url, "^https?://[^/]*webspace%.virginmedia%.com") or string.match(url, "^https?://[^/]*pwp%.blueyonder%.co%.uk") or string.match(url, "^https?://[^/]*freespace%.virgin%.net") or string.match(url, "^https?://[^/]*homepage%.ntlworld%.com") then
      if string.match(url, "&amp;") and not (string.match(url, "<") or string.match(url, ">")) then
        table.insert(urls, { url=string.gsub(url, "&amp;", "&") })
        addedtolist[url] = true
        addedtolist[string.gsub(url, "&amp;", "&")] = true
      elseif not (string.match(url, "<") or string.match(url, ">")) then
        table.insert(urls, { url=url })
        addedtolist[url] = true
      end
    end
  end

  local function checknewurl(newurl)
    if string.match(newurl, "^https?://") then
      check(newurl)
    elseif string.match(newurl, "^//") then
      check("http:"..newurl)
    elseif string.match(newurl, "^/") then
      check(string.match(url, "^(https?://[^/]+)")..newurl)
    elseif string.match(url, ".js$") then
      if (string.match(newurl, "%.[mM][pP]4$") or string.match(newurl, "%.[mM][pP]3$") or string.match(newurl, "%.[jJ][pP][gG]$") or string.match(newurl, "%.[gG][iI][fF]$") or string.match(newurl, "%.[aA][vV][iI]$") or string.match(newurl, "%.[fF][lL][vV]$") or string.match(newurl, "%.[pP][dD][fF]$") or string.match(newurl, "%.[rR][mM]$") or string.match(newurl, "%.[rR][aA]$") or string.match(newurl, "%.[wW][mM][vV]$") or string.match(newurl, "%.[jJ][pP][eE][gG]$") or string.match(newurl, "%.[sS][wW][fF]$")) and not string.match(newurl, "^%.%./") then
        fromjs[string.match(url, "^(https?://.+/)")..newurl] = true
        check(string.match(url, "^(https?://.+/)")..newurl)
      elseif string.match(newurl, "^%.%./") then
        tempurl = url
        tempnewurl = newurl
        while string.match(tempnewurl, "^%.%./") do
          if not string.match(tempurl, "^https?://[^/]+/$") then
            tempurl = string.match(tempurl, "^(.*/)[^/]*/")
          end
          tempnewurl = string.match(tempnewurl, "^%.%./(.*)")
        end
        fromjs[tempurl..tempnewurl] = true
        check(tempurl..tempnewurl)
      end
    end
  end

  local function checknewshorturl(newurl)
    if not (string.match(newurl, "^https?://") or string.match(newurl, "^/") or string.match(newurl, "^%.%./") or string.match(newurl, "^javascript:") or string.match(newurl, "^mailto:") or string.match(newurl, "^%${")) then
      check(string.match(url, "^(https?://.+/)")..newurl)
    end
  end
  
  if status_code ~= 404 and fromjs[url] ~= true and (string.match(url, "^https?://[^/]*webspace%.virginmedia%.com") or string.match(url, "^https?://[^/]*pwp%.blueyonder%.co%.uk") or string.match(url, "^https?://[^/]*freespace%.virgin%.net") or string.match(url, "^https?://[^/]*homepage%.ntlworld%.com")) and not (string.match(url, "%.[mM][pP]4$") or string.match(url, "%.[mM][pP]3$") or string.match(url, "%.[jJ][pP][gG]$") or string.match(url, "%.[gG][iI][fF]$") or string.match(url, "%.[aA][vV][iI]$") or string.match(url, "%.[fF][lL][vV]$") or string.match(url, "%.[pP][dD][fF]$") or string.match(url, "%.[rR][mM]$") or string.match(url, "%.[rR][aA]$") or string.match(url, "%.[wW][mM][vV]$") or string.match(url, "%.[jJ][pP][eE][gG]$") or string.match(url, "%.[sS][wW][fF]$")) then
    html = read_file(file)
    for newurl in string.gmatch(html, '([^"]+)') do
      checknewurl(newurl)
    end
    for newurl in string.gmatch(html, "([^']+)") do
      checknewurl(newurl)
    end
    for newurl in string.gmatch(html, ">([^<]+)") do
      checknewurl(newurl)
    end
    if string.match(url, "%?") then
      checknewurl(string.match(url, "^(https?://[^%?]+)%?"))
    end
    if string.match(url, "^https?://.+/[^/]+/") then
      checknewurl(string.match(url, "^(https?://.+/[^/]+)/"))
      checknewurl(string.match(url, "^(https?://.+/[^/]+/)"))
    end
  end

  return urls
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()

  if (status_code >= 200 and status_code <= 399) then
    if string.match(url.url, "https://") then
      local newurl = string.gsub(url.url, "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url.url] = true
    end
  end
  
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 403 and status_code ~= 404) or
    status_code == 0 then
    io.stdout:write("Server returned "..http_stat.statcode.." ("..err.."). Sleeping.\n")
    io.stdout:flush()
    os.execute("sleep 1")
    tries = tries + 1
    if tries >= 5 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      tries = 0
      if string.match(url["url"], "^https?://[^/]*webspace%.virginmedia%.com") or string.match(url["url"], "^https?://[^/]*pwp%.blueyonder%.co%.uk") or string.match(url["url"], "^https?://[^/]*freespace%.virgin%.net") or string.match(url["url"], "^https?://[^/]*homepage%.ntlworld%.com") then
        return wget.actions.EXIT
      else
        return wget.actions.EXIT
      end
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  local sleep_time = 0

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
