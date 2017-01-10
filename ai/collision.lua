--collision detection with other objects
ai_library.collision = {}
ai_library.collision.__index = ai_library.collision

ai_library.collision.objects_in_radius = minetest.get_objects_inside_radius

--how the mob collides with other mobs and players
function ai_library.collision:collide(self,dtime)
	local pos = self.object:getpos()
	pos.y = pos.y + self.height -- check bottom of mob
	
	for _,object in ipairs(self.ai_library.collision.objects_in_radius(pos, 1)) do
		--only collide with other mobs and players
					
		--add exception if a nil entity exists around it
		if object:is_player() or (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
			local pos2 = object:getpos()
			local vec  = {x=pos.x-pos2.x, z=pos.z-pos2.z}
			--push away harder the closer the collision is, could be used for mob cannons
			--+0.5 to add player's collisionbox, could be modified to get other mobs widths
			local force = (1) - vector.distance({x=pos.x,y=0,z=pos.z}, {x=pos2.x,y=0,z=pos2.z})--don't use y to get verticle distance
								
			--modify existing value to magnetize away from mulitiple entities/players
			self.c_x = self.c_x + (vec.x * force) * 20
			self.c_z = self.c_z + (vec.z * force) * 20
			
		else
			self.ai_library.collision:ride_object(self,object)
		end
	end
end


--how a mob rides an object
function ai_library.collision:ride_object(self,object)
	if not object:is_player() and 
	self.rides_cart == true and 
	(object:get_luaentity() and 
	object ~= self.object and 
	object:get_luaentity().old_dir and 
	object:get_luaentity().driver == nil) then
		self.ai_library.interaction:ride_in_cart(self,object)
	end
end
