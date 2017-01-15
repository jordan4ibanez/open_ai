--the movement class
ai_library.movement = {}
ai_library.movement.__index = ai_library.movement


--allow players to make mob jump when riding mobs,
--make function to jump, bool to check velocity
--moves bool - x and z for flopping and standing still

--the main onstep function for movement
function ai_library.movement:onstep(self,dtime)
	self.ai_library.movement:ridden(self)
	self.ai_library.collision:collide(self,dtime)
	self.ai_library.movement:apply_physics(self)
	self.ai_library.movement.jump:onstep(self,dtime)
end

--how a mob physically moves
function ai_library.movement:apply_physics(self)
	self.ai_library.movement:setwatervelocity(self)
	local vel = self.object:getvelocity()
	local x   = math.sin(self.yaw) * -self.velocity
	local z   = math.cos(self.yaw) * self.velocity	
	
	self.gravity = -10
	
	self.ai_library.movement:liquidgravity(self)
	
	self.ai_library.movement:leashpull(self)
	
	--land mob
	if self.liquid_mob ~= true then
		--jump only mobs
		if self.jump_only == true then
			--fall and stop because jump_only mobs only jump around to move
			if self.gravity == -10 and vel.y == 0 then 
				self.object:setacceleration({x=(0 - vel.x + self.c_x)*self.acceleration,y=self.gravity,z=(0 - vel.z + self.c_z)*self.acceleration})				
			--move around normally if jumping
			elseif self.gravity == -10 and vel.y ~= 0 then
				self.object:setacceleration({x=(x - vel.x + self.c_x)*self.acceleration,y=self.gravity,z=(z - vel.z + self.c_z)*self.acceleration})
			--allow jump only mobs to swim
			else 
				self.object:setacceleration({x=(x - vel.x + self.c_x)*self.acceleration,y=(self.gravity-vel.y)*self.acceleration,z=(z - vel.z + self.c_z)*self.acceleration})
			end				
		--normal walking mobs
		else
			--fall
			if self.gravity == -10 then
				self.object:setacceleration({x=(x - vel.x + self.c_x)*self.acceleration,y=self.gravity,z=(z - vel.z + self.c_z)*self.acceleration})				
			--swim
			else 
				self.object:setacceleration({x=(x - vel.x + self.c_x)*self.acceleration,y=(self.gravity-vel.y)*self.acceleration,z=(z - vel.z + self.c_z)*self.acceleration})
			end
		end
	--liquid mob
	elseif self.liquid_mob == true then
		--out of water
		if self.gravity == -10 and self.liquid == 0 then 
			self.object:setacceleration({x=(0 - vel.x + self.c_x)*self.acceleration,y=self.gravity,z=(0 - vel.z + self.c_z)*self.acceleration})
		--swimming
		else 
			self.object:setacceleration({x=(x - vel.x + self.c_x)*self.acceleration,y=(self.gravity-vel.y)*self.acceleration,z=(z - vel.z + self.c_z)*self.acceleration})
		end
	end	
	
end

--make land mobs slow down in water
function ai_library.movement:setwatervelocity(self)
	if self.liquid ~= 0 and self.liquid ~= nil and self.liquid_mob ~= true then
		self.velocity = self.liquid
	end
end

--make mobs sink or swim
function ai_library.movement:liquidgravity(self)
	--mobs that float float
	if self.float == true and self.liquid ~= 0 and self.liquid ~= nil then
		self.gravity = self.liquid
	--make mobs that can't swim sink to the bottom
	elseif (self.float == nil or self.float == false) and self.liquid ~= 0 and self.liquid ~= nil then
		self.gravity = -self.liquid
	end
	--make mobs swim in water, fall back into it, if jumped out
	if self.liquid_mob == true and self.liquid ~= 0 then
		self.gravity = self.swim_pitch
	end
end

--how mobs move around when a player is riding it
function ai_library.movement:ridden(self)
	--only allow owners to ride
	if self.tamed == true and self.attached ~= nil and self.attached:get_player_name() == self.owner_name then
		if self.attached:is_player() then
			self.yaw = self.attached:get_look_horizontal()
			if self.attached:get_player_control().up == true then
				if self.has_chair and self.has_chair == true then
					self.velocity = self.max_velocity * 1.5 --double the speed if wearing a chair
				else
					self.velocity = self.max_velocity
				end
				
			else
				self.velocity = 0
			end
		end
	end
end

--how the leash applies vertical force to the mob
function ai_library.movement:leashpull(self,x,z)
	--don't execute function
	if self.leashed ~= true then
		return
	end
	--exception for if mob spawns with player that is not the leash owner
	if not self.target or (self.target and self.target:is_player() and self.target:getpos() == nil) then
		self.target = nil
		self.target_name = nil
		self.leashed = false
		return
	end
	--exception for if mob spawns without other mob in world
	if not self.target or (self.target and self.target:getpos() == nil) then
		--print("fail mob")
		self.target = nil
		self.target_name = nil
		self.leashed = false	
		return			
	end

	local pos  = self.object:getpos()
	local pos2 = self.target:getpos()
	
	--auto configure the center of objects
	pos.y = pos.y + self.center
	if self.target:is_player() then
		pos2.y = pos2.y + 1
	else
		pos2.y = pos2.y + self.target:get_luaentity().center
	end
	
	local vec = {x=pos.x-pos2.x,y=pos.y-pos2.y, z=pos.z-pos2.z}
	--how strong a leash is pulling up a mob
	self.leash_pull = vec.y
	
	self.yaw = math.atan(vec.z/vec.x)+ math.pi / 2
	
	if pos2.x > pos.x then
		self.yaw = self.yaw+math.pi
	end
	
	--do max velocity if distance is over 2 else stop moving
	local distance_2d = vector.distance({x=pos.x,y=0,z=pos.z},{x=pos2.x,y=0,z=pos2.z})
	local distance_3d = vector.distance(pos,pos2)
	
	--run leash visual
	self.ai_library.aesthetic:leash_visual(self,distance_3d,pos,vec)
	
	--initialize a local variable
	local distance
	if distance_3d < 2 or distance_2d < 0.2 then
		distance = 0

	else
		distance = distance_3d
	end
	
	--how strong the elastic pull is
	local multiplyer = 3
	
	self.velocity = distance * multiplyer
	
	--vertical pull
	if (x~= 0 and self.vel.x == 0) or (z~= 0 and self.vel.z == 0) then
		self.gravity = self.velocity
	elseif self.leash_pull < -3 then
		self.gravity = (self.leash_pull+3)*-multiplyer
	end
