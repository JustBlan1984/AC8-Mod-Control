local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local busy=false
local done=false
local ticks=0
LoopAsync(5000,function()
 if done then return true end
 local request=io.open(directory..'request.txt','r')
 if not request then return true end
 request:close()
 if busy then return false end
 busy=true
 ExecuteInGameThread(function()
  local ok,result,pending=pcall(function() return assert(loadfile(directory..'Skills.lua'))()(directory) end)
  ticks=ticks+1
  if ok and not pending then
   done=true
   local removed,why=os.remove(directory..'request.txt')
   print('[AC8CampaignSkills] '..tostring(result)..' Request consumed='..tostring(removed)..' '..tostring(why or '')..'\n')
  elseif ticks==1 or ticks%60==0 then print('[AC8CampaignSkills] Waiting for remaining aircraft records: '..tostring(result)..'\n') end
  busy=false
 end)
 return false
end)

