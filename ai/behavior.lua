ai_library.behavior = {}
ai_library.behavior.__index = ai_library.behavior

--behavior on step
function ai_library.behavior:on_step(self,dtime)
	self.ai_library.behavior:decision(self,dtime)
end

--how a mob thinks
function ai_library.behavior:decision(self,dtime)
	--add to self counters
	self.behavior_timer = self.behavior_timer + dtime
	
	--debug test to change behavior
	if (self.following == false and self.behavior_timer >= self.behavior_timer_goal and self.leashed == false) or self.sitting == true then
		
		
		if self.sitting == true then
			self.state = 0
		else
			self.state = math.random(0,1) --2 is needed for all testing
		end
		
		--normal direction changing, or if jump_only, only change direction on ground
		if self.jump_only ~= true or (self.jump_only == true and self.vel.y == 0) then
			--standing
			if self.state == 0 then
				self.yaw = (math.random(0, 360)/360) * (math.pi*2) --double pi to allow complete rotation
				self.velocity = 0
				self.behavior_timer_goal = math.random(self.behavior_change_min,self.behavior_change_max)
				self.behavior_timer = 0
				--make fish swim up and down randomly
				if self.liquid_mob == true then
					self.swim_pitch = 0
				end
			--walking, jumping, swimming
			elseif self.state == 1 then
				--print("Changed direction")
				--self.goal = {x=math.random(-self.max_velocity,self.max_velocity),y=math.random(-self.max_velocity,self.max_velocity),z=math.random(-self.max_velocity,self.max_velocity)}
				self.yaw = (math.random(0, 360)/360) * (math.pi*2) --double pi to allow complete rotation
				self.velocity = math.random(1,self.max_velocity)+math.random()
				self.behavior_timer_goal = math.random(self.behavior_change_min,self.behavior_change_max)
				self.behavior_timer = 0
				--make fish swim up and down randomly
				if self.liquid_mob == true then
					self.swim_pitch = math.random(-self.max_velocity,self.max_velocity)+(math.random()*math.random(-1,1))
				end
			--build a structure
			elseif self.state == 2 then
				self.building = true
				
				self.yaw = (math.random(0, 360)/360) * (math.pi*2) --double pi to allow complete rotation
				self.velocity = 0
				self.behavior_timer_goal = math.random(self.behavior_change_min,self.behavior_change_max)
				self.behavior_timer = 0
				--make fish swim up and down randomly
				if self.liquid_mob == true then
					self.swim_pitch = 0
				end
			end
		end			
	end		
end
