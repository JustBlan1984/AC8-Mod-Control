-- Development only: called explicitly on the game thread, never automatically.
return function(directory,target)
 local core=assert(loadfile(directory..'Progression-core.lua'))()
 assert(assert(loadfile(directory..'Campaign-ready.lua'))()(),'Campaign is not ready')
 local managers=FindAllOf('LiveSaveDataManager') or {}
 assert(#managers==1,'Campaign manager unavailable')
 local save=managers[1].CampaignSaveGame
 assert(save:IsValid() and save.SavedVersion==38,'Unsupported save')
 assert(assert(loadfile(directory..'Session-ready.lua'))()(),'Campaign is not loaded yet')
 local data=save.CommonSaveData
 local before=data.CurrentMRP
 local after=core.credits(before,target)
 if after==before then return 'Balance already meets target; nothing changed.' end
 -- Capture before modification; caller must create a complete save backup first.
 local f=assert(io.open(directory..'credits-before-'..os.date('%Y%m%d-%H%M%S')..'.txt','w'))
 assert(f:write('CurrentMRP=',tostring(before),'\nTargetMRP=',tostring(after),'\n'))
 assert(f:close(),'Could not save credit snapshot')
 local ok,err=pcall(function()
  data.CurrentMRP=after
  assert(data.CurrentMRP==after,'Credit write did not verify')
 end)
 if not ok then
  local restored=pcall(function() data.CurrentMRP=before;assert(data.CurrentMRP==before) end)
  error(tostring(err)..'; restored='..tostring(restored))
 end
 -- Lifetime earned currency and online APIs are deliberately untouched.
 return 'Campaign balance set to '..tostring(after)..'. Reopen the tree and verify; let the game save normally.'
end
