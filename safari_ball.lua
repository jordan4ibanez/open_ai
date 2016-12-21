--empty safari ball
minetest.register_craftitem("open_ai:safari_ball_no_mob", {
	--remove modname and capitalize first letter
	description = "Empty Safari Ball",
	inventory_image = "open_ai_safari_ball_top.png^open_ai_safari_ball_bottom.png",
	on_use = function(itemstack, user, pointed_thing)
		local v = user:get_look_dir()
		local pos = user:getpos()
		pos.y = pos.y + 1.2
		--play sound when throwing
		minetest.sound_play("open_ai_safari_ball_throw", {
			max_hear_distance = 20,
			gain = 10.0,
			object = obj,
		})
		local obj = minetest.add_entity(pos, "open_ai:safari_ball_no_mob")
		
		obj:setvelocity({x = v.x * 7, y = v.y * 7 + 4, z = v.z * 7})
		obj:setacceleration({x = 0, y = -10, z = 0})

		itemstack:take_item()
		return itemstack
	end,
})

minetest.register_entity("open_ai:safari_ball_no_mob", {
	physical = true,
	collide_with_objects = false,
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	textures = {"open_ai_safari_ball_top.png^open_ai_safari_ball_bottom.png"},
	timer = 0,
	visual_size = {x = 0.4, y = 0.4},
	on_step = function(self, dtime)
		local pos = self.object:getpos()
		local vel = self.object:getvelocity()
		
		--only remove after a certain amount of time
		self.timer = self.timer + dtime
		
		
		--collect mob if exists
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
			if (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
				local name = object:get_luaentity().name
				minetest.add_item(pos, "open_ai:safari_ball_"..name:match("^.-:(.*)"))
				object:remove()
				self.object:remove()
				return
			end
		end
		--[[
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
			if (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
				local name = object:get_luaentity().name
				minetest.add_entity(pos, name)
				self.object:remove()
				return
			end
		end
		]]-- for mob safari ball
		
		
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
open_ai.register_safari_ball = function(mob_name, color)
	local texture = "open_ai_safari_ball_top.png^[colorize:#"..color.."^open_ai_safari_ball_bottom.png"

	minetest.register_craftitem("open_ai:safari_ball_"..mob_name:match("^.-:(.*)"), {
		--remove modname and capitalize first letter
		description = "Safari Ball Containing "..mob_name:match("^.-:(.*)"):gsub("^%l", string.upper),
		inventory_image = texture,
		on_use = function(itemstack, user, pointed_thing)
			local v = user:get_look_dir()
			local pos = user:getpos()
			pos.y = pos.y + 1.2
			--play sound when throwing
			minetest.sound_play("open_ai_safari_ball_throw", {
				max_hear_distance = 20,
				gain = 10.0,
				object = obj,
			})
			local obj = minetest.add_entity(pos, "open_ai:safari_ball_"..mob_name:match("^.-:(.*)"))
			
			obj:setvelocity({x = v.x * 7, y = v.y * 7 + 4, z = v.z * 7})
			obj:setacceleration({x = 0, y = -10, z = 0})

			itemstack:take_item()
			return itemstack
		end,
	})
	minetest.register_entity("open_ai:safari_ball_"..mob_name:match("^.-:(.*)"), {
		physical = true,
		collide_with_objects = false,
		collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
		textures = {texture},
		timer = 0,
		visual_size = {x = 0.4, y = 0.4},
		on_step = function(self, dtime)
			local pos = self.object:getpos()
			local vel = self.object:getvelocity()
			
			--only remove after a certain amount of time
			self.timer = self.timer + dtime

			--safari balls turn into items if past timer and not moving
			if self.oldvel and self.timer > 0.2 then
			if  (math.abs(self.oldvel.x) ~= 0 and vel.x == 0) or
				(math.abs(self.oldvel.y) ~= 0 and vel.y == 0) or
				(math.abs(self.oldvel.z) ~= 0 and vel.z == 0) then
				minetest.add_item(pos, "open_ai:safari_ball_no_mob")--return empty safari ball
				print("spawn mob")
				self.object:remove()
			end
			end
			self.oldvel = vel
		end,
	})
end
