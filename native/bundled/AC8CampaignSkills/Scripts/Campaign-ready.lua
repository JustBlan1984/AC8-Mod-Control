-- A fresh campaign can have LastPlayedMissionID=-1, and nested menu widgets
-- need not be directly in the viewport. Require an existing campaign on disk
-- plus the validated live campaign object instead of either of those signals.
return function()
 local managers=FindAllOf('LiveSaveDataManager') or {}
 if #managers~=1 then return false end
 local save=managers[1].CampaignSaveGame
 if not save or not save:IsValid() or save.SavedVersion~=38 then return false end
 local root=os.getenv('LOCALAPPDATA')
 if not root then return false end
 local file=io.open(root..'/BANDAI NAMCO Entertainment/ACE COMBAT 8/Saved/SaveGames/Campaign.sav','rb')
 if not file then return false end
 local size=file:seek('end');file:close()
 return size~=nil and size>0
end
