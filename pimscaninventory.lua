local market={}
market.itemlist={}
market.inventory={}
	

--pim event player_on name address address
--pim event player_off name address address
--pim getStackInSlot:table witch fields k+v: display_name,dmg,id,max_dmg,max_size,mod_id,name,ore_dict,qty,raw_name//whre qty is amount
--fields form item: display_name, id, raw_name. also need add price for bye, price for cell. may be in 2 custom listuire('component').pim


--event trigger player_on {name, uuid?, id?}
--scan player inventory
--build itemlist
function market.get_playeritemlist(inventory)--return table of current items in inventory
	pim=require('component').pim
	if not inventory then inventory={} end
	local index,id,item=1,'',''
	for f=1,36
	 do item=pim.getStackInSlot(f) 

		if item and not inventory[item.id] then
			local id=item.id
			inventory[id]={}
			inventory[id].display_name=item.display_name
			inventory[id].sell_price=item.sell_price
			inventory[id].bye_price=item.bye_price
			inventory[id].raw_name=item.raw_name
			inventory[id].qty=item.qty
			inventory[id].slots={f}
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
			while not tonumber(price) do price=io.read() end
			itemlist[id].sell_price=price price=''

			print('Введите цену покупки для '..itemlist[id].display_name..': ')
			while not tonumber(price) do price=io.read() end
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
--====================================================
--2022.02.13-14
--эта функция делает(будет делать)
--разные штуки по касанию экрана
--может быть вызывать какие-то методы
function market.touch_handler(touch,address,x,y,z,player_name)
	for f in pairs(market.screen) do
		if x > f.x and x < (f.xs+f.x) then
			if y > f.y and y < (f.ys+f.y) then
				if player_name == pim.getInventoryName() then
				market.screenActions[f.func](player_name)end
			end
		end
	end
end



--содержит используемые кнопки. Кнопки содержат поля:
--координаты x y, размер по x y, текст, внутренняя позиция текста, имя функции, цвета
market.button={
	bye={x=10,xs=22,y=4,ys=3,text='Купить',tx=2,ty=1,func='bye',bg=999999,fg=0x68f029},
	sell={x=10,xs=22,y=8,ys=3,text='Продать',tx=2,ty=1,func='sell',bg=999999,fg=0x68f029},
	one={x=2,xs=6,y=2,ys=3,text='1',tx=2,ty=1,func='1',bg=999999,fg=0x68f029},
	two={x=8,xs=6,y=2,ys=3,text='2',tx=2,ty=1,func='2',bg=999999,fg=0x68f029},
	free={x=14,xs=6,y=2,ys=3,text='3',tx=2,ty=1,func='3',bg=999999,fg=0x68f029},
	foo={x=2,xs=6,y=6,ys=3,text='4',tx=2,ty=1,func='4',bg=999999,fg=0x68f029},
	five={x=8,xs=6,y=6,ys=3,text='5',tx=2,ty=1,func='5',bg=999999,fg=0x68f029},
	six={x=14,xs=6,y=6,ys=3,text='6',tx=2,ty=1,func='6',bg=999999,fg=0x68f029},
	seven={x=2,xs=6,y=10,ys=3,text='7',tx=2,ty=1,func='7',bg=999999,fg=0x68f029},
	eight={x=8,xs=6,y=10,ys=3,text='8',tx=2,ty=1,func='8',bg=999999,fg=0x68f029},
	nine={x=14,xs=6,y=10,ys=3,text='9',tx=2,ty=1,func='9',bg=999999,fg=0x68f029},
	zero={x=8,xs=6,y=14,ys=3,text='0',tx=2,ty=1,func='0',bg=999999,fg=0x68f029},
	pimm={x=10,xs=24,y=12,ys=3,text='Welcome to PimMarket',tx=2,ty=1,func='pimm',bg=999999,fg=0x68f029},
	player={x=10,xs=24,y=8,ys=3,text='player',tx=2,ty=1,func='pimm',bg=999999,fg=0x68f029}
}

--это обработчик экрана.
--содержит все функции вызываемые кнопками
--в том числе меняющие содержимое экрана
market.screenActions={}
market.screenActions.pimm=function()
end


--замена кнопок экрана: вызов очистки и прорисовки
function market.replace(button_list)
	market.screen=button_list
	market.clear(0)
	market.place()
end

--заготовка под фингерпринт ае2
market.items={['minecraft:stone|0']={label='kamen'}}

--здесь располагаются кнопки текщего экрана и их параметры:
market.screen={
	pimm={x=5,xs=30,y=14,ys=3,text='Welcome to PimMarket',tx=4,ty=1,func='pimm',bg=999999,fg=0x68f029}
}



--Очистка экранаю ничего особенного. Обычный велосипед
market.clear=function(background)
		local gpu=require('component').gpu
		if not background then background=0 end
		local x,y=gpu.getViewport()
		gpu.setBackground(background)
		gpu.fill(1,1,x,y,' ')
	end


--размещает текущие одноцветные кнопки на экране
market.place=function()
	local gpu=require('component').gpu
	for k,b in pairs(market.screen)do
		local bg,fg=gpu.getBackground(),gpu.getForeground()
		gpu.setBackground(b.bg)
		gpu.fill(b.x,b.y,b.xs,b.ys,' ')
		gpu.setForeground(b.fg)
		gpu.set(tonumber(b.x)+tonumber(b.tx),tonumber(b.y)+tonumber(b.ty),b.text)
		gpu.setBackground(bg)
		gpu.setForeground(fg)
	end
end

--позаимствованная у BrightYC таблица цветов.добавлен мутно-зелёный
market.color = {
    pattern = "%[0x(%x%x%x%x%x%x)]",
    background = 0x000000,
    pim = 0x46c8e3,

    gray = 0x303030,
    lightGray = 0x999999,
    blackGray = 0x1a1a1a,
    lime = 0x68f029,
    greengray = 0x0bde31,
    blackLime = 0x4cb01e,
    orange = 0xf2b233,
    blackOrange = 0xc49029,
    blue = 0x4260f5,
    blackBlue = 0x273ba1,
    red = 0xff0000
}

--собственно отсюда начинаются действия покупателя в магазине
market.pimm=function()
	market.clear(2345)

end



market.hello=function(player_name,uuid,id)
	market.button.player.text=player_name
	market.button.player.xs=#player_name+2
	market.button.player.x=19-#player_name/2
	local btns={}
	btns.a=market.button.pimm
	btns.b=market.button.player
	market.replace(btns)
end

return market

