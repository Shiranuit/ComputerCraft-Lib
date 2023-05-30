local defaultScope = {}

local function insertItemSlotCache(self, itemName, slot)
    local cache = self._itemCache[itemName]

    if not cache then
        self._itemCache[itemName] = { [slot] = true }
    else
        cache[slot] = true
    end

    if not self._scope._dedupItemsName[itemName] then
        self._scope._dedupItemsName[itemName] = true
        table.insert(self._scope.itemsName, itemName)
    end
end

local function removeItemSlotCache(self, itemName, slot)
    local cache = self._itemCache[itemName]

    if cache then
        cache[slot] = nil
        if table.maxn(cache) == 0 then
            self._itemCache[itemName] = nil
        end
    end
end

local function list(self, reindex)
    if not self._items or reindex then
        self:loadInventory(self._inv.list())
    end
    return self._items
end

local function loadInventory(self, items, size)
    self._items = items
    self._itemCache = {}
    self._size = size or self:size()
    for i=1, self._size do
        local item = self._items[i]
        if item then
            insertItemSlotCache(self, item.name, i)
        end
    end
end

local function getItem(self, slot)
    local list = self:list()
    
    return list[slot]
end

local function getItemLimit(self, slot)
    local list = self:list()
    if not list[slot] then
        return 0
    end
    local item = list[slot].name
    if self._scope.itemsLimit[item] then
        return self._scope.itemsLimit[item]
    end
    local details = self._inv.getItemDetail(slot)
    self._scope.itemsLimit[item] = details.maxCount
    return self._scope.itemsLimit[item]
end

local function hasItem(self, itemName)
    return self._itemCache[itemName]
end

local function pushItems(self, side, slot, count, destSlot)
    local destInventory = self._scope.inventories[side]

    local list = self:list()
    local item = list[slot]
    if not list[slot] then
        return 0
    end

    local destSlot = destSlot or (destInventory and destInventory:findEmptySlot())

    if destSlot < 1 or destSlot > self:size() then
        return 0
    end

    local count = self._inv.pushItems(side, slot, count, destSlot)
    
    list[slot].count = list[slot].count - count
    if list[slot].count <= 0 then
        list[slot] = nil
        removeItemSlotCache(self, item.name, slot)
    end
    
    if count > 0 and destInventory then
        local destItemSlot = destInventory._items[destSlot]
        if destItemSlot then
            destItemSlot.count = destItemSlot.count + count
        else
            destInventory._items[destSlot] = {
                name = item.name,
                count = count,
            }
        end
        insertItemSlotCache(destInventory, item.name, destSlot)
    end
    return count
end

local function findEmptySlot(self)
    local slot = #self._items+1
    if slot > self:size() then
        return -1
    end
    return slot
end

local function countItem(self, name)
    local cache = self._itemCache[name]

    if not cache then
        return 0
    end

    local items = self:list()
    local count = 0
    for slot in pairs(cache) do
        count = count + items[slot].count
    end
    return count
end

local function mergeItems(self, side, slot, count)
    local destInventory = self._scope.inventories[side]

    if not destInventory then
        return self:pushItems(side, slot, count)
    end

    local item = self:getItem(slot)

    if not item then
        return 0
    end

    local originalCount = count
    local cachedSlots = destInventory:hasItem(item.name)
    local maxStackSize = self:getItemLimit(slot)

    if cachedSlots then
        for destSlot in pairs(cachedSlots) do
            local destItem = destInventory:getItem(destSlot)
            if destItem and destItem.count < maxStackSize then
                count = count - self:pushItems(side, slot, originalCount, destSlot)
            end
            if count == 0 then
                break
            end
        end
    end

    return originalCount - count
end

local function size(self)
    if not self._size then
        self._size = self._inv:size()
    end
    return self._size
end

local function wrapPeripheral(name, periph, scope)
    local scope = scope or defaultScope

    scope.inventories = scope.inventories or {}
    scope.itemsLimit = scope.itemsLimit or {}
    scope.itemsName = scope.itemsName or {}
    scope._dedupItemsName = scope._dedupItemsName or {}

    if not scope.inventories[name] then
        scope.inventories[name] = {
            name = name,
            _inv = periph,
            _itemCache = {},
            _scope = scope,
            list = list,
            size = size,
            getItem = getItem,
            getItemLimit = getItemLimit,
            hasItem = hasItem,
            findEmptySlot = findEmptySlot,
            pushItems = pushItems,
            countItem = countItem,
            mergeItems = mergeItems,
            loadInventory = loadInventory,
        }
    end
    return scope.inventories[name]
end

local function new(name, scope)
    if not peripheral.hasType(name, "inventory") then
        error("Peripheral \""..name.."\" must be of type 'inventory'", 1)
    end
    return wrapPeripheral(name, peripheral.wrap(name), scope)
end

local function getNames()
    local names = {}
    peripheral.find("inventory", function(name, periph)
        table.insert(names, name)
    end)
    return names
end

local function find(filter, scope)
    if filter and type(filter) ~= "function" then
        error('Filter must be a function', 1)
    end
    local periphs = {}
    peripheral.find("inventory", function(name, periph)
        if not filter or filter(name, periph) then
            table.insert(periphs, wrapPeripheral(name, periph, scope))
        end
    end)
    return periphs
end

return {
    new = new,
    getNames = getNames,
    find = find,
}