--pimserver
local pimserver={}
pimserver.version='0.9'
local db={}
local modem=require('component').modem
local computer=require('computer')
local port = 0xfffe
local send = 0xffef
local fs = require('filesystem')
local log={}

modem.open(port)
computer.pullSignal=function(...)
	local e={pullSignal(...)}
	if e[1]=='modem_message' then
		return pimserver.modem(e)
	end
	return table.unpack(e) 
end

function pimserver.modem(e) ---1type 2respondent 3sender 4port 5distance 6message
	local sender=e[3]
	--want to msg fields:
	--msg.number
	--msg.name =name of player
	--msg.op = enter|buy|sell|balanceIn|balanceOut
	--msg.value = value of operation
	local msg = serialization.unserialize(e[6])
	--запись нового игрока в бд
	if msg.name and not db[msg.name] then pimserver.newUser(msg.name) end
	--если в сообщении есть имя игрока отправляем по типу операции
	if msg.name then return pimserver[msg.op](msg) end
	--поиск отклика завершенных событий
	if msg.complite==true then return true end
	--остальные события нас не интересуют
	return true
end
function pimserver.enter(msg)
	return pimserver.modem.broadcast(msg)
end
function pimserver.buy(msg)
	db[msg.name].balance=db[msg.name].balance - value
	return pimserver.broadcast(msg)
end
function pimserver.sell(msg)
	db[msg.name].balance=db[msg.name].balance + value
	return pimserver.broadcast(msg)
end
function pimserver.balanceIn(msg)
	db[msg.name].balance=db[msg.name].balance + value
	return pimserver.broadcast(msg)
end
function pimserver.balanceOut(msg)
	db[msg.name].balance=db[msg.name].balance - value
	return pimserver.broadcast(msg)
end
function pimserver.broadcast(msg)
	local post = serialization.serialize({msg.number,msg.sender,msg.name,db[name]})
	modem.broadcast(send,post)
	if not log[msg.sender] then log[msg.sender]={} end
	log[msg.sender][msg.msgnumber]={name=msg.name,op=msg.op,val=msg.value}
	return true
end

function pimserver.newUser(name)
	db[name]={}
	db[name].balance='0'
	db[name].ban='-'
	db[name].income='0'
	return true
end

function pimserver.init()
	if not fs.exists ('home/db.pimserver') then 
		local dbs=io.open('db.pimserver','w')
		pimserver.newUser('Taoshi')
		dbs:write(db)
		dbs:close()
	end
	dbs=io.open('db.pimserver')
	db=dbs:read()
	db=serialization.unserialize(db)
	dbs:close()
	if not fs.exists('home/log.pimserver')then
		local lg=io.open('log.pimserver','w')
		log.fakesender={}
		log.fakesender[1]={name='Taoshi',op='init',val='1'}
		lg:write(serialization.serialize(log))
		lg:close()
	end
	lg=io.open(log.pimserver)
	log=lg:read()
	log=serialization.unserialize(log)
	lg:close()
	return true
end

pimserver.init()
print('Сервер поднят')
return pimserver