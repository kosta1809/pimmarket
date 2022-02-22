
local market={}
local event=require('event')
local gpu=require('component').gpu
local component=require('component')

--лист с полями sell_price, bye_price, qty, display_name,name
--и ключом raw_name
market.itemlist = {}--содержит все оценённые предметы магазина
market.chestList = {}--содержит предметы в сундуке связанном с терминалом
market.inumList={} --содержит нумерованный список с айди предметов магазина
market.inventory = {}--содержит список предметов текущего посетителя
market.selectedItem=''
market.mode='trade'
market.chest=''--используемый сундук. содержит ссылку на компонет сундук
market.number= ''--используется при выборе количества и установки цен
market.owner={
	{uuid="d2f4fce0-0f27-3a74-8f03-5d579a99988f",name="Vova77"},
	{uuid="0b448076-a810-3a82-8bb8-2913bdfb2ae5",name="Taoshi"},
	{uuid="2e1c3d2c-3c30-4424-a917-682cb9b9fd47",name="Velem77"}
}
market.shopLine=1
market.shopItemsOnScreen={}
market.player={status='player',name='name',uid='uid',balance='0',ban='-'}
--получаем название используемого торгового сундука. список сундуков GTImpact модпака
market.component = {'neutronium','iridium','osmium','chrome','wolfram','titanium',
'hsla','aluminium','steel','wriron','chest','tile_extrautils_chestfull_name'}
local pim=require('component').pim
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
--=============================================================
--2022.02.13-14
market.screen={}--здесь держать все кнопки экрана
market.activity={}--здесь держать функциональные кнопки. или нет

