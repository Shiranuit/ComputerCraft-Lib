local pretty = require "cc.pretty"
local completion = require "cc.completion"
local pp = pretty.pretty_print
local inventory = require("inventory")
local exchangeChestPeriph = "minecraft:chest_551"

local nameCache = {}
local nameRef = {}

local side = {
    top = true,
    bottom = true,
    front = true,
    back = true,
    left = true,
    right = true,
}

local scope = {}

print('Scanning peripherals...')
local chests = inventory.find(function(name, periph)
    return name ~= exchangeChestPeriph and not side[name]
end, scope)

local function writeStorageCache()
    local cache = {}
    for i=1, #chests do
        cache[chests[i].name] = {
            size = chests[i]:size(),
            items = chests[i]:list()
        }
    end

    local h = fs.open(".storage_cache", "w")
    h.write(textutils.serialize(cache, { compact = true }))
    h.close()
end

if fs.exists(".storage_cache") then
    local h = fs.open(".storage_cache", "r")
    local cache = textutils.unserialize(h.readAll())
    h.close()

    local modified = false
    local coroutines = {}
    for i=1, #chests do
        local chestInfo = cache[chests[i].name] 
        if chestInfo then
            print('Loading inventory "'..chests[i].name..'" from cache')
            chests[i]:loadInventory(chestInfo.items, chestInfo.size)
        else
            print('Indexing inventory "'..chests[i].name..'"')
            table.insert(coroutines, function()
                chests[i]:list()
            end)
            modified = true

            if #coroutines == 128 then
                parallel.waitForAll(table.unpack(coroutines))
                coroutines = {}
            end
        end
    end
    if modified then
        parallel.waitForAll(table.unpack(coroutines))
        writeStorageCache()
    end
