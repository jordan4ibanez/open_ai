--the pathfind class
ai_library.pathfind = {}
ai_library.pathfind.__index = ai_library.pathfind
--path finding towards goal - can be used to find food or water, or attack players or other mobs

--pathfinding on step
function ai_library.pathfind:on_step(self,dtime)
	self.ai_library.pathfind:update(self,dtime)
end

--update pathfind
function ai_library.pathfind:update(self,dtime)
	self.ai_library.pathfind:find_path(self)
end

function ai_library.pathfind:find_path(self)
	if self.following == true then
		self.velocity = self.max_velocity
	
		local pos1 = self.object:getpos()
		pos1.y = pos1.y + self.height
		
		self.target_pos = vector.round(self.target:getpos()) -- this is the goal debug
				
		if not self.target:is_player() then
			self.target_pos.y = self.target_pos.y + self.target:get_luaentity().height
		end
		
		--local path = nil
		
		
		--try not to fall off nodes
		local eye_pos = self.object:getpos()
		eye_pos.y = eye_pos.y + self.overhang 
		
		local eye_pos2 = self.target:getpos()
		if self.target:is_player() then
			eye_pos2.y = eye_pos2.y + 1.5
		else
			eye_pos2.y = eye_pos2.y + self.target:get_luaentity().center + self.target:get_luaentity().overhang 
		end
		--[[
		minetest.add_particle({
			pos = pos1,
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = 1,
			size = 4,
			collisiondetection = false,
			vertical = false,
			texture = "default_dirt.png",
		})
		]]--
		local line_of_sight = minetest.line_of_sight(eye_pos, eye_pos2)
		
		--open voxel manip object
		
		local z_vec = vector.multiply(vector.normalize(vector.subtract(pos1, self.target_pos)),-1)
		
		local pathfind_bool = false
		
		
		
		if self.target_pos then
		local floorpos = vector.round(pos1)
		
		--avoid walking off cliffs
		for i = 1,2 do
			local node = minetest.get_node(vector.add({x=z_vec.x,y=-i,z=z_vec.z},floorpos)).name
			if minetest.registered_nodes[node].walkable ~= true then
				pathfind_bool = true
				break
			end			
		end
		end
		
		--avoid getting caught on wall
		local vel = self.object:getpos()
		local x = (math.sin(self.yaw) * -1) 
		local z = (math.cos(self.yaw))
		if ((vel.x == 0 and x ~= 0) or (vel.z == 0 and z ~= 0)) then
			pathfind_bool = true
		end
		
		--pathfind if target is too high
		if math.abs(vector.subtract(self.target_pos,pos1).y) > 1 then
			pathfind_bool = true
		end
		---
		--local line_of_sight = false
		
		if line_of_sight == true and pathfind_bool ~= true then
			--print("walking")
			self.path = {}
			
			local vec = vector.subtract(pos1, self.target_pos)
			
			self.yaw = math.atan(vec.z/vec.x)+ math.pi / 2
	
			if self.target_pos.x > pos1.x then
				self.yaw = self.yaw+math.pi
			end
			
		else
			--print("pathfinding")
			
			local old_equals_new = false
			
			if self.old_target_pos then
				old_equals_new = vector.equals(self.old_target_pos, self.target_pos)
			end
			
			--if can't get goal then don't pathfind
			if (self.target_pos and old_equals_new == false) or table.getn(self.path) == 0  then
				--print("finding new path")
				self.path = minetest.find_path(pos1,self.target_pos,10,1,2,"Dijkstra")
			end
			
			local vec_pos = vector.round(pos1)
			
			if self.path == nil then
				--print("find if in node")
			end
			
			local node_below = minetest.registered_nodes[minetest.get_node({x=vec_pos.x,y=vec_pos.y-1,z=vec_pos.z}).name].walkable
			
			--set position to closest node
			if node_below == false then
				--if minetest.registered_nodes[minetest.get_node({x=pos1.x,y=pos1.y-2,z=pos1.z}).name].walkable then
				--	pos1.y = pos1.y - 1
				--else
					--find node standing on ,x or z
					
				--end
				--node direction
				local n_direction = vector.round(vector.direction(vec_pos, pos1))
				
				if n_direction.x ~= 0 or n_direction.z ~= 0 then
					if minetest.registered_nodes[minetest.get_node({x=vec_pos.x+n_direction.x,y=vec_pos.y-1,z=vec_pos.z}).name].walkable == true then
						pos1.x = pos1.x+n_direction.x
						--print("moving to z")
					elseif minetest.registered_nodes[minetest.get_node({x=vec_pos.x,y=vec_pos.y-1,z=vec_pos.z+n_direction.z}).name].walkable == true then
						pos1.z = pos1.z+n_direction.z
						--print("moving to x")
					--elseif minetest.registered_nodes[minetest.get_node({x=vec_pos.x+n_direction.x,y=vec_pos.y-1,z=vec_pos.z+n_direction.z}).name].walkable == true then
						--print("move diagnally")
					--	pos1.z = pos1.z-n_direction.z
					--	pos1.x = pos1.x-n_direction.x
					end
				end
				
				self.path = minetest.find_path(vector.round(pos1),self.target_pos,10,1,2,"Dijkstra")
			end
			--print(vec_pos.x,vec_pos.z, self.path[2].x,self.path[2].z)
			
			--{x=5,y=4,z=3}
			
			--{x=5,y=4,z=3} {x=6,y=4,z=3}
			
			--if in path step, delete it to not get stuck in place
			if table.getn(self.path) > 1  then
				--print(dump(self.path))
				if vector.equals(vec_pos, self.path[2]) then
					--print("delete first step")
					--self.path[1] = nil
					table.remove(self.path, 1)
				end
			end
			
			--Debug to visualize mob paths
			if table.getn(self.path) > 0 then
				for _,pos in pairs(self.path) do
					minetest.add_particle({
					pos = pos,
					velocity = {x=0, y=0, z=0},
					acceleration = {x=0, y=0, z=0},
					expirationtime = 0.1,
					size = 4,
					collisiondetection = false,
					vertical = false,
					texture = "heart.png",
					})
					
				end
			end
			
			--debug pathfinding
			local pos3 = nil
			
			--follow internal path
			if self.path and table.getn(self.path) > 1 then
			
				--the second step in the path
				pos3 = self.path[2]
				
				--display the path goal
				minetest.add_particle({
					pos = pos3,
					velocity = {x=0, y=0, z=0},
					acceleration = {x=0, y=0, z=0},
					expirationtime = 0.1,
					size = 4,
					collisiondetection = false,
					vertical = false,
					texture = "default_stone.png",
				})
			else
				--print("less than 2 steps, stop")
				self.velocity = 0
			end
			
			if pos3 then
				local vec = {x=pos1.x-pos3.x, z=pos1.z-pos3.z}
				--print(vec.x,vec.z)
				self.yaw = math.atan(vec.z/vec.x)+ math.pi / 2
				
				if pos3.x > pos1.x then
					self.yaw = self.yaw+math.pi
				end
			else
				--print("failure in pathfinding")
			end
		end
	--return table to nothing
	elseif self.old_following ~= self.following then
		self.path = {} 
	end
end
