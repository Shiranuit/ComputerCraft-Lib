local oldType = type
type = function(val)
  local ot = oldType(val)
	if ot=="table" then
    local meta = getmetatable(val)
    return (meta and meta.__type) or "table"
  end
  return ot
end

-- StringBuilder
local stringbuilderFunctions = {}

local function getTexte(stringb)
	if type(stringb) == "stringBuilder" then
		if getmetatable(stringb) and getmetatable(stringb).__txt then
			return getmetatable(stringb).__txt
		else
			return ""
		end
	else
		return tostring(stringb)
	end
end

stringbuilderFunctions.split = function(self, sep, _useregex)
  local ret = {}
  local last = 1
  local fn = string.find(getTexte(self), getTexte(sep), 1, not _useregex)
  while fn do
    ret[#ret+1] = string.sub(getTexte(self), last, fn-1)
  	last = fn + #getTexte(sep)
    fn = string.find(getTexte(self), getTexte(sep), last, not _useregex)
  end
  ret[#ret+1] = string.sub(getTexte(self), last)
  return ret
end

stringbuilderFunctions.contains = function(self, fTexte, _useregex)
	  return string.find(getTexte(self), getTexte(fTexte), 1, not _useregex) ~= nil
end

stringbuilderFunctions.endWith = function(self, fTexte)
	  return fTexte == string.sub(getTexte(self), -#getTexte(fTexte),-1)
end

stringbuilderFunctions.startWith = function(self, fTexte)
	  return fTexte == string.sub(getTexte(self), 1, #getTexte(fTexte))
end

stringbuilderFunctions.left = function(self, longueur)
	return stringB.new(string.sub(getTexte(self), 1, longueur))
end

stringbuilderFunctions.lTrim = function(self)
	return stringB.new(string.match(getTexte(self),"([^ ][ ]*.+)"))
end

stringbuilderFunctions.rTrim = function(self)
	return stringB.new(string.match(getTexte(self),"(.+[ ]*[^ ])"))
end

stringbuilderFunctions.right = function(self, longueur)
	return stringB.new(string.sub(getTexte(self), #getTexte(self)-longueur, #getTexte(self)))
end

stringbuilderFunctions.mid = function(self, debut, fin)
	if not fin then
		return stringB.new(string.sub(getTexte(self), debut))
	else
		return stringB.new(string.sub(getTexte(self), debut, fin))
	end
end

stringbuilderFunctions.space = function(self, num)
	if num and num > 0 then
		return stringB.new(getTexte(self)..string.rep(" ",num))
  else
  	return stringB.new(getTexte(self))
  end
end

stringbuilderFunctions.hash = function(self,number)
	local num = type(number)=="number" and number or 1
	local tTable = {}
	for i=1, #getTexte(self), num do
		tTable[#tTable+1]=string.sub(getTexte(self),i,i+num-1)
	end
	return tTable
end

stringbuilderFunctions.complete = function(self,dictionnaire)
  if dictionnaire == nil then
    return nil
  else
    if getTexte(self) == "" then
      return nil
    else
      tTable = {}
      for k, v in pairs(dictionnaire) do
        if string.sub(v,1,#getTexte(self)) == getTexte(self) then
          tTable[#tTable+1]=string.sub(v,#getTexte(self)+1,#v)
        end
      end
      return tTable
    end
  end
end

stringbuilderFunctions.rep = function(self, num)
	return stringB.new(string.rep(getTexte(self),num))
end

stringbuilderFunctions.inv = function(self)
	return stringB.new(string.reverse(getTexte(self)))
end

stringbuilderFunctions.add = function(self, _stringbuilder)
  return stringB.new(getTexte(self)..getTexte(_stringbuilder))
end

stringbuilder = {}
for k,v in pairs(stringbuilderFunctions) do stringbuilder[k]=v end

stringbuilder.new = function(txt)
  txt = getTexte(txt)
	return setmetatable({},{
    __index=stringbuilderFunctions,
    __add=stringbuilderFunctions.add,
	__mul=stringbuilderFunctions.rep,
	__div=stringbuilderFunctions.hash,
    __concat=stringbuilderFunctions.add,
    __tostring=function(tble) return getmetatable(tble).__txt end,
    __txt=txt,
  	__type="stringBuilder"
  })
end

stringB = stringbuilder