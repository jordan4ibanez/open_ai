--float in water and lava

--empty safari ball
minetest.register_craftitem("open_ai:safari_ball_no_mob", {
	--remove modname and capitalize first letter
	description = "Empty Safari Ball",
	inventory_image = "open_ai_safari_ball_top.png^open_ai_safari_ball_bottom.png",
	on_use = function(itemstack, user, pointed_thing)
		local v = user:get_look_dir()
		local pos = user:getpos()
		local vel = user:get_player_velocity()
		pos.y = pos.y + 1.2
		--play sound when throwing
		minetest.sound_play("open_ai_safari_ball_throw", {
			max_hear_distance = 20,
			gain = 10.0,
			object = obj,
		})
		local obj = minetest.add_entity(pos, "open_ai:safari_ball_no_mob")
		
		obj:setvelocity({x = (v.x * 7)+vel.x, y = (v.y * 7 + 4)+vel.y, z = (v.z * 7)+vel.z})
		obj:setacceleration({x = 0, y = -10, z = 0})

		itemstack:take_item()
		return itemstack
	end,
})
--entity
minetest.register_entity("open_ai:safari_ball_no_mob", {
	physical = true,
	collide_with_objects = false,
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	textures = {"open_ai_safari_ball_top.png^open_ai_safari_ball_bottom.png"},
	timer = 0,
	visual_size = {x = 0.4, y = 0.4},
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
		self.object:setacceleration({x=0,y=-10,z=0})
	end,
	on_step = function(self, dtime)
		local pos = self.object:getpos()
		local vel = self.object:getvelocity()
		
		--only remove after a certain amount of time
		self.timer = self.timer + dtime
		
		
		--collect mob if exists
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
			if not object:is_player() and (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
				local name = object:get_luaentity().name
				--catch sound
				minetest.sound_play("open_ai_safari_ball_catch", {
					max_hear_distance = 20,
					gain = 10.0,
					object = obj,
				})
				--particles
				minetest.add_particlespawner({
					amount = 80,
					time = 0.01,
					minpos = {x=pos.x, y=pos.y, z=pos.z},
					maxpos = {x=pos.x, y=pos.y, z=pos.z},
					minvel = {x=-5, y=-5, z=-5},
					maxvel = {x=5, y=5, z=5},
					minacc = {x=0, y=-10, z=0},
					maxacc = {x=0, y=-10, z=0},
					minexptime = 1,
					maxexptime = 1,
					minsize = 1,
					maxsize = 1,
					collisiondetection = true,
					vertical = false,
					texture = "open_ai_safari_ball_particle.png",
				})
				minetest.add_item(pos, "open_ai:safari_ball_"..name:match("^.-:(.*)"))
				object:remove()
				self.object:remove()
				--open_ai.mob_count = open_ai.mob_count - 1
				--minetest.chat_send_all(open_ai.mob_count.." Mobs in world!")
				return
			end
		end
	
		--safari balls turn into items if past timer and not moving
		if self.oldvel and self.timer > 0.2 then
		if  (math.abs(self.oldvel.x) ~= 0 and vel.x == 0) or
			(math.abs(self.oldvel.y) ~= 0 and vel.y == 0) or
			(math.abs(self.oldvel.z) ~= 0 and vel.z == 0) then
			minetest.add_item(pos, "open_ai:safari_ball_no_mob")
			self.object:remove()
		end
		end
		
		self.oldvel = vel
	end,
})

--function that creates safari ball item and entity
open_ai.register_safari_ball = function(mob_name, color,height)
	local texture = "open_ai_safari_ball_top.png^[colorize:#"..color.."^open_ai_safari_ball_bottom.png"
	local entity_name = minetest.get_current_modname()..":safari_ball_"..mob_name:match("^.-:(.*)")
	--item
	minetest.register_craftitem(entity_name, {
		--remove modname and capitalize first letter
		description = "Safari Ball Containing "..mob_name:match("^.-:(.*)"):gsub("^%l", string.upper),
		inventory_image = texture,
		on_use = function(itemstack, user, pointed_thing)
			local v = user:get_look_dir()
			local pos = user:getpos()
			local vel = user:get_player_velocity()
			pos.y = pos.y + 1.2
			--play sound when throwing
			minetest.sound_play("open_ai_safari_ball_throw", {
				max_hear_distance = 20,
				gain = 10.0,
				pos = pos,
			})
			local obj = minetest.add_entity(pos, entity_name)
			
			obj:setvelocity({x = (v.x * 7)+vel.x, y = (v.y * 7 + 4)+vel.y, z = (v.z * 7)+vel.z})
			obj:setacceleration({x = 0, y = -10, z = 0})

			itemstack:take_item()
			return itemstack
		end,
	})
	
	--entity
	minetest.register_entity(entity_name, {
		physical = true,
		collide_with_objects = false,
		collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
		textures = {texture},
		timer = 0,
		visual_size = {x = 0.4, y = 0.4},
		mob = mob_name,
		color = color,
		height = height,
		on_activate = function(self, staticdata, dtime_s)
			self.object:set_armor_groups({immortal = 1})
			self.object:setacceleration({x=0,y=-10,z=0})
		end,
		on_step = function(self, dtime)
			local pos = self.object:getpos()
			local vel = self.object:getvelocity()
			
			--only remove after a certain amount of time
			self.timer = self.timer + dtime

			--spawn mob in world
			if self.oldvel and self.timer > 0.2 then
			if  (math.abs(self.oldvel.x) ~= 0 and vel.x == 0) or
				(math.abs(self.oldvel.y) ~= 0 and vel.y == 0) or
				(math.abs(self.oldvel.z) ~= 0 and vel.z == 0) then
				--release sound
				minetest.sound_play("open_ai_safari_ball_release", {
					max_hear_distance = 20,
					gain = 10.0,
				})
				--particles
				minetest.add_particlespawner({
					amount = 80,
					time = 0.01,
					minpos = {x=pos.x, y=pos.y, z=pos.z},
					maxpos = {x=pos.x, y=pos.y, z=pos.z},
					minvel = {x=-5, y=-5, z=-5},
					maxvel = {x=5, y=5, z=5},
					minacc = {x=0, y=-10, z=0},
					maxacc = {x=0, y=-10, z=0},
					minexptime = 1,
					maxexptime = 1,
					minsize = 1,
					maxsize = 1,
					collisiondetection = true,
					vertical = false,
					texture = "open_ai_safari_ball_particle.png^[colorize:#"..self.color,
				})
				minetest.add_item(pos, "open_ai:safari_ball_no_mob")
				
				pos.y = pos.y + self.height --adjust for height
				minetest.add_entity(pos, self.mob)--spawned
				self.object:remove()
			end
			end
			self.oldvel = vel
		end,
	})
end
