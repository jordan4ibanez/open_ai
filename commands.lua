minetest.register_chatcommand("spawn", {
	params = "<mob>",
	description = "Send text to chat",
	privs = {server = true},
	func = function( name, mob)
		--local str = string.gsub(' [A-z ]*', '' , mob)
		local amount = tonumber(mob:match("^.-%s(.*)"))
		local mob = mob:match("(.*)%s")
		
		print(dump(minetest.registered_entities[name]))
		
		minetest.chat_send_all(str)
		minetest.chat_send_all(amount)
	end,
})