else
    local coroutines = {}
    local count = { value = 0 }
    for i=1, #chests do
        term.clear()
        term.setCursorPos(1,1)
        print('Indexing chest #'..i.." / "..#chests)
        table.insert(coroutines, function()
            chests[i]:list()
            count.value = count.value + 1
            print(count.value)
        end)
        if #coroutines == 128 then
            parallel.waitForAll(table.unpack(coroutines))
            coroutines = {}
        end
    end
    parallel.waitForAll(table.unpack(coroutines))
    writeStorageCache()
end



local function computeNameCache()
    nameCache = {}
    nameRef = {}
    local items = scope.itemsName
    local names = {}
    local seenNames = {}
    for i=1, #items do
        local prefix, name = items[i]:match('([^:]+):(.+)')
        seenNames[name] = (seenNames[name] or 0) + 1
        names[i] = { prefix, name }
    end

    for i=1, #names do
        if seenNames[names[i][2]] > 1 then
            nameCache[i] = items[i]
        else
            nameCache[i] = names[i][2]
        end
        nameRef[nameCache[i]] = items[i]
    end
end

computeNameCache()

local exChest = inventory.new(exchangeChestPeriph, scope)

exChest:list()

local function countItem(name)
    local count = 0
    for i=1, #chests do
        count = count + chests[i]:countItem(name)
    end
    return count
end

local function storeItems()
    local items = exChest:list(true)
    for i=1, exChest:size() do
        local item = items[i]

        if item then
            local maxStackSize = exChest:getItemLimit(i)
            local count = item.count

            for j=1, #chests do
                local chest = chests[j]
                count = count - exChest:mergeItems(chest.name, i, count)

                if count == 0 then
                    break
                end
            end

            if count > 0 then
                for j=1, #chests do
                    local chest = chests[j]
                    count = count - exChest:pushItems(chest.name, i, count)
    
                    if count == 0 then
                        break
                    end
                end
            end

        end
    end
    computeNameCache()
    writeStorageCache()
end

local function getItem(name, quantity)
    exChest:list(true)

    local quantity = quantity or 64
    local requiredQuantity = quantity
    for j=1, #chests do
        local chest = chests[j]

        local cachedSlot = chest:hasItem(name)

        if cachedSlot then
            for slot in pairs(cachedSlot) do
                quantity = quantity - chest:mergeItems(exChest.name, slot, quantity)

                if quantity == 0 then
                    writeStorageCache()
                    return requiredQuantity
                end

                quantity = quantity - chest:pushItems(exChest.name, slot, quantity)
            end
        end
    end
    writeStorageCache()
    return requiredQuantity - quantity
end

local usage = {
    {
        command = "getItem",
        usage = "getItem <item name> <quantity>",
        description = "Retrieve an item from the storage",
        completer = function(...)
            local args = {...}
            return completion.choice(args[1] or "", nameCache)
        end,
        func = function(...)
            local args = { ... }
            if #args < 2 then
                printError("Expected 2 arguments")
                printError("Usage: getItem <item name> <quantity>")
                return
            end
            local quantity = tonumber(args[2])
            if not quantity then
                printError("Expected argument #2 to be a number")
                return
            end
            quantity = math.floor(quantity)
            if quantity < 0 then
                printError("Expected argument #2 to be a positive number")
                return
            end
            local count = getItem(nameRef[args[1]] or args[1], quantity)
            term.setTextColor(colors.green)
            print('Retrieved ['..count..'] '..(nameRef[args[1]] or args[1]))
            term.setTextColor(colors.white)
        end
    },
    {
        command = "countItem",
        usage = "countItem <item name>",
        description = "Count how many instance of the same item is stored",
        completer = function(...)
            local args = {...}
            return completion.choice(args[1] or "", nameCache)
        end,
        func = function(...)
            local args = { ... }
            if #args < 1 then
                printError("Expected 1 arguments")
                printError("Usage: countItem <item name>")
                return
            end

            local count = countItem(nameRef[args[1]] or args[1])
            term.setTextColor(colors.green)
            print('Found ['..count..'] '..(nameRef[args[1]] or args[1]))
            term.setTextColor(colors.white)
        end
    },
    {
        command = "storeItems",
        usage = "storeItems",
        description = "Store all the items from the chest inside the storage system",
        func = function()
            storeItems()
            term.setTextColor(colors.green)
            print('Items stored')
            term.setTextColor(colors.white)
        end
    },
    {
        command = "list",
        usage = "list",
        description = "List all the items in the storage",
        func = function()
            local lines = {}
            table.sort(scope.itemsName)
            for i=1, #scope.itemsName do
                local name = scope.itemsName[i]
                local count = countItem(name)
                if count > 0 then
                    table.insert(lines, name.." ["..countItem(name).."]")
                end
            end
            local file = fs.open('.list', 'w')
            file.write(table.concat(lines, '\n'))
            file.close()
            shell.run("edit .list")
            fs.delete(".list")
        end
    },
    {
        command = "reindex",
        usage = "reindex",
        description = "Force the reindexing of the storage",
        func = function()
            local coroutines = {}
            term.setTextColor(colors.cyan)
            for i=1, #chests do
                table.insert(coroutines, function()
                    chests[i]:list(true)
                end)
                print('Reindexing chest #'..i.." / "..#chests)

                if #coroutines == 128 then
                    parallel.waitForAll(table.unpack(coroutines))
                    coroutines = {}
                end
            end
            parallel.waitForAll(table.unpack(coroutines))
            computeNameCache()
            term.setTextColor(colors.white)
            writeStorageCache()
        end
    },
    {
        command = "storageInfo",
        usage = "storageInfo",
        description = "Print informations about the storage",
        func = function()
            local totalSlots = 0
            local usedSlots = 0
            local totalItems = 0
            local seenItems = {}
            local itemsTypeCount = 0
            for i=1, #chests do
                local chest = chests[i]
                totalSlots = totalSlots + chest:size()
                local items = chest:list()
                for j=1, chest:size() do
                    if items[j] then
                        totalItems = totalItems  + items[j].count
                        usedSlots = usedSlots + 1
                        if not seenItems[items[j].name] then
                            itemsTypeCount = itemsTypeCount + 1
                            seenItems[items[j].name] = true
                        end
                    end
                end
            end
            term.setTextColor(colors.green)
            print('Storage Informations:')
            print(string.format("- Slots Used: %d / %d (%.3f%%)", usedSlots, totalSlots,  usedSlots / totalSlots))
            print(string.format("- Items Capacity: %d / %d (%.3f%%)", totalItems, totalSlots * 64,  totalItems / (totalSlots * 64)))
            print(string.format("- Total Item Type: %d", itemsTypeCount))
            term.setTextColor(colors.white)
        end
    }
}

local commandList = {}
local commands = {}
for i=1, #usage do
    commandList[i] = usage[i].command
end

local function completer(str)
    local args = {}
    local currentArg = 0
    for match in str:gmatch("[^ ]+") do
        table.insert(args, match)
    end
    for match in str:gmatch(" +") do
        currentArg = currentArg + 1
    end

    if currentArg == 0 then
        return completion.choice(args[1] or "", { "help", table.unpack(commandList) })
    elseif currentArg == 1 then
        for i=1, #usage do
            if args[1] == usage[i].command then
                if not usage[i].completer then
                    return {}
                end
                return usage[i].completer(select(2, table.unpack(args)))
            end
        end
        
        if args[1] == "help" then
            return completion.choice(args[2] or "", commandList)
        end
    end
    return {}
end

local function printHelp(command)
    local commandInfo
    for i=1, #usage do
        if usage[i].command == command then
            commandInfo = usage[i]
            break
        end
    end
    if commandInfo then
        term.setTextColor(colors.yellow)
        term.write(command..": ")
        term.setTextColor(colors.cyan)
        print(commandInfo.description)
        term.setTextColor(colors.red)
        term.write("Usage: ")
        print(commandInfo.usage)
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.red)
        print('No such command "'..command..'"')
        term.setTextColor(colors.white)
    end
end


term.clear()
term.setCursorPos(1,1)
local history = {}
while true do
    term.setTextColor(colors.yellow)
    term.write("> ")
    term.setTextColor(colors.white)
    local input = read(nil, history, completer)
    table.insert(history, input)

    local args = {}
    for match in input:gmatch("[^ ]+") do
        table.insert(args, match)
    end

    if #args == 0 or args[1] == "help" then
        if #args > 1 then
            printHelp(args[2])
        else
            term.setTextColor(colors.yellow)
            print('Commands:')
            term.setTextColor(colors.cyan)
            for i=1, #usage do
                print('- '..usage[i].command)
            end
            term.setTextColor(colors.white)
        end
    else
        for i=1, #usage do
            if args[1] == usage[i].command then
                local success, err = pcall(usage[i].func, select(2, table.unpack(args)))
                if not success then
                    printError(err)
                end
                break
            end
        end
    end
end
