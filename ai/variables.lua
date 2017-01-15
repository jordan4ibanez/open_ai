--the variables class
ai_library.variables = {}
ai_library.variables.__index = ai_library.variables

--update variables
function ai_library.variables:on_step(self,dtime)
	self.ai_library.variables:add_variables(self,dtime)
	--remember total age and time existing since spawned
	self.age = self.age + dtime
	self.time_existing = self.time_existing + dtime
	self.update_timer = self.update_timer + dtime
end


--gets current variables
function ai_library.variables:get_current_variables(self)
	--save these variables on each step
	self.mpos = self.object:getpos()
	self.liquid = minetest.registered_nodes[minetest.get_node({x=self.mpos.x,y=self.mpos.y+self.center,z=self.mpos.z}).name].liquid_viscosity
	self.vel = self.object:getvelocity()
	
	--reset these variables on each step
	self.c_x = 0
	self.c_z = 0
end

--stores old variables
function ai_library.variables:get_old_variables(self)
	self.old_vel = table.copy(self.vel)
	self.old_mpos = table.copy(self.mpos)
	self.old_liquid = self.liquid
	self.old_hp = self.object:get_hp()
	self.old_liquid = self.liquid
	if self.target_pos then
		self.old_target_pos = self.target_pos
	end
	self.old_following = self.following
end

--add arbitrary variables
function ai_library.variables:add_variables(self,dtime)
	if self.fall_damaged_timer then
		self.fall_damaged_timer = self.fall_damaged_timer + dtime
	end
end
