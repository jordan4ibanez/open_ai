--globalize the conf file
open_ai.conf = Settings(minetest.get_worldpath() .. "/open_ai_configuration.conf")

--helpers class
ai_library.helpers = {}
ai_library.helpers.__index = ai_library.helpers

--this is runs everything that is needed when a world starts with the mod newly installed
function ai_library.helpers:initialization()
	ai_library.helpers:create_conf()
end

--this allows a setting to be written without having to call write every time
function ai_library.helpers:write_setting(key,value)
	open_ai.conf:set(key, value)
	open_ai.conf:write()
end

--create the .conf file for world
function ai_library.helpers:create_conf()
	local check = open_ai.conf:get("count")
	if not check then
		ai_library.helpers:write_setting("count",0)
		ai_library.helpers:write_setting("peaceful",1)--0 would be hostile mobs
	end
end

--add mob to mob count and add to conf file
--this can only be called within a mob
--the count will always be one step ahead, to set the next id
--this will show how many mobs have been spawned
function ai_library.helpers:add_mob_count(self)
	--to start from 0
	local count = open_ai.conf:get("count")
	self.id = count
	count = count + 1
	--call within self
	self.ai_library.helpers:write_setting("count",count)
end
