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
local log={}
local serialization = require('serialization')

modem.open(port)
modem.setWakeMessage="{name="
computer.pullSignal=function(...)
	local e={pullSignal(...)}
	if e[1]=='modem_message' then
		return pimserver.modem(e)
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
	--если такого игрока нет, то запись нового игрока в бд
	if msg.name and not db[msg.name] then pimserver.newUser(msg.name) end
	--если в сообщении есть имя игрока отправляем по типу операции
	if msg.name then return pimserver[msg.op](msg) end
	--поиск отклика завершенных событий
	--if msg.complite==true then return true end
	--остальные события нас не интересуют
	return true
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
	print('I push message')
	modem.broadcast(send,post)
	
	local dbs=io.open('db.pimserver')
	dbs:write(serialization.serialize(db))
	dbs:close()

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
print('Сервер поднят')
return pimserver