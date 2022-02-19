
local market={}
local gpu=require('component').gpu
market.itemlist = {}
market.inventory = {}
market.number= ''
market.admins= {{uuid="d2f4fce0-0f27-3a74-8f03-5d579a99988f",name="Vova77"}}
market.shopLine=1
market.shopItemsOnScreen={}
market.player={status='player',name='name',uid='uid',balance='0',ban='-'}

local pim=require('component').pim
local chest=require('component').titanium
local fs=require('filesystem')
--получаем список админов из рабочей дирректории 
if fs.exists('home/admins.market') then
	market.admins=require('admins.market')
end

--pim getStackInSlot:table witch fields k+v: display_name,dmg,id,max_dmg,max_size,mod_id,name,ore_dict,qty,raw_name//whre qty is amount
--fields form item: display_name, id, raw_name. also need add price for bye, price for cell. 
--===============================================
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
			id=item.raw_name
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
		db:close()
	end
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

--добавление предметов и цен в итемлист
function builder()
	itemlist=market.load_fromFile()
	inventory=market.get_playeritemlist()
	itemlist=market.price_build(inventory,itemlist)
	market.save_toFile(itemlist)
	event.pull('player_off')
end

--====================================================
--2022.02.13-14

--содержит перечень активных кнопок экрана
market.screen={}--здесь держать все кнопки экрана
market.activity={}--хдесь держать функциональные кнопки
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
	back={x=2,xs=6,y=14,ys=3,text='<-',tx=2,ty=1,bg=999999,fg=0x68f029},
	enternumber={x=14,xs=6,y=14,ys=3,text='OK',tx=2,ty=1,bg=999999,fg=0x68f029},
	
	welcome={x=10,xs=24,y=12,ys=3,text='Welcome to PimMarket',tx=2,ty=1,func='pimm',bg=999999,fg=0x68f029},
	entrance={x=2,xs=56,y=2,ys=17,text='Go on PIM',tx=22,ty=9,bg=999999,fg=0x68f029},
	name={x=10,xs=24,y=8,ys=3,text='name',tx=2,ty=1,func='pimm',bg=999999,fg=0x68f029},
	number={x=14,xs=24  ,y=18,ys=3,text='',tx=2,ty=1,bg=999999,fg=0x68f029},
	shopUp={x=6,xs=10,y=3,ys=5,text='UP',tx=6,ty=3,bg=0x4cb01e,fg=0xf2b233},
	shopDown={x=6,xs=10,y=10,ys=5,text='DOWN',tx=5,ty=3,bg=0xc49029,fg=0x68f029},
	shopTopRight={x=32,xs=29,y=1,ys=1,text='Available items       price',tx=3,ty=0,bg=0xc49029,fg=0x0bae31},
	shopFillRight={x=32,xs=29,y=1,ys=1,text='',tx=0,ty=0,bg=0xc49029,fg=0x4cb01e},
	shopVert={x=55,xs=2,y=1,ys=20,text='',tx=0,ty=0,bg=0xc49029,fg=0x303030}
}

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
--это обработчик экрана.
--содержит все функции вызываемые кнопками
--в том числе меняющие содержимое экрана
market.screenActions={}
market.screenActions.one=function()market.number=market.number..'1' event.push('input_number','+') end
market.screenActions.two=function()market.number=market.number..'2' event.push('input_number','+') end
market.screenActions.free=function()market.number=market.number..'3' event.push('input_number','+') end
market.screenActions.foo=function()market.number=market.number..'4' event.push('input_number','+') end
market.screenActions.five=function()market.number=market.number..'5' event.push('input_number','+') end
market.screenActions.six=function()market.number=market.number..'6' event.push('input_number','+') end
market.screenActions.seven=function()market.number=market.number..'7' event.push('input_number','+') end
market.screenActions.eight=function()market.number=market.number..'8' event.push('input_number','+') end
market.screenActions.nine=function()market.number=market.number..'9' event.push('input_number','+') end
market.screenActions.zero=function()market.number=market.number..'0' event.push('input_number','+') end
market.screenActions.back=function()if #market.number > 0 then
	market.number=string.sub(market.number,1,#market.number-1) event.push('input_number','-') end end
market.screenActions.enternumber=function() event.push('input_number','ok') end
market.screenActions.shopUp=function()if market.shopLine > 1 then
	market.shopLine=market.shopLine-1 end event.push('list_moving','ok')end
market.screenActions.shopDown=function()if itemlist.size-20 > market.shoppLine then
	market.shopLine=market.shopLine+1 end event.push('list_moving','ok')end
--================================================================

--замена кнопок экрана: вызов очистки и прорисовки
function market.replace(buttons)
	market.screen=buttons
	market.clear(303030)
	market.place(buttons)
end

--Очистка экранаю ничего особенного. Обычный велосипед
market.clear=function(background)
	--gpu.setActiveBuffer(0)	
	if not background then background=0 end
	x,y=gpu.getViewport()
	gpu.setBackground(background)
	gpu.fill(1,1,x,y,' ')
	--gpu.setActiveBuffer(1)
end

--размещает текущие одноцветные кнопки на экране
market.place=function(btns)
	--gpu.setActiveBuffer(0)
	b = 0
	for n in pairs(btns)do
		b=market.button[btns[n]]
		bg,fg=gpu.getBackground(),gpu.getForeground()
		gpu.setBackground(tonumber(b.bg))
		gpu.fill(tonumber(b.x),tonumber(b.y),tonumber(b.xs),tonumber(b.ys),' ')
		gpu.setForeground(tonumber(b.fg))
		gpu.set(tonumber(b.x)+tonumber(b.tx),tonumber(b.y)+tonumber(b.ty),b.text)
		gpu.setBackground(bg)
		gpu.setForeground(fg)
	end
	b=nil
	--gpu.setActiveBuffer(1)
end
--==================================================================
--pim & chest - components contains inventory
--inventoryList - itemlist of csanning inventory
--item_id, count - name of item and count for migrate
--op - type of operation in string format. itemPull or itemPush
--передаёт пердметы из целевого в назначенный инвентарь
--параметр передачи задаётся агр. 'op'=itemPull or itemPush
function market.fromInvToInv(pim,itemlist_itemid,count, op)
	c=count
	for slot in pairs(itemlist_itemid.slots) do
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

--эта функция обрабатывает касания экрана
--сверяясь с расположением кнопок в листе market.screen
--вызывает одноименный кнопке метод в том случае,
--если имя в эвенте совпадает с именем инвентаря на пим
function market.screenDriver(_,_,x,y,_,player_name)
	if player.name == pim.getInventoryName() then
		for f in pairs(market.screen) do
			a=x > f.x and x < (f.xs+f.x)
			b=y > f.y and y < (f.ys+f.y)
				if a and b then
				market.screenActions[f]()
				end
			end
		end
	end

--displayet items availabled for trading
--where pos - position in itemlist for showing
--and itemlist - numerated itemlist
--создание экрана со списком пердметов
function market.showMeYourCandiesBaby(itemlist,pos)
	y=1
	index=#itemlist
	for f=pos, index do
		gpu.setBackground(0x202020)
		gpu.set(32,y,itemlist[f].display_name)
		gpu.setBackground(0x273ba1)
		gpu.set(55,y,' ')
		gpu.setBackground(0x202020)
		gpu.set(56,y,itemlist[f].price)
		y=y+1
		if f > 19 then f=#itemlist end
	end
end

--отрисовывает поля меню выбора товара
function market.showMe()
	buttons={'shopUp','shopDown','shopVert','shopTopRight','shopFillRight'}
	market.replace(buttons)
	market.screen.shopVert=nil
	market.screen.shopTopRight=nil
end

function market.seeMyOwns()
	line=market.shopLine
	--market.shopItemsOnScreen={}
	myItems={}
	y=1
	--items={}
	gpu.setActiveBuffer(0)
	gpu.setBackground(0xc49029)
	gpu.setForeground(0x4cb01e)
	--тут добавлю немного говна. потом возможно переделаю
	for item in pairs(itemlist) do
		if y<20 and line == 0 then
			gpu.set(33, line, item) 
			table.insert(myItems,item) y=y+1 
		else 
			if line > 0 then 
				line = line-1 
			end
		end
	end
	gpu.setActiveBuffer(1)
	market.shopItemsOnScreen=myItems
	myItems=nil
end

--==================================================
--ну привет, дружок-пирожок. посмотрим, что ты взял с собой
market.screenActions.welcome=function()
	print('touch event write this message for the test')
	market.inventory=market.get_playeritemlist()
	market.showMe()
end

--очистка и создание экрана ожидания
function market.pimByeBye()
	market.player={}
	market.clear(2345)
	screenInit()
	event.ignore('touch',screenDriver)
	event.ignore('player_off',pimByeBye)
end

--создание приветственного экрана
function market.hello(name)
	market.button.name.text=name
	market.button.name.xs=#name+4
	market.button.name.x=19-#name/2
	btns={'name','welcome'}
	market.clear(2345)
	market.place(btns)
end
--===============================================
--сюда попадает получая эвент player_on
function market.pimWhoIsIt(_,who,uid,id)
if not who then who='' uid='' end
	market.player.status = 'player'
for f=1, #market.admins do
		if market.admins[f].uuid==uid and market.admins[f].name==who then 
			market.player.status = 'admin'
		end
	end
	--здороваемся
	market.hello(who)
	--включаем наблюдение касаний экрана
	event.listen('touch',market.screenDriver)
	event.listen('player_off',market.pimByeBye)
	--после касания игроком стартовых отображённых кнопок он
	--попадает в функцию велком
end

function market.screenInit()
	market.screen={'entrance'}
	market.clear(0x202020)
	market.place(market.screen)
end
--ставим резолюцию, кнопки, начинаем слушать не топчет ли кто пим
function market.init()
	market.itemlist=market.load_fromFile({})
	--table.sort(table)
	gpu.setResolution(60,20)
	market.screenInit()
	gpu.allocateBuffer(1,1)
	gpu.setActiveBuffer(1)
	event.listen('player_on',market.pimWhoIsIt)
end

return market

