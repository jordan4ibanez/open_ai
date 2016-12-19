 --PROJECT GOALS
 --[[
 List of individual goals
 
 0 is mainly function ideas/notes on how to execute things
 
 0.) Make functions less linear and have sub functions after the proof of concept is completed
 
 0.) check if mob is hanging off the side of a node, somehow
 
 0.) only check nodes using voxelmanip when in new floored position
 
 0.) minetest.line_of_sight(pos1, pos2, stepsize) to check if a mob sees player
 
 0.) minetest.find_path(pos1,pos2,searchdistance,max_jump,max_drop,algorithm)
 0.) do pathfinding by setting yaw towards the next point in the table
 0.) only run this function if the goal entity/player is in a new node to prevent extreme lag
 
 0.) sneaking mobs, if a mob is sneaking, vs running at you, make no walking sounds
  
 0.) Make mobs define wether they float or sink in water
 
 0.) running particles
 
 0.) Make mobs collision detection detect boats, minecarts, and other physical things, somehow, possibly just don't collide with
 0.) item entities
 0.) Possibly lump movement in with collision detection in a few functions
     
 0.) when mob gets below 0.1 velocity do set velocity to make it stand still ONCE so mobs don't float and set acceleration to 0
 
 1.) lightweight ai that walks around, stands, does something like eat grass
 
 2.) make mobs drown if drown = true in definition
 
 3.) Make mobs avoid other mobs and players when walking around
  
 5.) attacking players
 
 6.) drop items
 
 7.) utility mobs
 
 8.) underwater and flying mobs
 
 9.) pet mobs
 
 10.) mobs climb ladders, and are affected by nodes like players are
 0.) if the pathfinding goal is unreachable then don't pathfind
 0.) else if pathfinding, try to find ladder in area if ladder = true in definition, then climb the ladder to the goal
 
 11.) have mobs with player mesh able to equip armor and wield an item with armor mod
 
 Or in other words, mobs that add fun and aesthetic to the game, yet do not take away performance
 
 This is my first "professional" level mod which I hope to complete
 
 This is a huge undertaking, I will sometimes take breaks, days in between to avoid rage quitting, but will try to
 make updates as frequently as possible
 
 Rolling release to make updates in minetest daily (git) to bring out the best in the engine
 
 I use tab because it's the easiest for me to follow in my editor, I apologize if this is not the same for you
 
 I am also not the best speller, feel free to call me out on spelling mistakes
 
 CC0 to embrace the GNU principles followed by Minetest, you are allowed to relicense this to your hearts desires
 This mod is designed for the community's fun
 
 Idea sources
 https://en.wikipedia.org/wiki/Mob_(video_gaming)
 
 Help from tenplus1 https://github.com/tenplus1/mobs_redo/blob/master/api.lua
 
 Help from pilzadam https://github.com/PilzAdam/mobs/blob/master/api.lua
 
 --notes on how to create mobs
 the height will divide by 2 to find the height, make your mob mesh centered in the editor to fit centered in the collisionbox
 This is done to use the actual center of mobs in functions, same with width
 
 
 ]]--

--global to enable other mods/packs to utilize the ai
open_ai = {}