--содержит все используемые кнопки. Кнопки содержат поля: координаты x y,
--размер по x y, текст, внутренняя позиция текста, имя функции если используется, цвета
market.button={
	status={x=1,xs=18,y=1,ys=1,text='hello',tx=1,ty=0,bg=0x68f029,fg=777777},
	mode={x=1,xs=12,y=2,ys=1,text='trade',tx=1,ty=0,bg=0x68f029,fg=777777},
	bye={x=10,xs=18,y=4,ys=3,text='Купить',tx=2,ty=1,bg=999999,fg=0x68f029},
	sell={x=10,xs=19,y=8,ys=3,text='Продать',tx=2,ty=1,bg=999999,fg=0x68f029},
	one={x=2,xs=6,y=4,ys=3,text='1',tx=2,ty=1,bg=999999,fg=0x68f029},
	two={x=8,xs=6,y=4,ys=3,text='2',tx=2,ty=1,bg=999999,fg=0x68f029},
	free={x=14,xs=6,y=4,ys=3,text='3',tx=2,ty=1,bg=999999,fg=0x68f029},
	foo={x=2,xs=6,y=8,ys=3,text='4',tx=2,ty=1,bg=999999,fg=0x68f029},
	five={x=8,xs=6,y=8,ys=3,text='5',tx=2,ty=1,bg=999999,fg=0x68f029},
	six={x=14,xs=6,y=8,ys=3,text='6',tx=2,ty=1,bg=999999,fg=0x68f029},
	seven={x=2,xs=6,y=12,ys=3,text='7',tx=2,ty=1,bg=999999,fg=0x68f029},
	eight={x=8,xs=6,y=12,ys=3,text='8',tx=2,ty=1,bg=999999,fg=0x68f029},
	nine={x=14,xs=6,y=12,ys=3,text='9',tx=2,ty=1,bg=999999,fg=0x68f029},
	zero={x=8,xs=6,y=16,ys=3,text='0',tx=2,ty=1,bg=999999,fg=0x68f029},
	back={x=2,xs=6,y=16,ys=3,text='<-',tx=2,ty=1,bg=999999,fg=0x68f029},
	enternumber={x=16,xs=6,y=16,ys=3,text='OK',tx=2,ty=1,bg=999999,fg=0x68f029},
	selectedItem={x=4,xs=25,y=1,ys=3,text='selectedItem',tx=2,ty=1,bg=999999,fg=0x68f029},
	
	welcome={x=10,xs=24,y=12,ys=3,text='Welcome to PimMarket',tx=2,ty=1,func='pimm',bg=999999,fg=0x68f029},
	entrance={x=2,xs=56,y=2,ys=17,text='Go on PIM',tx=22,ty=9,bg=999999,fg=0x68f029},
	name={x=10,xs=24,y=8,ys=3,text='name',tx=2,ty=1,func='pimm',bg=999999,fg=0x68f029},
	number={x=14,xs=24  ,y=18,ys=3,text='',tx=2,ty=1,bg=999999,fg=0x68f029},
	shopUp={x=2,xs=10,y=5,ys=5,text='UP',tx=5,ty=2,bg=0x4cb01e,fg=0xf2b233},
	shopDown={x=2,xs=10,y=12,ys=5,text='DOWN',tx=4,ty=2,bg=0x4cb01e,fg=0xf2b233},
	shopTopRight={x=16,xs=35,y=1,ys=1,text='Available items              count  price',tx=3,ty=0,bg=0xc49029,fg=0x000000},
	shopFillRight={x=12,xs=29,y=1,ys=1,text='',tx=0,ty=0,bg=0xc49029,fg=0x4cb01e},
	shopVert={x=53,xs=2,y=1,ys=20,text=' ',tx=0,ty=0,bg=0x202020,fg=0x303030}
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
market.screenActions.back=function()if #market.number > 0 then
	market.number=string.sub(market.number,1,#market.number-1) return market.inputNumber('-') end end
market.screenActions.enternumber=function() return market.inputNumber('n')  end
--================================================================
market.screenActions.shopUp=function()if market.shopLine > 10 then
	market.shopLine=market.shopLine-10 end return market.showMeYourCandyesBaby(market.itemlist,market.inumList) end
market.screenActions.shopDown=function()if market.itemlist.size-10 > market.shoppLine then
	market.shopLine=market.shopLine+10 end return market.showMeYourCandyesBaby(market.itemlist,market.inumList) end
market.screenActions.shopFillRight=function(_,y)--ловит выбор игроком предмета
	local line = y-1+market.shopLine
  market.selectedItem=market.itemlist[market.inumList[line]]
	return market.waitForCount() end

--====================================================================================
market.screenActions.name=function()return market.welcome() end
market.screenActions.welcome=function()return market.welcome() end
market.screenActions.status=function()
	if market.player.status=='owner' then
		market.mode = 'price edit'	
	else 
		market.mode = 'trade'
	end
end
--================================================================
--вызов меню набора номера.
market.waitForCount=function()
market.screen={'one','two','free','foo','five','six','seven','eight',
'nine','zero','back','enternumber','number','selectedItem'}
return market.replace()

end
--скромно перерисовывает поле цифрового ввода
market.inputNumber=function()
	
end

--================================================================
--pim getStackInSlot:table witch fields k+v: 
--display_name,dmg,id,max_dmg,max_size,mod_id,name,ore_dict,qty,raw_name//whre qty is amount
--fields form item: display_name, id, raw_name. also need add price for bye, price for cell. 
--===============================================
--scan inventory. return items table.
--из самостоятельной одноцелевой в многоцелевую
--на вход подать используемый компонент пим или сундук.
function market.get_inventoryitemlist(device)
	local size=device.getInventorySize() --число слотов в инвентаре
	print(size)
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
			inventory[id].bye_price=item.bye_price
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
				itemlist[id].bye_price=tonumber(db:read('*line'))
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
		db:write(tostring(itemlist[id].bye_price)..'\n')
	end
	itemlist.size=size
	db:close()
	return true
end


--==================================================================
--pim & chest - components contains inventory
--inventoryList - itemlist of csanning inventory
--item_id, count - name of item and count for migrate
--op - type of operation in string format. itemPull or itemPush
--передаёт выбранный предмет itemid в количестве count из целевого в назначенный инвентарь
--параметр передачи задаётся агр. 'op'=itemPull or itemPush
function market.fromInvToInv(device,itemid,count, op)
	local c=count
	for slot in pairs(itemid.slots) do
		local available=device.getItemInSlot(slot).qty
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
--=============================================================
--==--==--==--==--==--==--==--==--==--==--==--
--эта функция обрабатывает касания экрана.
--ориентируясь по списку в листе market.screen
--вызывает одноименный кнопке метод в том случае,
--если имя в эвенте совпадает с именем инвентаря на пим
function market.screenDriver(_,_,x,y,_,name)
	--if name == market.player.name then
	local list=market.screen
		for f in pairs (list) do
			local button=market.button[list[f]]
			local a=(x >= button.x and x <= (button.xs+button.x)) and (y >= (button.y) and y <= (button.ys+button.y))
			if a then
				return market.screenActions[list[f]](x,y)
			end
		end
	--else gpu.set(12,20,'ошибка сравнения имён')

	--end
end
----ход конём



--==--==--==--==--==--==--==--==--==--==--==--
--displayet items availabled for trading
--where pos - position in itemlist for showing
--and itemlist - numerated itemlist
--создание экрана со списком пердметов
function market.showMeYourCandyesBaby(itemlist,inumList)
	local y=2
	local pos=market.shopLine
	local total=#inumList

	gpu.setBackground(0xc49029)
	gpu.setForeground(0x0)
	gpu.set(3,18,total..'items')
	
	while pos <= total do
		--gpu.fill(24,y,30,1,'')
		local item=inumList[pos]
		gpu.set(14,y,itemlist[item].display_name)
		gpu.set(48,y,tostring(itemlist[item].qty))
		--gpu.setBackground(0x273ba1)
		gpu.set(55,y,' ')
		--gpu.setBackground(0x202020)
		gpu.set(56,y,tostring(itemlist[item].sell_price))
		y=y+1
		pos=pos+1
		if y > 19 then pos=total+1 end
	end
end

--отрисовывает поля меню выбора товара
function market.showMe()
	market.button.status.text=market.player.status..' '..market.player.name
	market.screen={'shopUp','shopDown','shopFillRight','status','shopVert','shopTopRight','mode'}
	market.replace()
	--market.screen[5]=nil
	--market.screen[6]=nil
	--market.screen[7]=nil
	
		--эта функция недописана
		--она размещает наэкране поля для списка айтемов
		--так же должна организовать вывод самого списка айтемов
		--или не должна. посмотрим
		
	return market.showMeYourCandyesBaby(market.itemlist,market.inumList)
end


--==================================================
--ну привет, дружок-пирожок. посмотрим, что ты взял с собой
--и отправим смотреть что сами припасли
function market.welcome()
	market.inventory=market.get_inventoryitemlist(pim)
	market.showMe()
end

--очистка и создание экрана ожидания
function market.pimByeBye()
	market.player={}
	market.inventory={}
	market.mode='trade'
	return market.start()
end

--создание приветственного экрана
function market.hello(name)
	market.button.name.text=name
	market.button.name.xs=#name+4
	market.button.name.x=19-#name/2
	market.screen={'name','welcome'}
	market.clear(2345)
	market.place(market.screen)
	os.sleep(1)
	return market.showMe()
end
--===============================================
--сюда попадает получая эвент player_on
function market.pimWho(_,who,uid)
	--=================================
	--need connect to server for get player info
	--=============================
	market.player.name=who
	market.player.uid=uid
	market.player.status = 'player'
	for f=1, #market.owner do
		if market.owner[f].uuid==uid and market.owner[f].name==who then 
			market.player.status = 'owner'
		end
	end
	--включаем наблюдение касаний экрана. выключаем наблюдение player_on
	--включаем наблюдение player_off
	event.ignode('player_on',pimWho) market.event_player_on=nil
	market.event_touch=event.listen('touch',market.screenDriver)
	market.event_player_off=event.listen('player_off',market.pimByeBye)
	--после касания игроком стартовых отображённых кнопок он
	--попадает в функцию велком
	--здороваемся
	return market.hello(market.player.name)
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
			market.itemlist[id].bye_price = '0'	
			market.itemlist[id].qty=market.chestList[id].qty
			market.itemlist[id].display_name=market.chestList[id].display_name
			market.itemlist.size=market.itemlist.size+1
		else
			print(market.chestList[id].qty)
			market.itemlist[id].qty=market.chestList[id].qty
			market.itemlist[id].slots=market.chestList[id].slots
		end
		index=index+1
	end
end

--=================================================
--замена кнопок экрана: вызов очистки и прорисовки
function market.replace()
	market.clear(303030)
	market.place(market.screen)
end

--Очистка экрана ничего особенного. Обычный велосипед
market.clear=function(background)
	--gpu.setActiveBuffer(0)	
	if not background then background=0 end
	local x,y=gpu.getViewport()
	gpu.setBackground(background)
	gpu.fill(1,1,x,y,' ')
	--gpu.setActiveBuffer(1)
end

--размещает текущие одноцветные кнопки на экране
market.place=function(btns)
	--gpu.setActiveBuffer(0)
	for n in pairs(btns)do
		local b=market.button[btns[n]]
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
	market.screen={'entrance'}
	market.clear(0x202020)
	return market.place(market.screen)
end

function market.start()
	market.event_player_on=event.listen('player_on',market.pimWho)
	if market.event_touch then event.ignore('touch',market.screenDriver) market.event_touch=nil end
	if market.event_player_off then event.ignore('player_off',pimByeBye) market.event_player_off=nil end
	return market.screenInit()
end

--ставим резолюцию, кнопки, начинаем слушать не топчет ли кто пим
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
	print('initialization complete') os.sleep(1)
	gpu.setResolution(60,20)
	gpu.allocateBuffer(1,1)
	--gpu.setActiveBuffer(1)
	return market.start()
end
return market