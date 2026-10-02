return function()
 local modes=FindAllOf('LiveHangarGameModeBase') or {}
 for _,mode in ipairs(modes) do
  if mode:IsValid() and not mode:GetFullName():find('Default__',1,true) then
   local tree=StaticFindObject('/Game/Datatables/UI/Menu/HangerMenu/AircraftTree/DT_LiveMenuAircraftTreeNodeDataTable.DT_LiveMenuAircraftTreeNodeDataTable')
   if tree and tree:IsValid() then return true end
  end
 end
 return false
end
