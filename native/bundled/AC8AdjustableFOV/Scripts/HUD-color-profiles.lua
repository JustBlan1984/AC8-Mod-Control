-- Color choices are independent of widget discovery and native rendering.
-- An absent override inherits All HUD; disabled means original game colors.
local P={}
P.groups={
 {'all','ALL HUD'}, {'score','SCORE / TARGET TEXT'}, {'timer','TIMER'},
 {'center','CENTER INSTRUMENTS'}, {'radar','RADAR GRID'},
 {'weapons','WEAPON COUNTS'}, {'aircraft','AIRCRAFT / STORES'},
 {'radio','RADIO PORTRAIT'}, {'commands','D-PAD / COMMANDS'},
 {'wingmen','ALL WINGMAN ELEMENTS'},
 {'wingarrows','WINGMAN EDGE ARROWS'}, {'wingedgenames','WINGMAN EDGE NAMES'},
 {'wingboxes','WINGMAN W BOXES'}, {'wingcallsigns','WINGMAN CALLSIGNS'},
 {'wingnames','WINGMAN NAMES'}, {'target','ACTIVE TARGET'},
 {'enemies','ENEMY MARKERS'}, {'lock','MISSILE LOCK'},
 {'allies','ALLY MARKERS'}, {'warnings','WARNINGS'},
}
local allowed={};for _,g in ipairs(P.groups)do allowed[g[1]]=true end
local function copy(v)return {enabled=v.enabled,h=v.h,s=v.s,v=v.v}end
local function clamp(v)return math.max(0,math.min(1,v))end
function P.new(default)
 local self={base=copy(default or {enabled=false,h=.33,s=1,v=1}),overrides={}}
 function self:get(key)return copy(self.overrides[key] or self.base)end
 function self:set(key,h,s,v)
  assert(allowed[key],'Unknown HUD color group')
  local value={enabled=true,h=clamp(h),s=clamp(s),v=clamp(v)}
  if key=='all'then self.base=value;self.overrides={}else self.overrides[key]=value end
 end
 function self:reset(key)
  assert(allowed[key],'Unknown HUD color group')
  if key=='all'then self.base.enabled=false;self.overrides={}
  else self.overrides[key]={enabled=false,h=.33,s=1,v=1}end
 end
 function self:inherit(key)self.overrides[key]=nil end
 function self:encode()
  local lines={'AC8_HUD_COLORS 2'}
  local function add(key,c)lines[#lines+1]=string.format('%s %d %.6f %.6f %.6f',key,c.enabled and 1 or 0,c.h,c.s,c.v)end
  add('all',self.base)
  for _,g in ipairs(P.groups)do local c=self.overrides[g[1]];if c then add(g[1],c)end end
  return table.concat(lines,'\n')..'\n'
 end
 function self:decode(text)
  local nextBase,nextOverrides=copy(self.base),{}
  for line in text:gmatch('[^\r\n]+')do
   local key,e,h,s,v=line:match('^(%w+) ([01]) ([%d.]+) ([%d.]+) ([%d.]+)$')
   h,s,v=tonumber(h),tonumber(s),tonumber(v)
   if allowed[key] and h and s and v and h<=1 and s<=1 and v<=1 then
    local c={enabled=e=='1',h=h,s=s,v=v}
    if key=='all'then nextBase=c else nextOverrides[key]=c end
   end
  end
  self.base,self.overrides=nextBase,nextOverrides
 end
 return self
end
return P
