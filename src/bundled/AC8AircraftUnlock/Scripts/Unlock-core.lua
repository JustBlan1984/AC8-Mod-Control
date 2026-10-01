-- Development build: aircraft selection and persistence are not yet verified.
local M = {}
local allowed = {}
for _,id in ipairs({1010,2010,3010,4010,5010,6010,7010,8010,9010,10010,11010,12010,13010,14010,15010,16010,17010,18010,19010,20010,21010,22010,23010,24010,25010,26010,27010,28010,29010,30010,31010,32010,38010}) do allowed[id]=true end

function M.plan(rows, owned, options)
 options=options or {}
 local candidates, seen = {}, {}
 for _,row in pairs(rows) do
  local id=row.id
  if ((allowed[id] and row.dlc=='Live') or (id==10034010 and (row.dlc=='DLC0000' or row.dlc=='Live') and options.IncludeDLCAircraft==true)) and not seen[id] then
   seen[id]=true
   if owned[id]==nil then candidates[#candidates+1]=id end
  end
 end
 local count=0;for id in pairs(seen) do if allowed[id] then count=count+1 end end
 assert(count==33,'Aircraft catalog differs from the inspected build; no changes made')
 -- Match the existing starter aircraft only in this development test.
 assert(owned[7010]==4,'Unexpected starter ownership value; no changes made')
 table.sort(candidates)
 return candidates
end

function M.apply(map, ids)
 local added={}
 local ok,err=pcall(function()
  for _,id in ipairs(ids) do
   assert(allowed[id] or id==10034010,'Unrecognized aircraft ID')
   assert(not map:Contains(id),'Ownership changed since planning')
   added[#added+1]=id
   map:Add(id,4)
   assert(map:Contains(id) and map:Find(id):get()==4,'Ownership write did not verify')
  end
 end)
 if not ok then
  local failures={}
  for _,id in ipairs(added) do
   local restored,why=pcall(function() if map:Contains(id) then map:Remove(id) end end)
   if not restored then failures[#failures+1]=tostring(why) end
  end
  error(tostring(err)..(#failures>0 and ('; rollback errors: '..table.concat(failures,'; ')) or '; additions rolled back'))
 end
 return #added
end
return M
