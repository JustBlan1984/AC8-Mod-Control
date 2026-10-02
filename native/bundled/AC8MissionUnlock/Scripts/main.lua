-- AC8 Mission Unlock 1.0.0: campaign access only.
local dir=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local helpers=require('UEHelpers')
local pending=nil
local function log(s) print('[AC8Missions] '..s..'\n') end
local function notice(s)
 log(s)
 pcall(function()
  local pc=helpers.GetPlayerController()
  local lib=StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
  if pc and pc:IsValid() and lib and lib:IsValid() then
   lib:PrintString(pc,s,true,false,{R=0.2,G=1,B=0.3,A=1},10,FName('AC8Missions'))
  end
 end)
end
local function array(a)
 local result={};a:ForEach(function(_,v) result[#result+1]=v:get() end);return result
end
local function same(a,b)
 if #a~=#b then return false end
 for i,v in ipairs(a) do if b[i]~=v then return false end end
 return true
end
local function merge(a,b)
 local out,seen={},{}
 for _,list in ipairs({a,b}) do for _,id in ipairs(list) do
  assert(type(id)=='number','Invalid mission ID')
  if not seen[id] then out[#out+1]=id;seen[id]=true end
 end end
 return out
end
local function prepare()
 local managers=FindAllOf('LiveSaveDataManager') or {}
 assert(#managers==1,'Expected one campaign save manager')
 local save=managers[1].CampaignSaveGame
 assert(save and save:IsValid() and save.SavedVersion==38,'Unsupported or unavailable campaign save')
 local dt=StaticFindObject('/Game/Datatables/Information/DT_LiveMissionTable.DT_LiveMissionTable')
 assert(dt and dt:IsValid(),'Campaign mission catalog is not loaded')
 local catalog={}
 for _,r in pairs(dt:GetRowMap()) do
  local key=r.MissionNumberOnlyTextID:ToString()
  local number=tonumber(key:match('^MissionNoOnly_Name_ms(%d+)'))
  if number and r.GameModeType==1 and r.DLCID:ToString()=='Live' and r.LevelStringID:ToString():match('^Mission ') then
   assert(number>=1 and number<=100 and r.MissionID>0,'Unexpected catalog record')
   catalog[number]=catalog[number] or {};table.insert(catalog[number],r.MissionID)
  end
 end
 assert(catalog[1] and catalog[2] and catalog[3],'Expected campaign catalog not found')
 local cfg=assert(loadfile(dir..'Mission-config.lua'))()
 assert(type(cfg)=='table','Invalid configuration')
 local wanted={}
 if cfg.Mode=='all' then for n in pairs(catalog) do wanted[n]=true end
 elseif cfg.Mode=='internal_through' then
  assert(type(cfg.ThroughID)=='number' and cfg.ThroughID%1==0 and cfg.ThroughID>=1 and cfg.ThroughID<=31,'Invalid mission cutoff')
  for n,list in pairs(catalog) do for _,id in ipairs(list) do if id<=cfg.ThroughID then wanted[n]=true end end end
 elseif cfg.Mode=='through' then
  assert(type(cfg.ThroughMission)=='number' and cfg.ThroughMission%1==0 and catalog[cfg.ThroughMission],'Invalid ThroughMission')
  for n in pairs(catalog) do if n<=cfg.ThroughMission then wanted[n]=true end end
 elseif cfg.Mode=='selected' then
  assert(type(cfg.SelectedMissions)=='table' and #cfg.SelectedMissions>0,'No selected missions')
  for _,n in ipairs(cfg.SelectedMissions) do assert(catalog[n],'Unknown mission number '..tostring(n));wanted[n]=true end
 else error('Mode must be through, selected, or all') end
 local numbers={};for n in pairs(wanted) do numbers[#numbers+1]=n end;table.sort(numbers)
 local ids={};for _,n in ipairs(numbers) do table.sort(catalog[n]);for _,id in ipairs(catalog[n]) do ids[#ids+1]=id end end
 if cfg.Mode=='internal_through' then
  local filtered={};for _,id in ipairs(ids) do if id<=cfg.ThroughID then filtered[#filtered+1]=id end end;ids=filtered
 end
 assert(cfg.CampaignAccess==true or cfg.FreeMissionAccess==true,'No access lists selected')
 local c=save.CampaignSaveData
 local plans={}
 for _,field in ipairs({'UnlockedMissionIdList','UnlockedFreeMissionIDs'}) do
  if (field=='UnlockedMissionIdList' and cfg.CampaignAccess==true) or (field=='UnlockedFreeMissionIDs' and cfg.FreeMissionAccess==true) then
   local old=array(c[field]);plans[#plans+1]={field=field,old=old,new=merge(old,ids)}
  end
 end
 local signature=table.concat(ids,',')..'|'..tostring(cfg.CampaignAccess)..'|'..tostring(cfg.FreeMissionAccess)
 for _,p in ipairs(plans) do signature=signature..'|'..p.field..'='..table.concat(p.old,',') end
 return {save=save,data=c,plans=plans,signature=signature,numbers=numbers,ids=ids,catalog=catalog}
end
local function inspect()
 local p=prepare()
 notice('Preview missions '..table.concat(p.numbers,',')..' (internal IDs '..table.concat(p.ids,',')..'). F4 twice applies access only.')
 for _,plan in ipairs(p.plans) do log(plan.field..': '..table.concat(plan.old,',')..' -> '..table.concat(plan.new,',')) end
 log('Story position unchanged: played='..tostring(p.data.LastPlayedMissionID)..', completed='..tostring(p.data.LastCompletedMissionID))
 return p
end
local function apply(automaticPlan)
 local p=automaticPlan or prepare()
 if not automaticPlan and (not pending or pending.signature~=p.signature or os.time()>pending.expires) then
  pending={signature=p.signature,expires=os.time()+15}
  notice('Unlock access to missions '..table.concat(p.numbers,',')..'? Press F4 again within 15 seconds. No completion or story changes.')
  return
 end
 pending=nil
 local featureBefore=p.data.FeatureFlagMask
 -- ELiveFeature: Training=7, MusicPlayer=8, FreeMission=11,
 -- FreeFlight=12, DataViewer=13. Preserve unrelated feature bits.
 local featureAfter=featureBefore | (1 << 7) | (1 << 8) | (1 << 11) | (1 << 12) | (1 << 13)
 local path=dir..'mission-snapshot-'..os.date('%Y%m%d-%H%M%S')..'.lua'
 local f=assert(io.open(path,'w'),'Cannot write rollback snapshot')
 f:write('return {\n')
 f:write(' FeatureFlagMask=',tostring(featureBefore),',\n')
 for _,plan in ipairs(p.plans) do f:write(' ',plan.field,'={',table.concat(plan.old,','),'},\n') end
 assert(f:write('}\n'));assert(f:close(),'Cannot finish rollback snapshot')
 local touched={}
 local ok,err=pcall(function()
  p.data.FeatureFlagMask=featureAfter
  assert(p.data.FeatureFlagMask==featureAfter,'Campaign menu feature verification failed')
  for _,plan in ipairs(p.plans) do
   if not same(plan.old,plan.new) then
    touched[#touched+1]=plan;p.data[plan.field]=plan.new
    assert(same(array(p.data[plan.field]),plan.new),'Verification failed: '..plan.field)
   end
  end
 end)
 if not ok then
  p.data.FeatureFlagMask=featureBefore
  local errors={}
  for i=#touched,1,-1 do local plan=touched[i];local success,why=pcall(function()p.data[plan.field]=plan.old;assert(same(array(p.data[plan.field]),plan.old))end);if not success then errors[#errors+1]=tostring(why) end end
  error(tostring(err)..'; rollback failures='..#errors)
 end
 notice('Access lists updated and read back: '..#touched..' lists. Reopen mission selection. Gameplay and persistence still need testing.')
 log('Campaign menus enabled: Free Mission, Free Flight, Training, Music Player, Data Viewer; mask '..tostring(featureBefore)..' -> '..tostring(featureAfter))
end
local function run(fn) ExecuteInGameThread(function() local ok,err=pcall(fn);if not ok then pending=nil;notice('Stopped: '..tostring(err)) end end) end
RegisterKeyBind(Key.F9,function()run(inspect)end)
RegisterKeyBind(Key.F4,function()run(apply)end)
log('Mission access mod loaded. Configured automatic application is enabled; F9 previews, F4 twice is a manual fallback.')
ExecuteWithDelay(8000,function()run(inspect)end)

-- Keep checking after success: New Game/save loading can replace the live
-- campaign or reset its arrays. Only write when the desired state is missing.
local autoPending=false
local autoStableSignature=nil
local autoStableSave=nil
local autoLastError=nil
local autoReady=assert(loadfile(dir..'Campaign-ready.lua'))()
LoopAsync(2000,function()
 if autoPending then return false end
 autoPending=true
 local queued,queueError=pcall(ExecuteInGameThread,function()
  local ok,err=pcall(function()
   local cfg=assert(loadfile(dir..'Mission-config.lua'))()
   if not cfg.AutoApply or not autoReady() then
    autoStableSignature=nil;autoStableSave=nil;return
   end
   local p=prepare()
   local featureBits=(1 << 7) | (1 << 8) | (1 << 11) | (1 << 12) | (1 << 13)
   local signature=p.signature..'|'..tostring(p.data.FeatureFlagMask)
   -- Require two consecutive stable samples before writing during loading.
   local saveID=p.save:GetFullName()
   if autoStableSignature~=signature or autoStableSave~=saveID then
    autoStableSignature=signature;autoStableSave=saveID;return
   end
   local needsApply=(p.data.FeatureFlagMask & featureBits)~=featureBits
   for _,plan in ipairs(p.plans) do
    if not same(plan.old,plan.new) then needsApply=true end
   end
   if needsApply then
    apply(p)
    autoStableSignature=nil
    log('Automatic mission access applied and verified; normal game saving is still required.')
   end
  end)
  if not ok then
   autoStableSignature=nil;autoStableSave=nil
   if autoLastError~=tostring(err) then log('Automatic unlock waiting/retrying: '..tostring(err)) end
   autoLastError=tostring(err)
  else autoLastError=nil end
  autoPending=false
 end)
 if not queued then
  autoPending=false;autoStableSignature=nil;autoStableSave=nil
  if autoLastError~=tostring(queueError) then log('Automatic unlock scheduling failed; retrying: '..tostring(queueError)) end
  autoLastError=tostring(queueError)
 end
 return false
end)
