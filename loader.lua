--local loader_v='0.9.5'--for check version
local inet=require'internet'
local c='component'
local gpu=require(c).gpu
local fs=require(c).filesystem
local branch='https://raw.githubusercontent.com/Zardar/pimmarket/master/'
local computer=require'computer'
local events={'touch'}
pullSignal=computer.pullSignal	
computer.pullSignal=function(...)
	local e={pullSignal(...)}
	for k in pairs(events)do
		if e[1]==events[k] then
			 return scrDr(e[3],e[4])
		end
	end
	return table.unpack(e) 
end

local b={
s={x=2,xs=20,y=2,ys=3,text='запустить сервер',tx=1,ty=1,bg=0x303030,fg=0x68f029,f='pimserver.lua'},
c={x=2,xs=20,y=6,ys=3,text='запустить клиент',tx=1,ty=1,bg=0x303030,fg=0x68f029,f='pimmarket.lua'},
us={x=2,xs=24,y=10,ys=3,text='апгрейд+запуск сервера',tx=1,ty=1,bg=0x303030,fg=0x68f029},
uc={x=2,xs=24,y=14,ys=3,text='апгрейд+запуск клиента',tx=1,ty=1,bg=0x303030,fg=0x68f029},
ul={x=2,xs=20,y=22,ys=3,text='апгрейд загрузчика',tx=1,ty=1,bg=0x303030,fg=0x68f029,f='loader.lua'},
up={x=2,xs=28,y=18,ys=3,text='апгрейд и запуск прекрафта',tx=1,ty=1,bg=0x303030,fg=0x68f029,f='pimmeprecraft.lua'}
}
local screen = {'s','c','us','uc','up'}

local function wget(url,name)
	local handle=inet.request(url)
	local result=''
	for chunk in handle do result=result..chunk end
	local file=io.open(name,'w')
	file:write(result)
	file:close()
	file=nil
	handle=nil
	result=nil
end

local sa={}
sa.c=function()if fs.exists('/home/'..b.c.f)then return require(b.c.f)end end
sa.s=function()if fs.exists('/home/'..b.s.f)then return require(b.s.f)end end
sa.us=function() wget(branch..b.s.f,b.s.f)return sa.s()end
sa.uc=function() wget(branch..b.c.f,b.c.f)return sa.c()end
sa.up=function() wget(branch..b.up.f,b.up.f)return require(b.up.f)end

clear=function()
	local x,y=gpu.getViewport()
	gpu.setBackground(0x111111)
	gpu.fill(1,1,x,y,' ')
	return true
end
local function place(buttons)
	for n in pairs(buttons)do
		local btn=b[buttons[n]]
		gpu.setBackground(btn.bg)
		gpu.fill((btn.x),(btn.y),(btn.xs),(btn.ys),' ')
		gpu.setForeground(btn.fg)
		gpu.set((btn.x)+(btn.tx),(btn.y)+(btn.ty),btn.text)
	end
	return true
end

function scrDr(e3,e4)
	local x,y=e3,e4
	for f in pairs (screen) do
		local btn=b[screen[f]]
		local a=(x >= btn.x and x <=(btn.xs+btn.x-1))and(y >=(btn.y)and y <=(btn.ys+btn.y-1))
		if a then
			events={}
			return sa[screen[f]]()
		end
	end
	return false
end

x=gpu.getViewport()
for n in pairs(b)do
	b[n].x = x/2-b[n].xs/2-1
end
wget(branch..b.ul.f,b.ul.f)
clear()
place(screen)
return true