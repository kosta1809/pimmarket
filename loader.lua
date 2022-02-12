local inet=require('internet')
local fs=require('filesystem')
local event=require('event')
local component=require('component')

for address in component.list("filesy") do 
        if component.proxy(address).spaceTotal() > 66000 then
            fs = component.proxy(address)
            --return true
        end
end

    if not fs then
        customError("Filesystem not found!")
    end


--if not fs.exists("market.lua") then
	local handle=inet.request('https://raw.githubusercontent.com/Zardar/pimmarket/master/pimscaninventory.lua')
	local result=''
	for chunk in handle do result=result..chunk end
	print('creating file')
	print(io)
	local file=io.open('market.lua','w')
	file:write(result)
	file:close()
--end

local market=require'market'
local itemlist=market.load_fromFile()
local inventory={}

local function builder(player,uuid,id)
	itemlist=market.load_fromFile(itemlist)
	inventory=market.get_playeritemlist(inventory)
	market.price_build(inventory,itemlist)
	market.save_toFile(itemlist)
	event.pull('player_off')
end

event.listen('player_on',builder)