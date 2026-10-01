-- CriminalGamer84 Mods | AC8 Adjustable FOV v1.2.2
-- See LICENSE-PERSONAL-USE.txt. UE4SS is separately MIT licensed.
local UEHelpers = require("UEHelpers")
local function log(message) print("[AC8FOV] " .. message .. "\n") end
local directory = assert(debug.getinfo(1,"S").source:match("^@(.+[\\/])"))
local memory = assert(loadfile(directory .. "FOV-memory.lua"))()({path=directory.."FOV-memory.ini", log=log})
local cachedController=nil
local function controller()
    if not cachedController or not cachedController:IsValid() then cachedController=UEHelpers.GetPlayerController() end
    if cachedController and cachedController:IsValid() then return cachedController end
end
local requestedAction=nil
local toggleRequested=false
local overlayState={}
local overlayWorker=nil
local function adjust(direction) requestedAction=direction end
local pending=false
local lastError=nil
LoopAsync(50,function()
 if pending then return false end
 pending=true
 ExecuteInGameThread(function()
  local ok,err=pcall(function()
   local pc=controller();if not pc then return end
   if toggleRequested then
    toggleRequested=false
    if not overlayState.visible then
     overlayWorker=assert(loadfile(directory.."FOV-overlay.lua"))()
    end
    if overlayWorker then overlayWorker(overlayState,pc,memory,log,true) end
   end
   if overlayWorker then overlayWorker(overlayState,pc,memory,log,false) end
   if not UEHelpers.GetGameplayStatics():IsGamePaused(pc) then
    memory.tick(pc)
    if requestedAction~=nil then local action=requestedAction;requestedAction=nil;memory.adjust(pc,action) end
   else requestedAction=nil end
  end)
  if not ok and overlayState.cleanup then pcall(overlayState.cleanup, false) end
  pending=false
  if not ok and lastError~=tostring(err) then lastError=tostring(err);log("HUD update error: "..lastError) end
 end)
 return false
end)
-- Load user-editable bindings beside this script; fall back as a complete set.
local defaults = {
    Wider = {Key = "PAGE_UP", Modifiers = {}},
    Narrower = {Key = "PAGE_DOWN", Modifiers = {}},
    Reset = {Key = "END", Modifiers = {}},
    Toggle = {Key = "F10", Modifiers = {}},
}
local actions = {{"Wider", 1}, {"Narrower", -1}, {"Reset", 0}, {"Toggle", "toggle"}}
local function validateBindings(config)
    assert(type(config) == "table", "Configuration must return a table")
    local bindings, seen = {}, {}
    for _, action in ipairs(actions) do
        local entry = config[action[1]]
        if action[1]=="Toggle" and entry==nil then entry=defaults.Toggle end
        assert(type(entry) == "table", "Missing action " .. action[1])
        assert(type(entry.Key) == "string" and type(Key[entry.Key]) == "number", "Unknown key for " .. action[1])
        assert(type(entry.Modifiers) == "table", "Modifiers must be a table")
        local names, values, used = {}, {}, {}
        for _, name in ipairs(entry.Modifiers) do
            assert(name == "CONTROL" or name == "ALT" or name == "SHIFT", "Unknown modifier")
            assert(not used[name], "Duplicate modifier")
            used[name] = true
            table.insert(names, name)
            table.insert(values, ModifierKey[name])
        end
        table.sort(names)
        local label = table.concat(names, "+") .. (#names > 0 and "+" or "") .. entry.Key
        assert(not seen[label], "Two actions use the same shortcut")
        seen[label] = true
        table.insert(bindings, {name=action[1], direction=action[2], key=Key[entry.Key], modifiers=values, label=label})
    end
    return bindings
end
local ok, bindings = pcall(function()
    local source = debug.getinfo(1, "S").source
    local directory = source:match("^@(.+[\\/])")
    assert(directory, "Cannot locate settings directory")
    local chunk, err = loadfile(directory .. "FOV-config.lua")
    assert(chunk, err)
    return validateBindings(chunk())
end)
if not ok then
    log("Settings error; using default shortcuts: " .. tostring(bindings))
    bindings = validateBindings(defaults)
end
for _, binding in ipairs(bindings) do
    local direction = binding.direction
    local callback
    if direction=="toggle" then
        overlayState.shortcut=binding.label
        callback=function() toggleRequested=true end
    else callback=function() adjust(direction) end end
    if #binding.modifiers == 0 then
        RegisterKeyBind(binding.key, callback)
    else
        RegisterKeyBind(binding.key, binding.modifiers, callback)
    end
    log(binding.name .. " = " .. binding.label)
end
log("Loaded v1.2.2. Range 50-150; step 5. D-pad reserved for wingman commands. FOV-config.lua controls the shortcuts.")
