minetest.register_chatcommand("spawn", {
	params = "<mob>",
	description = "Spawn x amount of a mob, used as /spawn sheep 10 or /spawn fish for one",
	privs = {server = true},
	func = function( name, mob)
		--local vars
		local str = mob
		local amount = 1
		
		--checks if a player put a number of mobs
		local number_of_mobs = string.find(str, "%s%d+")
		
		
		--remove spaces from the string
		if number_of_mobs == nil then
			str:gsub("%s", "")
			str = "open_ai:"..mob
			--don't change amount
		else--or find values
			amount = tonumber(str:match("^.-%s(.*)"))
			str = "open_ai:"..str:match("(.*)%s")
		end
		--explain formatting
		if amount == nil or str == nil then
			minetest.chat_send_player(name, "Format as /spawn mobname 20 or /spawn mobname")
		end
		
		--add amount of entities if registered
		if minetest.registered_entities[str] ~= nil then
			local pos = minetest.get_player_by_name(name):getpos()
			pos.y = pos.y - open_ai.defaults[str]["collisionbox"][2]
			--print(amount)
			--add in amount through loop
			if amount > 1 then
				for i = 1,amount do 
					minetest.add_entity(pos,str)
				end
			else --add single
				minetest.add_entity(pos,str)
			end
		else --tell player the mob doesn't exist
			minetest.chat_send_player(name, str:match("^.-:(.*)"):gsub("^%l", string.upper).." is not a registerd mob!")
		end
		
	end,
})
