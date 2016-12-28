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
 
 0.) Lasso that pulls mobs towards you without pathfinding
 
 0.) sneaking mobs, if a mob is sneaking, vs running at you, make no walking sounds
  
 0.) Make mobs define wether they float or sink in water
 
 0.) running particles
 
 0.) make mobs get hurt in nodes that deal player damage
 0.) make mobs slow down or bounce on nodes that do that to players
 
 0.) particles when falling in water 
 
 0.) Make mobs collision detection detect boats, minecarts, and other physical things, somehow, possibly just don't collide with
 0.) item entities
     
 0.) when mob gets below 0.1 velocity do set velocity to make it stand still ONCE so mobs don't float and set acceleration to 0
 
 0.) if mob stops moving and def.opens_doors = true and in door then open door to leave
 
 
 Fishing
 fish mobs are drawn to lures
 make fish mobs drown and flop around on land
  
  
  CURRENT:
  
  definable collision radius from center
  
  
  
  
 
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
 
 12.) Document each function with line number in release
 
 13.) Mobs that build structures
 
 14.) Traders
 14.) Traders can use stock gui or a 3d representation of a gui that shows the item physically in the world
 
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
open_ai.mob_count = 0
open_ai.max_mobs = 2000 -- limit the max number of mobs existing in the world

dofile(minetest.get_modpath("open_ai").."/leash.lua")
dofile(minetest.get_modpath("open_ai").."/safari_ball.lua")
dofile(minetest.get_modpath("open_ai").."/spawning.lua")
dofile(minetest.get_modpath("open_ai").."/fishing.lua")
dofile(minetest.get_modpath("open_ai").."/commands.lua")
dofile(minetest.get_modpath("open_ai").."/items.lua")


