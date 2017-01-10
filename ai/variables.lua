--the variables class
ai_library.variables = {}
ai_library.variables.__index = ai_library.variables

--update variables
function ai_library.variables:on_step(self,dtime)
	--remember total age and time existing since spawned
	self.age = self.age + dtime
	self.time_existing = self.time_existing + dtime
	self.update_timer = self.update_timer + dtime
end


--gets current variables
function ai_library.variables:get_current_variables(self)
	--save these variables on each step
	self.mpos = self.object:getpos()
	self.liquid = minetest.registered_nodes[minetest.get_node(self.mpos).name].liquid_viscosity
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
end			
