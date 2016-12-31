--the growth ray
minetest.register_craftitem("open_ai:growth_ray", {
	description = "Growth Ray",
	inventory_image = "open_ai_growth_ray.png",
 
	on_use = function(itemstack, user, pointed_thing)
		local pos = user:getpos()
		pos.y = pos.y + 1.25
		local dir = user:get_look_dir()
		
		dir.x = dir.x * 15
		dir.y = dir.y * 15
		dir.z = dir.z * 15
		
		local object = minetest.add_entity(pos, "open_ai:growth_ray_ray")
		
		object:setvelocity(dir)
	end,
})

--the growth ray orb
minetest.register_entity("open_ai:growth_ray_ray", {
	visual = "sprite",
	physical = true,
	collide_with_objects = false,
	textures = {"open_ai_growth_ray_ray.png"},
	
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
	end,
	
	on_step = function(self,dtime)
		local pos = self.object:getpos()
		local vel = self.object:getvelocity()
		
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 3)) do
			--only collide with other mobs and players
						
			--add exception if a nil entity exists around it
			if not object:is_player() and (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
				object:get_luaentity().grow_timer = 0.25
				object:get_luaentity().size_change = 1
				self.object:remove()
				return
			end
		end
		
		if self.oldvel and ((self.oldvel.x ~= 0 and vel.x == 0) or (self.oldvel.y ~= 0 and vel.y == 0) or (self.oldvel.z ~= 0 and vel.z == 0)) then
			self.object:setvelocity({x=0,y=0,z=0})
			self.object:remove()
		end
		
		self.oldvel = vel
	end,
})



--the shrink ray
minetest.register_craftitem("open_ai:shrink_ray", {
	description = "Shrink Ray",
	inventory_image = "open_ai_shrink_ray.png",
 
	on_use = function(itemstack, user, pointed_thing)
		local pos = user:getpos()
		pos.y = pos.y + 1.25
		local dir = user:get_look_dir()
		
		dir.x = dir.x * 15
		dir.y = dir.y * 15
		dir.z = dir.z * 15
		
		local object = minetest.add_entity(pos, "open_ai:shrink_ray_ray")
		
		object:setvelocity(dir)
	end,
})

--the shrink ray orb
minetest.register_entity("open_ai:shrink_ray_ray", {
	visual = "sprite",
	physical = true,
	collide_with_objects = false,
	textures = {"open_ai_shrink_ray_ray.png"},
	
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
	end,
	
	on_step = function(self,dtime)
		local pos = self.object:getpos()
		local vel = self.object:getvelocity()
		
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 3)) do
			--only collide with other mobs and players
						
			--add exception if a nil entity exists around it
			if not object:is_player() and (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
				object:get_luaentity().grow_timer = 0.25
				object:get_luaentity().size_change = -1
				self.object:remove()
				return
			end
		end
		
		if self.oldvel and ((self.oldvel.x ~= 0 and vel.x == 0) or (self.oldvel.y ~= 0 and vel.y == 0) or (self.oldvel.z ~= 0 and vel.z == 0)) then
			self.object:setvelocity({x=0,y=0,z=0})
			self.object:remove()
		end
		
		self.oldvel = vel
	end,
})
