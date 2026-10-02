-- CriminalGamer84 Mods | Aircraft Unlock 0.1.1 campaign DLC load repair
-- Manual F7 ownership/loadout repair; startup prepares campaign DLC caches without writing saves.
local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local core=assert(loadfile(directory..'Unlock-core.lua'))()
local busy=false
local function log(s) print('[AC8Aircraft] '..s..'\n') end
local function inspect()
 local managers=FindAllOf('LiveSaveDataManager') or {}
 assert(#managers==1,'Campaign save manager unavailable')
 local save=managers[1].CampaignSaveGame
 assert(save and save:IsValid(),'Campaign save is not loaded')
 assert(save.SavedVersion==38,'Unsupported save version')
 local dt=StaticFindObject('/Game/Datatables/Player/DT_LiveAircraft.DT_LiveAircraft')
 assert(dt and dt:IsValid(),'Aircraft catalog not loaded; open the campaign hangar first')
 local rows={}
 for name,row in pairs(dt:GetRowMap()) do rows[name]={id=row.PlaneID,dlc=row.DLCID:ToString()} end
 local map=save.CommonSaveData.OwnedAircrafts
 local owned={}
 map:ForEach(function(k,v) owned[k:get()]=v:get() end)
 local loader=loadfile(directory..'Unlock-config.lua')
 local options=loader and loader() or {}
 return save,map,owned,core.plan(rows,owned,options)
end
local function repairNow()
 if busy then return end
 busy=true
 local ok,err=pcall(function()
   local save,map,owned,ids=inspect()
   if #ids==0 then
    log('All configured catalog aircraft already have ownership entries.')
    -- DLC cache preparation runs automatically before save validation.
   assert(loadfile(directory..'Loadout-fix.lua'))()(directory,log)
    assert(loadfile(directory..'Skin-menu-fix.lua'))()(directory,log)
    return
   end
   local path=directory..'ownership-before-'..os.date('%Y%m%d-%H%M%S')..'.txt'
   local snapshot=assert(io.open(path,'w'),'Cannot record ownership snapshot')
   local keys={};for id in pairs(owned) do keys[#keys+1]=id end;table.sort(keys)
   snapshot:write('Aircraft Unlock development snapshot; full save backup is required.\n')
   for _,id in ipairs(keys) do snapshot:write(id,'=',owned[id],'\n') end
   assert(snapshot:close(),'Cannot finish ownership snapshot')
   local n=core.apply(map,ids)
   log('Added '..n..' campaign aircraft ownership entries. Reopen aircraft selection to test. Saving/persistence still requires verification.')
   -- DLC cache preparation runs automatically before save validation.
   assert(loadfile(directory..'Loadout-fix.lua'))()(directory,log)
   assert(loadfile(directory..'Skin-menu-fix.lua'))()(directory,log)
  end)
  busy=false
  if not ok then log('Stopped: '..tostring(err)) end
  return ok
end
local function repair()
 local ok,err=pcall(ExecuteInGameThread,repairNow)
 if not ok then log('Could not schedule repair: '..tostring(err)) end
end
RegisterKeyBind(Key.F7,repair)
log('Campaign mod ready. DLC compatibility initializes automatically; F7 repairs aircraft ownership and loadouts.')

assert(loadfile(directory..'DLC-load-support.lua'))().start(directory,log)

-- Never allocate aircraft-record structs; repair records created by the game.
local lastSignature,stableSignature,lastError=nil,nil,nil
local autoPending=false
local function signature(save)
 local parts={tostring(save:GetAddress())}
 save.CommonSaveData.OwnedAircrafts:ForEach(function(k,v)
  parts[#parts+1]='o'..k:get()..'='..v:get()
 end)
 save.CampaignSaveData.AircraftTypeRecords:ForEach(function(_,v)
  local record=v:get()
  local weapons={}
  record.OwnedWeapons:ForEach(function(_,w) weapons[#weapons+1]=w:get() end)
  table.sort(weapons)
  parts[#parts+1]='r'..record.PlaneID..'='..table.concat(weapons,',')
 end)
 save.CommonSaveData.UnlockedSkinIdList:ForEach(function(_,v) parts[#parts+1]='s'..v:get() end)
 table.sort(parts)
 return table.concat(parts,';')
end
LoopAsync(2000,function()
 if autoPending or busy then return false end
 autoPending=true
 local queued,queueError=pcall(ExecuteInGameThread,function()
  local ok,err=pcall(function()
   if not assert(loadfile(directory..'Campaign-ready.lua'))()() then
    stableSignature=nil;lastSignature=nil;return
   end
   local save=inspect()
   local skins=StaticFindObject('/Game/Datatables/Information/DT_Skin.DT_Skin')
   if not skins or not skins:IsValid() then stableSignature=nil;return end
   local current=signature(save)
   if current==lastSignature then return end
   if current~=stableSignature then stableSignature=current;return end
   log('Automatic aircraft ownership and loadout repair starting.')
   if repairNow() then
    -- Record success only after repair completes; failures retry next tick.
    lastSignature=signature(save)
    stableSignature=lastSignature
    log('Automatic aircraft repair verified; normal game saving is still required.')
   end
  end)
  autoPending=false
  if not ok then
   stableSignature=nil
   if tostring(err)~=lastError then log('Automatic readiness check: '..tostring(err)) end
   lastError=tostring(err)
  else lastError=nil end
 end)
 if not queued then
  autoPending=false;stableSignature=nil
  if tostring(queueError)~=lastError then log('Automatic scheduling: '..tostring(queueError)) end
  lastError=tostring(queueError)
 end
 return false
end)
