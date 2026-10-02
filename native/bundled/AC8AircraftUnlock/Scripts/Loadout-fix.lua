-- Repairs catalog-backed campaign special-weapon and skin ownership.
return function(directory,log,options)
 if options==nil then
  local loader=loadfile(directory..'Unlock-config.lua')
  options=loader and loader() or {}
 end
 assert(type(options)=='table','Invalid unlock configuration')
 local includeDLC=options.IncludeDLCSkins==true
 local includeDLCAircraft=options.IncludeDLCAircraft==true
 local function array(a)
  local t={};a:ForEach(function(_,v) t[#t+1]=v:get() end);return t
 end
 local function merged(old,extra)
  local t,seen={},{}
  for _,list in ipairs({old,extra}) do for _,v in ipairs(list) do if not seen[v] then t[#t+1]=v;seen[v]=true end end end
  return t
 end
 local managers=FindAllOf('LiveSaveDataManager') or {};assert(#managers==1,'Campaign manager unavailable')
 local save=managers[1].CampaignSaveGame;assert(save:IsValid() and save.SavedVersion==38,'Unsupported campaign save')
 local dt=StaticFindObject('/Game/Datatables/Player/DT_LiveAircraft.DT_LiveAircraft')
 local skins=StaticFindObject('/Game/Datatables/Information/DT_Skin.DT_Skin')
 assert(dt:IsValid() and skins:IsValid(),'Open aircraft selection first')
 local catalog,skinRows={},{}
 for _,s in pairs(skins:GetRowMap()) do skinRows[s.SkinID]={plane=s.PlaneStringID:ToString(),dlc=s.DLCID:ToString()} end
 local owned=save.CommonSaveData.OwnedAircrafts
 for _,r in pairs(dt:GetRowMap()) do
  if (r.DLCID:ToString()=='Live' or ((includeDLCAircraft or includeDLC) and r.DLCID:ToString():match('^DLC%d+$'))) and owned:Contains(r.PlaneID) then
   local default=assert(skinRows[r.DefaultSkinID],'Missing default skin')
   local weapons={};local rows=0
   for _,p in pairs(r.PlayerParameter:GetRowMap()) do
    rows=rows+1
    for i=1,4 do local w=p['SpWeaponID'..i];assert(type(w)=='number' and w>=0 and w<256,'Invalid weapon ID');if w~=0 then weapons[#weapons+1]=w end end
   end
   assert(rows==1 and #weapons>0,'Unexpected weapon catalog')
   catalog[r.PlaneID]={weapons=weapons,skinPlane=default.plane}
  end
 end
 local plans,missing,found={},{},{}
 save.CampaignSaveData.AircraftTypeRecords:ForEach(function(_,v)
  local record=v:get();local c=catalog[record.PlaneID]
  if c then
   found[record.PlaneID]=true
   local old=array(record.OwnedWeapons);local new=merged(old,c.weapons)
   if #new>#old then plans[#plans+1]={object=record,field='OwnedWeapons',old=old,new=new,label='aircraft '..record.PlaneID} end
  end
 end)
 local skinPlanes={};for id,c in pairs(catalog) do skinPlanes[c.skinPlane]=true;if not found[id] then missing[#missing+1]=id end end
 local extra={};local dlcCandidates=0
 for id,s in pairs(skinRows) do
  if skinPlanes[s.plane] and (s.dlc=='Live' or (includeDLC and s.dlc:match('^DLC%d+$'))) then
   extra[#extra+1]=id
   if s.dlc~='Live' then dlcCandidates=dlcCandidates+1 end
  end
 end
 table.sort(extra)
 local old=array(save.CommonSaveData.UnlockedSkinIdList);local new=merged(old,extra)
 local skinCount=#new-#old
 if skinCount>0 then plans[#plans+1]={object=save.CommonSaveData,field='UnlockedSkinIdList',old=old,new=new,label='skins'} end
 local snapshot=assert(io.open(directory..'loadout-before-'..os.date('%Y%m%d-%H%M%S')..'.txt','w'))
 for _,p in ipairs(plans) do snapshot:write(p.label,'=',table.concat(p.old,','),'\n') end
 assert(snapshot:close(),'Cannot finish loadout backup')
 local touched={}
 local ok,err=pcall(function()
  for _,p in ipairs(plans) do
   touched[#touched+1]=p;p.object[p.field]=p.new
   local actual=array(p.object[p.field]);assert(#actual==#p.new,'Array write size mismatch')
   for i,v in ipairs(p.new) do assert(actual[i]==v,'Array write verification failed') end
  end
 end)
 if not ok then
  local failures={}
  for i=#touched,1,-1 do local p=touched[i];local success,why=pcall(function() p.object[p.field]=p.old end);if not success then failures[#failures+1]=tostring(why) end end
  error(tostring(err)..'; rollback errors='..#failures)
 end
 log('Loadout repair verified: '..(#plans-(skinCount>0 and 1 or 0))..' aircraft weapon lists, '..skinCount..' skin unlocks. Reopen aircraft selection.')
 if includeDLC then log('DLC skin option enabled: '..dlcCandidates..' catalog skins matched already-owned aircraft. DLC aircraft ownership and platform entitlements are unchanged.') end
 if #missing>0 then table.sort(missing);log('Awaiting game-created loadout records; automatic repair will retry when records appear: '..table.concat(missing,',')) end
end