end


--[[


--move mob to goal velocity using acceleration for smoothness

--stop constant motion if stopped
--if (math.abs(vel.x) < 0.1 and math.abs(vel.z) < 0.1) and (vel.x ~= 0 and vel.z ~= 0) and self.velocity == 0 then
--	self.object:setvelocity({x=0,y=vel.y,z=0})
--only apply gravity if stopped
--elseif self.velocity == 0 and (math.abs(vel.x) < 0.1 and math.abs(vel.z) < 0.1) then
--	self.object:setacceleration({x=0,y=-10,z=0})		
--stop motion if trying to stop
--elseif self.velocity == 0 and (math.abs(vel.x) > 0.1 or math.abs(vel.z) > 0.1) then
---	self.object:setacceleration({x=(0 - vel.x + c_x)*self.acceleration,y=-10,z=(0 - vel.z + c_z)*self.acceleration})				
--do normal things
--elseif self.velocity ~= 0 then
--end


]]--

--#################################################################

--the jump subclass
ai_library.movement.jump = {}
ai_library.movement.jump.__index = ai_library.movement.jump

--the main onstep function for jumping
function ai_library.movement.jump:onstep(self,dtime)
	self.ai_library.movement.jump:jumpcounter(self,dtime)
	self.ai_library.movement.jump:jumplogic(self)
end

--this adds the jump timer
function ai_library.movement.jump:jumpcounter(self,dtime)
	self.jump_timer = self.jump_timer + dtime
end

--the function to set velocity
function ai_library.movement.jump:jump(self,velcheck,move,checkifstopped)
	local vel = self.object:getvelocity() --use self.vel
	--check if standing on node or within jump timer
	if self.jump_timer < 0.5 or (velcheck == true and (vel.y ~= 0 or (self.old_vel and self.old_vel.y > 0) or (self.old_vel == nil))) then
		return
	end
	self.jump_timer = 0
	--check for nan
	if self.yaw ~= self.yaw then
		return
	end
	--if mob jumps with horizontal movement
	local x = 0
	local z = 0
	if move == true then
		x = (math.sin(self.yaw) * -1) * self.velocity
		z = (math.cos(self.yaw)) * self.velocity
	end
	--check if jump is needed
	if checkifstopped == true and not ((vel.x == 0 and x ~= 0) or (vel.z == 0 and z ~= 0)) then
		return
	end
	--jump
	self.object:setvelocity({x=x,y=self.jump_height,z=z})
	--execute player defined function
	if self.user_defined_on_jump then
		self.user_defined_on_jump(self)
	end
end

--jumping while pathfinding
function ai_library.movement.pathfinding_jump(self)
	local pos = self.object:getpos()
	pos.y = pos.y + self.center
	
	--only try to jump if pathfinding exists
	if self.path and table.getn(self.path) > 1 then
		--don't jump if current position is equal to or higher than goal			
		if vector.round(pos).y >= self.path[2].y then
			return
		end
		self.ai_library.movement.jump:jump(self,true,true,false)
	else
		self.ai_library.movement.jump:jump(self,true,true,true)
	end
	
end

--the logic the mobs use to jump
function ai_library.movement.jump:jumplogic(self)
	--if not liquid mob
	if self.liquid_mob ~= true then
		--if not jump only then execute normal jumping
		if self.jump_only ~= true then
			--only jump on it's own if player is not riding		
			if self.attached == nil then
				--land mob jumping states
				--pathfinding jump
				if self.following == true and self.leashed == false then
					self.ai_library.movement.pathfinding_jump(self)
				--stupidly jump on land
				elseif self.following == false and self.liquid == 0 and self.leashed == false then
					self.ai_library.movement.jump:jump(self,true,true,true)
				--stupidly jump in water
				elseif self.liquid ~= 0 then					
					self.ai_library.movement.jump:jump(self,false,true,true)
				end
			--jumping when riding
			elseif self.attached ~= nil then
				if self.attached:is_player() then
					if self.attached:get_player_control().jump == true then
						--jump only if standing on node
						if self.liquid == 0 then
							self.ai_library.movement.jump:jump(self,true,true,false)
						--always allowed to jump in water
						elseif self.liquid ~= 0 then
							self.ai_library.movement.jump:jump(self,false,true,true)
						end
					end
				end
			end
		--jump only mob
		else
			self.ai_library.movement.jump:jump(self,true,true,false)
		end
	--liquid mob 
	elseif self.liquid == 0 then
		--if caught then don't execute
		if self.object:get_attach() then
			return
		end
		--self.velocity = 0
		self.ai_library.movement.jump:jump(self,true,false,false)
		--play flop sound
		--minetest.sound_play("open_ai_flop", {
		--	pos = pos,
		--	max_hear_distance = 10,
		--	gain = 1.0,
		--})
	end
end
