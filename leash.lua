open_ai.leash_table = {}

minetest.register_craftitem("open_ai:leash", {
	description = "Leash",
	inventory_image = "open_ai_leash.png",
	on_use = function(itemstack, user, pointed_thing)
	
		if pointed_thing.type == "object" then
			local object = pointed_thing.ref
			local name   = user:get_player_name()
			--player sneaks to connect mobs together
			if user:get_player_control().sneak == true then
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
			else --just connect to player
				if open_ai.leash_table[name] ~= nil then
					minetest.chat_send_player(name, "Link failed!")
					open_ai.leash_table[name] = nil
				end
				object:get_luaentity().target = user
				object:get_luaentity().leashed = true
			end
		end
	end,
})
