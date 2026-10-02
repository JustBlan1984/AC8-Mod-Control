-- Prepare campaign catalog caches before the title-screen save check.
-- No save writes or platform configuration edits. Online catalog maps are untouched.
local M={}
local skins={
 [34001001]='DLC0000',[34002001]='DLC0000',[34101001]='DLC0000',
 [7006001]='DLC0002',[3006001]='DLC0002',
}
function M.apply(info,options)
 local plans={}
 local function plan(map,id,original,kind)
  if not map:Contains(id) then return false end
  local row=map:Find(id):get()
  assert((kind=='plane' and row.PlaneID==id) or (kind=='skin' and row.SkinID==id),'DLC cache ID mismatch')
  local before=row.DLCID:ToString()
  assert(before==original or before=='Live','Unexpected DLC cache tag for '..id)
  if before~='Live' then plans[#plans+1]={row=row,before=before} end
  return true
 end
 if options.IncludeDLCAircraft then
  if not plan(info.PlaneDataMap_,10034010,'DLC0000','plane') then return false,0 end
  if not plan(info.PlaneDataOnlyCarrierBasedMap_,10034010,'DLC0000','plane') then return false,0 end
 end
 if options.IncludeDLCSkins then
  for id,dlc in pairs(skins) do
   if not plan(info.SkinDataMap_,id,dlc,'skin') then return false,0 end
  end
 end
 local touched={}
 local ok,err=pcall(function()
  for _,p in ipairs(plans) do
   touched[#touched+1]=p;p.row.DLCID='Live'
   assert(p.row.DLCID:ToString()=='Live','DLC cache write failed')
  end
 end)
 if not ok then
  local failures=0
  for i=#touched,1,-1 do local p=touched[i];if not pcall(function() p.row.DLCID=p.before end) then failures=failures+1 end end
  error(tostring(err)..'; rollback failures='..failures)
 end
 return true,#plans
end
function M.start(directory,log)
 local options=assert(loadfile(directory..'Unlock-config.lua'))()
 if not options.IncludeDLCAircraft and not options.IncludeDLCSkins then return end
 local pending,ready,failed=false,false,false
 LoopAsync(50,function()
  if ready or failed then return true end
  if pending then return false end
  pending=true
  ExecuteInGameThread(function()
   local ok,err=pcall(function()
    local managers=FindAllOf('LiveInformationManager') or {}
    if #managers==0 then return end
    assert(#managers==1,'Multiple aircraft information managers')
    local count
    ready,count=M.apply(managers[1],options)
    if ready then log('Startup DLC cache prepared: '..count..' records. Save-load verification required.') end
   end)
   pending=false
   if not ok then failed=true;log('Startup DLC preparation stopped: '..tostring(err)) end
  end)
  return false
 end)
end
return M
