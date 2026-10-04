-- Release the seven verified endgame gates in the runtime purchase table.
-- Keep native graph links, prices, ownership, weapons and save progress intact.
return function(dt)
 assert(dt:GetRowStruct():GetFullName()=='ScriptStruct /Script/Live.LiveMenuAircraftTreeNodeDataTable','Unexpected tree table')
 local expected={[18010]={56,0,750000},[19010]={55,0,750000},[16010]={58,0,1000000},
  [2057802]={105,1},[2042802]={106,1},[2043802]={107,1},[2060802]={7,1}}
 local plans,seen={},{}
 for _,row in pairs(dt:GetRowMap())do
  local e=expected[row.ReferenceId]
  if e then
   assert(not seen[row.ReferenceId],'Duplicate target');seen[row.ReferenceId]=true
   assert(row.NodeID==e[1] and row.NodeType==e[2],'Target schema mismatch')
   if e[3] then assert(row.CostBase1==e[3],'Unexpected aircraft price')end
   assert(row.UnlockTrigger==0 or row.UnlockTrigger==1,'Unexpected unlock trigger')
   if row.UnlockTrigger==1 then plans[#plans+1]={row=row,before=row.UnlockTrigger}end
  end
 end
 for id in pairs(expected)do assert(seen[id],'Missing endgame row '..id)end
 local touched={}
 local ok,err=pcall(function()
  for _,p in ipairs(plans)do touched[#touched+1]=p;p.row.UnlockTrigger=0;assert(p.row.UnlockTrigger==0,'Trigger readback failed')end
 end)
 if not ok then
  local errors=0
  for i=#touched,1,-1 do local p=touched[i];if not pcall(function()p.row.UnlockTrigger=p.before end)then errors=errors+1 end end
  error(tostring(err)..'; rollback failures='..errors)
 end
 return #plans
end
