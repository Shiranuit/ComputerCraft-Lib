white = 1
orange = 2
magenta = 4
lightBlue = 8
yellow = 16
lime = 32
pink = 64
gray = 128
lightGray = 256
cyan = 512
purple = 1024
blue = 2048
brown = 4096
green = 8192
red = 16384
black = 32768

colorsHex = {white="F0F0F0",orange="F2B233",magenta="E57FD8",lightBlue="99B2F2",yellow="DEDE6C",lime="7FCC19",pink="F2B2CC",gray="4C4C4C",lightGray="999999",cyan="4C99B2",purple="B266E5",blue="3366CC",brown="7F664C",green="57A64E",red="CC4C4C",black="000000"}

function combine( ... )
    local r = 0
    for n,c in ipairs( { ... } ) do
        r = bit.bor(r,c)
    end
    return r
end

function subtract( colors, ... )
	local r = colors
	for n,c in ipairs( { ... } ) do
		r = bit.band(r, bit.bnot(c))
	end
	return r
end

function test( colors, color )
    return ((bit.band(colors, color)) == color)
end

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function decToHex(num)
	if num > 0 then
    local b,k,out,i,d=16,"0123456789abcdef","",0
		while num>0 do
			i=i+1
			num,d=math.floor(num/b),(num%b)+1
			out=string.sub(k,d,d)..out
		end
		return string.rep("0",2-#tostring(out))..out
	elseif num == 0 then
		return "00"
	end
    return ""
end

function getPaintChar(color)
	if type(color) == "number" then
		return decToHex(math.floor(math.log(color)/math.log(2)))
	end
end

function RGBToHSL(r, g, b, a)
  r, g, b = r / 255, g / 255, b / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, l
  l = (max + min) / 2
  if max == min then
    h, s = 0, 0
  else
    local d = max - min
    if l > 0.5 then s = d / (2 - max - min) else s = d / (max + min) end
    if max == r then h = (g - b) / d
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
  end
  h = h*60
  if h < 0 then h=h+360 end
  return round(h,0), round(s*100,0), round(l*100,0), a or 255
end

function HSLToRGB(h, s, l, a)
	local t_1,t_2,t_R,t_G,t_B,r,g,b
	h,s,l=h/360,s/100,l/100
	if l < 0.5 then t_1=l*(1+s)
	else t_1=l+s-l*s
	end
	t_2=2*l-t_1
	t_R=h+0.333
	t_G=h
	t_B=h-0.333
	if t_R < 0 then t_R=t_R+1 end
	if t_G < 0 then t_G=t_G+1 end
	if t_B < 0 then t_B=t_B+1 end
	if t_R > 1 then t_R=t_R-1 end
	if t_G > 1 then t_G=t_G-1 end
	if t_B > 1 then t_B=t_B-1 end
	function t_n(v)
		local r
		if 6*v < 1 then r=t_2+(t_1-t_2)*6*v
		elseif 2*v < 1 then r=t_1
		elseif 3*v < 2 then r=t_2+(t_1-t_2)*(0.666-v)*6*v
		else r=t_2
		end
		return r
	end
	r = t_n(t_R)
	g = t_n(t_G)
	b = t_n(t_B)
	return round(r*255,0),round(g*255,0),round(b*255,0),a or 255
end

function HEXToRGB(hex)
    hex = hex:gsub("#","")
	hex = string.rep("0",8-#hex)..hex
    return tonumber("0x"..hex:sub(1,2))==0 and 255 or tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)),tonumber("0x"..hex:sub(7,8))
end

function RGBToHex(r,g,b,a)
	return decToHex(a or 255)..decToHex(r)..decToHex(g)..decToHex(b)
end

function hue_offset(h,s,l,delta)
   return (h + delta) % 360, s, l
end

