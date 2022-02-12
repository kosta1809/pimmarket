--io=require('io')
--pim event player_on name address address
--pim event player_off name address address
--pim getStackInSlot:table witch fields k+v: display_name,dmg,id,max_dmg,max_size,mod_id,name,ore_dict,qty,raw_name//whre qty is amount
--fields form item: display_name, id, raw_name. also need add price for bye, price for cell. may be in 2 custom listuire('component').pim
local item,items='',{}


--event trigger player_on {name, uuid?, id?}
--getting items table from player inventoryfill items table
for f=1,40 do item=pim.getStackInSlot(f) 
	if item then print('enter price for '..item.display_name..':') items[f].display_name=item.display_name items[f].id=item.id 
	else items[f]=false end
end
for f=1,40 do if items[f] then
	print(items[f].display_name,items[f].id,items[f].qty)
end end


--I have an idea for create table by id of item
--load db from file by id
loadFromFile=function(itemlist)
    if 'table'~=type(itemlist) then itemlist={} end
	local db=io.open('db','r')
	if db then
		local size=db:read('*line')
		itemlist.size=size
		for f=1, size do 
			id=db:read('*line')
			itemlist[id]={}
			itemlist[id].display_name=db:read('*line')
			itemlist[id].sell_price=db:read('*line')
			itemlist[id].bye_price=db:read('*line')
			itemlist[id].raw_name=db:read('*line')
		end
	end
	return itemlist
end

saveTableToFile=function(itemlist)
--creating items list and build by id of item

db=io.open('db','w')
db:write(itemlist.size..'\n')
local size=itemlist.size
itemlist.size=nil
for f














