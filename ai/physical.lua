--game engine physical properties of mobs
ai_library.physical = {}
ai_library.physical.__index = ai_library.physical


--physical on step
function ai_library.physical:on_step(self,dtime)
	self.ai_library.physical:change_size(self,dtime)
	self.ai_library.physical:velocity_damage(self,dtime)
end

--How a mob changes it's size
function ai_library.physical:change_size(self,dtime)
	--initialize this variable here for testing
	if self.grow_timer == nil or self.size_change == nil then
		--print("returning nil")
		return
	end
	self.grow_timer = self.grow_timer - 0.1
	
	--limit ray size
	if self.grow_timer <= 0 or ((self.scale_size > 5 and self.size_change > 0) or (self.scale_size < 0.2 and self.size_change < 0)) then
		--print("size too big or too small")
		self.grow_timer = nil
		self.size_change = nil
		return
	end
	--change based on variable
	local size_multiplier = 1.1
	if self.size_change < 0 then
		--print("shrink")
		self.scale_size = self.scale_size / 1.1
		
		--iterate through collisionbox
		for i = 1,table.getn(self.collisionbox) do
			self.collisionbox[i] = self.collisionbox[i] / size_multiplier
		end
		self.visual_size = {x=self.visual_size.x / size_multiplier, y = self.visual_size.y / size_multiplier}				
	elseif self.size_change > 0 then
		self.scale_size = self.scale_size * 1.1
		--iterate through collisionbox
		for i = 1,table.getn(self.collisionbox) do
			self.collisionbox[i] = self.collisionbox[i] * size_multiplier
		end
		self.visual_size = {x=self.visual_size.x * size_multiplier, y = self.visual_size.y * size_multiplier}
	end
	self.height       = self.collisionbox[2]
	self.width        = math.abs(self.collisionbox[1])
	--vars for collision detection and floating
	self.overhang     = self.collisionbox[5]
	--create variable that can be added to pos to find center
	self.center = (self.collisionbox[5]+self.collisionbox[2])/2
				
	--attempt to set the collionbox to internal yadayada
	self.object:set_properties({collisionbox = self.collisionbox,visual_size=self.visual_size})
	
end


--mob velocity damage x,y, and z
function ai_library.physical:velocity_damage(self,dtime)
	local vel = self.object:getvelocity()
	if self.old_vel then
	if  (vel.x == 0 and self.old_vel.x ~= 0) or
		(vel.y == 0 and self.old_vel.y ~= 0) or
		(vel.z == 0 and self.old_vel.z ~= 0) then
		
		local diff = vector.subtract(vel, self.old_vel)
		
		diff.x = math.ceil(math.abs(diff.x))
		diff.y = math.ceil(math.abs(diff.y))
		diff.z = math.ceil(math.abs(diff.z))
		
		local punches = 0
		
		--2 hearts of damage every 2 points over hurt_velocity
		if diff.x > self.hurt_velocity then
			punches = punches + diff.x
		end
		if diff.y > self.hurt_velocity then
			punches = punches + diff.y
		end
		if diff.z > self.hurt_velocity then
			punches = punches + diff.z
		end
		--hurt entity and set texture modifier
		if punches > 0 then
			self.object:punch(self.object, 1.0,  {
				full_punch_interval=1.0,
				damage_groups = {fleshy=punches}
			}, nil)
			
		end
	end
	end
	--this is created here because it is unnecasary to define it in initial properties
	--self.old_vel = vel
end