function RGBToXYZ(r,g,b)
	local var_R,var_G,var_B=r/255,g/255,b/255
	if var_R > 0.04045 then var_R=((var_R+0.055)/1.055)^2.4
	else var_R=var_R/12.92 end
	if var_G > 0.04045 then var_G=((var_G+0.055)/1.055)^2.4
	else var_G=var_G/12.92 end
	if var_B > 0.04045 then var_B=((var_B+0.055)/1.055)^2.4
	else var_B=var_B/12.92 end
	var_R,var_G,var_B=var_R*100,var_G*100,var_B*100
	local X=var_R*0.4124+var_G*0.3576+var_B*0.1805
	local Y=var_R*0.2126+var_G*0.7152+var_B*0.0722
	local Z=var_R*0.0193+var_G*0.1192+var_B*0.9505
	return X, Y, Z
end

function XYZToRGB(X,Y,Z)
	local var_X,var_Y,var_Z=X/100,Y/100,Z/100
	local var_R=var_X*3.2406+var_Y*-1.5372+var_Z*-0.4986
	local var_G=var_X*-0.9689+var_Y*1.8758+var_Z*0.0415
	local var_B=var_X*0.0557+var_Y*-0.2040+var_Z*1.0570
	if var_R > 0.0031308 then var_R=1.055*(var_R^(1/2.4))-0.055
	else var_R=12.92*var_R end
	if var_G > 0.0031308 then var_G=1.055*(var_G^(1/2.4))-0.055
	else var_G=12.92*var_G end
	if var_B > 0.0031308 then var_B=1.055*(var_B^(1/2.4))-0.055
	else var_B=12.92*var_B end
	local r,g,b=var_R*255,var_G*255,var_B*255
	return round(r,0),round(g,0),round(b,0)
end

function XYZToHLab(X,Y,Z)
	local HL,Ha,Hb=10*math.sqrt(Y),17.5*(((1.02*X)-Y)/math.sqrt(Y)),7*((Y-(0.847*Z))/math.sqrt(Y))
	return HL,Ha,Hb
end

function HLabToXYZ(HL,Ha,Hb)
	local var_Y,var_X,var_Z=HL/10,Ha/17.5*HL/10,Hb/7*HL/10
	local Y = var_Y^2
	local X = (var_X+Y)/1.02
	local Z = -(var_Z-Y)/0.847
	return X, Y, Z
end

function XYZToCIELab(X,Y,Z)
	local var_X,var_Y,var_Z=X/95.047,Y/100,Z/108.833
	if var_X > 0.008856 then var_X=var_X^(1/3)
	else var_X=(7.787*var_X)+(16/116) end
	if var_Y > 0.008856 then var_Y=var_Y^(1/3)
	else var_Y=(7.787*var_Y)+(16/116) end
	if var_Z > 0.008856 then var_Z=var_Z^(1/3)
	else var_Z=(7.787*var_Z)+(16/116) end
	local CIEL,CIEa,CIEb=(116*var_Y)-16,500*(var_X-var_Y),200*(var_Y-var_Z)
	return CIEL,CIEa,CIEb
end

function CIELabToXYZ(CIEL,CIEa,CIEb)
	local var_Y=(CIEL+16)/116
	local var_X=CIEa/500+var_Y
	local var_Z=var_Y-CIEb/200
	if var_Y^3 > 0.008856 then var_Y=var_Y^3
	else var_Y=(var_Y-16/116)/7.787 end
	if var_X^3 > 0.008856 then var_X=var_X^3
	else var_X=(var_X-16/116)/7.787 end
	if var_Z^3 > 0.008856 then var_Z=var_Z^3
	else var_Z=(var_Z-16/116)/7.787 end
	local X,Y,Z=95.047*var_X,100*var_Y,108.883*var_Z
	return X,Y,Z
end

function CIELabToCIELCH(CIEL,CIEa,CIEb)
	local var_H=math.atan(CIEb/CIEa)
	if var_H>0 then var_H=(var_H/math.pi)*180
	else var_H=360-(math.abs(var_H)/math.pi)*180 end
	local CIEC,CIEH=math.sqrt(CIEa^2+CIEb^2),var_H
	return CIEL,CIEC,CIEH
end

function CIELCHToCIELab(CIEL,CIEC,CIEH)
	local CIEa,CIEb=math.cos(math.rad(CIEH))*CIEC,math.sin(math.rad(CIEH))*CIEC
	return CIEL,CIEa,CIEb
