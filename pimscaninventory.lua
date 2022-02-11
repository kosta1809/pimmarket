--io=require('io')
--pim event player_on name address address
--pim event player_off name address address
--pim getStackInSlot:table witch fields k+v: display_name,dmg,id,max_dmg,max_size,mod_id,name,ore_dict,qty,raw_name//whre qty is amount
pim=require('component').pim
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

--read db from file--
local items={}
local index=1
db=io.open('db','r')
if db then
	for f in db do items[f]={} 
		items[f].id=db:read('*line')
		items[f].price=db:read('*line')
		items[f].display_name=db:read('*line')
		index=index+1
	end
end