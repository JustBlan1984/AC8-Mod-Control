local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local busy=false
local done=false
local ticks=0
local nativeReady=false
local readyAddress=nil
local readyTicks=0
LoopAsync(5000,function()
 if done and nativeReady then return true end
 local request=io.open(directory..'request.txt','r')
 if request then request:close() else done=true end
 if busy then return false end
 busy=true
 ExecuteInGameThread(function()
  local ok,result=pcall(function()
   assert(assert(loadfile(directory..'Campaign-ready.lua'))()(),'Waiting for loaded campaign')
   local address=FindAllOf('LiveSaveDataManager')[1].CampaignSaveGame:GetAddress()
   if readyAddress~=address then readyAddress=address;readyTicks=0 end
   readyTicks=readyTicks+1
   assert(readyTicks>=2,'Waiting for campaign initialization')
   if not nativeReady then
    local dt=StaticFindObject('/Game/Datatables/UI/Menu/HangerMenu/AircraftTree/DT_LiveMenuAircraftTreeNodeDataTable.DT_LiveMenuAircraftTreeNodeDataTable')
    assert(dt and dt:IsValid(),'Waiting for tree catalog')
    assert(loadfile(directory..'Native-tree-access.lua'))()(dt)
    nativeReady=true
   end
   if not done then return assert(loadfile(directory..'Tree.lua'))()(directory) end
   return 'Native tree gates ready.'
  end)
  ticks=ticks+1
  if ok then
   done=true
   local removed,why=os.remove(directory..'request.txt')
   print('[AC8CampaignTree] '..tostring(result)..' Request consumed='..tostring(removed)..' '..tostring(why or '')..'\n')
  else
   if not assert(loadfile(directory..'Campaign-ready.lua'))()() then readyAddress=nil;readyTicks=0 end
   if ticks==1 or ticks%60==0 then print('[AC8CampaignTree] Waiting: '..tostring(result)..'\n') end
  end
  busy=false
 end)
 return false
end)
