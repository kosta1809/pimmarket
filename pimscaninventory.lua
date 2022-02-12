local market={}
--pim event player_on name address address
--pim event player_off name address address
--pim getStackInSlot:table witch fields k+v: display_name,dmg,id,max_dmg,max_size,mod_id,name,ore_dict,qty,raw_name//whre qty is amount
--fields form item: display_name, id, raw_name. also need add price for bye, price for cell. may be in 2 custom listuire('component').pim


--event trigger player_on {name, uuid?, id?}
--scan player inventory
--build itemlist
function market.get_playeritemlist(inventory)--return table of current items in inventory
	if not inventory then local inventory={} end
	local index,id,item=1,'',''
	for f=1,40 do item=pim.getStackInSlot(f) 
		if item and not inventory[item.id] then
			id=item.id
			inventory[id]={}
			inventory[id].display_name=item.display_name
			inventory[id].sell_price=item.sell_price
			inventory[id].bye_price=item.bye_price
			inventory[id].raw_name=item.raw_name
			inventory[id].qty=item.qty
			inventory[id].inventory_slot_number={f}
		else if item then
			id=item.id
			inventory[id].qty=inventory[id].qty+item.qty
			inventory[id].slots[#inventory[id].slots+1]=f
			end
		end
	end
	return inventory
end

--запрос цен от игрока на предоставленные предметы 
function market.price_build(inventory,itemlist)
 	local price=''
 	for id in pairs(inventory) do
 		if not itemlist[id] then
 			itemlist[id]={}
 			itemlist[id].display_name=inventory[id].display_name
			itemlist[id].raw_name=inventory[id].raw_name

			print('Введите цену продажи для '..itemlist[id].display_name..': ')
			while 'number' ~=type(price) do price=io.read() end
			itemlist[id].sell_price=price price=''

			print('Введите цену покупки для '..itemlist[id].display_name..': ')
			while 'number' ~=type(price) do price=io.read() end
			itemlist[id].bye_price=price price='' 
		end
	end
	price=nil
end


--load itemlist from file by id
function market.load_fromFile(itemlist)
    if 'table'~=type(itemlist) then itemlist={} end
	local db=io.open('db','r')
	if db then
		local size=db:read('*line')
		itemlist.size=size
		for f=1, size do 
			id=db:read('*line')
			itemlist[id]={}
			itemlist[id].display_name=db:read('*line')
			itemlist[id].sell_price=db:read('*line')
			itemlist[id].bye_price=db:read('*line')
			itemlist[id].raw_name=db:read('*line')
		end
	end
	return itemlist
end

--save itemlist to file
function market.save_toFile(itemlist)
	db=io.open('db','w')
	db:write(itemlist.size..'\n')
	local size=itemlist.size
	itemlist.size=nil
	for id in pairs(itemlist)do
		db:write(id..'\n')
		db:write(itemlist[id].display_name..'\n')
		db:write(itemlist[id].sell_price..'\n')
		db:write(itemlist[id].bye_price..'\n')
		db:write(itemlist[id].raw_name..'\n')
	end
	itemlist.size=size
	return true
end

return market