end

function XYZToCIELuv(X,Y,Z)
	local var_U,var_V,var_Y=(4*X)/(X+(15*Y)+(3*Z)),(9*Y)/(X+(15*Y)+(3*Z)),Y/100
	if var_Y > 0.008856 then var_Y=var_Y^(1/3)
	else var_Y=(7.787*var_Y)+(16/116) end
	local ref_X,ref_Y,ref_Z=95.047,100,108.883
	local ref_U,ref_V=(9*ref_X)/(ref_X+(15*ref_Y)+(3*ref_Z)),(9*ref_Y)/(ref_X+(15*ref_Y)+(3*ref_Z))
	local CIEL=(116*var_Y)-16
	local CIEu=13*CIEL*(var_U-ref_U)
	local CIEv=13*CIEL*(var_V-ref_V)
	return CIEL,CIEu,CIEv
end

function CIELuvToXYZ(CIEL,CIEu,CIEv)
	local var_Y=(CIEL+16)/116
	if var_Y^3 > 0.008856 then var_Y=var_Y^3
	else var_Y=(var_Y-16/16)/7.787 end
	local ref_X,ref_Y,ref_Z=95.047,100,108.883
	local ref_U,ref_V=(9*ref_X)/(ref_X+(15*ref_Y)+(3*ref_Z)),(9*ref_Y)/(ref_X+(15*ref_Y)+(3*ref_Z))
	local var_U,var_V=CIEu/(13*CIEL)+ref_U,CIEv/(13*CIEL)+ref_V
	local Y=var_Y*100
	local X=-(9*Y*var_U)/((var_U-4)*var_V-var_U*var_V)
	local Z=(9*Y-(15*var_V*Y)-(var_V*X))/(3*var_V)
	return X, Y, Z
end

function RGBToCMY(r,g,b)
	local C,M,Y=1-(r/255),1-(g/255),1-(b/255)
	return C,M,Y
end

function CMYToRGB(C,M,Y)
	local r,g,b=(1-C)*255,(1-M)*255,(1-Y)*255
	return r,g,b
end

function CMYToCMYK(C,M,Y)
	local var_K=1
	if C < var_K then var_K=C end
	if M < var_K then var_K=M end
	if Y < var_K then var_K=Y end
	if var_K==1 then C,M,Y=0,0,0
	else C,M,Y=(C-var_K)/(1-var_K),(M-var_K)/(1-var_K),(C-var_K)/(1-var_K) end
	local K=var_K
	return C,M,Y,K
end

function CMYKToCMY(C,M,Y,K)
	local C,M,Y=(C*(1-K)+K),(M*(1-K)+K),(Y*(1-K)+K)
	return C,M,Y
end

function RGBToHSV(r,g,b)
	local var_R,var_G,var_B=r/255,g/255,b/255
	local var_Min,var_Max=math.min(var_R,var_G,var_B),math.max(var_R,var_G,var_B)
	local del_Max=var_Max-var_Min
	local V=var_Max
	local H,S
	if del_Max == 0 then H,S=0,0
	else
		S=del_Max/var_Max
		local del_R=(((var_Max-var_R)/6)+(del_Max/2))/del_Max
		local del_G=(((var_Max-var_G)/6)+(del_Max/2))/del_Max
		local del_B=(((var_Max-var_B)/6)+(del_Max/2))/del_Max
		if var_R==var_Max then H=del_B-del_G
		elseif var_G==var_Max then H=(1/3)+del_R-del_B
		elseif var_B==var_Max then H=(2/3)+del_G-del_R end
		if H<0 then H=H+1 end
		if H>1 then H=H-1 end
	end
	return H,S,V
end

