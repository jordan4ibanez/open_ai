--[[

make an api to create fishing poles and lures

]]--

--fishing items and entities
minetest.register_craftitem("open_ai:fishing_pole_lure", {
	description = "Fishing Pole (With Lure)",
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
	description = "Fishing Pole",
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
	on_land = false,
	attached = nil,
	rod_pull = 0,
	test_pull = 0,
	reeling = false,
	is_lure = true,
	
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
		self.reel(self)
	
		self.check_pole(self)
		local pos = self.object:getpos()
		local vel  = self.object:getvelocity()
		--remove if owner is not in game
		if not self.owner or not self.owner:is_player() then
			self.object:remove()
			return
		end
		
		--find if on land
		self.touch_land(self)
		
		
		local pos  = self.object:getpos()
		local pos2 = self.owner:getpos()
		local c = 0
		if self.owner:is_player() then --so mobs can wield fishing poles
			c = 1
		end
		local vec = {x=pos.x-pos2.x,y=pos.y-pos2.y-c, z=pos.z-pos2.z}
		
		--allow players to pull up lines off a bridge or ledge
		self.test_pull = vector.distance({x=pos.x,y=0,z=pos.z},{x=pos2.x,y=0,z=pos2.z})
		self.rod_pull = vec.y
		
		--hurt mobs and players
		self.collect(self,pos)
		
		--print(vec.x,vec.z)
		self.yaw = math.atan(vec.z/vec.x)+ math.pi / 2
		
		if pos2.x > pos.x then
			self.yaw = self.yaw+math.pi
		end
		
		--do max velocity if distance is over 2 else stop moving
		local distance = vector.distance(pos,pos2)
		
		--collect reeled in lures
		if distance < 2 and (self.in_water == true or self.on_land == true) then
			minetest.sound_play("open_ai_collect_lure", {
				pos = pos2,
				max_hear_distance = 10,
				gain = 10.0,
			})
			--stop reel sound
			if self.reel_sound ~= nil then
				minetest.sound_stop(self.reel_sound)
				self.reel_sound = nil
			end
			if self.attached then
				self.attached:set_detach()
				self.attached:setvelocity({x=vec.x*-5,y=math.abs(self.rod_pull)+6,z=vec.z*-5})
				if self.attached:get_luaentity() and self.attached:get_luaentity().mob == true and self.attached:get_luaentity().liquid_mob == true then
					print("on_land")
					self.attached:get_luaentity().on_land = true
				end
			end
			self.owner:set_wielded_item("open_ai:fishing_pole_lure")
			self.object:remove()
		end
		
		--run line visual
		self.line_visual(self,distance,pos,vec)
		
		--how lures move
		self.lure_movement(self,distance)
		
	end,
	touch_land = function(self)
		local vel = self.object:getvelocity()
		local pos = self.object:getpos()
		--switch to on land mode
		if self.on_land == false and self.oldvel and self.in_water == false then
		if (self.oldvel.y <= 0 and vel.y == 0) then
			--on land
			self.velocity = 0
			self.on_land = true
		end
		end	
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
		--function on land or water
		if self.in_water == false and self.liquid ~= 0 then
			self.in_water = true
		end
		if self.on_land == true and self.in_water == true then
			self.on_land = false
		end
		
		--allow players to drag lures over nodes and pull straight up
		if self.on_land == true or self.in_water == true then
		if (x~= 0 and vel.x == 0) or (z ~= 0 and vel.z == 0) then
			gravity = self.velocity
		elseif self.rod_pull < 0 and self.test_pull < 2 and self.reeling == true then
			gravity = (self.rod_pull-3)*-1
		end
		end
		
		--only do goal y velocity if floating up
		if self.in_water == true or self.on_land == true then
		if gravity == -10 then
			self.object:setacceleration({x=(x - vel.x)*self.acceleration,y=-10,z=(z - vel.z)*self.acceleration})
		elseif self.test_pull >= 2 then
			self.object:setacceleration({x=(x - vel.x)*self.acceleration,y=(gravity-vel.y)*self.acceleration,z=(z - vel.z)*self.acceleration})
		else --reel straight up slightly in front of player
			self.object:setacceleration({x=(0 - vel.x)*self.acceleration,y=(gravity-vel.y)*self.acceleration,z=(0 - vel.z)*self.acceleration})
		end
		end
		self.oldvel = vel
	end,
	--collect mob or player if in radius
	collect = function(self,pos)
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
			if self.attached == nil then
			if (object:is_player() and object ~= self.owner) or (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
				object:set_attach(self.object, "", {x=0, y=0, z=0}, {x=0, y=0, z=0})
				self.attached = object
			
			end
			end
		end
	
	end,
	--checks if player is holding fishing pole
	check_pole = function(self)
		local breakline = false
		if self.owner and self.owner:get_wielded_item():to_string() ~= "" then
			if self.owner:get_wielded_item():to_table().name ~= "open_ai:fishing_pole_no_lure" then
				breakline = true
			end
		elseif self.owner and self.owner:get_wielded_item():to_string() == "" then
			breakline = true
		end
		if breakline == true then
			minetest.sound_play("open_ai_line_break", {
				pos = pos2,
				max_hear_distance = 10,
				gain = 10.0,
			})
			--stop reel sound
			if self.reel_sound ~= nil then
				minetest.sound_stop(self.reel_sound)
				self.reel_sound = nil
			end
			self.object:remove()
		end
	end,


	--checks if player is reeling in
	reel = function(self)

		--reeling in
		if self.owner and self.owner:get_player_control().RMB == true then
			self.velocity = self.speed
			self.reeling = true
			--reel sound attached to player
			if self.reel_sound == nil then
				self.reel_sound = minetest.sound_play("open_ai_reel", {
					max_hear_distance = 10,
					gain = 10.0,
					object = self.owner,
					loop = true,
				})
			end
		else
			--stop reel sound
			if self.reel_sound ~= nil then
				minetest.sound_stop(self.reel_sound)
				self.reel_sound = nil
			end
			self.reeling = false
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
