return function(directory,log)
 local managers=FindAllOf('LiveSaveDataManager') or {};assert(#managers==1,'Campaign manager unavailable')
 local save=managers[1].CampaignSaveGame;assert(save:IsValid() and save.SavedVersion==38,'Unsupported save')
 local data=save.CampaignSaveData
 -- ELiveFeature.Skin = 4 in this game's generated enum.
 local before=data.FeatureFlagMask
 local after=before | (1 << 4)
 if after==before then log('Skin customization feature already enabled.');return end
 local f=assert(io.open(directory..'skin-feature-before-'..os.date('%Y%m%d-%H%M%S')..'.txt','w'))
 f:write('FeatureFlagMask=',before,'\n');assert(f:close())
 data.FeatureFlagMask=after
 if data.FeatureFlagMask~=after then data.FeatureFlagMask=before;error('Skin feature write did not verify') end
 log('Skin customization enabled; FeatureFlagMask '..before..' -> '..after..'. Reopen the hangar menu.')
end
