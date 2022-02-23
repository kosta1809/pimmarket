--=============================================================
--2022.02.11-14...02.22
--=============================================================
local market={}
local gpu=require('component').gpu
local component=require('component')
local computer=require('computer')
local pullSignal=computer.pullSignal
local pim=require('component').pim
local event=require('event')
local table=require('table')
local math=require('math')

--лист с полями sell_price, buy_price, qty, display_name,name
--и ключом raw_name
market.money = ''
market.itemlist = {}--содержит все оценённые предметы магазина
market.chestList = {}--содержит предметы в сундуке связанном с терминалом
market.inumList={} --содержит нумерованный список с айди предметов магазина
market.inventory = {}--содержит список предметов текущего посетителя
market.select='' --raw_name выбранного предмета
market.mode='trade'
market.chest=''--используемый сундук. содержит ссылку на компонет сундук
market.number= ''--используется при выборе количества и установки цен
market.owner={
	{uuid="d2f4fce0-0f27-3a74-8f03-5d579a99988f",name="Vova77"},
	{uuid="0b448076-a810-3a82-8bb8-2913bdfb2ae5",name="Taoshi"},
	{uuid="2e1c3d2c-3c30-4424-a917-682cb9b9fd47",name="Velem77"},
	{uuid="9e5f1396-ad94-3b1a-8ab7-c7c150e2c6f5",name="kosta1809"},
	{uuid="d48a04c1-2aa0-302e-9363-1f83feb2b523",name="Imforceble"}
}
market.shopLine=1
market.selectedLine='1'
market.player={status='player',name='name',uid='uid',balance='0',ban='-',cash='0'}
--получаем название используемого торгового сундука. список сундуков GTImpact модпака
market.component = {'neutronium','iridium','osmium','chrome','wolfram','titanium',
'hsla','aluminium','steel','wriron','chest','tile_extrautils_chestfull_name'}

for chest in pairs(market.component)do 
	if component.isAvailable(market.component[chest]) then
		market.chest=require('component')[market.component[chest]]
	end
end
--получаем список админов из рабочей дирректории 
local fs=require('filesystem')
if fs.exists('home/owner.market') then
	market.owner=require('owner.market')
end

