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
local function repair()
 if busy then return end
 busy=true
 ExecuteInGameThread(function()
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
 end)
end
RegisterKeyBind(Key.F7,repair)
log('Campaign mod ready. DLC compatibility initializes automatically; F7 repairs aircraft ownership and loadouts.')

assert(loadfile(directory..'DLC-load-support.lua'))().start(directory,log)

-- Never allocate or replace aircraft-record structs. Observe game-owned records.
local lastSignature=nil
local autoPending=false
LoopAsync(2000,function()
 if autoPending or busy then return false end
 autoPending=true
 ExecuteInGameThread(function()
  local ok,err=pcall(function()
   local managers=FindAllOf('LiveSaveDataManager') or {}
   if #managers~=1 then return end
   local save=managers[1].CampaignSaveGame
   if not save or not save:IsValid() or save.SavedVersion~=38 then return end
   local ids={};save.CampaignSaveData.AircraftTypeRecords:ForEach(function(_,v)ids[#ids+1]=v:get().PlaneID end)
   -- A single starter aircraft is valid. Avoid the temporary startup save by
   -- waiting for a visible campaign/hangar menu instead of counting aircraft.
   if not assert(loadfile(directory..'Campaign-ready.lua'))()() then return end
   table.sort(ids)
   local signature=tostring(save:GetAddress())..':'..table.concat(ids,',')
   if signature==lastSignature then return end
   local dt=StaticFindObject('/Game/Datatables/Player/DT_LiveAircraft.DT_LiveAircraft')
   local skins=StaticFindObject('/Game/Datatables/Information/DT_Skin.DT_Skin')
   if not dt or not dt:IsValid() or not skins or not skins:IsValid() then return end
   lastSignature=signature
   log('Automatic repair of game-created aircraft records starting.')
   repair()
  end)
  autoPending=false
  if not ok then log('Automatic readiness check: '..tostring(err)) end
 end)
 return false
end)