open_ai.register_mob = function(name,def)
	minetest.register_entity(name, {
		--Do simpler definition variables for ease of use
		mob          = true,
		collisionbox = {-def.width/2,-def.height/2,-def.width/2,def.width/2,def.height/2,def.width/2},
		height       = def.height,
		width        = def.width,
		physical     = def.physical,
		collide_with_objects = false, -- for magnetic collision
		max_velocity = def.max_velocity,
		acceleration = def.acceleration,
		hp_max       = def.health,
		automatic_face_movement_dir = def.automatic_face_movement_dir, --for smoothness
		
		--Aesthetic variables
		visual   = def.visual,
		mesh     = def.mesh,
		textures = def.textures,
		makes_footstep_sound = def.makes_footstep_sound,
		animation = def.animation,
		
		
		--Behavioral variables
		behavior_timer      = 0, --when this reaches behavior change goal, it changes states and resets
		behavior_timer_goal = 0, --randomly selects between min and max time to change direction
		behavior_change_min = def.behavior_change_min,
		behavior_change_max = def.behavior_change_max,
		update_timer        = 0,
		follow_item         = def.follow_item,
		
		
		--Physical variables
		old_position = nil,
		yaw          = 0,
		jump_height = def.jump_height,
		
		
		--Pathfinding variables
		path = {},
		target = "singleplayer",
		following = false,
		
		
		
		--what mobs do when created
		on_activate = function(self, staticdata, dtime_s)
			--debug for movement
			self.velocity = math.random(1,self.max_velocity)+math.random()
			
			self.behavior_timer_goal = math.random(self.behavior_change_min,self.behavior_change_max)
			
			local pos = self.object:getpos()
			pos.y = pos.y - (self.height/2) -- the bottom of the entity
			--self.old_position = vector.floor(pos)
			
			self.yaw = (math.random(0, 360)/360) * (math.pi*2)
			if self.user_defined_on_activate then
				self.user_defined_on_activate(self, staticdata, dtime_s)
			end
		end,
		--user defined function
		user_defined_on_activate = def.on_activate,
		
		
		
		
		--decide wether an entity should jump or change direction
		jump = function(self)
			local pos = self.object:getpos()
			
			--only jump when path step is higher up
			if self.following == true then
				--only try to jump if pathfinding exists
				if self.path and table.getn(self.path) > 1 then
					--don't jump if current position is equal to or higher than goal					
					if vector.round(pos).y >= self.path[2].y then
						return
					end
				--don't jump if pathfinding doesn't exist
				else
					return
				end
				
					
					
				--find out if node is underneath
				local under_node = minetest.get_node({x=pos.x,y=pos.y-(self.height/2)-0.1,z=pos.z}).name
				local vel = self.object:getvelocity()
				if minetest.registered_nodes[under_node].walkable == true then
					--print("jump")
					self.object:setvelocity({x=vel.x,y=self.jump_height,z=vel.z})
				end
			--stupidly jump
			elseif self.following == false then
			
				--find out if node is underneath
				local under_node = minetest.get_node({x=pos.x,y=pos.y-(self.height/2)-0.1,z=pos.z}).name
				
				if minetest.registered_nodes[under_node].walkable == false then
					--print("JUMP FAILURE")
					return
				end
				
				
				local vel = self.object:getvelocity()
				
				--commented out section is to use vel to get yaw dir, hence redeffing it as local yaw verus self.yaw
				local yaw = self.yaw--(math.atan(vel.z / vel.x) + math.pi / 2)
							
				--don't check if not moving instead change direction
				if yaw == yaw then --check for nan
					--turn it into usable position modifier
					local x = (math.sin(yaw) * -1)*1.5
					local z = (math.cos(yaw))*1.5
					local node = minetest.get_node({x=pos.x+x,y=pos.y,z=pos.z+z}).name
					if minetest.registered_nodes[node].walkable == true then
						--print("jump")
						self.object:setvelocity({x=vel.x,y=self.jump_height,z=vel.z})
					end			
				end
			end

		end,
		
		--this runs everything that happens when a mob update timer resets
		update = function(self,dtime)
			self.update_timer = self.update_timer + dtime
			if self.update_timer >= 0.1 then
				self.update_timer = 0
				self.jump(self)
				self.path_find(self)			
			end

		end,
		
		--how a mob thinks
		behavior = function(self,dtime)
			self.behavior_timer = self.behavior_timer + dtime

			local vel = self.object:getvelocity()
	
			--debug to find node the mob exists in
			local testpos = self.object:getpos()
			testpos.y = testpos.y-- - (self.height/2) -- the bottom of the entity
			local vec_pos = vector.floor(testpos) -- the node that the mob exists in
		
			--debug test to change behavior
			if self.following == false and self.behavior_timer >= self.behavior_timer_goal then
				--print("Changed direction")
				--self.goal = {x=math.random(-self.max_velocity,self.max_velocity),y=math.random(-self.max_velocity,self.max_velocity),z=math.random(-self.max_velocity,self.max_velocity)}
				self.yaw = (math.random(0, 360)/360) * (math.pi*2) --double pi to allow complete rotation
				self.velocity = math.random(1,self.max_velocity)+math.random()
				self.behavior_timer_goal = math.random(self.behavior_change_min,self.behavior_change_max)
				self.behavior_timer = 0
				print("randomly moving around")
			elseif self.following == true then
				--print("following in behavior function")
			end		
		end,
		
		--how the mob collides with other mobs and players
		collision = function(self)
			local pos = self.object:getpos()
			local vel = self.object:getvelocity()
			local x   = 0
			local z   = 0
			for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, self.width)) do
				--only collide with other mobs and players
				if object:is_player() or (object:get_luaentity().mob == true and object ~= self.object) then
					local pos2 = object:getpos()
					local vec  = {x=pos.x-pos2.x, z=pos.z-pos2.z}
					--push away harder the closer the collision is, could be used for mob cannons
					--+0.5 to add player's collisionbox, could be modified to get other mobs widths
					local force = (self.width+0.5) - vector.distance({x=pos.x,y=0,z=pos.z}, {x=pos2.x,y=0,z=pos2.z})--don't use y to get verticle distance
										
					--modify existing value to magnetize away from mulitiple entities/players
					x = x + (vec.x * force) * 20
					z = z + (vec.z * force) * 20
					
				end
			end
			return({x,z})
		end,
		
		-- how a mob moves around the world
		movement = function(self)
			
			local collide_values = self.collision(self)
			local c_x = collide_values[1]
			local c_z = collide_values[2]
			--print(c_x,c_z)
			--move mob to goal velocity using acceleration for smoothness
			local vel = self.object:getvelocity()
			local x   = math.sin(self.yaw) * -self.velocity
			local z   = math.cos(self.yaw) * self.velocity
			
			self.object:setacceleration({x=(x - vel.x + c_x)*self.acceleration,y=-10,z=(z - vel.z + c_z)*self.acceleration})

		end,
		
		--check if a mob should follow a player when holding an item
		check_to_follow = function(self)
			--print(dump(self.follow_item))
			local pos = self.object:getpos()
			for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 10)) do
				if object:is_player() then
					local item = object:get_wielded_item()
					if item:to_string() ~= "" and item:to_table().name == self.follow_item then
						self.following = true
					else
						self.following = false
					end
				end
			end
		end,

		
		--path finding towards goal - can be used to find food or water, or attack players or other mobs
		path_find = function(self)
			if self.following == true then
				self.velocity = self.max_velocity
			
				local pos1 = self.object:getpos()
				
				local pos2 = minetest.get_player_by_name(self.target):getpos() -- this is the goal debug
				
				local path = nil
				
				
				--if can't get goal then don't pathfind
				if not pos2 then
					path = self.path
				else
					path = minetest.find_path(pos1,pos2,5,1,3,"Dijkstra")
				end
				
				
				
				--if in path step, delete it to not get stuck in place
				
				local vec_pos = vector.round(pos1)
				
				--print(vec_pos.x,vec_pos.z, self.path[2].x,self.path[2].z)
				
				if table.getn(self.path) > 1  then
					if vec_pos.x == self.path[2].x and vec_pos.z == self.path[2].z then
						print("delete first step")
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
				
				--create a path internally
				if path then
					self.path = path
				end
				
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
		end,
		--how the mob sets it's mesh animation
		set_animation = function(self)
			local vel = self.object:getvelocity()
			local speed = (math.abs(vel.x)+math.abs(vel.z))*self.animation.speed_normal --check this
			
			self.object:set_animation({x=self.animation.walk_start,y=self.animation.walk_end}, speed, 0, true)
		end,
		
		--what happens when you hit a mob
		on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		
			if self.user_defined_on_punch then
				self.user_defined_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
			end
		end,
		--user defined
		user_defined_on_punch = def.on_punch,
		
		--what happens when you right click a mob
		on_rightclick = function(self, clicker)
			if self.user_defined_on_rightclick then
				self.user_defined_on_rightclick(self, clicker)
			end
		end,
		--user defined
		user_defined_on_rightclick = def.on_rightclick,
		
		--what mobs do on each server step
		on_step = function(self,dtime)
			self.check_to_follow(self)
			self.behavior(self,dtime)
			self.update(self,dtime)
			self.set_animation(self)
			self.movement(self)
			if self.user_defined then
				self.user_defined_on_step(self,dtime)
			end
		end,
		
		--a function that users can define
		user_defined_on_step = def.on_step,
		
		
		
	})
