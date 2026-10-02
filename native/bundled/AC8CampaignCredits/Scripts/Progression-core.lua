-- Pure planning functions. No game objects, networking, or save writes.
local M={}
local function integer(n,max)
 assert(type(n)=='number' and n==n and n>=0 and n%1==0 and n<=max,'Invalid integer')
 return n
end
function M.credits(current,target)
 integer(current,9007199254740991)
 integer(target,999999999)
 -- A target balance never removes credits and repeated application is idempotent.
 return math.max(current,target)
end
function M.tree(existing,catalog,selected)
 assert(type(existing)=='table' and type(catalog)=='table' and type(selected)=='table','Invalid tree input')
 local out,seen={},{}
 for _,id in ipairs(existing) do
  integer(id,4294967295)
  if not seen[id] then out[#out+1]=id;seen[id]=true end
 end
 for _,id in ipairs(selected) do
  integer(id,32767)
  assert(catalog[id]==true,'Node is not in the verified campaign catalog')
  if not seen[id] then out[#out+1]=id;seen[id]=true end
 end
 return out
end
return M
