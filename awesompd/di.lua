local util = require('awful.util')
local format = string.format

-- Submodule for Digitally Imported radio
local di =
   { api_key = "5b8ef08bed0e0388fbe3102b",
     stream_url_fmt = "http://pub8.di.fm:80/di_%s_aac?%s",
     covers_folder = util.getdir("cache") .. "/di_covers/",
     image_size = 200,
     image_url_fmt = "api.audioaddict.com/v1/assets/image/%s?size=%dx%d",
     channel_links = {
        "00sclubhits","ambient","bassnjackinhouse","bassline","bigbeat","bigroomhouse","breaks","chillntropicalhouse","chillhop","chillout","chilloutdreams","chillstep","classiceurodance","classiceurodisco","classictrance","classicvocaltrance","clubdubstep","club","djmixes","darkdnb","darkpsytrance","deephouse","deepnudisco","deeptech","detroithousentechno","discohouse","downtempolounge","drumandbass","drumstep","dub","dubtechno","dubstep","ebm","eclectronica","electro","electroswing","electronicpioneers","electronics","electropop","epictrance","eurodance","funkyhouse","futurebeats","futuregarage","futuresynthpop","gabber","glitchhop","goapsy","handsup","harddance","hardtechno","hardcore","hardstyle","house","idm","indiedance","jazzhouse","jungle","latinhouse","liquiddnb","liquiddubstep","liquidtrap","lounge","mainstage","melodicprogressive","minimal","nightcore","nudisco","oldschoolacid","oldschoolhouse","oldschoolrave","classictechno","progressive","progressivepsy","psychill","psybient","russianclubhits","soulfulhouse","spacemusic","techhouse","techno","trance","trap","tribalhouse","umfradio","undergroundtechno","vocalchillout","vocallounge","vocaltrance",},
     channels = {
        ["00sclubhits"] = { link="00sclubhits", image="1f2189badb0bb9ccba20e54163afff69.png", name="00's Club Hits" },
        ["ambient"] = { link="ambient", image="c4939b4e0129cd9abada597e35332db3.png", name="Ambient" },
        ["bassnjackinhouse"] = { link="bassnjackinhouse", image="89b0dfb93cb7eba4d345d116f7fc00e7.png", name="Bass & Jackin' House" },
        ["bassline"] = { link="bassline", image="98bbdb73486e5c0431a44117af617576.png", name="Bassline" },
        ["bigbeat"] = { link="bigbeat", image="949efba54329d6d9264dfd54eeebbc31.png", name="Big Beat" },
        ["bigroomhouse"] = { link="bigroomhouse", image="5b7f5db07bd3bc6e8097ea33bbea7552.png", name="Big Room House" },
        ["breaks"] = { link="breaks", image="5fe8da68c08afeba771f1c0a5ba6bc2f.png", name="Breaks" },
        ["chillntropicalhouse"] = { link="chillntropicalhouse", image="48c55f45921a5ba9671612172dce8f38.png", name="Chill & Tropical House" },
        ["chillhop"] = { link="chillhop", image="2bca153955723e44b5ef9ab9e9fcba8d.png", name="ChillHop" },
        ["chillout"] = { link="chillout", image="8f7ce44aa749a97563c98dc5b69053aa.png", name="Chillout" },
        ["chilloutdreams"] = { link="chilloutdreams", image="7a0a070cca01976ea62c9e1c5a19e9b1.png", name="Chillout Dreams" },
        ["chillstep"] = { link="chillstep", image="7251688497a15b6a27a8e6952a3318fc.png", name="Chillstep" },
        ["classiceurodance"] = { link="classiceurodance", image="a272766a55dc1d3c5b63e688d7a3d0de.png", name="Classic EuroDance" },
        ["classiceurodisco"] = { link="classiceurodisco", image="f9c6cdb880da74aa74ec581dc3f09dbd.png", name="Classic EuroDisco" },
        ["classictrance"] = { link="classictrance", image="53906dc786e7f3d55536defca56a4b5f.png", name="Classic Trance" },
        ["classicvocaltrance"] = { link="classicvocaltrance", image="6c59bb5709a2e2ecae99765d64ce57e6.png", name="Classic Vocal Trance" },
        ["clubdubstep"] = { link="clubdubstep", image="29b1b727e81f9dc1c6ca40926ac8ae34.jpg", name="Club Dubstep" },
        ["club"] = { link="club", image="6620a82bb6a6d0bc281260645b996b0a.png", name="Club Sounds" },
        ["djmixes"] = { link="djmixes", image="5a0a6603d9a3f151b9eced1629e77d66.png", name="DJ Mixes" },
        ["darkdnb"] = { link="darkdnb", image="1561ba009eb79c68b9de141f8685c927.png", name="Dark DnB" },
        ["darkpsytrance"] = { link="darkpsytrance", image="7addf6ec30967ceec317dc46c861f0d1.png", name="Dark PsyTrance" },
        ["deephouse"] = { link="deephouse", image="8dd90c88b4ee5399e6182204a2ede8ed.jpg", name="Deep House" },
        ["deepnudisco"] = { link="deepnudisco", image="3896ecff86795302304c64386ff2c5db.png", name="Deep Nu-Disco" },
        ["deeptech"] = { link="deeptech", image="87d3b2ee913e6ac75882329971d58be4.png", name="Deep Tech" },
        ["detroithousentechno"] = { link="detroithousentechno", image="5d086388aca22629f80ba7c65bd4a163.png", name="Detroit House & Techno" },
        ["discohouse"] = { link="discohouse", image="0ea9396414430256ffb76cd6148bf88a.png", name="Disco House" },
        ["downtempolounge"] = { link="downtempolounge", image="6da83f72080cb225acf608e54f992cf2.png", name="Downtempo Lounge" },
        ["drumandbass"] = { link="drumandbass", image="f2ed26a932bdb5cd0a0eac576aebfa3f.png", name="Drum and Bass" },
        ["drumstep"] = { link="drumstep", image="ed6a072e2ee5db23ceed7136fa2db72b.png", name="Drumstep" },
        ["dub"] = { link="dub", image="e4b346b193c1adec01f8489b98a2bf3f.png", name="Dub" },
        ["dubtechno"] = { link="dubtechno", image="4677d19284fdb4522cd9e60ec4244686.png", name="Dub Techno" },
        ["dubstep"] = { link="dubstep", image="e0614d304c8fd5879a1278dd626d8769.png", name="Dubstep" },
        ["ebm"] = { link="ebm", image="969d1a4840606786752ebb02bad71a8a.png", name="EBM" },
        ["eclectronica"] = { link="eclectronica", image="25f559a97855d8107e7cdc63f2acb345.png", name="EcLectronica" },
        ["electro"] = { link="electro", image="387bfe3c7d50b4edd1408135596a03df.png", name="Electro House" },
        ["electroswing"] = { link="electroswing", image="f37dde025f56dee1631102fc3ad9d2b0.png", name="Electro Swing" },
        ["electronicpioneers"] = { link="electronicpioneers", image="6cc168f2893ea542fc02fa32e32dd27a.png", name="Electronic Pioneers" },
        ["electronics"] = { link="electronics", image="75288a5811df82a782718253222e8154.png", name="Electronics" },
        ["electropop"] = { link="electropop", image="72852e54a50b903aa0a726f87c0050c2.jpg", name="Electropop" },
        ["epictrance"] = { link="epictrance", image="5a76739725cd2106a3e2f30a1461a9bd.jpg", name="Epic Trance" },
        ["eurodance"] = { link="eurodance", image="a42ae2b9810acb81c6003915113c7d9d.png", name="EuroDance" },
        ["funkyhouse"] = { link="funkyhouse", image="45d5aa9e246fd59fe03e601171059581.png", name="Funky House" },
        ["futurebeats"] = { link="futurebeats", image="560659bc59ac29cd9a4eb8a63a469267.png", name="Future Beats" },
        ["futuregarage"] = { link="futuregarage", image="d6aa1e9b4c48141fa573d498eba41a2a.png", name="Future Garage" },
        ["futuresynthpop"] = { link="futuresynthpop", image="f4b0f3c30b34cf76de0955652ae5664a.png", name="Future Synthpop" },
        ["gabber"] = { link="gabber", image="83b92cbe5cdc692fb0c8871135e98c55.png", name="Gabber" },
        ["glitchhop"] = { link="glitchhop", image="15eea5494b52ec59d8f426eff1a76f20.png", name="Glitch Hop" },
        ["goapsy"] = { link="goapsy", image="b5b22bf5232f246bf63b25914bd369e3.png", name="Goa-Psy Trance" },
        ["handsup"] = { link="handsup", image="9d04d9b20de5378994fa8653a1dc69f3.jpg", name="Hands Up" },
        ["harddance"] = { link="harddance", image="a67b19cab6cdb97ec77f8264f9c4c562.png", name="Hard Dance" },
        ["hardtechno"] = { link="hardtechno", image="64249abcb7fcfb5b790953632dc6c779.png", name="Hard Techno" },
        ["hardcore"] = { link="hardcore", image="14f1a4484dc88e0df006e9cd71407bcb.png", name="Hardcore" },
        ["hardstyle"] = { link="hardstyle", image="b27a7b020806ce4428307b30b44734ec.png", name="Hardstyle" },
        ["house"] = { link="house", image="6f8a0b3279c24b1c5fa1c6c1397b9b56.png", name="House" },
        ["idm"] = { link="idm", image="966d955e9ffc6124be1d185703a436c4.png", name="IDM" },
        ["indiedance"] = { link="indiedance", image="2425f3532b9f9e0c2c32ab13889a9aba.png", name="Indie Dance" },
        ["jazzhouse"] = { link="jazzhouse", image="49e159ac3b8473eac86af4cc1e24ffd3.png", name="Jazz House" },
        ["jungle"] = { link="jungle", image="1501288819231087619e6e659f122830.png", name="Jungle" },
        ["latinhouse"] = { link="latinhouse", image="cbf4ea080e36bf804f12710114dc3fff.png", name="Latin House" },
        ["liquiddnb"] = { link="liquiddnb", image="75b2b5e697e7948f5fcd64a1c54f3f72.png", name="Liquid DnB" },
        ["liquiddubstep"] = { link="liquiddubstep", image="df258a92e9d5152cb182b439f1d0eb2b.png", name="Liquid Dubstep" },
        ["liquidtrap"] = { link="liquidtrap", image="f350f444c8d87b080c08a2abe9b6106f.png", name="Liquid Trap" },
        ["lounge"] = { link="lounge", image="58f7afca5a6883c063f8642bfd2cef80.png", name="Lounge" },
        ["mainstage"] = { link="mainstage", image="5bafe3802484d479d77b21aa34f537fe.png", name="Mainstage" },
        ["melodicprogressive"] = { link="melodicprogressive", image="3d8eb1823a29d891b516cc3bf2f539c9.png", name="Melodic Progressive" },
        ["minimal"] = { link="minimal", image="5c29e3063f748d156260fb874634b602.png", name="Minimal" },
        ["nightcore"] = { link="nightcore", image="2200134b0c655a3cd40e0fbf7380c9a0.png", name="Nightcore" },
        ["nudisco"] = { link="nudisco", image="4ba0684daed5c3c422b8ad3aa59c7eaf.png", name="Nu Disco" },
        ["oldschoolacid"] = { link="oldschoolacid", image="7edf76e784f740c1a20904309bbc7080.png", name="Oldschool Acid" },
        ["oldschoolhouse"] = { link="oldschoolhouse", image="503959f01400b6ecf59379d9c6844d11.png", name="Oldschool House" },
        ["oldschoolrave"] = { link="oldschoolrave", image="8c4ec9353361ef5fd6c9cbc4999e2fd1.png", name="Oldschool Rave" },
        ["classictechno"] = { link="classictechno", image="ad112b71e9682c79343a4df45d419297.png", name="Oldschool Techno & Trance " },
        ["progressive"] = { link="progressive", image="fcea7c9d9a16314103a41f66bd6dfd15.png", name="Progressive" },
        ["progressivepsy"] = { link="progressivepsy", image="4aeae25360c3792e8e9fd6f2e5cdf39e.jpg", name="Progressive Psy" },
        ["psychill"] = { link="psychill", image="f301e3e597472b3edbf50a770a52c087.png", name="PsyChill" },
        ["psybient"] = { link="psybient", image="178802e0d43b3d42f2476a183541d652.jpg", name="Psybient" },
        ["russianclubhits"] = { link="russianclubhits", image="3b2e1348eb2ded04b1b97e1791001bf8.png", name="Russian Club Hits" },
        ["soulfulhouse"] = { link="soulfulhouse", image="950ff823b9989f18f19ba65fb149fcad.png", name="Soulful House" },
        ["spacemusic"] = { link="spacemusic", image="4531d1656bc302d4f1898f779a988c17.png", name="Space Dreams" },
        ["techhouse"] = { link="techhouse", image="a1cb226c2170a74ed0fdb4839dafe869.png", name="Tech House" },
        ["techno"] = { link="techno", image="cedaa3b495a451bdd6ee4b21311e155c.png", name="Techno" },
        ["trance"] = { link="trance", image="befc1043f0a216128f8570d3664856f7.png", name="Trance" },
        ["trap"] = { link="trap", image="a79fc1acd04100c12f7b55c17c72a23e.png", name="Trap" },
        ["tribalhouse"] = { link="tribalhouse", image="4af36061eb3e97a0aa21b746b51317dd.png", name="Tribal House" },
        ["umfradio"] = { link="umfradio", image="2c91e9bbb77821106c9905653a5ade9e.png", name="UMF Radio" },
        ["undergroundtechno"] = { link="undergroundtechno", image="cfaee945340928dd2250e731efda8e6c.png", name="Underground Techno" },
        ["vocalchillout"] = { link="vocalchillout", image="a5b0bd27de43d04e1da9acf5b8883e85.png", name="Vocal Chillout" },
        ["vocallounge"] = { link="vocallounge", image="5381371e7ebab35aaa3b8f3f290f31ca.png", name="Vocal Lounge" },
        ["vocaltrance"] = { link="vocaltrance", image="009b4fcdb032cceee6f3da5efd4a86e9.png", name="Vocal Trance" },
   } }

