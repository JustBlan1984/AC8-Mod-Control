local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local busy,done=false,false
local stable,last=nil,nil
local ticks=0
local function log(message) print('[AC8CampaignCredits] '..message..'\n') end
local function attempt(manual)
 if busy then return end
 busy=true
 local queued,why=pcall(ExecuteInGameThread,function()
  local ok,result=pcall(function()
   assert(assert(loadfile(directory..'Campaign-ready.lua'))()(),'Campaign not ready')
   assert(assert(loadfile(directory..'Session-ready.lua'))()(),'Waiting for loaded campaign')
   local save=FindAllOf('LiveSaveDataManager')[1].CampaignSaveGame
   local signature=tostring(save:GetAddress())..':'..tostring(save.CommonSaveData.CurrentMRP)
   if not manual then
    if signature~=last then last=signature;stable=0;return 'Waiting for stable campaign balance' end
    stable=stable+1
    if stable<2 then return 'Waiting for stable campaign balance' end
   end
   local config=assert(loadfile(directory..'Credits-config.lua'))()
   assert(type(config)=='table' and type(config.Target)=='number' and config.Target>=1 and config.Target<=999999999 and config.Target%1==0,'Invalid MRP target')
   local result=assert(loadfile(directory..'Credits.lua'))()(directory,config.Target)
   done=true
   os.remove(directory..'request.txt')
   log(result..' Back out and reopen the tree to refresh its display. F6 retries explicitly.')
   return nil
  end)
  ticks=ticks+1
  if not ok then last=nil;stable=nil end
  if manual or ticks==1 or ticks%60==0 then
   if result then log(tostring(result)) end
  end
  busy=false
 end)
 if not queued then busy=false;log('Scheduling failed: '..tostring(why)) end
end
RegisterKeyBind(Key.F6,function() attempt(true) end)
LoopAsync(5000,function()
 if done then return true end
 local request=io.open(directory..'request.txt','r')
 if not request then return true end
 request:close();attempt(false);return false
end)
log('Credits queued by Apply; waits for a loaded campaign. F6 adds credits on demand after the campaign loads.')
