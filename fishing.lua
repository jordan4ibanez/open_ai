--fishing items and entities
minetest.register_craftitem("open_ai:fishing_pole", {
	description = "Fishing Pole",
	inventory_image = "open_ai_fishing_pole.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local dir = user:get_look_dir()
		local pos = user:getpos()
		pos.y = pos.y + 1.5
		dir.x = dir.x * 10
		dir.y = dir.y * 10
		dir.z = dir.z * 10
		local lure = minetest.add_entity(pos, "open_ai:lure")
		lure:setvelocity({x=dir.x,y=dir.y,z=dir.z})
		lure:get_luaentity().owner = user
		
		print("make this fishing pole_no lure ")
		
		minetest.sound_play("open_ai_safari_ball_throw", {
			pos = pos,
			max_hear_distance = 10,
			gain = 10.0,
		})
	end,
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
		--remove self if player doesn't exist
		if self.owner == nil or not self.owner:is_player() then
			self.object:remove()
			return
		end
		local vel  = self.object:getvelocity()
		local pos  = self.object:getpos()
		local pos2 = self.owner:getpos()
		local c = 0
		if self.owner:is_player() then --so mobs can wield fishing poles
			c = 1
		end
		local vec = {x=pos.x-pos2.x,y=pos.y-pos2.y-c, z=pos.z-pos2.z}
		
		if self.owner:get_player_control().RMB == true then
			self.velocity = 10
		else
			self.velocity = 0
		end
		
		--print(vec.x,vec.z)
		self.yaw = math.atan(vec.z/vec.x)+ math.pi / 2
		
		if pos2.x > pos.x then
			self.yaw = self.yaw+math.pi
		end
		
		--do max velocity if distance is over 2 else stop moving
		local distance = vector.distance(pos,pos2)
		
		--run line visual
		self.line_visual(self,distance,pos,vec)
		
		if distance < 2 then
			distance = 0
		end
		
		local x   = math.sin(self.yaw) * -self.velocity
		local z   = math.cos(self.yaw) * self.velocity
		
		--self.velocity = distance
	--debug to float mobs for now
		local gravity = -10
		self.float(self)	
		if self.liquid ~= 0 and self.liquid ~= nil then
			gravity = self.liquid
		end
		if self.in_water == false and self.liquid ~= 0 then
			self.in_water = true
		end
		--only do goal y velocity if swimming up
		if self.in_water == true then
		if gravity == -10 then
			self.object:setacceleration({x=(x - vel.x)*self.acceleration,y=-10,z=(z - vel.z)*self.acceleration})
		else
			self.object:setacceleration({x=(x - vel.x)*self.acceleration,y=gravity-vel.y,z=(z - vel.z)*self.acceleration})
		end
		end
	end,
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