function HSVToRGB(H,S,V)
	local r,g,b
	if S==0 then
		r=V*255
		g=V*255
		b=V*255
	else
		local var_H=H*6
		if var_H==6 then var_H=0 end
		local var_I=math.floor(var_H)
		local var_1=V*(1-S)
		local var_2=V*(1-S*(var_H-var_I))
		local var_3=V*(1-S*(1-(var_H-var_I)))
		local var_R,var_G,var_B
		if var_I==0 then var_R,var_G,var_B=V,var_3,var_1
		elseif var_I==1 then var_R,var_G,var_B=var_2,V,var_1
		elseif var_I==2 then var_R,var_G,var_B=var_1,V,var_3
		elseif var_I==3 then var_R,var_G,var_B=var_1,var_2,V
		elseif var_I==4 then var_R,var_G,var_B=var_3,var_1,V
		else var_R,var_G,var_B=V,var_1,var_2 end
		r,g,b=var_R*255,var_G*255,var_B*255
	end
	return r,g,b
end

function XYZToYxy(X,Y,Z)
	local x,y=Y,X/(X+Y+Z),Y/(X+Y+Z)
	return Y,x,y
end

function YxyToXYZ(Y,x,y)
	local X,Z=x*(Y/y),(1-x-y)*(Y/y)
	return X,Y,Z
end

function DeltaC(CIEa1,CIEb1,CIEa2,CIEb2)
	return math.sqrt((CIEa2^2)+(CIEb2^2))-math.sqrt((CIEa1^2)+(CIEb1^2))
end

function DeltaH(CIEa1,CIEb1,CIEa2,CIEb2)
	local xDE=DeltaC(CIEa1,CIEb1,CIEa2,CIEb2)
	return math.sqrt((CIEa2^2-CIEa1)^2+(CIEb2-CIEb1)^2-(xDE^2))
end

function DeltaCIE76(CIEL1,CIEa1,CIEb1,CIEL2,CIEa2,CIEb2)
	return math.sqrt((CIEL1-CIEL2)^2+(CIEa1-CIEa2)^2+(CIEb1-CIEb2)^2)
end

function DeltaCIE94(CIEL1,CIEa1,CIEb1,CIEL2,CIEa2,CIEb2,app)
	local WHTL,WHTC,WHTH=1,0.045,0.015
	app = app or 1
	if app == 1 then WHTL,WHTC,WHTH=1,0.045,0.015
	elseif app == 2 then WHTL,WHTC,WHTH=2,0.048,0.014 end
	local xC1,xC2,xDL=math.sqrt(CIEa1^2+CIEb1^2),math.sqrt(CIEa2^2+CIEb2^2),CIEL2-CIEL1
	local xDC=xC2-xC1
	local xDE=DeltaCIE76(CIEL1,CIEa1,CIEb1,CIEL2,CIEa2,CIEb2)
	local xDH
	if math.sqrt(xDE) > math.sqrt(math.abs(xDL))+math.sqrt(math.abs(xDC)) then xDH=math.sqrt(xDE^2-xDL^2-xDC^2)
	else xDH=0 end
	local xSC,xSH=1+(0.045*xC1),1+(0.015*xC1)
	local xDL=xDL/WHTL
	local xDC=xDC/(WHTC*xSC)
	local xDH=xDH/(WHTH*xSH)
	return math.sqrt(xDL^2+xDC^2+xDH^2)
end

function CIELabToHue(var_A,var_B)
	local var_bias=0
	if var_A>=0 and var_B==0 then return 0 end
	if var_A<0 and var_B==0 then return 180 end
	if var_A==0 and var_B>0 then return 90 end
	if var_A==0 and var_B<0 then return 270 end
	if var_A>0 and var_B>0 then var_bias=0 end
	if var_A<0 then var_bias=180 end
	if var_A>0 and var_B<0 then var_bias=360 end
	return math.deg(math.atan(var_B/var_A)+var_bias)
end

