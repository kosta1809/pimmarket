local market={}
market.itemlist={}
market.inventory={}
market.number=''
pim=require('component').pim
chest=require('component').titanium

--pim getStackInSlot:table witch fields k+v: display_name,dmg,id,max_dmg,max_size,mod_id,name,ore_dict,qty,raw_name//whre qty is amount
--fields form item: display_name, id, raw_name. also need add price for bye, price for cell. 

--scan inventory. return items table.
--из самостоятельной одноцелевой в многоцелевую
--на вход подать используемый компонент. обычно пим или сундук. или любой другой инвентарь для работы
function market.get_playeritemlist(device)
	size=device.totalSlots --число слотов в инвентаре
	inventory={}
	index,id,item=1,'',''
	for f=1,size
	 do item=device.getStackInSlot(f) 
	 	--заполняет таблицу инвентаря,
	 	--добавляя поле slots для повторяющихся
	 	--в инвентаре предметов. суммирует qty для них
	 	--в поле id пишется raw_name
		if item and not inventory[item.raw_name] then
			local id=item.raw_name
			inventory[id]={}
			inventory[id].display_name=item.display_name
			inventory[id].sell_price=item.sell_price
			inventory[id].bye_price=item.bye_price
			inventory[id].name=item.name
			inventory[id].qty=item.qty
			inventory[id].slots={f}
		else if item then
			id=item.id
			inventory[id].qty=inventory[id].qty+item.qty
			inventory[id].slots[#inventory[id].slots+1]=f
			end
		end
	end
	pim=nil
	return inventory
end

--запрос цен от админа на предоставленные предметы 
function market.price_build(inventory,itemlist)
 	price=''
 	for id in pairs(inventory) do
 		if not itemlist[id] then
 			itemlist[id]={}
 			itemlist[id].display_name=inventory[id].display_name
			itemlist[id].name=inventory[id].name

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
	return itemlist
end


--load itemlist from file by id
function market.load_fromFile(itemlist)
    if not itemlist then itemlist={} end
	db=io.open('db.market','r')
	if db then
		size=db:read('*line')
		if tonumber(size) then
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
	end
	db:close()
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
		db:write(itemlist[id].name..'\n')
	end
	itemlist.size=size
	db:close()
	return true
end
--====================================================
--2022.02.13-14
--эта функция делает(будет делать)
--разные штуки по касанию экрана
--может быть вызывать какие-то методы
function market.touch_handler(_,_,x,y,_,player_name)
	if player_name == pim.getInventoryName() then
		for f in pairs(market.screen) do
			a=x > f.x and x < (f.xs+f.x)
			b=y > f.y and y < (f.ys+f.y)
				if a and b then
				market.screenActions[f]()
				end
			end
		end
	end



--содержит используемые кнопки. Кнопки содержат поля:
--координаты x y, размер по x y, текст, внутренняя позиция текста, имя функции, цвета
market.button={
	bye={x=10,xs=18,y=4,ys=3,text='Купить',tx=2,ty=1,bg=999999,fg=0x68f029},
	sell={x=10,xs=19,y=8,ys=3,text='Продать',tx=2,ty=1,bg=999999,fg=0x68f029},
	one={x=2,xs=6,y=2,ys=3,text='1',tx=2,ty=1,bg=999999,fg=0x68f029},
	two={x=8,xs=6,y=2,ys=3,text='2',tx=2,ty=1,bg=999999,fg=0x68f029},
	free={x=14,xs=6,y=2,ys=3,text='3',tx=2,ty=1,bg=999999,fg=0x68f029},
	foo={x=2,xs=6,y=6,ys=3,text='4',tx=2,ty=1,bg=999999,fg=0x68f029},
	five={x=8,xs=6,y=6,ys=3,text='5',tx=2,ty=1,bg=999999,fg=0x68f029},
	six={x=14,xs=6,y=6,ys=3,text='6',tx=2,ty=1,bg=999999,fg=0x68f029},
	seven={x=2,xs=6,y=10,ys=3,text='7',tx=2,ty=1,bg=999999,fg=0x68f029},
	eight={x=8,xs=6,y=10,ys=3,text='8',tx=2,ty=1,bg=999999,fg=0x68f029},
	nine={x=14,xs=6,y=10,ys=3,text='9',tx=2,ty=1,bg=999999,fg=0x68f029},
	zero={x=8,xs=6,y=14,ys=3,text='0',tx=2,ty=1,bg=999999,fg=0x68f029},
	pimm={x=10,xs=24,y=12,ys=3,text='Welcome to PimMarket',tx=2,ty=1,func='pimm',bg=999999,fg=0x68f029},
	player={x=10,xs=24,y=8,ys=3,text='player',tx=2,ty=1,func='pimm',bg=999999,fg=0x68f029},
	number={x=14,xs=24  ,y=18,ys=3,text='',tx=2,ty=1,bg=999999,fg=0x68f029},
	shopUp={x=6,xs=10,y=3,ys=5,text='UP',tx=6,ty=3,bg=0x4cb01e,fg=0xf2b233},
	shopDown={x=6,xs=10,y=10,ys=5,text='DOWN',tx=5,ty=3,bg=0xc49029,fg=0x68f029},
	shopTopRight={x=32,xs=29,y=1,ys=1,text='Available items       price',tx=3,ty=0,bg=0xc49029,fg=0x0bae31}
	shopFillRight={x=32,xs=29,y=1,ys=1,text='',tx=0,ty=0,bg=0xc49029,fg=0x4cb01e}
	shopVert={x=55,xs=2,y=1,ys=20,text='',tx=0,ty=0,bg=0xc49029,fg=0x303030}
}

--это обработчик экрана.
--содержит все функции вызываемые кнопками
--в том числе меняющие содержимое экрана
market.screenActions={}
market.screenActions.one=function()market.number=market.number..'1' event.push('input_number') end
market.screenActions.two=function()market.number=market.number..'2' event.push('input_number') end
market.screenActions.free=function()market.number=market.number..'3' event.push('input_number') end
market.screenActions.foo=function()market.number=market.number..'4' event.push('input_number') end
market.screenActions.five=function()market.number=market.number..'5' event.push('input_number') end
market.screenActions.six=function()market.number=market.number..'6' event.push('input_number') end
market.screenActions.seven=function()market.number=market.number..'7' event.push('input_number') end
market.screenActions.eight=function()market.number=market.number..'8' event.push('input_number') end
market.screenActions.nine=function()market.number=market.number..'9' event.push('input_number') end
market.screenActions.zero=function()market.number=market.number..'0' event.push('input_number') end
market.screenActions.back=function()if #market.number > 0 then
	market.number=string.sub(market.number,1,#market.number-1) event.push('input_number') end end



market.inputNumber=function()

end


market.screenActions.pimm=function()
	print('touch event write this message')
	local inventory=market.get_playeritemlist()


end

--замена кнопок экрана: вызов очистки и прорисовки
function market.replace(button_list)
	market.screen=button_list
	market.clear(0)
	market.place()
end

--заготовка под фингерпринт ае2
--  market.items={['minecraft:stone|0']={label='kamen'}}

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
market.place=function(btns)
	local gpu=require('component').gpu
	for k,b in pairs(btns)do
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




--создание приветственного экрана
market.hello=function(player_name,uuid,id)
	market.button.player.text=player_name
	market.button.player.xs=#player_name+4
	market.button.player.x=19-#player_name/2
	local btns={}
	btns.a=market.button.pimm
	btns.b=market.button.player
	market.clear(2345)
	market.place(btns)
end


--pim & chest - components contains inventory
--inventoryList - itemlist of csanning inventory
--item_id, count - name of item and count for migrate
--op - type of operation in string format. itemPull or itemPush
--
function fromInvToInv(pim,item_list[item_id],count, op)
	c=count
	for slot in pairs(item_list[item_id].slots) do
		available=chest.getItemInSlot(slot).qty
		if c > 0 then
			if c >  available then
				c=c-available
				pim[op]('down',slot,available)
			else
				pim[op]('down',slot,c)
				c=0
			end
		end
	end
	c=nil
end

--displayet items availabled for trading
--where pos - position in itemlist for showing
--and itemlist - numerated itemlist
function showMeYourCandiesBaby(itemlist,pos)

	y=1
	for f=pos, #itemlist do
		gpu.setBackground(0x202020)
		gpu.set(32,y,itemlist[f].display_name)
		gpu.setBackground(0x273ba1)
		gpu.set(55,y,' ')
		gpu.setBackground(0x202020)
		gpu.set(56,y,itemlist[f].price)
		y=y+1
		if f > 20 then f=#itemlist end
	end
end




return market

