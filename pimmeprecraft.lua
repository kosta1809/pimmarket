--me=component.me_interface
--d=component.database


--allItems=me.getItemsInNetwork()
--stack=me.getItemDetail({id=allItems[3].name})
--stack.all()
--stack.basic()
--stack.select()

--allCraftables={}--создаёт список предметов доступных к крафту
--for v,f im pairs(me.getCraftables())do if type(f)=='table' then table.insert(allCraftables,f.getItemStack())end end

--работа в рамках базы данных
--stack={}
--for n in pairs(db) do
	-- получаем данные о конкретном предмете 
--stack[n]=me.getItemDetail({id=db.get(n).name,raw_name=db.get(n).label}).basic()
--или table.insert(stack,me.getItemDetail({id=db.get(n).name,raw_name=db.get(n).label}).basic())
--amount=stack.basic().qty 
--count=1 or 64
--получаем предмет из сети
--size= me.exportItem({id=id,dmg=dmg,raw.name=raw_name},'up',count).size


print ('empty in this time')
return true

-- что собственно надо от ме
--составление списка предметов на основе данных database
--помещение предмета в ме
--изъятие предмета из ме
--выбор между ме и сундуком и сопутствующая переменная, меняющая вызов методов
--допустим market.workmode='me' или 'ch'
--и на основе этого вызовы методов 
--market[market.workmode].вызываемый метод
--функции market.me.getInventoryItemList
--market.me.fromInvToInv
--на вход подать используемый компонент: пим или сундук.
db=require'component'.database
capacity = 0
for _,v in pairs(computer.getDeviceInfo())do if v.description='Memory bank' then capacity = v.capacity end end

function market.me.get_inventoryitemlist()
	
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