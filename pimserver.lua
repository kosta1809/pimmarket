--pimserver
local pimserver={}
pimserver.version='1.00'
local db={}
local modem=require('component').modem
local computer=require('computer')
local pullSignal=computer.pullSignal
local port = 0xfffe
local send = 0xffef
local fs = require('filesystem')
--local log={}
local serialization = require('serialization')
local terminals={}
local unregistered={}
local gpu = require('component').gpu

modem.open(port)
modem.setWakeMessage="{name="

computer.pullSignal=function(...)
	local e={pullSignal(...)}
	if e[1]=='modem_message' then
		return pimserver.modem(e)
	end
	if e[1]=='touch' then
		return pimserver.accept(e)
	end
	return table.unpack(e) 
end

function pimserver.modem(e) ---1type 2respondent 3sender 4port 5distance 6message
	local sender=e[3]
	os.sleep(0.5)
	--want to msg fields:
	--msg.number
	--msg.name =name of player
	--msg.op = enter|buy|sell|balanceIn|balanceOut
	--msg.value = value of operation
	local msg = serialization.unserialize(e[6])
  msg.sender = sender
  --регистрация терминалов
  if msg.name and msg.name=='pimmarket' then
  	if msg.op == 'connect' then
  		return pimserver.registration(sender)
  	end
  end
	--если такого игрока нет, то запись нового игрока в бд
	if msg.name and not db[msg.name] then pimserver.newUser(msg.name) end
	--если в сообщении есть имя игрока отправляем по типу операции
	if msg.name then return pimserver[msg.op](msg) end
	--поиск отклика завершенных событий
	--if msg.complite==true then return true end
	--остальные события нас не интересуют
	return true
end

--постановка терминала в список ожидания регистрации
function pimserver.registration(sender)
	table.insert(unregistered,sender)
	return pimserver.place()
end

--отсылка подтверждения регистрации
function pimserver.accept(msg)
	local x,y = msg[3],msg[4]
	--if msg[6]==adminname then
	
	if y < 13 then return true end
	y=y-12
	if x == 3 and y <= #unregistered then
		table.remove(unregistered,y)
	end
	if x == 43 and y <= #unregistered then
		local sender=table.remove(unregistered,y)
		table.insert(terminals, sender)
		local post={sender=sender,number=1,name='pimmarket',balance=0,op='connect'}
		modem.broadcast(send,post)
		return pimserver.place()
	end
	--end
end

function pimserver.place()
	local x,y = gpu.getResolution()
	gpu.setBackground(0x113311)
	gpu.setForeground(0x58f029)
	gpu.fill(1,1,x,y,' ')
	gpu.set(5,1,'Registered terminals:')
	for t in pairs(terminals) do
		gpu.set(5,t+1,terminals[t])
	end

	gpu.set(5,12,'Unregistered terminals:')
	for t in pairs(unregistered) do
		gpu.set(5,t+12,unregistered[t])
		gpu.set(3,t+12,'X')
		gpu.set(43,t+12,'V')
	end
end

--первичная регистрация игрока
function pimserver.enter(msg)
	if not db[msg.name] then pimserver.newUser(msg.name)
		print('new user'..msg.name)
		msg.new='new'
	end
	return pimserver.broadcast(msg)
end
--вычитание с баланса при покупке
function pimserver.buy(msg)
	db[msg.name].balance=db[msg.name].balance - msg.value
	return pimserver.broadcast(msg)
end
--пополнение баланса при продаже
function pimserver.sell(msg)
	db[msg.name].balance=db[msg.name].balance + msg.value
	return pimserver.broadcast(msg)
end
function pimserver.balanceIn(msg)
	db[msg.name].balance=db[msg.name].balance + msg.value
	return pimserver.broadcast(msg)
end
function pimserver.balanceOut(msg)
	db[msg.name].balance=db[msg.name].balance - msg.value
	return pimserver.broadcast(msg)
end
--отправка результата с указанием адреса пославшего
function pimserver.broadcast(msg)
  local sender, balance, number, name, op = msg.sender, db[msg.name].balance, msg.number, msg.name, msg.op
	
	local post={sender=sender,number=number,name=name,balance=balance,op=op}
	if msg.new then post.new='new' end
	local post = serialization.serialize(post)
	modem.broadcast(send,post)

	--[[if not log[msg.sender] then log[msg.sender]={} end
		log[msg.sender][msg.number]={name=msg.name,op=msg.op,val=msg.value}
	local line='['..serialization.serialize(msg.sender)..']'..'['..serialization.serialize(msg.number)..']'..serialization.serialize(log[msg.sender][msg.mnumber])
	local logs=io.open('logs.pimserver','w','a')
	logs:write(line)
	logs:close()]]--

	return pimserver.saveFile()
end

function pimserver.newUser(name)
	db[name]={}
	db[name].balance='0'
	db[name].ban='-'
	db[name].income='0'
	return pimserver.saveFile()
end
function pimserver.saveFile()
	local dbs=io.open('db.pimserver','w')
	for player in pairs(db)do
		dbs:write(tostring(player)..'\n')
		dbs:write(tostring(db[player].ban..'\n'))
		dbs:write(tostring(db[player].balance..'\n'))
		dbs:write(tostring(db[player].income..'\n'))
	end
	dbs:close()
	return true
end
function pimserver.loadFile()
	db={}
	local dbs=io.open('db.pimserver','r')
		local loop = true
		while loop do
			local line=dbs:read('*line')

			if not line then
				loop = false	
			else
				local name=tostring(line)
				db[name]={}
				db[name].ban=tostring(dbs:read('*line'))
				db[name].balance=tostring(dbs:read('*line'))
				db[name].income=tostring(dbs:read('*line'))
			end
		end
		
		dbs:close()
		return db
	end

function pimserver.init()
	if not fs.exists ('home/db.pimserver') then 
		pimserver.newUser('Taoshi')
		pimserver.saveFile()
	end
		pimserver.loadFile()
	--[[if not fs.exists('home/logs.pimserver')then
		local lg=io.open('logs.pimserver','w')
		log.fakesender={}
		log.fakesender[1]={name='Taoshi',op='init',val='1'}
		lg:write(serialization.serialize(log))
		lg:close()
	end]]
	return true
end

pimserver.init()
gpu.setResolution(76,24)
print('Сервер поднят. Бужу терминалы.')
modem.broadcast(port,'name')
return pimserver