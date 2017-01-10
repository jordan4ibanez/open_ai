--[[
This is how mobs build things

This is a prototype


--]]

ai_library.build = {}
ai_library.build.__index = ai_library.build

function ai_library.build:on_step(self,dtime)
	if self.building ~= true then
		return
	end
	self.ai_library.build:hold_behavior(self)
	self.ai_library.build:load_schematic(self)
	self.ai_library.build:build_schematic(self,dtime)
end

--hold the behavior until finished
function ai_library.build:hold_behavior(self)
	self.behavior_timer = 0
end


--inject a schematic for what it will build, else don't execute
function ai_library.build:load_schematic(self)
	if self.schematic == nil then
		print("getting schematic")
		local building = minetest.get_modpath("open_ai").."/schematics/jungle_tree.mts"
		local str = minetest.serialize_schematic(building, "lua", {lua_use_comments = false, lua_num_indent_spaces = 0}).." return(schematic)"
		self.schematic = loadstring(str)()
		self.schematic_map = {x=1,y=1,z=1}
		self.schematic_origin = table.copy(self.mpos)
		self.schematic_size = schematic.size
		self.index = 1
	end
end


--build the structure node by node
function ai_library.build:build_schematic(self,dtime)
	self.build_timer = self.build_timer + dtime
	--place next node if timer is up or if next node is air
	if self.build_timer > 0.1 or (self.schematic.data[self.index] and self.schematic.data[self.index].name == "air") then

		self.build_timer = 0
				
		--reset all the mappings
		if self.schematic_map.x > self.schematic_size.x then
			self.schematic_map.x = 1
			self.schematic_map.y = self.schematic_map.y + 1
		end
		if self.schematic_map.y > self.schematic_size.y then
			self.schematic_map.y = 1
			self.schematic_map.z = self.schematic_map.z + 1
		end
		--
		--finished
		if self.schematic_map.z > self.schematic_size.z then
			self.schematic_map.z = 1
			self.building = false
			self.schematic = nil
			print("done")
			return
		end
		---
		
		--print(dump(self.schematic_map))

		print(dump(self.schematic.data[self.index]))

		minetest.set_node({x=self.schematic_origin.x+self.schematic_map.x,y=self.schematic_origin.y+self.schematic_map.y,z=self.schematic_origin.z+self.schematic_map.z}, self.schematic.data[self.index])

		
		self.schematic_map.x = self.schematic_map.x + 1
		self.index = self.index + 1
	end
end
