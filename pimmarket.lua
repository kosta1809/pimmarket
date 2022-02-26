--=============================================================
--2022.02.11-14...02.22
--=============================================================
local market={}
market.version='0.99'
local gpu=require('component').gpu
local component=require('component')
local computer=require('computer')
local pullSignal=computer.pullSignal
local pim=require('component').pim
local event=require('event')
local modem=require('component').modem
local table=require('table')
local math=require('math')
local port = 0xffef
local send = 0xfffe
local serialization=require("serialization")
local zero, one = 0, 1

modem.open(port)
modem.setWakeUpMessage='sender'
market.msgnum=14041
market.money = 'item.npcmoney'
--лист с полями sell_price, buy_price, qty, display_name, и ключом raw_name
market.itemlist = {}--содержит все оценённые предметы магазина
market.chestList = {}--содержит предметы в сундуке связанном с терминалом
market.inumList={} --содержит нумерованный список с айди предметов магазина
market.inventory = {}--содержит список предметов текущего посетителя
market.select='' --raw_name выбранного предмета
market.mode='trade'
market.chest=''--используемый сундук. содержит ссылку на компонет сундук
market.number= ''--означает число товара в покупке. также поле в установке цен
market.substract =''--содержит число для вычета наличных
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
	eula1={x=5,xs=70,y=3,ys=1,text='Здравствуйте! Рады впервые видеть вас!',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula2={x=5,xs=68,y=5,ys=1,text='Вас приветствует электронный магазин ПимМаркет.',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula3={x=5,xs=70,y=7,ys=1,text='Все покупки в магазине производятся за НПЦ монеты.',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula4={x=5,xs=70,y=9,ys=1,text='Если цена товара не равна целому числу НПЦ монет -',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula5={x=5,xs=70,y=11,ys=1,text='остаток от операции зачислится на Пим-счёт игрока.',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula6={x=5,xs=70,y=13,ys=1,text='Этот счёт автоматически используется при последующих покупках.',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula7={x=5,xs=38,y=15,ys=1,text='Курс Пим к НПЦ составляет 10 к 1.',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula8={x=5,xs=38,y=17,ys=1,text='Все цены в магазине указаны в Пимах.',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula9={x=5,xs=38,y=19,ys=1,text='Если вы согласны с предоставленными условиями пользования',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula10={x=5,xs=38,y=21,ys=1,text='подтвердите ваше решение',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	eula11={x=14,xs=21,y=24,ys=1,text='СОГЛАСЕН/СОГЛАСНА',tx=1,ty=0,bg=0xf2b233,fg=0x111111},
	eula12={x=56,xs=19,y=24,ys=1,text='discord:taoshi#2664',tx=0,ty=0,bg=0x305030,fg=0xf2b233},

	status={x=3,xs=8,y=1,ys=1,text='player',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	mode={x=3,xs=8,y=2,ys=1,text='trade',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	totalitems={x=1,xs=19,y=24,ys=1,text=tostring(#market.inumList)..'items',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	cash={x=3,xs=8,y=4,ys=1,text='NPC money:',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	balance={x=3,xs=8,y=5,ys=1,text='lua coins:',tx=1,ty=0,bg=0x303030,fg=0x68f029},
	ratio={x=3,xs=8,y=6,ys=1,text='1нпс=10пим',tx=1,ty=0,bg=0x303030,fg=0x68f029},

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
	totalprice={x=38,xs=12,y=12,ys=3,text='',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	incorrect={x=38,xs=20,y=12,ys=3,text='нехватка средств',tx=2,ty=1,bg=0x303030,fg=0x68f029},

	newname={x=26,xs=4,y=16,ys=3,text='newname',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	acceptbuy={x=38,xs=24,y=16,ys=3,text='подтвердить',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	cancel={x=34,xs=10,y=23,ys=1,text='отмена',tx=2,ty=0,bg=0x303030,fg=0x68f029},

	welcome={x=24,xs=24,y=12,ys=3,text='добро пожаловать в ПимМаркет',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	name={x=32,xs=24,y=8,ys=3,text='name',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	wait={x=27,xs=24,y=16,ys=3,text='ждём ответ сервера...',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	entrance={x=3,xs=72,y=2,ys=22,text='',tx=1,ty=1,bg=0x141414,fg=color.blackLime},
	pim1={x=24,xs=24,y=6,ys=12,text='',tx=1,ty=1,bg=0x404040,fg=0x68f029},
	pim2={x=26,xs=20,y=7,ys=10,text='Встаньте на PIM',tx=2,ty=4,bg=0x202020,fg=0x68f029},
	buy={x=30,xs=16,y=8,ys=3,text='Купить',tx=5,ty=1,bg=0x303030,fg=0x68f029},
	sell={x=30,xs=16,y=12,ys=3,text='Продать',tx=5,ty=1,bg=0x303030,fg=0x68f029},
	full={x=16,xs=39,y=10,ys=3,text='Ваш инвентарь полон. Доступ закрыт.',tx=2,ty=1,bg=0x303030,fg=0x68f029},
	
	shopUp={x=3,xs=10,y=7,ys=5,text='ВВЕРХ',tx=2,ty=2,bg=0x303030,fg=0x68f029},
	shopDown={x=3,xs=10,y=13,ys=5,text='ВНИЗ',tx=3,ty=2,bg=0x303030,fg=0x68f029},
	shopTopRight={x=21,xs=36,y=1,ys=1,text='Available items                         count  цена в пим',tx=3,ty=0,bg=0xc49029,fg=0x000000},
	shopFillRight={x=21,xs=40,y=2,ys=20,text='',tx=0,ty=0,bg=0x303030,fg=0x68f029},
	shopVert={x=65,xs=2,y=2,ys=20,text=' ',tx=0,ty=0,bg=0x404040,fg=0x68f029}
}

--это обработчик экрана.
--содержит все функции вызываемые кнопками
--в том числе меняющие содержимое экрана
market.screenActions={}
market.screenActions.eula11=function()market.screen={'sell','buy'} return market.replace() end
market.screenActions.sell=function()return false end
market.screenActions.buy=function()return market.inShopMenu()end
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
market.screenActions.acceptbuy=function() return market.getNewBalance() end
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
	market.number = ''
	market.totalprice = '0'
	market.button.number.text=''
	market.button.totalprice.text=''
	return market.inShopMenu()
end
--====================================================================================
market.screenActions.status=function()
	if market.player.status=='owner' then
		if market.mode=='trade' then market.mode = 'edit'	
		else 
			if market.mode == 'edit' then market.mode = 'rename'
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
market.rename=function(line)
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
	if tonumber(market.number) > market.itemlist[market.select].qty then
			market.number=tostring(market.itemlist[market.select].qty)
	end
	if #market.number>3 then
		if tonumber(market.number) > 999 then
			market.number=tostring(math.floor(999))
		end	
	end
	market.button.number.text=market.number..' '
	market.button.number.xs= #market.itemlist[market.inumList[market.selectedLine]].display_name+4
	market.button.number.tx=
	(#market.itemlist[market.inumList[market.selectedLine]].display_name+4)/2-#market.button.number.text/2
	local items= tonumber(market.number) or 0
	local count= tonumber(market.itemlist[market.inumList[market.selectedLine]].sell_price) or 0
	market.button.totalprice.text= tostring(items*count)..' '
	market.button.totalprice.xs= #market.itemlist[market.inumList[market.selectedLine]].display_name+4
	market.button.totalprice.tx= 
	(#market.itemlist[market.inumList[market.selectedLine]].display_name+4)/2-#market.button.totalprice.text/2
	if market.mode == 'trade' then return market.place({'number','totalprice'}) end
	return market.place({'number'})
end

--запрашивает подтверждение выбора и количества
--осуществляет вызов продажи либо продаёт изымая нал/баланс
market.acceptBuy=function()
	--узнаём суммарную платёжеспособность покупателя
	local player_money= tonumber(market.player.cash)*10 + tonumber(market.player.balance)
	if player_money >= tonumber(market.button.totalprice.text) then
		market.place({'acceptbuy'})
		table.insert(market.screen,'acceptbuy')
	end
end
--на основе объёма покупки производим действия с балансом
market.getNewBalance=function()
	totalprice = tonumber(market.button.totalprice.text)
	balance = tonumber(market.player.balance)
	if balance > 0 then
		--если баланс не ниже суммы покупки
		if balance >= totalprice then
				market.substract=0
				market.balanceOP=totalprice
			else --баланс ниже суммы покупки, но не 0
				--число монет к изъятию
				market.substract=math.floor((totalprice-balance)/10)+1
				--сумма вычета с баланса
				market.balanceOP=totalprice-market.substract*10
		end
	else--если баланс 0, то он не может стать меньше!
		market.substract=math.floor(totalprice/10)+1
		--для автозачисления сдачи на баланс
		market.balanceOP=totalprice-market.substract*10
	end
	local msg={name=market.player.name,op='buy',number=market.msgnum,value=market.balanceOP}
	return market.serverPost(msg)
			
end

--завершает продажу. забирает валюту. выдаёт предметы
market.finalizeBuy=function()
	market.clear()
	local price = market.substract
	--пушим в сундук монеты
	gpu.set(50,23,'push money into chest')
	market.fromInvToInv(pim,market.money,price,'pushItem')

	item_raw_name=market.inumList[market.selectedLine]--рав-имя предмета
	local count=tonumber(market.number)
	--пуллим из сундука.
	gpu.set(50,24,'pull items into buyer')
	market.fromInvToInv(market.chest,item_raw_name,count,'pullItem')

	market.itemlist[item_raw_name].qty=market.itemlist[item_raw_name].qty - count
	return market.inShopMenu()
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
	local thisItem = item_raw_name
	if slots == 40 then slots=36 end
	for slot=1,slots do
		if device.getStackInSlot(slot) and thisItem == device.getStackInSlot(slot).raw_name
			then table.insert(legalSlots, slot)
		end
	end

	for slot in pairs(legalSlots)do
		local currentItem = device.getStackInSlot(legalSlots[slot])
		local available=currentItem.qty
		if c > 0 then
			if c >  available then
				c=c-available
				pim[op]('down',legalSlots[slot],available)--из слота в назначение
			else
				pim[op]('down',legalSlots[slot],c)--остатки меньше стака
				c=0
			end
		end
	end
	return true
end

function market.findCash()
	local cash=0
	if market.inventory[market.money] then
		cash = market.inventory[market.money].qty
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

	gpu.setActiveBuffer(zero)
	gpu.setBackground(0x111111)
	gpu.setForeground(color.blackLime)
	gpu.fill(21,2,40,20,' ')
	gpu.fill(64,2,5,20,' ')
	gpu.fill(72,2,5,20,' ')
	while pos <= total do
		local item=inumList[pos]
		gpu.set(21,y,itemlist[item].display_name)
		gpu.set(64,y,tostring(math.floor(itemlist[item].qty)))
		gpu.set(72,y,tostring(itemlist[item].sell_price))
		y=y+1
		pos=pos+1
		if y > 21 then pos=total+1 end
	end
	gpu.setActiveBuffer(one)
end


function market.showMe()
	--костыль. убрать после появления сервера

	return market.inShopMenu()
end

--отрисовывает поля меню выбора товара
market.inShopMenu=function()
	--обновляем список предметов
	--market.chestList=market.get_inventoryitemlist(market.chest)
	--market.merge()

	--заглядываем в инвентарь игрока. просто любопытство, не более
	market.inventory = market.get_inventoryitemlist(pim)
	--проверка на наличие свободных слотов. если их нет - прощаемся
	local emptySlot=false
	for slot = 1,36 do
		if not pim.getStackInSlot(slot) then emptySlot = true end
	end
	if not emptySlot then return market.full() end
	--обновляем список товаров в магазине
	market.inumList={}
	market.chestList=market.get_inventoryitemlist(market.chest)
	market.merge()
	market.sort()
	market.number=''
	market.button.number.text=''
	
	--находим наличку в инвентаре игрока
	market.player.cash=market.findCash()
	market.button.cash.text='НПС коин:'..tostring(market.player.cash)
	market.button.balance.text='луа-мани:'..tostring(market.player.balance)
	market.button.totalprice.text='0'
	market.button.totalitems.text=#market.inumList..' type of items available'
	market.screen={'status','shopUp','shopDown','shopFillRight','cancel'}
	market.replace()
	market.place({'shopVert','shopTopRight','mode','cash','balance','ratio','totalitems'})
	return market.showMeYourCandyesBaby(market.itemlist,market.inumList)
end
--если инвентарь игрока полон
market.full=function()
	market.clear()
	return market.place({'full'})
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
	local list = market.screen
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
	market.mode='trade'
	market.button.mode.text='trade'
	market.money='item.npcmoney'
	market.player.status = 'player'
	for f=1, #market.owner do
		if market.owner[f].uuid==uid and market.owner[f].name==who then 
			market.player.status = 'owner'
		end
	end
	market.button.status.text=market.player.status
	market.player.balance='0'
	market.player.cash='0'
	if who == 'Taoshi' then
    market.money='gt.metaitem.02.18061'--test
	end
	--здороваемся
	market.button.name.text=who
	market.button.name.xs=#who+4
	market.button.name.x=38-#who/2
	market.clear()
	market.place('welcome','name','wait')
	--делаем запрос баланса на сервер
	local msg={name=market.player.name,op='enter',number=market.msgnum,value='0'}
	return market.serverPost(msg)
end

--очистка и создание экрана ожидания
--сюда попадаем получая эвент player_off
function market.pimByeBye()
	market.player={}
	market.inventory={}
	market.screen={}
	
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
	gpu.setActiveBuffer(zero)	
	if not background then background=0x111111 end
	local x,y=gpu.getViewport()
	gpu.setBackground(background)
	gpu.fill(1,1,x,y,' ')
	gpu.setActiveBuffer(one)
end
--размещает текущие одноцветные кнопки на экране
market.place=function(buttons)
	gpu.setActiveBuffer(zero)
	for n in pairs(buttons)do
		local b=market.button[buttons[n]]
		gpu.setBackground(b.bg)
		gpu.fill((b.x),(b.y),(b.xs),(b.ys),' ')
		gpu.setForeground(b.fg)
		gpu.set((b.x)+(b.tx),(b.y)+(b.ty),b.text)
	end
	gpu.setActiveBuffer(one)
end

function market.screenInit()
	market.clear(0x202020)
	return market.place({'entrance','pim1','pim2'})
end



--пытаемся получить сообщение подтверждающее операцию
market.serverResponse=function(e)
	msg=serialization.unserialize(e)
	--а нам ли сообщение?
	if msg.sender and not msg.sender==modem.address then return true end
		--msg.number,msg.name,msg.value
		-- =name of player
		--msg.op = enter|buy|sell|balanceIn|balanceOut
		-- = value of operation
	if msg.name and msg.name == market.player.name then 
		market.player.balance = msg.balance
		market.msgnum = market.msgnum + 1

	end
	return market.modem[msg.op](msg)
end
market.modem={}
market.modem.buy=function(msg)

	market.finalizeBuy()
end
market.modem.sell=function(msg)

end
market.modem.balanceIn=function(msg)

end
market.modem.balanceOut=function(msg)
	
end
market.modem.enter=function(msg)
	--выводим меню магазина
	return market.eula()
	
end

market.eula=function()
market.clear()
market.place({'eula1','eula2','eula3','eula4','eula5','eula6','eula7','eula8','eula9','eula10','eula12'})
market.screen={'eula11'}
return market.place(market.screen)
end



--сигнал побудки?
market.serverPost=function(msg)
	msg=serialization.serialize(msg)
	modem.broadcast(0xfffe,msg)

end




computer.pullSignal=function (...)
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
	if e[1]=='modem_message' then return market.serverResponse(e[6])
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
	print('save current database...')
	market.save_toFile(market.itemlist)
	--и сохранение нового листа на диск?. когда, если не сейчас? возможно, в админской функции сета цен
	--table.sort(table)
	print('initialization complete')
	gpu.setResolution(76,24)
	gpu.allocateBuffer(1,1)
	--gpu.setActiveBuffer(1)
	return market.screenInit()
end
return market