end

--this is a test mob which can be used to learn how to make mobs using open ai - uses pilzadam's sheep mesh
open_ai.register_mob("open_ai:test",{
	--mob physical variables
	height = 0.7, --divide by 2 for even height
	width  = 0.7, --divide by 2 for even width
	physical = true, --if the mob collides with the world, false is useful for ghosts
	jump_height = 5, --how high a mob will jump
	health = 20,
	
	--mob movement variables
	max_velocity = 3, --set the max velocity that a mob can move
	acceleration = 3, --how quickly a mob gets up to max velocity
	behavior_change_min = 3, -- the minimum time a mob will wait to change it's behavior
	behavior_change_max = 5, -- the max time a mob will wait to change it's behavior
	
	--mob aesthetic variables
	visual = "mesh", --can be changed to anything for flexibility
	mesh = "mobs_sheep.x",
	textures = {"mobs_sheep.png"},
	animation = { --the animation keyframes and speed
		speed_normal = 10,--animation speed
		stand_start = 0,--standing animation start and end
		stand_end = 80,
		walk_start = 81,--walking animation start and end
		walk_end = 100,
	},
	automatic_face_movement_dir = -90.0, --what direction the mob faces in
	makes_footstep_sound = true, --if a mob makes footstep sounds
	
	--mob behavior variables
	follow_item = "default:dry_grass_1", --if you're holding this a peaceful mob will follow you
	
	--user defined functions
	on_step = function(self,dtime)
		print("test")
	end,
	on_activate = function(self, staticdata, dtime_s)
		print("activating")
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		print("hit")
	end,
	on_rightclick = function(self, clicker)
		print("right clicked")
	end,
})