open_ai.register_mob = function(name,def)
	minetest.register_entity("open_ai:"..name, {
		--Do simpler definition variables for ease of use
		mob          = true,
		name         = "open_ai:"..name,
		
		collisionbox = def.collisionbox,--{-def.width/2,-def.height/2,-def.width/2,def.width/2,def.height/2,def.width/2},
		height       = def.collisionbox[2], --sample from bottom of collisionbox - absolute for the sake of math
		width        = math.abs(def.collisionbox[1]), --sample first item of collisionbox
		--vars for collision detection and floating
		overhang     = def.collisionbox[5],
		--create variable that can be added to pos to find center
		center = (def.collisionbox[5]+def.collisionbox[2])/2,
		
		collision_radius = def.collision_radius+0.5, -- collision sphere radius
		
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
		visual_size = {x=def.visual_size.x, y=def.visual_size.y},
		eye_offset = def.eye_offset,
		visual_offset = def.visual_offset,
		player_pose = def.player_pose,
		
		
		--Behavioral variables
		behavior_timer      = 0, --when this reaches behavior change goal, it changes states and resets
		behavior_timer_goal = 0, --randomly selects between min and max time to change direction
		behavior_change_min = def.behavior_change_min,
		behavior_change_max = def.behavior_change_max,
		update_timer        = 0,
		follow_item         = def.follow_item,
		leash               = def.leash,
		leashed             = false,
		in_cart             = false,
		rides_cart          = def.rides_cart,
		rideable            = def.rideable,
		
		--taming variables
		tameable            = def.tameable,
		tame_item           = def.tame_item,
		owner               = nil,
		owner_name          = nil,
		tamed               = false,
		tame_click_min      = def.tame_click_min,
		tame_click_max      = def.tame_click_max,
		--chair variables - what the player sits on
		mob_chair           = def.mob_chair,
		has_chair           = false,
		chair_textures      = def.chair_textures,
		
		
		
		--Physical variables
		old_position = nil,
		yaw          = 0,
		jump_timer   = 0,
		jump_height  = def.jump_height,
		jump_velocity= 0,
		float        = def.float,
		liquid       = 0,
		hurt_velocity= def.hurt_velocity,
		liquid_mob   = def.liquid_mob,
		on_land      = false,
		attached     = nil,
		attached_name = nil,
		
		
		--Pathfinding variables
		path = {},
		target = nil,
		target_name = nil,
		following = false,
		
		
		
		--what mobs do when created
		on_activate = function(self, staticdata, dtime_s)
			--print("activating at "..dump(self.object:getpos()))
			if string.sub(staticdata, 1, string.len("return")) == "return" then
				local data = minetest.deserialize(staticdata)
				for key,value in pairs(data) do
					self[key] = value
				end
			end
			--keep hp
			if self.old_hp then
				self.object:set_hp(self.old_hp)
			end
			
			--keep leashes connected when respawning
			if self.target_name then
				self.target = minetest.get_player_by_name(self.target_name)
			end
			
			--keep object riding
			if self.attached_name then
				self.attached = minetest.get_player_by_name(self.attached_name)
				self.attached:set_attach(self.object, "", {x=0, y=self.visual_offset, z=0}, {x=0, y=self.automatic_face_movement_dir+90, z=0})
				if self.attached:is_player() == true then
					self.attached:set_properties({
						visual_size = {x=1/self.visual_size.x, y=1/self.visual_size.y},
					})
					--set players eye offset for mob
					self.attached:set_eye_offset({x=0,y=self.eye_offset,z=0},{x=0,y=0,z=0})
				end
			end
			
			--set the amount of times a player has to feed the mob to tame it
			if not self.tame_amount and self.tameable == true then
				self.tame_amount = math.random(self.tame_click_min,self.tame_click_max)
			end
			--re apply the mob chair texture
			if self.has_chair and self.has_chair == true then
				self.object:set_properties({textures = self.chair_textures})
			end
			
			
			if self.user_defined_on_activate then
				self.user_defined_on_activate(self, staticdata, dtime_s)
			end
		end,

		--user defined function
		user_defined_on_activate = def.on_activate,
		
		
		
		
		
		
		--when the mob entity is deactivated
		get_staticdata = function(self)
			--print("staticdata at "..dump(self.object:getpos()))
			--self.global_mob_counter(self)
			local serialize_table = {}
			for key,value in pairs(self) do
				--don't get object item
				if key ~= "object" then
					--don't do userdata
					if type(value) == "userdata" then
						value = nil
					end
					serialize_table[key] = value
				end
			end
			local value_string = minetest.serialize(serialize_table)
			return(value_string)
		end,
		
		
		
		
		
		
		
		--used to tell if mob entity has despawned
		global_mob_counter = function(self)
			--print(dump(minetest.get_node_or_nil(pos)))
			--debug for limiting max mobs
			
			--do this to save a lot of resources vs a global table
			
			--automatically remove mob if dead
			if self.object:get_hp() <= 0 then
				open_ai.mob_count = open_ai.mob_count - 1
				minetest.chat_send_all(open_ai.mob_count.." Mobs in world!")
			else--use assumption logic for mob counter
				minetest.after(0,function(self)
					local pos = self.object:getpos()
					local exists
					
					--for despawned mobs
					if pos == nil then
						exists = nil 
					else
						exists = table.getn(minetest.get_objects_inside_radius(pos, 0.01))
					end
					
					--print("static data global mob count")
					if exists == nil then
						open_ai.mob_count = open_ai.mob_count - 1
						minetest.chat_send_all(open_ai.mob_count.." Mobs in world!")
					elseif exists > 0 then
						--limit the max amount of mobs in the world
						if self.activated == nil then
							if open_ai.mob_count+1 > open_ai.max_mobs then
								self.object:remove()
								minetest.chat_send_all(open_ai.max_mobs.." mob limit reached!")
							else
								open_ai.mob_count = open_ai.mob_count + 1
								minetest.chat_send_all(open_ai.mob_count.." Mobs in world!")
							end
							--trigger to not readd mobs to global mob counter when already existing
							self.activated = true	
						end
					end
				end,self)
			end
		end,
		--allow players to make mob jump when riding mobs
		ridden_jump = function(self)
			if self.attached ~= nil then
			local pos = self.object:getpos()
			if self.attached:is_player() then
				if self.attached:get_player_control().jump == true then
					if self.liquid == 0 then
						local vel = self.object:getvelocity()
						
						--return to save cpu
						if vel.y ~= 0 then
							return
						end
					
					
						--find out if node is underneath
						local under_node = minetest.get_node({x=pos.x,y=pos.y+self.height-0.1,z=pos.z}).name
						
						if minetest.registered_nodes[under_node].walkable == false then
							--print("JUMP FAILURE")
							return
						end
						
						local yaw = self.yaw 
						if yaw == yaw then --avoid inf 
							local x = (math.sin(yaw) * -1) * self.velocity
							local z = (math.cos(yaw)) * self.velocity
							self.jump_velocity = self.jump_height
						end
					elseif self.liquid ~= 0 then
						
						local vel = self.object:getvelocity()
						
						--disalow infinite jumping
						if vel.y > 0 then
							return
						end
						
						--commented out section is to use vel to get yaw dir, hence redeffing it as local yaw verus self.yaw
						local yaw = self.yaw--(math.atan(vel.z / vel.x) + math.pi / 2)
									
						--don't check if not moving instead change direction
						if yaw == yaw then --check for nan
							--use velocity calculation to find whether to jump
							local x = (math.sin(yaw) * -1)
							local z = (math.cos(yaw))
							
							self.jump_velocity = self.jump_height
							
						end
					end
				end
			end
			end
		end,
		--decide wether an entity should jump or change direction
		jump = function(self,dtime)
			--return jump velocity to 0 after timer
			if self.jump_velocity ~= 0 then
				self.jump_timer = self.jump_timer + dtime
				if self.jump_timer >= 0.25 then
					self.jump_velocity = 0
					self.jump_timer = 0
				end
			end
			
			if self.attached == nil then--only jump on it's own if player is not riding
				--don't execute if liquid mob
				if self.liquid_mob == true then
					local vel = self.object:getvelocity()
					
					--use velocity calculation to find whether to jump
					local x = (math.sin(self.yaw) * -1)
					local z = (math.cos(self.yaw))
					
					--reset the timer to change direction
					if (x~= 0 and vel.x == 0) or (z~= 0 and vel.z == 0) then
						self.behavior_timer = self.behavior_timer_goal
					end
				else
					local pos = self.object:getpos()
					
					--only jump when path step is higher up
					if self.following == true and self.leashed == false then
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
						local under_node = minetest.get_node({x=pos.x,y=pos.y+self.height-0.1,z=pos.z}).name
						local vel = self.object:getvelocity()
						if minetest.registered_nodes[under_node].walkable == true then
							--print("jump")
							self.jump_velocity = self.jump_height
						end
					--stupidly jump
					elseif self.following == false and self.liquid == 0 and self.leashed == false then
					
						local vel = self.object:getvelocity()
						
						--return to save cpu
						if vel.y ~= 0 then
							return
						end
					
					
						--find out if node is underneath
						local under_node = minetest.get_node({x=pos.x,y=pos.y+self.height-0.1,z=pos.z}).name
						
						if minetest.registered_nodes[under_node].walkable == false then
							--print("JUMP FAILURE")
							return
						end
						
						local yaw = self.yaw
									
						--don't check if not moving instead change direction
						if yaw == yaw then --check for nan
							
							--use velocity calculation to find whether to jump
							local x = (math.sin(yaw) * -1)
							local z = (math.cos(yaw))
							
							if (x~= 0 and vel.x == 0) or (z~= 0 and vel.z == 0) then
								self.jump_velocity = self.jump_height
							end

										
						end
					elseif self.liquid ~= 0 then
						
						local vel = self.object:getvelocity()
						
						--commented out section is to use vel to get yaw dir, hence redeffing it as local yaw verus self.yaw
						local yaw = self.yaw--(math.atan(vel.z / vel.x) + math.pi / 2)
									
						--don't check if not moving instead change direction
						if yaw == yaw then --check for nan
							--use velocity calculation to find whether to jump
							local x = (math.sin(yaw) * -1)
							local z = (math.cos(yaw))
							
							if (x~= 0 and vel.x == 0) or (z~= 0 and vel.z == 0) then
								self.jump_velocity = self.jump_height
							end		
						end
					end
				end
			end

		end,
		
		--this runs everything that happens when a mob update timer resets
		update = function(self,dtime)
			self.update_timer = self.update_timer + dtime
			if self.update_timer >= 0.1 then
				self.update_timer = 0
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
			if self.following == false and self.behavior_timer >= self.behavior_timer_goal and self.leashed == false then
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
				--print("randomly moving around")
			elseif self.following == true then
				--print("following in behavior function")
			elseif self.leashed == true then
				self.leashed_function(self,dtime)
			end		
		end,
		
		--when a mob is on a leash
		leashed_function = function(self,dtime)
			--exception for if mob spawns with player that is not the leash owner
			if not self.target or (self.target and self.target:is_player() and self.target:getpos() == nil) then
				print("fail player")
				self.target = nil
				self.target_name = nil
				self.leashed = false
				return
			end
			
			
			--exception for if mob spawns without other mob in world
			if not self.target or (self.target and self.target:getpos() == nil) then
				print("fail mob")
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
			--print(vec.x,vec.z)
			self.yaw = math.atan(vec.z/vec.x)+ math.pi / 2
			
			if pos2.x > pos.x then
				self.yaw = self.yaw+math.pi
			end
			
			--do max velocity if distance is over 2 else stop moving
			local distance = vector.distance(pos,pos2)
			
			--run leash visual
			self.leash_visual(self,distance,pos,vec)
			
			if distance < 2 then
				distance = 0
			end
			self.velocity = distance
			
			
		end,
		--if fish is on land, flop
		flop_on_land = function(self)
			
			--if caught then don't execute
			if self.object:get_attach() then
				return
			end
			
			local vel = self.object:getvelocity()
			local pos = self.object:getpos()
			--return to save cpu
			if vel.y ~= 0 then
				return
			end
		
		
			--find out if node is underneath
			local under_node = minetest.get_node({x=pos.x,y=pos.y+self.height-0.1,z=pos.z}).name
			
			if minetest.registered_nodes[under_node].walkable == false then
				--print("JUMP FAILURE")
				return
			end
			
			self.on_land = true --stop fish from moving around
			
			self.jump_velocity = self.jump_height
			
			self.velocity = 0
			self.behavior_timer = -5
			--play flop sound
			minetest.sound_play("open_ai_flop", {
				pos = pos,
				max_hear_distance = 10,
				gain = 1.0,
			})

		end,
		--a visual of the leash
		leash_visual = function(self,distance,pos,vec)
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
		
		--how the mob collides with other mobs and players
		collision = function(self)
			local pos = self.object:getpos()
			pos.y = pos.y + self.height -- check bottom of mob
			
			local vel = self.object:getvelocity()
			local x   = 0
			local z   = 0
			for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
				--only collide with other mobs and players
							
				--add exception if a nil entity exists around it
				if object:is_player() or (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
					local pos2 = object:getpos()
					local vec  = {x=pos.x-pos2.x, z=pos.z-pos2.z}
					--push away harder the closer the collision is, could be used for mob cannons
					--+0.5 to add player's collisionbox, could be modified to get other mobs widths
					local force = (1) - vector.distance({x=pos.x,y=0,z=pos.z}, {x=pos2.x,y=0,z=pos2.z})--don't use y to get verticle distance
										
					--modify existing value to magnetize away from mulitiple entities/players
					x = x + (vec.x * force) * 20
					z = z + (vec.z * force) * 20
				--ride in a minecart
				elseif not object:is_player() and self.rides_cart == true and (object:get_luaentity() and object ~= self.object and object:get_luaentity().old_dir and object:get_luaentity().driver == nil) then
					self.ride_in_cart(self,object)
				end
			end
			return({x,z})
		end,
		--logic for riding in cart
		ride_in_cart = function(self,object)
			
			--reset value if cart is removed
			local ride = self.object:get_attach()
			if ride == nil and self.in_cart == true then
				self.in_cart = false
			end
			
			if self.in_cart == false then
				self.object:set_attach(object, "", {x=0, y=0, z=0}, {x=0, y=0, z=0})
				object:get_luaentity().driver = "open_ai:mob"
				self.in_cart = true
			end
		end,
		--how mobs move around when a player is riding it
		ridden = function(self)
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
		end,
		-- how a mob moves around the world
		movement = function(self,dtime)
			
			self.jump(self,dtime) --jump on step
			self.ridden_jump(self)--allow players to jump while they ride mobs
			
			local collide_values = self.collision(self)
			local c_x = collide_values[1]
			local c_z = collide_values[2]
			
			self.ridden(self)
			
			--print(c_x,c_z)
			--move mob to goal velocity using acceleration for smoothness
			local vel = self.object:getvelocity()
			local x   = math.sin(self.yaw) * -self.velocity
			local z   = math.cos(self.yaw) * self.velocity
			
			--debug to float mobs for now
			local gravity = -10
			self.swim(self)	--this gets the viscosity of the liquid it's in
			if self.float == true and self.liquid ~= 0 and self.liquid ~= nil then
				gravity = self.liquid
			end
			
			--acceleration based jumping
			if self.jump_velocity ~= 0 then
				gravity = self.jump_velocity
			end
			
			--drag the mob up nodes with leash, or lift them up
			if self.leashed == true then
			if (x~= 0 and vel.x == 0) or (z~= 0 and vel.z == 0) then
				gravity = self.velocity
			elseif self.leash_pull < -3 then
				gravity = (self.leash_pull-3)*-1
			end
			end
			
			--make mobs swim in water, fall back into it, if jumped out
			if self.liquid_mob == true and self.liquid ~= 0 then
				gravity = self.swim_pitch
			elseif self.liquid_mob == true and self.liquid == 0 then
				self.flop_on_land(self)
				--allow fish to flop on land
				if self.jump_velocity ~= 0 then
					gravity = self.jump_velocity
				end
			end
			
			--only do goal y velocity if swimming up

			--print(self.velocity)
			
			local jump_multiplier = 4 --multiply the jump velocity to simulate setvelocity
			
			--land mob
			if self.liquid_mob == false or self.liquid_mob == nil then
				if gravity == -10 then --fall
					self.object:setacceleration({x=(x - vel.x + c_x)*self.acceleration,y=-10,z=(z - vel.z + c_z)*self.acceleration})				
				elseif self.jump_velocity == 0 then --swim
					self.object:setacceleration({x=(x - vel.x + c_x)*self.acceleration,y=(gravity-vel.y)*self.acceleration,z=(z - vel.z + c_z)*self.acceleration})
				elseif jump_velocity ~= 0 then --jump
					self.object:setacceleration({x=(x - vel.x + c_x)*self.acceleration,y=(gravity-vel.y)*jump_multiplier,z=(z - vel.z + c_z)*self.acceleration})
				end
			elseif self.liquid_mob == true then--liquid mob
				if gravity == -10 and self.on_land == false then --out of water
					self.object:setacceleration({x=(0 - vel.x + c_x)*self.acceleration,y=-10,z=(0 - vel.z + c_z)*self.acceleration})				
				elseif gravity == -10 and self.on_land == true then --on land
					self.object:setacceleration({x=(0 - vel.x + c_x)*self.acceleration,y=-10,z=(0 - vel.z + c_z)*self.acceleration})
				elseif self.on_land == true and self.jump_velocity ~= 0 then --on land and jumping
					self.object:setacceleration({x=(0 - vel.x + c_x)*self.acceleration,y=(gravity-vel.y)*jump_multiplier,z=(0 - vel.z + c_z)*self.acceleration})
				else --swimming
					self.object:setacceleration({x=(x - vel.x + c_x)*self.acceleration,y=(gravity-vel.y)*self.acceleration,z=(z - vel.z + c_z)*self.acceleration})
				end			
			end
				

		end,
		follow_lure = function(self)
			
		
		end,
		swim = function(self)
			local pos = self.object:getpos()
			pos.y = pos.y + self.center
			self.liquid = minetest.registered_nodes[minetest.get_node(pos).name].liquid_viscosity
			--make land mobs slow down in water
			if self.liquid ~= 0 then
			if self.liquid_mob == nil or self.liquid_mob == false then
				self.velocity = self.liquid
			end
			end
			--reset the on_land variable
			if self.liquid ~= 0 and self.on_land == true then
				self.on_land = false
			end
		end,
		
		--check if a mob should follow a player when holding an item
		check_to_follow = function(self)
			--don't follow if leashed
			if self.leashed == true then
				return
			end
			self.following = false
			
			--liquid mobs follow lure
			if self.liquid_mob == true then
				local pos = self.object:getpos()
				for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 10)) do
					if not object:is_player() and object:get_luaentity() and object:get_luaentity().is_lure == true and object:get_luaentity().in_water == true and object:get_luaentity().attached == nil then 
						local pos2 = object:getpos()
						local vec = {x=pos.x-pos2.x,y=pos2.y-pos.y, z=pos.z-pos2.z}
						--how strong a leash is pulling up a mob
						self.leash_pull = vec.y
						--print(vec.x,vec.z)
						local yaw = math.atan(vec.z/vec.x)+ math.pi / 2
						
						if yaw == yaw then
							
							if pos2.x > pos.x then
								self.yaw = yaw+math.pi
							end
							
							self.yaw = yaw
						end
						
						--float up or down to lure
						self.swim_pitch = vec.y
					end
				end
			else 
				local pos = self.object:getpos()
				for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 10)) do
					if object:is_player() then
						local item = object:get_wielded_item()
						if item:to_string() ~= "" and item:to_table().name == self.follow_item then
							self.following = true
							self.target = object
						else
							self.following = false
						end
					end
				end
			end
			
			
		end,

		
		--path finding towards goal - can be used to find food or water, or attack players or other mobs
		path_find = function(self)
			if self.following == true then
				self.velocity = self.max_velocity
			
				local pos1 = self.object:getpos()
				pos1.y = pos1.y + self.height
				
				local pos2 = self.target:getpos() -- this is the goal debug
				
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
		
		--mob velocity damage x,y, and z
		velocity_damage = function(self,dtime)
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
			self.old_vel = vel
		end,
		
		--check if mob is hurt and show damage
		check_for_hurt = function(self,dtime)
			local hp = self.object:get_hp()
			
			if self.old_hp and hp < self.old_hp then
				--run texture function
				self.hurt_texture(self,(self.old_hp-hp)/4)
				--allow user to do something when hurt
				if self.user_on_hurt then
					self.user_on_hurt(self,self.old_hp-hp)
				end
			end
			
			self.old_hp = hp
		end,
		
		user_on_hurt = def.on_hurt,
		
		--makes a mob turn red when hurt
		hurt_texture = function(self,punches)
			self.fall_damaged_timer = 0
			self.fall_damaged_limit = punches
		end,
		--makes a mob turn back to normal after being hurt
		hurt_texture_normalize = function(self,dtime)
			--reset the mob texture and timer
			if self.fall_damaged_timer ~= nil then
				self.object:settexturemod("^[colorize:#ff0000:100")
				self.fall_damaged_timer = self.fall_damaged_timer + dtime
				if self.fall_damaged_timer >= self.fall_damaged_limit then
					self.object:settexturemod("")
					self.fall_damaged_timer = nil
					self.fall_damaged_limit = nil
				end
			end
		end,
		
		--how the mob sets it's mesh animation
		set_animation = function(self,dtime)
			local vel = self.object:getvelocity()
			local speed = (math.abs(vel.x)+math.abs(vel.z))*self.animation.speed_normal --check this
			
			self.object:set_animation({x=self.animation.walk_start,y=self.animation.walk_end}, speed, 0, true)
			--run this in here because it is part of animation and textures
			self.hurt_texture_normalize(self,dtime)
			--set the riding player's animation to sitting
			if self.attached and self.attached:is_player() and self.player_pose then
				self.attached:set_animation(self.player_pose, 30,0)
			end
		end,
		

		
		--what happens when you hit a mob
		on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
			
			if self.user_defined_on_punch then
				self.user_defined_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
			end
			if self.object:get_hp() <= 0 then
				self.global_mob_counter(self) --remove from global mob count
				--return player back to normal scale
				if self.attached then
				if self.attached:is_player() == true then
					self.attached:set_properties({
						visual_size = {x=1, y=1},
					})
					--revert back to normal
					self.attached:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
				end
				end
				if self.user_defined_on_die then
					self.user_defined_on_die(self, puncher, time_from_last_punch, tool_capabilities, dir)
				end
			end
		end,
		--user defined
		user_defined_on_punch = def.on_punch,
		user_defined_on_die   = def.on_die,
		
		--what happens when a player tries to ride the mob
		try_to_ride = function(self,clicker)
			local item = clicker:get_wielded_item()
			--don't ride if putting on mob chair
			if self.has_chair and self.has_chair == false or (item:to_string() ~= "" and item:to_table().name == self.mob_chair) then
				return
			end
			--initialize riding the horse
			if self.rideable == true and self.tamed == true and clicker:get_player_name() == self.owner_name then
				if self.attached == nil and self.leashed == false then
					self.attached = clicker
					self.attached_name = clicker:get_player_name()
					self.attached:set_attach(self.object, "", {x=0, y=self.visual_offset, z=0}, {x=0, y=self.automatic_face_movement_dir+90, z=0})
					--sit animation
					if self.attached:is_player() == true then
						self.attached:set_properties({
							visual_size = {x=1/self.visual_size.x, y=1/self.visual_size.y},
						})
						--set players eye offset for mob
						self.attached:set_eye_offset({x=0,y=self.eye_offset,z=0},{x=0,y=0,z=0})
					end
				elseif self.attached ~= nil then
					--normal animation
					if self.attached:is_player() == true then
						self.attached:set_properties({
							visual_size = {x=1, y=1},
						})
						--revert back to normal
						self.attached:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
					end
					self.attached:set_detach()
					self.attached_name = nil
					self.attached = nil
				end
				
			end
		end,
		taming = function(self,clicker)
			--disalow mobs that can't be tamed or mobs that are already tamed
			if not self.tameable or (self.tameable == false or self.tamed == true) then 
				return
			end

			local item = clicker:get_wielded_item()
			
			if item:to_string() ~= "" and item:to_table().name == self.tame_item then
				item:take_item(1)
				clicker:set_wielded_item(item)
				self.tame_amount = self.tame_amount - 1
			end
			if self.tame_amount <= 0 then
				self.tamed = true
				self.owner = clicker
				self.owner_name = clicker:get_player_name()
				
				local pos = self.object:getpos()
				minetest.add_particlespawner({
					amount = 50,
					time = 0.001,
					minpos = pos,
					maxpos = pos,
					minvel = {x=-6, y=3, z=-6},
					maxvel = {x=6, y=8, z=6},
					minacc = {x=0, y=-10, z=0},
					maxacc = {x=0, y=-10, z=0},
					minexptime = 1,
					maxexptime = 2,
					minsize = 1,
					maxsize = 2,
					collisiondetection = false,
					vertical = false,
					texture = "heart.png",
				})
			end
		end,
		
		--how a player puts a "chair" on a mob
		place_chair = function(self,clicker)
			if self.tameable == false or self.tamed == false or self.rideable == false or self.mob_chair == nil or self.has_chair == true then
				return
			end
			local item = clicker:get_wielded_item()
			
			if item:to_string() ~= "" and item:to_table().name == self.mob_chair then
				item:take_item(1)
				clicker:set_wielded_item(item)
				self.has_chair = true
				self.object:set_properties({textures = self.chair_textures})
			end			
		end,
		
		--what happens when you right click a mob
		on_rightclick = function(self, clicker)
			
					
			self.try_to_ride(self,clicker)
			
			self.place_chair(self,clicker) -- this after try to ride so player puts on chair before riding
			
			self.taming(self,clicker)
			
			--undo leash
			if self.leashed == true then
				self.leashed = false
				self.target = nil
				self.target_name = nil
				return
			end

			if self.user_defined_on_rightclick then
				self.user_defined_on_rightclick(self, clicker)
			end
		end,
		--user defined
		user_defined_on_rightclick = def.on_rightclick,

		--overcompensate for lag
		lag_check = function(self,dtime)
			--move mob back to last known position
			if dtime > 0.2 and self.last_pos then
				self.object:moveto(self.last_pos)
			end
			
			self.last_pos = self.object:getpos()
		end,
	
		--what mobs do on each server step
		on_step = function(self,dtime)
			self.check_for_hurt(self,dtime)
			self.check_to_follow(self)
			self.behavior(self,dtime)
			self.update(self,dtime)
			self.set_animation(self,dtime)
			self.movement(self,dtime)
			self.velocity_damage(self,dtime)
			self.lag_check(self,dtime)
			if self.user_defined_on_step then
				self.user_defined_on_step(self,dtime)
			end
		end,
		
		--a function that users can define
		user_defined_on_step = def.on_step,	
		
		
	})
	
	open_ai.register_safari_ball("open_ai:"..name,def.ball_color,math.abs(def.collisionbox[2]))
	
end

--run api call
dofile(minetest.get_modpath("open_ai").."/mobs.lua")
