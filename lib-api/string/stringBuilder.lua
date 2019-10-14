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

local function getText(stringb)
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
  local fn = string._endd(getText(self), getText(sep), 1, not _useregex)
  while fn do
    ret[#ret+1] = string.sub(getText(self), last, fn-1)
  	last = fn + #getText(sep)
    fn = string._endd(getText(self), getText(sep), last, not _useregex)
  end
  ret[#ret+1] = string.sub(getText(self), last)
  return ret
end

stringbuilderFunctions.contains = function(self, fTexte, _useregex)
	  return string._endd(getText(self), getText(fTexte), 1, not _useregex) ~= nil
end

stringbuilderFunctions.endWith = function(self, fTexte)
	  return fTexte == string.sub(getText(self), -#getText(fTexte),-1)
end

stringbuilderFunctions.startWith = function(self, fTexte)
	  return fTexte == string.sub(getText(self), 1, #getText(fTexte))
end

stringbuilderFunctions.left = function(self, length)
	return stringB.new(string.sub(getText(self), 1, length))
end

stringbuilderFunctions.lTrim = function(self)
	return stringB.new(string.match(getText(self),"([^ ][ ]*.+)"))
end

stringbuilderFunctions.rTrim = function(self)
	return stringB.new(string.match(getText(self),"(.+[^ ]).*$"))
end

stringbuilderFunctions.right = function(self, length)
	return stringB.new(string.sub(getText(self), #getText(self)-length, #getText(self)))
end

stringbuilderFunctions.mid = function(self, start, _end)
	if not _end then
		return stringB.new(string.sub(getText(self), start))
	else
		return stringB.new(string.sub(getText(self), start, _end))
	end
end

stringbuilderFunctions.space = function(self, num)
	if num and num > 0 then
		return stringB.new(getText(self)..string.rep(" ",num))
  else
  	return stringB.new(getText(self))
  end
end

stringbuilderFunctions.slice = function(self,number)
	local num = type(number)=="number" and number or 1
	local tTable = {}
	for i=1, #getText(self), num do
		tTable[#tTable+1]=string.sub(getText(self),i,i+num-1)
	end
	return tTable
end

stringbuilderFunctions.complete = function(self,dictionary)
  if dictionary == nil then
    return nil
  else
    if getText(self) == "" then
      return nil
    else
      tTable = {}
      for k, v in pairs(dictionary) do
        if string.sub(v,1,#getText(self)) == getText(self) then
          tTable[#tTable+1]=string.sub(v,#getText(self)+1,#v)
        end
      end
      return tTable
    end
  end
end

stringbuilderFunctions.rep = function(self, num)
	return stringB.new(string.rep(getText(self),num))
end

stringbuilderFunctions.inv = function(self)
	return stringB.new(string.reverse(getText(self)))
end

stringbuilderFunctions.add = function(self, _stringbuilder)
  return stringB.new(getText(self)..getText(_stringbuilder))
end

stringbuilder = {}
for k,v in pairs(stringbuilderFunctions) do stringbuilder[k]=v end

stringbuilder.new = function(txt)
  txt = getText(txt)
	return setmetatable({},{
    __index=stringbuilderFunctions,
    __add=stringbuilderFunctions.add,
	__mul=stringbuilderFunctions.rep,
	__div=stringbuilderFunctions.slice,
    __concat=stringbuilderFunctions.add,
    __tostring=function(tble) return getmetatable(tble).__txt end,
    __txt=txt,
  	__type="stringBuilder"
  })
end

stringB = stringbuilder