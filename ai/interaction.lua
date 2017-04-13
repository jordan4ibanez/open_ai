--how players/mobs interact
ai_library.interaction = {}
ai_library.interaction.__index = ai_library.interaction

--interactions on step
function ai_library.interaction:on_step(self)
	self.ai_library.interaction:check_to_follow(self)
end
--what happens when you hit a mob
function ai_library.interaction:on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
	if self.user_defined_on_punch then
		self.user_defined_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
	end
	self.ai_library.interaction:knockback(self,puncher,dir)

	local hitpoints = self.object:get_hp()

	if damage ~= nil then
		hitpoints = hitpoints - damage
	end

	if hitpoints <= 0 then
		self.ai_library.aesthetic:on_die(self)
		self.ai_library.interaction:on_die(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
	end

	return false
end

--what happens when you right click a mob
function ai_library.interaction:on_rightclick(self, clicker)
	
	self.ai_library.interaction:ride_attempt(self,clicker)
	
	self.ai_library.interaction:place_chair(self,clicker) -- this after try to ride so player puts on chair before riding
	
	self.ai_library.interaction:taming(self,clicker)
	
	self.ai_library.interaction:sit(self,clicker)
	
	--undo leash
	if self.leashed == true then
		self.leashed = false
		self.target = nil
		self.target_name = nil
		return
	end

	if self.user_defined_on_rightclick then
		self.user_defined_on_rightclick(self, clicker)
	end
end

--how a player puts a "chair" on a mob
function ai_library.interaction:place_chair(self,clicker)
	if self.tameable == false or self.tamed == false or self.rideable == false or self.mob_chair == nil or self.has_chair == true then
		return
	end
	local item = clicker:get_wielded_item()
	
	if item:to_string() ~= "" and item:to_table().name == self.mob_chair then
		item:take_item(1)
		clicker:set_wielded_item(item)
		self.has_chair = true
		self.object:set_properties({textures = self.chair_textures})
	end			
end

--what happens when a player tries to ride the mob
function ai_library.interaction:ride_attempt(self,clicker)
	local item = clicker:get_wielded_item()
	--don't ride if putting on mob chair
	if self.has_chair and self.has_chair == false or (item:to_string() ~= "" and item:to_table().name == self.mob_chair) then
		return
	end
	--initialize riding the horse
	if self.rideable == true and self.tamed == true and clicker:get_player_name() == self.owner_name and self.sitting ~= true then
		if self.attached == nil and self.leashed == false and clicker:get_player_control().sneak ~= true then
			self.attached = clicker
			self.attached_name = clicker:get_player_name()
			self.attached:set_attach(self.object, "body", {x=0, y=self.visual_offset, z=0}, {x=0, y=self.automatic_face_movement_dir+90, z=0}) -- "body" bone should really be a variable defined in the mob lua
			--sit animation
			if self.attached:is_player() == true then
				self.attached:set_properties({
					visual_size = {x=1/self.visual_size.x, y=1/self.visual_size.y},
				})
				--set players eye offset for mob
				self.attached:set_eye_offset({x=0,y=self.eye_offset,z=0},{x=0,y=0,z=0})
			end
		elseif self.attached ~= nil then
			--normal animation
			if self.attached:is_player() == true then
				self.attached:set_properties({
					visual_size = {x=1, y=1},
				})
				--revert back to normal
				self.attached:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
			end
			self.attached:set_detach()
			self.attached_name = nil
			self.attached = nil
		end
		
	end
end

--how a mob is tamed
function ai_library.interaction:taming(self,clicker)
	--disalow mobs that can't be tamed or mobs that are already tamed
	if not self.tameable or (self.tameable == false or self.tamed == true) then 
		return
	end

	local item = clicker:get_wielded_item()
	
	if item:to_string() ~= "" and item:to_table().name == self.tame_item then
		item:take_item(1)
		clicker:set_wielded_item(item)
		self.tame_amount = self.tame_amount - 1
	end
	if self.tame_amount <= 0 then
		self.tamed = true
		self.owner = clicker
		self.owner_name = clicker:get_player_name()
		
		local pos = self.object:getpos()
		
		self.ai_library.aesthetic:tamed(self)
	end
end

--allow owner to make mob sit
function ai_library.interaction:sit(self,clicker)
	if self.owner_name == clicker:get_player_name() and clicker:get_player_control().sneak == true then
		if self.sitting == nil then
			self.sitting = true
			minetest.chat_send_player(clicker:get_player_name(), "Mob is sitting!")
			self.ai_library.aesthetic:sat(self)
		else
			self.sitting = nil
			minetest.chat_send_player(clicker:get_player_name(), "Mob is free!")
			self.ai_library.aesthetic:stood(self)
		end
	end
end

--mob knockback
function ai_library.interaction:knockback(self,puncher,dir)
	if puncher:is_player() then
		if self.vel.y ~= 0 then
			return
		end
		local dirr = vector.multiply(dir,self.max_velocity)
		self.object:setvelocity({x=dirr.x,y=self.jump_height,z=dirr.z})
	end
end

--on die
function ai_library.interaction:on_die(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)

	--return player back to normal scale
	self.ai_library.interaction:normalize(self)

	local pos = self.object:getpos()
	local pos2 = puncher:getpos()

	--throw item at player
	--multiply dir times vector.distance
	local object = minetest.add_item(pos, self.drops)

	if object then
		local vec = vector.multiply(vector.multiply(dir, -1), vector.distance(pos, pos2))
		vec.y = vec.y * 3
		object:setvelocity(vec)
	end

	if self.user_defined_on_die then
		self.user_defined_on_die(self, puncher, time_from_last_punch, tool_capabilities, dir)
	end
end

--return player visuals to normal
function ai_library.interaction:normalize(self)
	if self.attached then
	if self.attached:is_player() == true then
		self.attached:set_properties({
			visual_size = {x=1, y=1},
		})
		--revert back to normal
		self.attached:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
	end
	end
end

--mob getting in cart
function ai_library.interaction:ride_in_cart(self,object)
	
	--reset value if cart is removed
	local ride = self.object:get_attach()
	if ride == nil and self.in_cart == true then
		self.in_cart = false
	end
	
	if self.in_cart == false then
		self.object:set_attach(object, "", {x=0, y=0, z=0}, {x=0, y=0, z=0})
		object:get_luaentity().driver = "open_ai:mob"
		self.in_cart = true
	end
end

--check if a mob should follow a player when holding an item
--check_to_follow
function ai_library.interaction:check_to_follow(self)
	--don't follow if leashed
	if self.leashed == true then
		return
	end
	self.following = false
	--liquid mobs follow lure
	if self.liquid_mob == true then
		local pos = self.object:getpos()
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 10)) do
			if not object:is_player() and object:get_luaentity() and object:get_luaentity().is_lure == true and object:get_luaentity().in_water == true and object:get_luaentity().attached == nil then 
				local pos2 = object:getpos()
				local vec = {x=pos.x-pos2.x,y=pos2.y-pos.y, z=pos.z-pos2.z}
				--how strong a leash is pulling up a mob
				self.leash_pull = vec.y
				--print(vec.x,vec.z)
				local yaw = math.atan(vec.z/vec.x)+ math.pi / 2
				
				if yaw == yaw then
					
					if pos2.x > pos.x then
						self.yaw = yaw+math.pi
					end
					
					self.yaw = yaw
				end
				
				--float up or down to lure
				self.swim_pitch = vec.y
			end
		end
	else
		--pathfind to player
		local pos = self.object:getpos()
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 30)) do
			if object:is_player() then
				local item = object:get_wielded_item()
				if item:to_string() ~= "" and item:to_table().name == self.follow_item then
					self.following = true
					self.target = object
				else
					self.following = false
				end
			end
		end
	end
end
