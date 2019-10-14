function newSurround(dt)
	local w, h = 0, 0
	local _w, _h = 0, 0
	local posX, posY = 1, 1
	local _posX, _posY = 1, 1
	local sel = dt[1][1]
	local bg = dt[1][1].getBackgroundColor()
	local fg = dt[1][1].getTextColor()
	local buffer = {}
	local all = {}
	local emptyLine = ""
	local emptyBg = ""
	local emptyFg = ""
	local blinkstate = false
	for x=1, #dt do
		for y=1, #dt[x] do
			if dt[x][y] then
				all[#all+1]=dt[x][y]
			end
		end
	end

	local function getColor(char)
		local chars = "0123456789abcdef"
		local _start, _end = string.find(chars,char)
		if _start then
			return 2^(_start-1)
		end
	end
	
	local function getChar(num)
		local chars = "0123456789abcdef"
		local val = math.log(num)/math.log(2)
		return chars:sub(val+1,val+1)
	end
	
	local function calc()
		w, h = 0, 0
		_w, _h = 0, 0
		for x=1, #dt do
			local _w, _h = dt[x][1].getSize()
			w=w+_w
		end
		for y=1,#dt[1] do
			local _w, _h = dt[1][y].getSize()
			h=h+_h
		end
		_w, _h = dt[1][1].getSize()
		emptyLine = string.rep(" ",w)
		emptyFg = string.rep("0",w)
		emptyBg = string.rep("f",w)
	end
	calc()
	
	local function get(x,y)
		x=x-1
		y=y-1
		local _x = (x-(x%_w))/_w
		local _y = (y-(y%_h))/_h
		_x = _x+1
		_y = _y+1
		return (dt[_x] and dt[_x][_y]), _x, _y
	end

	local function getSize()
		return w, h
	end
	
	local function setCursorBlink(state)
		for i=1, #all do
			local sc = all[i]
			sc.setCursorBlink(false)
		end
		if sel then
			sel.setCursorBlink(state)
		end
		blinkstate = state
	end
	
	local function setCursorPos(x,y)
		local sc, w, h = get(x,y)
		posX, posY = x, y
		_posX, _posY = x-((w-1)*_w), y-((h-1)*_h)
		if sc then
			sc.setCursorPos(_posX, _posY)
		end
		if sel ~= sc then
			sel=sc
			setCursorBlink(blinkstate)
		end
	end
	
	local function replacePos(ntxt,x,txt)
		local ntxt = ntxt:sub(1,x-1)..txt..ntxt:sub(x+#txt+1,#ntxt)
		return ntxt
	end
	
	local function writeBuffer(x,y,txt,fg,bg)
		buffer[y] = buffer[y] or {txt=emptyLine,fg=emptyFg,bg=emptyBg}
		buffer[y].txt = replacePos(buffer[y].txt,x,txt)
		buffer[y].fg = replacePos(buffer[y].fg,x,fg)
		buffer[y].bg = replacePos(buffer[y].bg,x,bg)
	end
	
	local function write(txt)
		setCursorPos(posX,posY)
		local tposX, tposY = posX, posY
		local npos = 1
		while npos <= #txt do
			local dst = _w-_posX
			if #txt-npos < dst then
				dst = #txt-npos
			end
			if sel then
				sel.write(txt:sub(npos,npos+dst))
			end
			npos = npos + dst + 1
			setCursorPos(posX+1+dst,posY)
		end
		writeBuffer(tposX,tposY,txt,string.rep(getChar(fg),#txt),string.rep(getChar(bg),#txt))
	end
	
	local function getCursorPos()
		return posX, posY
	end
	
	local function setTextColor(color)
		for i=1, #all do
			local sc = all[i]
			sc.setTextColor(color)
		end
		fg = color
	end
		
	local function setBackgroundColor(color)
		for i=1, #all do
			local sc = all[i]
			sc.setBackgroundColor(color)
		end
		bg = color
	end
	
	local function clear()
		setBackgroundColor(bg)
		setTextColor(fg)
		for i=1, #all do
			local sc = all[i]
			sc.clear()
		end
		for i=1, h do
			buffer[i] = {txt=emptyLine,fg=emptyFg,bg=emptyBg}
		end
		setCursorBlink(blinkstate)
	end
	
	local function clearLine()
		setBackgroundColor(bg)
		setTextColor(fg)
		for x=1, #dt do
			local x, y = (x-1)*_w+1, posY
			local sc, w, h = get(x,y)
			local _posX, _posY = x-((w-1)*_w), y-((h-1)*_h)
			if sc then
				sc.setCursorPos(_posX, _posY)
				sc.clearLine()
			end
		end
		buffer[posY]={txt=emptyLine,fg=emptyFg,bg=emptyBg}
		setCursorBlink(blinkstate)
	end
	
	local function blit(txt, fgcolor, bgcolor)
		setCursorPos(posX,posY)
		local tposX, tposY = posX, posY
		local npos = 1
		while npos <= #txt do
			local dst = _w-_posX
			if #txt-npos < dst then
				dst = #txt-npos
			end
			if sel then
				sel.blit(txt:sub(npos,npos+dst),fgcolor:sub(npos,npos+dst),bgcolor:sub(npos,npos+dst))
			end
			npos = npos + dst + 1
			setCursorPos(posX+1+dst,posY)
		end
		writeBuffer(tposX, tposY, txt, fgcolor, bgcolor)
	end
	
	local function redraw()
		local tposX, tposY = posX, posY
		for i=1, #all do
			local sc = all[i]
			sc.clear()
		end
		for y, v in pairs(buffer) do
			setCursorPos(1,y)
			blit(v.txt,v.fg,v.bg)
		end
		setCursorPos(tposX,tposY)
		setCursorBlink(blinkstate)
	end
	
	local function setTextScale(scale)
		for i=1, #all do
			local sc = all[i]
			sc.setTextScale(scale)
		end
		calc()
		redraw()
	end
	
	local function setPaletteColor(cindex, r, g, b)
		for i=1, #all do
			local sc = all[i]
			sc.setPaletteColor(cindex, r, g, b)
		end
	end
	
	local function getPaletteColor(cindex)
		return all[1].getPaletteColor(cindex)
	end
	
	local function scroll(y)
		y=y or 1
		local nbuffer = {}
		for ny, v in pairs(buffer) do
			nbuffer[ny-y]=v
		end
		buffer = nbuffer
		redraw()
	end
	
	local function getTextColor()
		return fg
	end
	
	local function getBackgroundColor()
		return bg
	end
	
	
	local function isColor()
		return dt[1][1].isColor()
	end
	
	return {getSize=getSize ,setCursorPos=setCursorPos, clear=clear, clearLine=clearLine, write=write, setTextColor=setTextColor, setTextColour=setTextColor, setBackgroundColor=setBackgroundColor, setBackgroundColour=setBackgroundColor, setTextScale=setTextScale, getCursorPos=getCursorPos, scroll=scroll, getBackgroundColor=getBackgroundColor, getBackgroundColour=getBackgroundColor, getTextColor=getTextColor, getTextColour=getTextColor, blit=blit, isColor=isColor, isColour=isColor, setCursorBlink=setCursorBlink, setPaletteColor=setPaletteColor, getPaletteColor=getPaletteColor, setPaletteColour=setPaletteColor, getPaletteColour=getPaletteColor}
end