--позаимствованная у BrightYC таблица цветов.добавлен мутно-зелёный
local color = {
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
market.screen={}--здесь держать все кнопки экрана
market.activity={}--здесь держать функциональные кнопки. или нет

--содержит все используемые кнопки. Кнопки содержат поля: координаты x y,
--размер по x y, текст, внутренняя позиция текста, имя функции если используется, цвета
market.button={
	status={x=3,xs=8,y=1,ys=1,text='player',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	mode={x=3,xs=8,y=2,ys=1,text='trade',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	totalitems={x=3,xs=19,y=19,ys=1,text=tostring(#market.inumList)..'items',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	cash={x=3,xs=8,y=4,ys=1,text='cash:'..tostring(market.player.cash),tx=1,ty=0,bg=0x303030,fg=0x68f029},
	balance={x=3,xs=8,y=5,ys=1,text='bal: '..tostring(market.player.balance),tx=1,ty=0,bg=0x303030,fg=0x68f029},
	
	one={x=14,xs=6,y=4,ys=3,text='1',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	two={x=22,xs=6,y=4,ys=3,text='2',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	free={x=30,xs=6,y=4,ys=3,text='3',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	foo={x=14,xs=6,y=8,ys=3,text='4',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	five={x=22,xs=6,y=8,ys=3,text='5',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	six={x=30,xs=6,y=8,ys=3,text='6',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	seven={x=14,xs=6,y=12,ys=3,text='7',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	eight={x=22,xs=6,y=12,ys=3,text='8',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	nine={x=30,xs=6,y=12,ys=3,text='9',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	zero={x=22,xs=6,y=16,ys=3,text='0',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	back={x=14,xs=6,y=16,ys=3,text='<-',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	dot={x=30,xs=6,y=16,ys=3,text='.',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	enternumber={x=30,xs=6,y=16,ys=3,text='OK',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	set={x=38,xs=6,y=16,ys=3,text='ok',tx=2,ty=1,bg=0x303030,fg=0x68f029},

	number={x=38,xs=12,y=8,ys=3,text='',tx=10,ty=1,bg=0x303030,fg=0x68f029},
	select={x=38,xs=24,y=4,ys=3,text='item',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	totalprice={x=38,xs=10,y=12,ys=3,text='',tx=2,ty=1,bg=0x303030,fg=0x68f029},

	newname={x=26,xs=4,y=16,ys=3,text='newname',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	acceptbuy={x=26,xs=24,y=19,ys=3,text='accept buy',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	cancel={x=26,xs=10,y=23,ys=1,text='cancel',tx=2,ty=0,bg=0x303030,fg=0x68f029},

	welcome={x=10,xs=24,y=12,ys=3,text='Welcome to PimMarket',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	name={x=10,xs=24,y=8,ys=3,text='name',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	entrance={x=3,xs=68,y=2,ys=22,text='',tx=1,ty=1,bg=0x141414,fg=color.blackLime},
	pim1={x=20,xs=32,y=6,ys=12,text='',tx=1,ty=1,bg=0x000929,fg=0x68f029},
	pim2={x=22,xs=28,y=7,ys=10,text='Go on PIM',tx=10,ty=4,bg=0x202020,fg=0x68f029},
	buy={x=28,xs=16,y=8,ys=3,text='Купить',tx=5,ty=1,bg=0x303030,fg=0x68f029},
	sell={x=28,xs=16,y=12,ys=3,text='Продать',tx=5,ty=1,bg=0x303030,fg=0x68f029},
	
	shopUp={x=3,xs=10,y=7,ys=5,text='UP',tx=4,ty=2,bg=0x303030,fg=0x68f029},
	shopDown={x=3,xs=10,y=13,ys=5,text='DOWN',tx=3,ty=2,bg=0x303030,fg=0x68f029},
	shopTopRight={x=17,xs=36,y=1,ys=1,text='Available items                         count  price',tx=3,ty=0,bg=0xc49029,fg=0x000000},
	shopFillRight={x=17,xs=40,y=2,ys=20,text='',tx=0,ty=0,bg=0x303030,fg=0x68f029},
	shopVert={x=65,xs=2,y=2,ys=20,text=' ',tx=0,ty=0,bg=0x404040,fg=0x68f029}
}

--это обработчик экрана.
--содержит все функции вызываемые кнопками
--в том числе меняющие содержимое экрана
market.screenActions={}
market.screenActions.sell=function()return false end
market.screenActions.buy=function()return market.showMe()end
market.screenActions.one=function()market.number=market.number..'1' return market.inputNumber(1) end
market.screenActions.two=function()market.number=market.number..'2' return market.inputNumber(2) end
market.screenActions.free=function()market.number=market.number..'3' return market.inputNumber(3) end
market.screenActions.foo=function()market.number=market.number..'4' return market.inputNumber(4) end
market.screenActions.five=function()market.number=market.number..'5' return market.inputNumber(5) end
market.screenActions.six=function()market.number=market.number..'6' return market.inputNumber(6) end
market.screenActions.seven=function()market.number=market.number..'7' return market.inputNumber(7) end
market.screenActions.eight=function()market.number=market.number..'8' return market.inputNumber(8) end
market.screenActions.nine=function()market.number=market.number..'9' return market.inputNumber(9) end
market.screenActions.zero=function()market.number=market.number..'0' return market.inputNumber(0) end
market.screenActions.dot=function()market.number=market.number..'.' return market.inputNumber('.')end
market.screenActions.back=function()if #market.number > 0 then
	market.number=string.sub(market.number,1,#market.number-1) return market.inputNumber('-') end end
market.screenActions.enternumber=function() return market.inputNumber('n')  end
market.screenActions.acceptbuy=function() return market.finalizeSell() end
--================================================================
market.screenActions.shopTopRight=function() end
market.screenActions.shopVert=function() end
market.screenActions.shopUp=function()if market.shopLine > 10 then
	market.shopLine=market.shopLine-10 end return market.showMeYourCandyesBaby(market.itemlist,market.inumList) end
market.screenActions.shopDown=function()if market.itemlist.size-10 > market.shopLine then
	market.shopLine=market.shopLine+10 end return market.showMeYourCandyesBaby(market.itemlist,market.inumList) end
market.screenActions.shopFillRight=function(_,y)--ловит выбор игроком предмета
	market.selectedLine = y+market.shopLine-2
	gpu.set(68,23,tostring(market.selectedLine))
	if market.selectedLine <= #market.inumList then
	market.select=market.inumList[market.selectedLine]
	market.button.select.text=market.itemlist[market.select].display_name
	market.button.select.xs=#market.itemlist[market.select].display_name+4
	return market[market.mode](market.selectedLine)
	else

	end
end
market.screenActions.set=function()return market.inputNumber('set') end
market.screenActions.cancel=function()
	return market.inShopMenu()
end
--====================================================================================
market.screenActions.name=function()return market.welcome() end
market.screenActions.welcome=function()return market.welcome() end
market.screenActions.status=function()
	if market.player.status=='owner' then
		if market.mode=='trade' then market.mode = 'edit'	
		else 
			if market.mode == 'edit' then market.mode = 'typing'
			else
				market.mode = 'trade'
			end
		end
	else 
		market.mode = 'trade'	
	end
	market.button.mode.text=market.mode
	return market.place({'mode'})
end
--================================================================
--вызов меню набора номера.
market.trade=function()
	market.screen={'status','one','two','free','foo','five','six','seven','eight',
	'nine','zero','back','enternumber','cancel'}
	market.replace()
	return market.place({'mode','number','select','totalprice','cash','balance'})
end

--меню владельца для ввода цены
market.edit=function()
	market.screen={'status','one','two','free','foo','five','six','seven','eight',
	'nine','zero','back','set','dot','cancel'}
	market.replace()
	return market.place({'mode','number','select','cash','balance'})
end

--меню владельца для наименования
market.typing=function(line)
	market.clear(0x202020)
	market.place({'select','newname'})
	market.screen={}
	local loop = true
	local name=''

	while loop do
		local _,_,ch,scd = event.pull('key_down')
		if ch then
			if ch>32 then 
				name=name..string.char(ch)
			end

			if ch == 8 then name=string.sub(name,1,#name-1) end
			if ch==0 and scd==211 then name=string.sub(name,1,#name-1) end
			if ch==13 then loop = false end
		market.button.newname.text=name
		market.button.newname.xs=#name+4
		market.place({'newname'})
		end
	end
	market.button.newname.text=''
	market.itemlist[market.inumList[line]].display_name = name
	market.save_toFile(market.itemlist)
	return market.inShopMenu()
end

--скромно перерисовывает поле цифрового ввода и следит за ним
market.inputNumber=function(n)
	if n == 'set' then return market.setPrice() end
	if n == 'n' then return market.acceptBuy() end
	if #market.number>3 then
		if tonumber(market.number) > 999 then
			market.number=string.sub(market.number,1,#market.number-1)
		end
	end
	market.button.number.text=market.number
	market.button.number.xs= #market.itemlist[market.inumList[market.selectedLine]].display_name+4
	market.button.number.tx=
	(#market.itemlist[market.inumList[market.selectedLine]].display_name+4)/2-#market.button.number.text/2
	local items= tonumber(market.number) or 0
	local count= tonumber(market.itemlist[market.inumList[market.selectedLine]].sell_price) or 0
	market.button.totalprice.text= tostring(items*count)
	market.button.totalprice.xs= #market.itemlist[market.inumList[market.selectedLine]].display_name+4
	market.button.totalprice.tx= 
	(#market.itemlist[market.inumList[market.selectedLine]].display_name+4)/2-#market.button.totalprice.text/2
	return market.place({'number','totalprice'})
end

--запрашивает подтверждение выбора и количества
--осуществляет вызов продажи либо продаёт изымая нал/баланс
market.acceptBuy=function()
	local player_money= tonumber(market.player.cash) + tonumber(market.player.balance)
	if player_money >= tonumber(market.button.totalprice.text) then
		market.place({'acceptbuy'})
		market.screen[1+#market.screen]='acceptbuy'
	end
end
--завершает продажу. забирает валюту. выдаёт предметы
market.finalizeSell=function()
	local price = tonumber(market.button.totalprice.text)
	--market.inumList[market.selectedLine] --рав-имя предмета
	price=math.floor(price)
	local item_raw_name=market.money
	--пушим в сундук
	market.fromInvToInv(market.chest,item_raw_name,price,'pushItem')

	item_raw_name=market.inumList[market.selectedLine]
	local count=tonumber(market.number)
	--пуллим из сундука
	market.fromInvToInv(pim,item_raw_name,count,'pullItem')
	return market.showMe
end

--завершает сессию установки цены овнером
market.setPrice=function()
	market.itemlist[market.inumList[market.selectedLine]].sell_price = market.number
	market.save_toFile(market.itemlist)
	return market.inShopMenu()
end
--==================================================================
--pim & chest - components contains inventory
--inventoryList - itemlist of csanning inventory
--item_raw_name, count - raw name of item and count for migrate
--op - type of operation in string format. itemPull or itemPush
--device - определяет проверяемый инвентарь
--передаёт выбранный предмет itemid в количестве count из целевого в назначенный инвентарь
--параметр передачи задаётся агр. 'op'=itemPull or itemPush
function market.fromInvToInv(device,item_raw_name,count, op)
	local c=count
	local legalSlots={}
	local slots= device.getInventorySize()
	
	if slots == 40 then slots=36 end
	for slot=1,slots,1 do
		if device.getStackInSlot and item_raw_name == device.getStackInSlot(slot).raw_name
			then table.insert(legalSlots, slot)
		end
	end

	for slot in pairs(slots)do
		local currentItem = device.getStackInSlot(slots[slot])
		local available=currentItem.qty
		if c > 0 then
			if c >  available then
				c=c-available
				pim[op]('down',slot,available)--из слота в назначение
			else
				pim[op]('down',slot,c)--остатки меньше стака
				c=0
			end
		end
	end
end

function market.findCash(inventory)
	local cash=0
	if inventory[market.money] then
		cash = inventory[market.money].qty
	end
	return cash
end
--=============================================================
--displayet items availabled for trading
--where pos - position in itemlist for showing
--and itemlist - numerated itemlist
--создание экрана со списком пердметов
function market.showMeYourCandyesBaby(itemlist,inumList)
	local y=2
	local pos=market.shopLine
	local total=#inumList

	gpu.setBackground(0x111111)
	gpu.setForeground(color.blackLime)
	gpu.fill(17,2,38,19,' ')
	while pos <= total do
		local item=inumList[pos]
		gpu.set(17,y,itemlist[item].display_name)
		gpu.set(60,y,tostring(itemlist[item].qty))
		--gpu.setBackground(0x273ba1)
		gpu.set(67,y,' ')
		--gpu.setBackground(0x202020)
		gpu.set(68,y,tostring(itemlist[item].sell_price))
		y=y+1
		pos=pos+1
		if y > 21 then pos=total+1 end
	end
end

--отрисовывает поля меню выбора товара
function market.showMe()
	--заглядываем в инвентарь игрока. просто любопытство, не более
	market.inventory=market.get_inventoryitemlist(pim)
	--находим наличку в инвентаре игрока
	market.player.cash=market.findCash(market.inventory)
	--костыль. убрать после появления сервера
	market.player.balance=0
	if market.player.name == 'Taoshi' then market.player.balance = 9876 end
	--статус игрока. владелец или игрок
	market.button.status.text=market.player.status
	market.number=''
	market.mode='trade'
	market.button.number.text=''
	market.button.mode.text='trade'
	return market.inShopMenu()
end

market.inShopMenu=function()
	market.screen={'status','shopUp','shopDown','shopFillRight','cancel'}
	market.replace()
	market.place({'shopVert','shopTopRight','mode','cash','balance'})
	return market.showMeYourCandyesBaby(market.itemlist,market.inumList)
end
--===============================================
--==--==--==--==--==--==--==--==--==--==--==--
--сюда попадаем получая эвент  touch
--эта функция обрабатывает касания экрана.
--ориентируясь по списку в листе market.screen
--вызывает одноименный кнопке метод в том случае,
--если имя в эвенте совпадает с именем инвентаря на пим
function market.screenDriver(x,y,name)
	if name == market.player.name then
	local list=market.screen
		for f in pairs (list) do
			local button=market.button[list[f]]
			local a=(x >= button.x and x <= (button.xs+button.x-1)) and (y >= (button.y) and y <= (button.ys+button.y-1))
			if a then
				return market.screenActions[list[f]](x,y)
			end
		end
	end
end
--==--==--==--==--==--==--==--==--==--==--==--
--сюда попадает получая эвент player_on
function market.pimWho(who,uid)
	--=================================
	--need connect to server for get player info
	--=============================
	market.player.name=who
	market.player.uid=uid
	market.money='item.npcmoney'
	market.player.status = 'player'
	for f=1, #market.owner do
		if market.owner[f].uuid==uid and market.owner[f].name==who then 
			market.player.status = 'owner'
		end
	end

	if who == 'Taoshi' then
    market.money='gt.metaitem.01.18061'--test
	end
	--здороваемся
	market.button.name.text=who
	market.button.name.xs=#who+4
	market.button.name.x=19-#who/2
	market.screen={'sell','buy'}
	market.clear(2345)
	market.place(market.screen)
	
	--отправляемся в каталог товаров
	--return market.showMe()
end

--очистка и создание экрана ожидания
--сюда попадаем получая эвент player_off
function market.pimByeBye()
	market.player={}
	market.inventory={}
	
	return market.screenInit()
end
--=============================================================
--сортируем лист в алфавитном порядке
function market.sort()
	local index=#market.inumList 
	local pos=1
	while index > pos do
		for int = index, pos, -1 do
			if market.inumList[int] < market.inumList[pos] then
				market.inumList[pos], market.inumList[int] = market.inumList[int], market.inumList[pos]
			end
			if market.inumList[int] > market.inumList[index] then
				market.inumList[index], market.inumList[int] = market.inumList[int], market.inumList[index]
			end
		end
		index=index-1
		pos=pos+1
	end
end
--подшивает актульный список предметов к основному
function market.merge()
	local index=1
	if not market.itemlist.size then market.itemlist.size=0 end
	market.chestList.size=nil
	for id in pairs(market.chestList) do
		market.inumList[index]=id
		if not market.itemlist[id] then
			market.itemlist[id]={}
			market.itemlist[id].sell_price = '9999'
			market.itemlist[id].buy_price = '0'	
			market.itemlist[id].qty=market.chestList[id].qty
			market.itemlist[id].display_name=market.chestList[id].display_name
			market.itemlist.size=market.itemlist.size+1
		else
			market.itemlist[id].qty=market.chestList[id].qty
			market.itemlist[id].slots=market.chestList[id].slots
		end
		index=index+1
	end
end
--=================================================
--scan inventory. return items table.
--из самостоятельной одноцелевой в многоцелевую
--на вход подать используемый компонент: пим или сундук.
function market.get_inventoryitemlist(device)
	local size=device.getInventorySize() --число слотов в инвентаре
	local inventory={}
	inventory.size=0
	local id,item='',''
	for f=1,size do
		item=device.getStackInSlot(f) 
	 	--заполняет таблицу инвентаря,
	 	--добавляя поле slots для повторяющихся
	 	--в инвентаре предметов. суммирует qty для них
	 	--в поле id пишется raw_name
		if item and not inventory[item.raw_name] then
			id=item.raw_name
			inventory[id]={}
			inventory[id].display_name=item.display_name
			inventory[id].sell_price=item.sell_price
			inventory[id].buy_price=item.buy_price
			inventory[id].name=item.name
			inventory[id].qty=item.qty
			inventory[id].slots={f}--номера слотов занимаемых предметом
			inventory.size=inventory.size+1
		else if item then
			id=item.raw_name
			inventory[id].qty=inventory[id].qty+item.qty
			inventory[id].slots[#inventory[id].slots+1]=f
			--table.insert(inventory[id].slots,f)--можно заменить на
			end
		end
	end
	return inventory
end
--load itemlist from file
function market.load_fromFile()
	local itemlist = {}
	if not fs.exists('home/db.market') then
		local db=io.open('db.market','w')
		db:write('0'..'\n')
		itemlist.size=0
	else
		local db=io.open('db.market','r')
		local size=db:read('*line')
		if tonumber(size) then
			itemlist.size=size
			for _=1, size do 
				local id=tostring(db:read('*line'))
				itemlist[id]={}
				itemlist[id].display_name=tostring(db:read('*line'))
				itemlist[id].sell_price=tonumber(db:read('*line'))
				itemlist[id].buy_price=tonumber(db:read('*line'))
			end
  end
  db:close()
	end
	return itemlist
end

--save itemlist to file
function market.save_toFile(list)
	local itemlist=list
	local db=io.open('db.market','w')
	db:write(tostring(itemlist.size)..'\n')
	local size=itemlist.size
	itemlist.size=nil
	for id in pairs(itemlist)do
		db:write(tostring(id)..'\n')
		db:write(tostring(itemlist[id].display_name)..'\n')
		db:write(tostring(itemlist[id].sell_price)..'\n')
		db:write(tostring(itemlist[id].buy_price)..'\n')
	end
	itemlist.size=size
	db:close()
	return true
end

--замена кнопок экрана: вызов очистки и прорисовки
function market.replace()
	market.clear(0x111111)
	market.place(market.screen)
end

--Очистка экрана ничего особенного. Обычный велосипед
market.clear=function(background)
	--gpu.setActiveBuffer(0)	
	if not background then background=0x111111 end
	local x,y=gpu.getViewport()
	gpu.setBackground(background)
	gpu.fill(1,1,x,y,' ')
	--gpu.setActiveBuffer(1)
end
--размещает текущие одноцветные кнопки на экране
market.place=function(buttons)
	--gpu.setActiveBuffer(0)
	for n in pairs(buttons)do
		local b=market.button[buttons[n]]
		-- bg,fg=gpu.getBackground(),gpu.getForeground()
		gpu.setBackground(tonumber(b.bg))
		gpu.fill(tonumber(b.x),tonumber(b.y),tonumber(b.xs),tonumber(b.ys),' ')
		gpu.setForeground(tonumber(b.fg))
		gpu.set(tonumber(b.x)+tonumber(b.tx),tonumber(b.y)+tonumber(b.ty),b.text)
		--gpu.setBackground(bg)
		--gpu.setForeground(fg)
	end
	--gpu.setActiveBuffer(1)
end

function market.screenInit()
	market.clear(0x202020)
	return market.place({'entrance','pim1','pim2'})
end

computer.pullSignal=function(...)
	local e={pullSignal(...)}
	if e[1]=='player_on' then
		return market.pimWho(e[2],e[3])
	end
	if e[1]=='player_off'then
		return market.pimByeBye()
	end
	if e[1]=='touch'then
		return market.screenDriver(e[3],e[4],e[6])
	end
	return table.unpack(e) 
end
--инициализация
function market.init()
	--надо сперва чекать сундук, затем на его основе подтягивать поля с ценой из файла
	--либо наоборот. в любом случае сундук апдейдит лист в файле и сохраняет его
	market.mode='trade'
	print('load database from file...')
	market.itemlist=market.load_fromFile()
	print('file loading succesfull')
	print('getting chest inventory...')
	market.chestList=market.get_inventoryitemlist(market.chest)
	print('complite')
	--теперь апдейт листа путем добавления полей с отсутствующими айди из сундука в итемлист
	--а market.inumList будет содержать указатели присутствующих товаров в основном листе
	print('merge tables')
	market.merge()
	--потом сортировка нумерного листа торговли
	print('sorting available items...')
	market.sort()
	--for item in pairs(market.inumList) do print (market.inumList[item]) end
	print('save current database...')
	market.save_toFile(market.itemlist)
	--и сохранение нового листа на диск?. когда, если не сейчас? возможно, в админской функции сета цен
	--table.sort(table)
	print('initialization complete')
	gpu.setResolution(72,24)
	gpu.allocateBuffer(1,1)
	--gpu.setActiveBuffer(1)
	return market.screenInit()
end
return market