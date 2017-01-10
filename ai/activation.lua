--the activation class
ai_library.activation = {}
ai_library.activation.__index = ai_library.activation

--this function restored staticdata variables
function ai_library.activation:restore_variables(self,staticdata,dtime_s)
	--print("activating at "..dump(self.object:getpos()))
	if string.sub(staticdata, 1, string.len("return")) == "return" then
		local data = minetest.deserialize(staticdata)
		for key,value in pairs(data) do
			self[key] = value
		end
	end
	self.ai_library.activation:set_id(self)
	self.ai_library.activation:restore_function(self)
	self.user_defined_on_activate(self,staticdata,dtime_s)
end

--give the mob an individual id when spawned
function ai_library.activation:set_id(self)
	if self.age == 0 then
		--print("give id")
		self.ai_library.helpers:add_mob_count(self)
	end
	--show id number
	self.ai_library.aesthetic:debug_id(self)
end

--this keeps the mob consistant
--restores variables and state
function ai_library.activation:restore_function(self)
	--keep hp
	if self.old_hp then
		self.object:set_hp(self.old_hp)
	end
	
	--keep leashes connected when respawning
	if self.target_name then
		self.target = minetest.get_player_by_name(self.target_name)
	end
	
	--keep object riding
	if self.attached_name then
		self.attached = minetest.get_player_by_name(self.attached_name)
		self.attached:set_attach(self.object, "body", {x=0, y=self.visual_offset, z=0}, {x=0, y=self.automatic_face_movement_dir+90, z=0}) -- "body" bone should really be a variable defined in the mob lua
		if self.attached:is_player() == true then
			self.attached:set_properties({
				visual_size = {x=1/self.visual_size.x, y=1/self.visual_size.y},
			})
			--set players eye offset for mob
			self.attached:set_eye_offset({x=0,y=self.eye_offset,z=0},{x=0,y=0,z=0})
		end
	end
	
	--set the amount of times a player has to feed the mob to tame it
	if not self.tame_amount and self.tameable == true then
		self.tame_amount = math.random(self.tame_click_min,self.tame_click_max)
	end
	--re apply the mob chair texture
	if self.has_chair and self.has_chair == true then
		self.object:set_properties({textures = self.chair_textures})
	end
			
	--re apply collisionbox and visualsize
	if self.scale_size ~= 1 and self.collisionbox and self.visual_size then
		self.object:set_properties({collisionbox = self.collisionbox,visual_size = self.visual_size})
	else
		--fix the glitch of entity collisionboxes being shared between entities
		self.object:set_properties({collisionbox = table.copy(open_ai.defaults[self.name]["collisionbox"])})
		self.collisionbox = table.copy(open_ai.defaults[self.name]["collisionbox"])
		self.scale_size = 1
	end
	
	--hack
	if self.velocity == nil then
		self.velocity = 0
	end
	--print("Remember to add to global id table")
end
function ai_library.activation:getstaticdata(self)
	--don't get static data if just spawning
	--if self.time_existing == 0 then
	--	print("not storing data \n\n\n\n\n\n\n")
	--	return
	--end
	
	local serialize_table = {}
	for key,value in pairs(self) do
		--don't get object item
		if key ~= "object" and key ~= "time_existing" then
			--don't do userdata
			if type(value) == "userdata" then
				value = nil
			end
			serialize_table[key] = value
		end
	end
	return(minetest.serialize(serialize_table))
end
