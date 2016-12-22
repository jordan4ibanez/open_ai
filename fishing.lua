--fishing items and entities
minetest.register_craftitem("open_ai:fishing_pole_lure", {
	description = "Fishing Pole",
	inventory_image = "open_ai_fishing_pole_lure.png^[transformFX",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local dir = user:get_look_dir()
		local pos = user:getpos()
		pos.y = pos.y + 1.5
		dir.x = dir.x * 15
		dir.y = (dir.y * 15)+4
		dir.z = dir.z * 15
		local lure = minetest.add_entity(pos, "open_ai:lure")
		lure:setvelocity({x=dir.x,y=dir.y,z=dir.z})
		lure:get_luaentity().owner = user
		
			
		minetest.sound_play("open_ai_safari_ball_throw", {
			pos = pos,
			max_hear_distance = 10,
			gain = 10.0,
		})
		itemstack:replace("open_ai:fishing_pole_no_lure")
		
		return(itemstack)
	end,
})
minetest.register_craftitem("open_ai:fishing_pole_no_lure", {
	description = "Fishing Pole (Cast)",
	inventory_image = "open_ai_fishing_pole_no_lure.png^[transformFX",
	stack_max = 1,
})


--lures
minetest.register_entity("open_ai:lure", {
	physical = true,
	collide_with_objects = false,
	textures = {"default_stone.png"},
	owner   = nil,
	visual_size = {x=0.3, y=0.3},
	collisionbox = {-0.17,-0.17,-0.17,0.17,0.17,0.17},
	velocity = 0,
	acceleration = 4,
	speed = 5,
	in_water = false,
	
	on_activate = function(self, staticdata)
		self.object:set_armor_groups({immortal=1})
		self.object:setvelocity({x=0, y=1, z=0})
		self.object:setacceleration({x=0, y=-10, z=0})
		local data = core.deserialize(staticdata)
		if data and type(data) == "table" then
			self.owner = data.owner
		end
	end,
	get_staticdata = function(self)
		--return core.serialize({
		--	owner = self.owner
		--})
	end,
	--when a mob is on a leash
	lure_function = function(self,dtime)
		self.check_pole(self)
		
		local vel  = self.object:getvelocity()
		--remove if owner is not in game
		if not self.owner or not self.owner:is_player() then
			self.object:remove()
			return
		end
		
		if self.oldvel then
		if  (math.abs(self.oldvel.x) ~= 0 and vel.x == 0) or
			(math.abs(self.oldvel.y) ~= 0 and vel.y == 0) or
			(math.abs(self.oldvel.z) ~= 0 and vel.z == 0) then
			
			minetest.sound_play("open_ai_line_break", {
				pos = pos2,
				max_hear_distance = 10,
				gain = 10.0,
			})
			self.object:remove()
		end
		end
		
		self.reel(self)
		
		
		
		local pos  = self.object:getpos()
		local pos2 = self.owner:getpos()
		local c = 0
		if self.owner:is_player() then --so mobs can wield fishing poles
			c = 1
		end
		local vec = {x=pos.x-pos2.x,y=pos.y-pos2.y-c, z=pos.z-pos2.z}
		
		--hurt mobs and players
		hurt_mobs(self,pos)
		
		--print(vec.x,vec.z)
		self.yaw = math.atan(vec.z/vec.x)+ math.pi / 2
		
		if pos2.x > pos.x then
			self.yaw = self.yaw+math.pi
		end
		
		--do max velocity if distance is over 2 else stop moving
		local distance = vector.distance(pos,pos2)
		
		--collect reeled in lures
		if distance < 2 and self.in_water == true then
			minetest.sound_play("open_ai_collect_lure", {
				pos = pos2,
				max_hear_distance = 10,
				gain = 10.0,
			})
			self.owner:set_wielded_item("open_ai:fishing_pole_lure")
			self.object:remove()
		end
		
		--run line visual
		self.line_visual(self,distance,pos,vec)
		
		--how lures move
		self.lure_movement(self,distance)
		
	end,
	--how lures move
	lure_movement = function(self,distance)
		local vel  = self.object:getvelocity()
		if distance < 2 then
			distance = 0
		end
		
		local x   = math.sin(self.yaw) * -self.velocity
		local z   = math.cos(self.yaw) * self.velocity
		
		--self.velocity = distance
		local gravity = -10
		self.float(self)	
		if self.liquid ~= 0 and self.liquid ~= nil then
			gravity = self.liquid
		end
		if self.in_water == false and self.liquid ~= 0 then
			self.in_water = true
		end
		--only do goal y velocity if floating up
		if self.in_water == true then
		if gravity == -10 then
			self.object:setacceleration({x=(x - vel.x)*self.acceleration,y=-10,z=(z - vel.z)*self.acceleration})
		else
			self.object:setacceleration({x=(x - vel.x)*self.acceleration,y=(gravity-vel.y)*self.acceleration,z=(z - vel.z)*self.acceleration})
		end
		end
		self.oldvel = vel
	end,
	--hurt mobs and players if in radius
	hurt_mobs = function(self,pos)
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
			if (object:is_player() and object ~= self.owner) or (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
				object:punch(self.object, 1.0,  {
					full_punch_interval=1.0,
					damage_groups = {fleshy=1}
				}, vec)
			
			end
		end
	
	end,
	--checks if player is holding fishing pole
	check_pole = function(self)
		if self.owner:get_wielded_item():to_string() ~= "" then
			if self.owner:get_wielded_item():to_table().name ~= "open_ai:fishing_pole_no_lure" then
				minetest.sound_play("open_ai_line_break", {
					pos = pos2,
					max_hear_distance = 10,
					gain = 10.0,
				})
				self.object:remove()
				
			end
		end
	end,


	--checks if player is reeling in
	reel = function(self)

		--reeling in
		if self.owner:get_player_control().RMB == true then
			self.velocity = self.speed
		else
			self.velocity = 0
		end
	end,
	--makes lure float
	float = function(self)
		self.liquid = minetest.registered_nodes[minetest.get_node(self.object:getpos()).name].liquid_viscosity
		if self.liquid ~= 0 then
			self.velocity = self.liquid
		end
	end,
	
	--a visual of the leash
	line_visual = function(self,distance,pos,vec)
		--multiply times two if too far
		distance = math.floor(distance*2) --make this an int for this function
		
		--divide the vec into a step to run through in the loop
		local vec_steps = {x=vec.x/distance,y=vec.y/distance,z=vec.z/distance}
		
		--add particles to visualize leash
		for i = 1,math.floor(distance) do
			minetest.add_particle({
				pos = {x=pos.x-(vec_steps.x*i), y=pos.y-(vec_steps.y*i), z=pos.z-(vec_steps.z*i)},
				velocity = {x=0, y=0, z=0},
				acceleration = {x=0, y=0, z=0},
				expirationtime = 0.01,
				size = 1,
				collisiondetection = false,
				vertical = false,
				texture = "open_ai_leash_particle.png",
			})
		end
	
	end,
	on_step = function(self, dtime)
		self.lure_function(self,dtime)
	end,
})