function DeltaCIEDE2000(CIEL1,CIEa1,CIEb1,CIEL2,CIEa2,CIEb2,app)
	local WHTL,WHTC,WHTH=1,0.045,0.015
	app = app or 1
	if app == 1 then WHTL,WHTC,WHTH=1,0.045,0.015
	elseif app == 2 then WHTL,WHTC,WHTH=2,0.048,0.014 end
	local xC1,xC2=math.sqrt(CIEa1^2+CIEb1^2),math.sqrt(CIEa2^2+CIEb2^2)
	local xCX=(xC1+xC2)/2
	local xGX=0.5*(1-math.sqrt((xCX^7)/((xCX^7) + (25^7))))
	local xNN=(1+xGX)*CIEa1
	xC1=math.sqrt(xNN^2+CIEb1^2)
	local xH1=CIELabToHue(xNN,CIEb1)
	xNN=(1+xGX)*CIEa2
	xC2=math.sqrt(xNN^2+CIEb2^2)
	local xH2=CIELabToHue(xNN,CIEb2)
	local xDL=CIEL2-CIEL1
	local xDC=xC2-xC1
	if xC1*xC2 == 0 then
		xDH=0
	else
		xNN=round(xH2-xH1,12)
		if math.abs(xNN) <= 180 then
			xDH=xH2-xH1
		else
			if xNN>180 then xDH=xH2-xH1-360
			else xDH=xH2-xH1+360 end
		end
	end
	xDH=2*math.sqrt(xC1*xC2)*math.sin(math.rad(xDH/2))
	local xLX=(CIEL1+CIEL2)/2
	local xCY=(xC1+xC2)/2
	local xHX
	if xC1*xC2 == 0 then
		xHX=xH1+xH2
	else
		xNN=math.abs(round(xH1-xH2,12))
		if xNN > 180 then 
			if xH2+xH1 < 360 then xHX=xH1+xH2+360
			else xHX=xH1+xH2-360 end
		else
			xHX=xH1+xH2
		end
		xHX=xHX/2
	end
	local xTX=1-0.17*math.cos(math.rad(xHX-30))+0.24*math.cos(math.rad(2*xHX))+0.32*math.cos(math.rad(3*xHX+6))-0.20*math.cos(math.rad(4*xHX-63))
	local xPH=30*math.exp(-((xHX-275)/25)*((xHX-275)/25))
	local xRC=2*math.sqrt((xCY^7)/((xCY^7)+(25^7)))
	local xSL=1+(0.015*((xLX-50)^2)/math.sqrt(20+((xLX-50)^2)))
	local xSC=1+0.045*xCY
	local xSH=1+0.015*xCY*xTX
	local xRT=-math.sin(math.rad(2*xPH))*xRC
	xDL=xDC/(WHTL*xSL)
	xDC=xDC/(WHTC*xSC)
	xDH=xDH/(WHTH*xSH)
	return math.sqrt(xDL^2+xDC^2+xDH^2+xRT*xDC*xDH)
end

function DeltaCMC(CIEL1,CIEa1,CIEb1,CIEL2,CIEa2,CIEb2,app)
	local WHTL,WHTC,WHTH=1,0.045,0.015
	app = app or 1
	if app == 1 then WHTL,WHTC,WHTH=1,0.045,0.015
	elseif app == 2 then WHTL,WHTC,WHTH=2,0.048,0.014 end
	local xC1=math.sqrt(CIEa1^2+CIEb1^2)
	local xC2=math.sqrt(CIEa2^2+CIEb2^2)
	local xff=math.sqrt((xC1^4)/(xC1^4)+1900)
	local xH1=CIELabToHue(CIEa1,CIEb1)
	local xTT,xSL,xSC,xSH,xDH
	if xH1 < 164 or xH1 > 345 then xTT=0.36+math.abs(0.4*math.cos(math.rad(35+xH1)))
	else xTT=0.56+math.abs(0.2*math.cos(math.rad(168+xH1))) end
	if CIEL1 < 16 then xSL=0.511
	else xSL=(0.040975*CIEL1)/(1+(0.01765*CIEL1)) end
	xSC=((0.0638*xC1)/(1+(0.0131*xC1)))+0.638
	xSH=((xff*xTT)+1-xff)*xSC
	xDH=math.sqrt((CIEa2-CIEa1)^2+(CIEb2-CIEb1)^2-(xC2-xC1)^2)
	xSL=(CIEL2-CIEL1)/WHTL*xSL
	xSC=(xC2-xC1)/WHTC*xSC
	xSH=xDH/xSH
	return math.sqrt(xSL^2+xSC^2+xSH^2)
end