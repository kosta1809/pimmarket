local market={}
--pim event player_on name address address
--pim event player_off name address address
--pim getStackInSlot:table witch fields k+v: display_name,dmg,id,max_dmg,max_size,mod_id,name,ore_dict,qty,raw_name//whre qty is amount
--fields form item: display_name, id, raw_name. also need add price for bye, price for cell. may be in 2 custom listuire('component').pim


--event trigger player_on {name, uuid?, id?}
--scan player inventory
--build itemlist
function market.get_playeritemlist(inventory)--return table of current items in inventory
	if not inventory then inventory={} end
	index,id,item=1,'',''
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
 	price=''
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
			itemlist.size=itemlist.size+1
		end
	end
	price=nil
end


--load itemlist from file by id
function market.load_fromFile(itemlist)
    if 'table'~=type(itemlist) then itemlist={} end
	db=io.open('db.market','r')
	if db then
		size=db:read('*line')
		itemlist.size=size
		for f=1, size do 
			id=db:read('*line')
			itemlist[id]={}
			itemlist[id].display_name=db:read('*line')
			itemlist[id].sell_price=db:read('*line')
			itemlist[id].bye_price=db:read('*line')
			itemlist[id].raw_name=db:read('*line')
		end
	else itemlist.size=0 end
	return itemlist
end

--save itemlist to file
function market.save_toFile(itemlist)
	db=io.open('db.market','w')
	db:write(itemlist.size..'\n')
	size=itemlist.size
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

--2022.02.13-14
--эта функция делает(будет делать)
--разные штуки по касанию экрана
--может быть вызывать какие-то методы
function market.touch_handler(touch,address,x,y,z,player_name)
for f in pairs(buttons) do
	if x > f.x and x < (f.xs+f.x) then
		if y > f.y and y < (f.ys+f.y) then
			--здесь надо добавить проверку на соответствие
			--имени игрока на пим имени присланном эвентом
			if player_name == pim.getInventoryName() then
			market.screenActions[f.func](player_name)
		end
end

--содержит используемые кнопки. Кнопки содержат поля:
--координаты x y, размер по x y, текст, внутренняя позиция текста, имя функции, цвета
market.buttons={
	bye={x=10,xs=10,y=4,ys=3,text='Купить',tx=4,ty=1,func='bye',bg=777777,fg=111111}
	sell={x=15,xs=10,y=8,ys=3,text='Продать',tx=4,ty=1,func='sell',bg=999999,fg=222222}

}

--здесь располагаются кнопки текщего экрана и их параметры:
market.screen={}

--это обработчик экрана.
--содержит все функции вызываемые кнопками
--в том числе меняющие содержимое экрана
market.screenActions={}
market.screenActions.clear=function(background)
		x,y=gpu.getViewport()
		gpu.setBackground(background)
		gpu.fill(1,1,x,y,' ')
	end
}

--размещает текущие одноцветные кнопки на экране
market.screenActions.place=function()
	for b in pairs(screen)do
		bg,fg=gpu.getBackground(),gpu.getForeground()
		gpu.setBackground(b.bg)
		gpu.fill(b.x,b.y,b.x+b.xs,b.y+b.ys,' ')
		gpu.setForeground(b.fg)
		gpu.set(b.x+b.tx,b.y+b.ty,b.text)
		gpu.setBackground(bg)
		gpu.setForeground(fg)
	end
end


market.color = {
    pattern = "%[0x(%x%x%x%x%x%x)]",
    background = 0x000000,
    pim = 0x46c8e3,

    gray = 0x303030,
    lightGray = 0x999999,
    blackGray = 0x1a1a1a,
    lime = 0x68f029,
    blackLime = 0x4cb01e,
    orange = 0xf2b233,
    blackOrange = 0xc49029,
    blue = 0x4260f5,
    blackBlue = 0x273ba1,
    red = 0xff0000
}


return market


