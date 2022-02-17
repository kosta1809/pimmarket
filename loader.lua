local loader_v='0.5.0'--for check version
local market_v='0.5.0'
local inet=require('internet')
local component=require('component')
local event=require('event')

--fs it is filesystem
for address in component.list("filesy") do
    if component.proxy(address).spaceTotal() > 66000  and component.proxy(address).exists('init.lua') then
        local fs = component.proxy(address)
    end
end
if not fs then
  print("Filesystem not found!")
end

--download files
function wget(url,name)
	local handle=inet.request(url)
	local result=''
	for chunk in handle do result=result..chunk end
	local file=io.open(name,'w')
	file:write(result)
	file:close()
end

--in this place need add block: check updates available
--if veersios < this.versions then download new else nothing end
wget('https://raw.githubusercontent.com/Zardar/pimmarket/master/loader.lua','loader.lua')
wget('https://raw.githubusercontent.com/Zardar/pimmarket/master/pimmarket.lua','market.lua')

local gpu=require('component').gpu
gpu.setResolution(60,20)

local itemlist,inventory={},{}
local market=require'market'
local itemlist=market.load_fromFile()

event.listen('player_on',market.builder)
--event.listen('touch',market.touch_handler)
print('starting up')
