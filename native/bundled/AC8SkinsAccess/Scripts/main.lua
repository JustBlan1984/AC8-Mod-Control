local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local pending=false
local last=nil
local function log(s) print('[AC8Skins] '..s..'\n') end
LoopAsync(2000,function()
 if pending then return false end
 pending=true
 local queued,why=pcall(ExecuteInGameThread,function()
  local ok,err=pcall(function()
   if not assert(loadfile(directory..'Campaign-ready.lua'))()() then last=nil;return end
   local save=FindAllOf('LiveSaveDataManager')[1].CampaignSaveGame
   local keys={tostring(save:GetAddress())}
   save.CommonSaveData.OwnedAircrafts:ForEach(function(k,v) keys[#keys+1]='a'..k:get() end)
   save.CommonSaveData.UnlockedSkinIdList:ForEach(function(_,v) keys[#keys+1]='s'..v:get() end)
   table.sort(keys);local signature=table.concat(keys,';')
   if signature==last then return end
   assert(loadfile(directory..'Loadout-fix.lua'))()(directory,log)
   assert(loadfile(directory..'Skin-menu-fix.lua'))()(directory,log)
   last=signature
  end)
  pending=false
  if not ok and tostring(err)~=_G.AC8SkinError then log(tostring(err));_G.AC8SkinError=tostring(err) end
 end)
 if not queued then pending=false;log(tostring(why)) end
 return false
end)
log('Skins Access enabled for owned aircraft only.')
