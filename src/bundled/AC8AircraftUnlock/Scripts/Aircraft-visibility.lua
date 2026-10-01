-- Session-only catalog repair for the user's campaign F-14A.
-- Disk assets and Steam configuration are not modified.
return function(directory,log)
 local options=assert(loadfile(directory..'Unlock-config.lua'))()
 if options.IncludeDLCAircraft~=true then return end
 local managers=FindAllOf('LiveSaveDataManager') or {}
 assert(#managers==1,'Campaign manager unavailable')
 local save=managers[1].CampaignSaveGame
 assert(save and save:IsValid() and save.SavedVersion==38,'Unsupported campaign save')
 assert(save.CommonSaveData.OwnedAircrafts:Contains(10034010),'F-14A ownership entry missing')
 local dt=StaticFindObject('/Game/Datatables/Player/DT_LiveAircraft.DT_LiveAircraft')
 assert(dt and dt:IsValid(),'Open campaign aircraft selection first')
 local target,count=nil,0
 for _,row in pairs(dt:GetRowMap()) do
  if row.PlaneID==10034010 then target=row;count=count+1 end
 end
 assert(count==1 and target.DefaultSkinID==34101001,'F-14A catalog differs from the inspected build')
 local before=target.DLCID:ToString()
 assert(before=='DLC0000' or before=='Live','Unexpected F-14A catalog tag')
 local infos=FindAllOf('LiveInformationManager') or {}
 assert(#infos==1,'Aircraft information manager unavailable')
 local plans={}
 for _,field in ipairs({'PlaneDataMap_','PlaneDataOnlyCarrierBasedMap_'}) do
  local map=infos[1][field]
  assert(map:Contains(10034010),'F-14A missing from '..field)
  local row=map:Find(10034010):get()
  assert(row.PlaneID==10034010 and row.DefaultSkinID==34101001,'Unexpected cached F-14A')
  local tag=row.DLCID:ToString()
  assert(tag=='DLC0000' or tag=='Live','Unexpected cached F-14A tag')
  if tag~='Live' then plans[#plans+1]={row=row,before=tag,after='Live',label=field} end
 end
 -- Undo the previous table-only experiment; the menu reads the cached maps.
 if before=='Live' then plans[#plans+1]={row=target,before=before,after='DLC0000',label='source table restore'} end
 if #plans==0 then log('F-14A cached visibility already repaired for this session.');return end
 local f=assert(io.open(directory..'f14a-visibility-before-'..os.date('%Y%m%d-%H%M%S')..'.txt','w'))
 for _,p in ipairs(plans) do f:write(p.label,'=',p.before,' -> ',p.after,'\n') end
 assert(f:close())
 local touched={}
 local ok,err=pcall(function()
  for _,p in ipairs(plans) do
   touched[#touched+1]=p
   p.row.DLCID=p.after
   assert(p.row.DLCID:ToString()==p.after,'F-14A cache write did not verify')
  end
 end)
 if not ok then
  local failures={}
  for i=#touched,1,-1 do local p=touched[i];local restored,why=pcall(function() p.row.DLCID=p.before end);if not restored then failures[#failures+1]=tostring(why) end end
  error(tostring(err)..'; rollback errors='..#failures)
 end
 log('F-14A cached visibility updated for this session. Reopen aircraft selection; menu verification required.')
end
