 --PROJECT GOALS
 --[[
 List of individual goals
 
 0 is mainly function ideas/notes on how to execute things
 
 0.) only check nodes using voxelmanip when in new floored position
 
 0.) minetest.line_of_sight(pos1, pos2, stepsize) to check if a mob sees player
 
 0.) minetest.find_path(pos1,pos2,searchdistance,max_jump,max_drop,algorithm)
 0.) do pathfinding by setting yaw towards the next point in the table
 0.) only run this function if the goal entity/player is in a new node to prevent extreme lag
 
 0.) Health
 
 0.) running particles
     
 0.) when mob gets below 0.1 velocity do set velocity to make it stand still ONCE so mobs don't float and set acceleration to 0
 
 1.) lightweight ai that walks around, stands, does something like eat grass
 
 2.) make mobs drown if drown = true in definition
 
 3.) Make mobs avoid other mobs and players when walking around
 
 4.) pathfinding, avoid walking off cliffs
 
 5.) attacking players
 
 6.) drop items
 
 7.) utility mobs
 
 8.) underwater and flying mobs
 
 9.) pet mobs
 
 10.) mobs climb ladders, and are affected by nodes like players are
 
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
		collisionbox = {-def.width/2,-def.height/2,-def.width/2,def.width/2,def.height/2,def.width/2},
		height       = def.height,
		width        = def.width,
		physical     = def.physical,
		max_velocity = def.max_velocity,
		acceleration = def.acceleration,
		
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
		
		--Physical variables
		old_position = nil,
		yaw          = 0,
		jump_height = def.jump_height,
		
		
		--Pathfinding variables
		path = {},
		target = "singleplayer",
		
		
		
		--what mobs do when created
		on_activate = function(self, staticdata, dtime_s)
			--debug for movement
			self.velocity = math.random(1,self.max_velocity)+math.random()
			
			self.behavior_timer_goal = math.random(self.behavior_change_min,self.behavior_change_max)
			
			local pos = self.object:getpos()
			pos.y = pos.y - (self.height/2) -- the bottom of the entity
			self.old_position = vector.floor(pos)
			
			self.yaw = (math.random(0, 360)/360) * (math.pi*2)
			
		end,
		
		
		--decide wether an entity should jump or change direction
		jump = function(self)
			
			local pos = self.object:getpos()
			local vel = self.object:getvelocity()
			
			--commented out section is to use vel to get yaw dir, hence redeffing it as local yaw verus self.yaw
			local yaw = self.yaw--(math.atan(vel.z / vel.x) + math.pi / 2)
						
			--don't check if not moving instead change direction
			if yaw == yaw then --check for nan
				--turn it into usable position modifier
				local x = (math.sin(yaw) * -1)*1.5
				local z = (math.cos(yaw))*1.5
				--[[ uncomment this to see where mobs check for obstacles
				minetest.add_particle({
					pos = {x=pos.x+x,y=pos.y,z=pos.z+z},
					velocity = {x=0, y=0, z=0},
					acceleration = {x=0, y=0, z=0},
					expirationtime = 1,
					size = 3,
					collisiondetection = false,
					vertical = false,
					texture = "heart.png",
					playername = "singleplayer"
				})
				]]--
				local node = minetest.get_node({x=pos.x+x,y=pos.y,z=pos.z+z}).name
				if minetest.registered_nodes[node].walkable == true then
					--print("jump")
					self.object:setvelocity({x=vel.x,y=self.jump_height,z=vel.z})
				end			
			end

		end,
		
		--this runs everything that happens when a mob enters a new node
		update = function(self)
			self.jump(self)
			self.path_find(self)
		end,
		
		
		behavior = function(self,dtime)
			self.behavior_timer = self.behavior_timer + dtime
			local vel = self.object:getvelocity()

			
			--debug to find node the mob exists in
			local testpos = self.object:getpos()
			testpos.y = testpos.y-- - (self.height/2) -- the bottom of the entity
			local vec_pos = vector.floor(testpos) -- the node that the mob exists in
			
			
			--update the node it exists in if changed - also do jump function to find if jumping is needed
			if vec_pos.x ~= self.old_position.x or
			vec_pos.y ~= self.old_position.y or
			vec_pos.z ~= self.old_position.z then
				self.old_position = vec_pos
				self.update(self)
			end
					
			--debug test to change behavior
			if self.behavior_timer >= self.behavior_timer_goal then
				--print("Changed direction")
				--self.goal = {x=math.random(-self.max_velocity,self.max_velocity),y=math.random(-self.max_velocity,self.max_velocity),z=math.random(-self.max_velocity,self.max_velocity)}
				self.yaw = (math.random(0, 360)/360) * (math.pi*2) --double pi to allow complete rotation
				self.velocity = math.random(1,self.max_velocity)+math.random()
				self.behavior_timer_goal = math.random(self.behavior_change_min,self.behavior_change_max)
				self.behavior_timer = 0
				print(self.yaw)
			end		
		end,
		
		
		-- how a mob moves around the world
		movement = function(self)
			--move mob to goal velocity using acceleration for smoothness
			local vel = self.object:getvelocity()
			local x   = math.sin(self.yaw) * -self.velocity
			local z   = math.cos(self.yaw) * self.velocity
			self.object:setacceleration({x=(x - vel.x)*self.acceleration,y=-10,z=(z - vel.z)*self.acceleration})
		
		end,
		
		
		
		
		
		--path finding towards goal - can be used to find food or water, or attack players or other mobs
		path_find = function(self)
			local pos1 = self.object:getpos()
			local pos2 = minetest.get_player_by_name(self.target):getpos() -- this is the goal debug
						
			local path = minetest.find_path(pos1,pos2,5,1,3,"A*_noprefetch")
						
			if path ~= nil then
				self.path = path
				--print("set path!")
			end
		end,
		
		
		
		
		
		
		
		
		set_animation = function(self)
			local vel = self.object:getvelocity()
			local speed = (math.abs(vel.x)+math.abs(vel.z))*self.animation.speed_normal --check this
			
			self.object:set_animation({x=self.animation.walk_start,y=self.animation.walk_end}, speed, 0, true)

		
		end,
		
		--what mobs do on each server step
		on_step = function(self,dtime)
			
			self.behavior(self,dtime)
			self.set_animation(self)
			self.movement(self)			
		end,
		
		
		
		
		
		
	})
end

--this is a test mob which can be used to learn how to make mobs using open ai - uses pilzadam's sheep mesh
open_ai.register_mob("open_ai:test",{
	--mob physical variables
	height = 0.7, --divide by 2 for even height
	width  = 0.7, --divide by 2 for even width
	physical = true, --if the mob collides with the world, false is useful for ghosts
	jump_height = 5, --how high a mob will jump
	
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
})
