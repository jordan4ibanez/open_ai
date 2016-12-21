open_ai.leash_table = {}

minetest.register_craftitem("open_ai:leash", {
	description = "Leash",
	inventory_image = "open_ai_leash.png",
	on_use = function(itemstack, user, pointed_thing)
	
		if pointed_thing.type == "object" then
			local object = pointed_thing.ref
			local name   = user:get_player_name()
			if open_ai.leash_table[name] == nil then
				open_ai.leash_table[name] = object
				
				object:get_luaentity().target = user
				object:get_luaentity().leashed = true
				
				print("got first")
			else
				print("got second")
				open_ai.leash_table[name]:get_luaentity().target = object
				open_ai.leash_table[name]:get_luaentity().leashed = true
				open_ai.leash_table[name] = nil
			end
		end
	end,
})
