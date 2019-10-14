function Writer(val)
	local buff = {}
	if val then
		if type(val) == "table" then
			buff=val
		elseif type(val) == "string" then
			buff={}
			for i=1, #val do
				buff[#buff+1]=val:sub(i,i)
			end
		else
			buff={}
		end
	else
		buff={}
	end
	local function intLenght(d)
		for i=1, 7 do
			local v = 2^i
			local v1 = 2^(v-1)-1
			if v1 < d then
				return v
			end
		end
		return 4
	end
	local function write(byte)
		buff[#buff+1]=string.char(byte)
	end
	local function writeByte(val)
		if type(val)~="number" then 
			return 
		end
		write(val)
	end
	local function writeInt(val, size)
		if type(val)~="number" then
			return
		end
		for i=1, size/8 do
			write(bit.band(val,255))
			val=bit.brshift(val,8)
		end
	end
	
	local function writeString(val)
		if 
			type(val)~="string" then 
			return 
		end
		writeInt(#val,32)
		for i=1, #val do
			write(val:sub(i,i):byte())
		end
	end

	local function writeBool(val)
		if type(val)~="boolean" then
			return 
		end
		write(val and 1 or 0)
	end
	
	local writeTable, writeFunc
	
	local function writeVar(val)
		if type(val) == "number" then
			write(1)
			writeInt(val,32)
		elseif type(val) == "string" then
			write(2)
			writeString(val)
		elseif type(val) == "boolean" then
			write(3)
			writeBool(val)
		elseif type(val) == "table" then
			write(4)
			writeTable(val)
		elseif type(val) == "function" then
			write(5)
			writeFunc(val)
		end
	end

	writeTable = function(val)
		if type(val)~="table" then
			return
		end
		local n=0
		for k, v in pairs(val) do
			n=n+1
		end 
		writeInt(n,32)
		for k, v in pairs(val) do
			writeVar(k)
			writeVar(v)
		end
	end

	writeFunc = function(val)
		if type(val)~="function" then
			return 
		end
		writeString(string.dump(val))
	end
	
	local function getBuff()
		local b = table.concat(buff,"")
		buff={}
		return b
	end
	
	return {getBuff=getBuff,writeByte=writeByte,writeInt=writeInt,writeString=writeString,writeBool=writeBool,writeTable=writeTable,writeFunc=writeFunc,writeVar=writeVar}
end

function Reader(val)
	local buff = {}
	if val then
		if type(val) == "table" then
			buff=val
		elseif type(val) == "string" then
			buff={}
			for i=1, #val do
				buff[#buff+1]=val:sub(i,i)
			end
		else
			buff={}
		end
	else
		buff={}
	end
	
	local function checkSize(n)
		n=n or 1
		for i=1, n do
			if not buff[i] then
				error("Out of limit",1)
			end
		end
	end
	
	local function read(n)
		n = n or 1
		checkSize(n)
		local t = {}
		for i=1, n do
			t[#t+1]=buff[1]:byte()
			table.remove(buff,1)
		end
		return t
	end

	local function readByte()
		checkSize()
		local v = buff[1]
		table.remove(buff,1)
		return v:byte()
	end

	local function readInt(size)
		if size then
			checkSize(size/8)
			local val = 0
			for i=1, size/8 do
				val = bit.bor(val,bit.blshift(bit.band(buff[i]:byte(),255),(i-1)*8))
			end
			for i=1, size/8 do
				table.remove(buff,1)
			end
			return val
		end
	end

	local function readString()
		local size = readInt(32)
		checkSize(size)
		local t = ""
		for i=1, size do
			t=t..buff[1]
			table.remove(buff,1)
		end
		return t
	end

	local function readBool()
		checkSize()
		return read()[1]==1 and true or false
	end
	local readTable, readFunc
	local function readVar()
		checkSize()
		local id = buff[1]:byte()
		table.remove(buff,1)
		if id == 0 then
			return readByte()
		elseif id == 1 then
			return readInt(32)
		elseif id == 2 then
			return readString()
		elseif id == 3 then
			return readBool()
		elseif id == 4 then
			return readTable()
		elseif id == 5 then
			return readFunc()
		end
	end

	readTable = function()
		local size = readInt(32)
		if size then
			local t = {}
			for i=1, size do
				local key = readVar()
				local val = readVar()
				t[key]=val
			end
			return t
		end
	end

	readFunc = function()
		local dt = readString()
		return loadstring(dt)
	end
	
	function getBuff()
		return buff
	end

	return {readByte=readByte,readInt=readInt,readString=readString,readBool=readBool,readTable=readTable,readFunc=readFunc,readVar=readVar}
end