function di.menu(selection_callback)
   local menu = {}
   local chan_group = {}
   local start_chan, last_chan
   local i = 0
   for i, chan_link in ipairs(di.channel_links) do
      local chan = di.channels[chan_link]
      if (i % 15 == 1) then
         start_chan = chan.name
      end
      table.insert(chan_group, { chan.name, function() selection_callback(chan) end })
      if (i % 15 == 0 or i == #di.channel_links) then
         table.insert(menu, { start_chan .. " – " .. chan.name, chan_group })
         chan_group = {}
      end
   end
   return menu
end

-- Gets channel link (simple name) from full stream URL.
function di.get_link(full_link)
   return string.match(full_link, "https?://pub%d+.di.fm:80/di_([%w%d]+)_aac.+")
end

-- Returns a file containing a channel cover for the given channel link. First
-- searches in the cache folder. If file is not there, fetches it from the
-- Internet and saves into the cache folder.
function di.get_channel_cover(channel_link)
   local file_path, fetch_req = di.fetch_channel_cover_request(channel_link)
   if fetch_req then
      local f = io.popen(fetch_req)
      f:close()

      -- Let's check if file is finally there, just in case
      if not util.file_readable(file_path) then
         return nil
      end
   end
   return file_path
end

-- Returns a filename of the channel cover and formed wget request that
-- downloads the channel cover for the given channel link name. If the channel
-- cover already exists returns nil as the second argument.
function di.fetch_channel_cover_request(channel_link)
   local chan = di.channels[channel_link]

   local file_path = di.covers_folder .. chan.image

   if not util.file_readable(file_path) then -- We need to download it
      return file_path, format("wget %s -O %s 2> /dev/null",
                               format(di.image_url_fmt, chan.image, di.image_size, di.image_size),
                               file_path)
   else -- Cover already downloaded, return its filename and nil
      return file_path, nil
   end
end

-- Same as get_album_cover, but downloads (if necessary) the cover
-- asynchronously.
function di.get_channel_cover_async(channel_link)
   local file_path, fetch_req = di.fetch_channel_cover_request(channel_link)
   if fetch_req then
      asyncshell.request(fetch_req)
   end
end

-- Checks if track_name is actually a link to di.fm stream. If true returns the
-- file with channel cover for the stream.
function di.try_get_cover(track_name)
   local link = di.get_link(track_name)
   if link then
      return di.get_channel_cover(link)
   end
end

-- Same as try_get_cover, but calls get_channel_cover_async inside.
function di.try_get_cover_async(track_name)
   local link = di.get_link(track_name)
   if link then
      return di.get_channel_cover_async(link)
   end
end

-- Returns a playable stream URL for the given channel link.
function di.form_stream_url(channel_link)
   return format(di.stream_url_fmt, channel_link, di.api_key)
end

return di
