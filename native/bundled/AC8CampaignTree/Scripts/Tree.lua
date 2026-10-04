-- Enables campaign tree and customization access; purchases remain separate.
return function(directory)
 local core=assert(loadfile(directory..'Progression-core.lua'))()
 assert(assert(loadfile(directory..'Campaign-ready.lua'))()(),'Campaign is not ready')
 local managers=FindAllOf('LiveSaveDataManager') or {}
 assert(#managers==1,'Campaign manager unavailable')
 local save=managers[1].CampaignSaveGame
 assert(save:IsValid() and save.SavedVersion==38,'Unsupported save')
 local dt=StaticFindObject('/Game/Datatables/UI/Menu/HangerMenu/AircraftTree/DT_LiveMenuAircraftTreeNodeDataTable.DT_LiveMenuAircraftTreeNodeDataTable')
 assert(dt and dt:IsValid(),'Open campaign hangar first')
 assert(dt:GetRowStruct():GetFullName()=='ScriptStruct /Script/Live.LiveMenuAircraftTreeNodeDataTable','Unexpected tree catalog')
 local catalog,selected={},{}
 for _,row in pairs(dt:GetRowMap()) do
  -- Despite the save field name, native purchases store ReferenceId, not NodeID.
  local id=row.ReferenceId
  assert(type(id)=='number' and id%1==0 and id>0 and id<4294967295,'Invalid tree reference')
  assert(row.NodeType==0 or row.NodeType==1,'Unknown node type')
  assert(not catalog[id],'Duplicate tree reference')
  catalog[id]=true;selected[#selected+1]=id
 end
 assert(#selected>0 and #selected<1000,'Unexpected tree size')
 table.sort(selected)
 local data=save.CommonSaveData
 local function array(a) local r={};a:ForEach(function(_,v)r[#r+1]=v:get()end);return r end
 local before=array(data.UnlockedAircraftTreeNodeIDs)
 local after=core.tree(before,catalog,selected)
 local campaign=save.CampaignSaveData
 local flags=campaign.FeatureFlagMask
 -- Native ELiveFeature: AircraftSet=2, AircraftTree=3, Part=6. Purchasing parts alone does
 -- not release their equip menu on a fresh campaign.
 local nextFlags=flags | (1 << 2) | (1 << 3) | (1 << 6)
 local f=assert(io.open(directory..'tree-before-'..os.date('%Y%m%d-%H%M%S')..'.lua','w'))
 assert(f:write('return {FeatureFlagMask=',tostring(flags),',UnlockedAircraftTreeNodeIDs={',table.concat(before,','),'}}\n'))
 assert(f:close(),'Could not finish snapshot')
 local ok,why=pcall(function()
  data.UnlockedAircraftTreeNodeIDs=after
  assert(table.concat(array(data.UnlockedAircraftTreeNodeIDs),',')==table.concat(after,','),'Node readback failed')
  campaign.FeatureFlagMask=nextFlags
  assert(campaign.FeatureFlagMask==nextFlags,'Tree menu readback failed')
 end)
 if not ok then
  local restored=pcall(function()
   data.UnlockedAircraftTreeNodeIDs=before;campaign.FeatureFlagMask=flags
   assert(table.concat(array(data.UnlockedAircraftTreeNodeIDs),',')==table.concat(before,','))
   assert(campaign.FeatureFlagMask==flags)
  end)
  error(tostring(why)..'; restored='..tostring(restored))
 end
 return 'Campaign tree access: '..#selected..' catalog references; Aircraft Set and Parts enabled.'
end
