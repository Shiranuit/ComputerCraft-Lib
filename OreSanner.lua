local fov = math.rad(70)
local ar = 1.8
local hintToBehind = false
local charSize = 16
local maxOreGroups = 32
local maxOreGroupRadius = 0

local scansPerSecond = 1
local rendersPerSecond = 5

local modules = peripheral.find("neuralInterface")
local modb = peripheral.wrap("back")
local c3d = modb.canvas3d()
c3d.clear()
_G.can = c3d.create()


local renderDelay = 1 / rendersPerSecond
local scanDelay = 1 / scansPerSecond

local scrhor = (1 / math.tan(fov / 2)) / ar
local scrver = (1 / math.tan(fov / 2))

local oreGroups = { }
local oreTexts = { }
for i = 1,maxOreGroups do
    oreGroups[i] =  { ["x"]=0, ["y"]=0, ["z"]=0, ["color"]=0x0, ["amount"]=0, ["name"]="minecraft:air" }
    oreTexts[i] = can.addBox(0,0,0,1,1,1,0x0)
	oreTexts[i].setDepthTested(false)
end

local checkedBlocks = { }

local blocksToShow = {
    ["minecraft:emerald_ore"] = 0x46FF26FF,
    ["minecraft:diamond_ore"] = 0x50F8FFFF,
    ["minecraft:gold_ore"] = 0xFFDF50FF,
    ["minecraft:redstone_ore"] = 0xCC1215FF,
    ["minecraft:lit_redstone_ore"] = 0xCC1215FF,
    ["minecraft:iron_ore"] = 0xFFAC87Ff,
    ["minecraft:lapis_ore"] = 0x0A107FFf,
    ["minecraft:coal_ore"] = 0x202020FF,
    ["minecraft:quartz_ore"] = 0xCCCCCCFF,
    ["minecraft:glowstone"] = 0xFFDFA1FF
}

function drawOre(x, y, z, color, amount, n)
        oreTexts[n].setPosition(x, y, z)
        oreTexts[n].setColor(color or 0x0)
end

function scan()
    while true do
        blocks = modb.scan()

        for i = 1,maxOreGroups do
            oreGroups[i] =  { ["x"]=0, ["y"]=0, ["z"]=0, ["color"]=0x0, ["amount"]=0, ["name"]="minecraft:air" }
        end

        checkedBlocks = { }

        local n = 1

        local finished = false


        for x = -8,8 do

            if finished then break end

            for y = -8,8 do

                if finished then break end

                for z = -8,8 do
                    if n > maxOreGroups then
                        finished = true
                        break
                    end

                    if checkedBlocks[17^2 * (x + 8) + 17 * (y + 8) + (z + 8) + 1] == nil then
                        local block = blocks[17^2 * (x + 8) + 17 * (y + 8) + (z + 8) + 1]
                        local color = blocksToShow[block.name]

                        local blockb = false
                        local colorb = false

                        if color ~= nil then
                            local amount = 0
                            local xa,ya,za = 0,0,0

                            for xb = x-maxOreGroupRadius, x+maxOreGroupRadius do
                                for yb = y-maxOreGroupRadius, y+maxOreGroupRadius do
                                    for zb = z-maxOreGroupRadius, z+maxOreGroupRadius do
                                        if xb >= -8 and xb <= 8 and yb >= -8 and yb <= 8 and zb >= -8 and zb <= 8 and not checkedBlocks[17^2 * (xb + 8) + 17 * (yb + 8) + (zb + 8) + 1] then
                                            blockb = blocks[17^2 * (xb + 8) + 17 * (yb + 8) + (zb + 8) + 1]
                                            colorb = blocksToShow[blockb.name]

                                            if color == colorb then
                                                amount = amount + 1
                                                xa,ya,za = xa+xb,ya+yb,za+zb
                                                checkedBlocks[17^2 * (xb + 8) + 17 * (yb + 8) + (zb + 8) + 1] = true
                                            end
                                        end
                                    end
                                end
                            end

                            xa,ya,za = xa / amount, ya / amount, za / amount

                            oreGroups[n] = { ["x"]=xa, ["y"]=ya, ["z"]=za, ["amount"]=amount, ["name"]=block.name, ["color"]=color }
                            n = n + 1
                        end
                    end
                end
            end
        end
        sleep(scanDelay)
    end
end

local drawed = {}

function render()
    while true do
        local meta = modules.getMetaOwner()
		can.recenter({-meta.withinBlock.x,-meta.withinBlock.y,-meta.withinBlock.z})
		
        local block = false
		
        for n = 1, maxOreGroups do
            block = oreGroups[n]
            if block.amount > 0 then
				drawOre(block.x - meta.x, block.y + meta.y, block.z - meta.z, block.color, block.amount, n)
            else
                oreTexts[n].setColor(0x0)
            end
        end

        sleep(renderDelay)
    end
end

parallel.waitForAny(
    render,
	scan
)
