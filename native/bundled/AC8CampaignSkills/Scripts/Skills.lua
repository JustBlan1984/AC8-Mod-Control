-- Grants campaign tree parts and catalog SP weapons for already-owned aircraft.
return function(directory)
 assert(assert(loadfile(directory..'Campaign-ready.lua'))()(),'Campaign is not ready')
 local managers=FindAllOf('LiveSaveDataManager') or {}
 assert(#managers==1,'Campaign manager unavailable')
 local save=managers[1].CampaignSaveGame
 assert(save:IsValid() and save.SavedVersion==38,'Unsupported save')
 local dt=StaticFindObject('/Game/Datatables/UI/Menu/HangerMenu/AircraftTree/DT_LiveMenuAircraftTreeNodeDataTable.DT_LiveMenuAircraftTreeNodeDataTable')
 assert(dt and dt:IsValid(),'Open Campaign or Free Mission hangar first')
 assert(dt:GetRowStruct():GetFullName()=='ScriptStruct /Script/Live.LiveMenuAircraftTreeNodeDataTable','Unexpected tree catalog')
 local function integer(v,max) assert(type(v)=='number' and v%1==0 and v>=0 and v<=max,'Invalid catalog ID');return v end
 local parts,nodes,seenNodes={},{},{}
 local rows=0
 for _,row in pairs(dt:GetRowMap()) do
  rows=rows+1
  local node=integer(row.NodeID,32767)
  assert(not seenNodes[node],'Duplicate node');seenNodes[node]=true
  assert(row.NodeType==0 or row.NodeType==1,'Unknown node type')
  if row.NodeType==1 then
   local part=integer(row.ReferenceId,2147483647);assert(part>0,'Invalid part')
   -- Native tree unlocks use ReferenceId; NodeID is only a layout identifier.
   parts[#parts+1]=part;nodes[#nodes+1]=part
  end
 end
 assert(rows>0 and rows<1000 and #parts>0,'Unexpected catalog size')
 table.sort(parts);table.sort(nodes)
 local function array(a) local r={};a:ForEach(function(_,v)r[#r+1]=integer(v:get(),4294967295)end);return r end
 local function merge(old,extra)
  local result,seen={},{}
  for _,v in ipairs(old)do result[#result+1]=v;seen[v]=true end
  for _,v in ipairs(extra)do if not seen[v]then result[#result+1]=v;seen[v]=true end end
  return result
 end
 local data=save.CommonSaveData
 local beforeParts=array(data.OwnedParts)
 local beforeNodes=array(data.UnlockedAircraftTreeNodeIDs)
 local afterParts=merge(beforeParts,parts)
 local afterNodes=merge(beforeNodes,nodes)
 local aircraft=StaticFindObject('/Game/Datatables/Player/DT_LiveAircraft.DT_LiveAircraft')
 assert(aircraft and aircraft:IsValid(),'Waiting for aircraft catalog')
 local weaponsByPlane={}
 for _,row in pairs(aircraft:GetRowMap())do
  if data.OwnedAircrafts:Contains(row.PlaneID) then
   local weapons={};local count=0
   for _,params in pairs(row.PlayerParameter:GetRowMap())do
    count=count+1
    for i=1,4 do local id=integer(params['SpWeaponID'..i],255);if id~=0 then weapons[#weapons+1]=id end end
   end
   assert(count==1 and #weapons>0,'Unexpected aircraft weapon catalog')
   weaponsByPlane[row.PlaneID]=weapons
  end
 end
 local weaponPlans,found={},{}
 save.CampaignSaveData.AircraftTypeRecords:ForEach(function(_,v)
  local record=v:get();local weapons=weaponsByPlane[record.PlaneID]
  if weapons then
   found[record.PlaneID]=true
   local before=array(record.OwnedWeapons);local after=merge(before,weapons)
   if #after>#before then weaponPlans[#weaponPlans+1]={record=record,before=before,after=after} end
  end
 end)
 local pending=false
 for id in pairs(weaponsByPlane)do if not found[id]then pending=true end end
 if #afterParts==#beforeParts and #afterNodes==#beforeNodes and #weaponPlans==0 then
  return 'Skills and available aircraft weapons already granted.',pending
 end
 local snapshot=assert(io.open(directory..'skills-before-'..os.date('%Y%m%d-%H%M%S')..'.lua','w'))
 assert(snapshot:write('return {OwnedParts={',table.concat(beforeParts,','),'},UnlockedAircraftTreeNodeIDs={',table.concat(beforeNodes,','),'}}\n'))
 for _,plan in ipairs(weaponPlans)do assert(snapshot:write('-- Aircraft ',tostring(plan.record.PlaneID),' weapons before: ',table.concat(plan.before,','),'\n'))end
 assert(snapshot:close(),'Snapshot failed')
 local function matches(field,expected) assert(table.concat(array(data[field]),',')==table.concat(expected,','),field..' readback failed') end
 local ok,why=pcall(function()
  data.OwnedParts=afterParts;matches('OwnedParts',afterParts)
  data.UnlockedAircraftTreeNodeIDs=afterNodes;matches('UnlockedAircraftTreeNodeIDs',afterNodes)
  for _,plan in ipairs(weaponPlans)do
   plan.record.OwnedWeapons=plan.after
   assert(table.concat(array(plan.record.OwnedWeapons),',')==table.concat(plan.after,','),'Weapon readback failed')
  end
 end)
 if not ok then
  local restored=pcall(function()
   data.OwnedParts=beforeParts;data.UnlockedAircraftTreeNodeIDs=beforeNodes
   matches('OwnedParts',beforeParts);matches('UnlockedAircraftTreeNodeIDs',beforeNodes)
   for _,plan in ipairs(weaponPlans)do
    plan.record.OwnedWeapons=plan.before
    assert(table.concat(array(plan.record.OwnedWeapons),',')==table.concat(plan.before,','),'Weapon rollback failed')
   end
  end)
  error(tostring(why)..'; restored='..tostring(restored))
 end
 return 'Granted '..(#afterParts-#beforeParts)..' tree parts; updated '..#weaponPlans..' aircraft weapon lists. MRP and aircraft ownership unchanged. Reopen tree/loadout and save normally.',pending
end
