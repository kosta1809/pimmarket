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
--stack[n]=me.getItemDetail({id=d.get(n).name,raw_name=d.get(n).label}).basic()
--amount=stack.basic().qty 
--count=1 or 64
--получаем предмет из сети
--size= me.exportItem({id=id,dmg=dmg,raw.name=raw_name},'up',count).size



-----бинд модема по адресу
--серверная часть
--loadFile(terminals.pimmarket)
--сервер получая сообщение с ключом connect предлагает отправить ответ для подтверждения регистрации
--Print: адрес терминала <адрес>. нажмите Y чтобы подтвердить терминал. N чтобы отказаться
--при подтверждении добавляет в лист терминалов новый адрес
--и сохраняет лист терминалов в файл.
--если прошло N времени - забывает непринятый терминал, записывая во временный лист неизвестных?


--терминал: при включении отсылает сообщение с ключом connect
--при первом получении ключа connect записывает адрес сервера
--вызовом функции market[market.link](sender.address) (unlinked / linked)
--market.unlinked=function(address) market.serverAddress = address 
--market.link = linked
--после чего меняет статус с unlinked на linked