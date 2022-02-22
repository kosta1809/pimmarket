local loader_v='0.5.0'--for check version
local inet=require'internet'
--download files
wget=function(url,name)
	local handle=inet.request(url)
	local result=''
	for chunk in handle do result=result..chunk end
	local file=io.open(name,'w')
	file:write(result)
	file:close()
end
--in this place need add block: check updates available
wget('https://raw.githubusercontent.com/Zardar/pimmarket/master/loader.lua','loader.lua')
wget('https://raw.githubusercontent.com/Zardar/pimmarket/master/pimmarket.lua','market.lua')
market=require('market')
market.init()