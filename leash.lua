open_ai.leash_table = {}

minetest.register_craftitem("open_ai:leash", {
	description = "Leash",
	inventory_image = "open_ai_leash.png",
	on_use = function(itemstack, user, pointed_thing)
	
		
	
		if pointed_thing.type == "object" then
			
			
			
			local object = pointed_thing.ref
			
			--don't allow liquid mobs to be leashed
			if object:get_luaentity() and object:get_luaentity().mob == true and object:get_luaentity().liquid_mob == true then
				return
			end
			
			local name   = user:get_player_name()
			--player sneaks to connect mobs together
			if user:get_player_control().sneak == true and object:get_luaentity() and object:get_luaentity().mob == true then
				if open_ai.leash_table[name] == nil then
					minetest.chat_send_player(name, "Click other mob to link")
					open_ai.leash_table[name] = object
					--object:get_luaentity().target = user
					--object:get_luaentity().leashed = true
				else
					minetest.chat_send_player(name, "Linked!")
					open_ai.leash_table[name]:get_luaentity().target = object
					open_ai.leash_table[name]:get_luaentity().leashed = true
					open_ai.leash_table[name] = nil
				end
			elseif object:get_luaentity() and object:get_luaentity().mob == true then--just connect to player
				if open_ai.leash_table[name] ~= nil then
					minetest.chat_send_player(name, "Link failed!")
					open_ai.leash_table[name] = nil
				end
				object:get_luaentity().target = user
				object:get_luaentity().leashed = true
				object:get_luaentity().target_name = user:get_player_name()
			end
		end
	end,
})
