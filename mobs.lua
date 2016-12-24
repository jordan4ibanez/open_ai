--this is a water test mob which can be used to learn how to make mobs using open ai - uses FreeLikeGNU's sheep mesh
open_ai.register_mob("open_ai:fish",{
	--mob physical variables
	--			   {keep left right forwards and backwards equal, will not work correctly if not equal
	--             {left, below, right, forwards, above , backwards}
	collisionbox = {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25}, --the collision box of the mesh,
	
	collision_radius = 0.5, --the radius around the entity which will check for collision
						  --use the biggest number in your collision box for best result
						  
	--height = 0.7, --divide by 2 for even height }DEPRECATED due to having to center when creating meshes
	--width  = 0.7, --divide by 2 for even width  }
	physical = true, --if the mob collides with the world, false is useful for ghosts
	jump_height = 5, --how high a mob will jump
	health = 20, --how much health a mob has
	hurt_velocity = 7, --how fast a mob can hit a node in any direction before taking damage
	
	--mob movement variables
	max_velocity = 3, --set the max velocity that a mob can move
	acceleration = 3, --how quickly a mob gets up to max velocity
	behavior_change_min = 3, -- the minimum time a mob will wait to change it's behavior
	behavior_change_max = 5, -- the max time a mob will wait to change it's behavior
	
	--float = false, --if a mob tries to swim in liquids
	
	liquid_mob = true, --if a mob swims in a liquid
	liquids = {"default:water_source", "default:water_flowing"}, --liquids mob swims in
	
	--mob aesthetic variables
	visual = "mesh", --can be changed to anything for flexibility
	mesh = "open_ai_fish.b3d",
	textures = {"fish.png"},
        -- sheared textures = {"sheeptest-sheared.png"},
	animation = { --the animation keyframes and speed
		speed_normal = 10,--animation speed
		stand_start = 1,--standing animation start and end
		stand_end = 80,
		walk_start = 81,--swimming animation start and end
		walk_end = 155,
		-- jump start = 100,
		-- jump end = 120,
	},
	automatic_face_movement_dir = 0.0, --what direction the mob faces in
	makes_footstep_sound = false, --if a mob makes footstep sounds
	visual_size = {x=1,y=1}, --resizes a mob mesh if needed
	
	--mob behavior variables
	follow_item = "default:fish_food", --if you're holding this a peaceful mob will follow you
	leash       = false,
	rides_cart  = false,
	hostile     = false,
	
	--safari ball variables
	ball_color = "0000ff",--color in hex, can be any color 
	
	--user defined functions
	on_step = function(self,dtime)
		--print("test")
	end,
	on_activate = function(self, staticdata, dtime_s)
		--print("activating")
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--print("hit")
	end,
	on_die = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--print("poof")
	end,
	on_rightclick = function(self, clicker)
		--print("right clicked")
	end,
	--when a mob gets hurt
	on_hurt = function(self,hp_change)
		--print(hp_change)
	end,
})





--this is a test mob which can be used to learn how to make mobs using open ai - uses FreeLikeGNU's sheep mesh
open_ai.register_mob("open_ai:sheep",{
	--mob physical variables
	--			   {keep left right forwards and backwards equal, will not work correctly if not equal
	--             {left, below, right, forwards, above , backwards}
	collisionbox = {-0.4, -0.0, -0.4, 0.4, 1.0, 0.4}, --the collision box of the mesh,
	
	collision_radius = 0.5, --the radius around the entity which will check for collision
						  --use the biggest number in your collision box for best result
						  
	--height = 0.7, --divide by 2 for even height }DEPRECATED due to having to center when creating meshes
	--width  = 0.7, --divide by 2 for even width  }
	physical = true, --if the mob collides with the world, false is useful for ghosts
	jump_height = 5, --how high a mob will jump
	health = 20, --how much health a mob has
	hurt_velocity = 7, --how fast a mob can hit a node in any direction before taking damage
	
	--mob movement variables
	max_velocity = 3, --set the max velocity that a mob can move
	acceleration = 3, --how quickly a mob gets up to max velocity
	behavior_change_min = 3, -- the minimum time a mob will wait to change it's behavior
	behavior_change_max = 5, -- the max time a mob will wait to change it's behavior
	float = true, --if a mob tries to swim in liquids
	
	--mob aesthetic variables
	visual = "mesh", --can be changed to anything for flexibility
	mesh = "sheeptest.b3d",
	textures = {"sheeptest.png"},
        -- sheared textures = {"sheeptest-sheared.png"},
	animation = { --the animation keyframes and speed
		speed_normal = 10,--animation speed
		stand_start = 0,--standing animation start and end
		stand_end = 60,
		walk_start = 71,--walking animation start and end
		walk_end = 89,
		-- jump start = 100,
		-- jump end = 120,
	},
	automatic_face_movement_dir = -90.0, --what direction the mob faces in
	makes_footstep_sound = true, --if a mob makes footstep sounds
	visual_size = {x=2,y=2}, --resizes a mob mesh if needed
	
	--mob behavior variables
	follow_item = "default:dry_grass_1", --if you're holding this a peaceful mob will follow you
	leash       = true,
	rides_cart  = true,
	hostile     = false,
	
	--safari ball variables
	ball_color = "0000ff",--color in hex, can be any color 
	
	--user defined functions
	on_step = function(self,dtime)
		--print("test")
	end,
	on_activate = function(self, staticdata, dtime_s)
		--print("activating")
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--print("hit")
	end,
	on_die = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--print("poof")
	end,
	on_rightclick = function(self, clicker)
		--print("right clicked")
	end,
	--when a mob gets hurt
	on_hurt = function(self,hp_change)
		--print(hp_change)
	end,
})





--a silly santa testmob
open_ai.register_mob("open_ai:santa",{
	--mob physical variables
	--			   {keep left right forwards and backwards equal, will not work correctly if not equal
	--             {left, below, right, forwards, above , backwards}
	collisionbox = {-0.3,-1.0,-0.3, 0.3,0.8,0.3}, --the collision box of the mesh,
	
	collision_radius = 1, --the radius around the entity which will check for collision
						  --use the biggest number in your collision box for best result
	
	--height = 0.7, --divide by 2 for even height }DEPRECATED due to having to center when creating meshes
	--width  = 0.7, --divide by 2 for even width  }
	physical = true, --if the mob collides with the world, false is useful for ghosts
	jump_height = 5, --how high a mob will jump
	health = 20, --how much health a mob has
	hurt_velocity = 7, --how fast a mob can hit a node in any direction before taking damage
	
	--mob movement variables
	max_velocity = 3, --set the max velocity that a mob can move
	acceleration = 3, --how quickly a mob gets up to max velocity
	behavior_change_min = 3, -- the minimum time a mob will wait to change it's behavior
	behavior_change_max = 5, -- the max time a mob will wait to change it's behavior
	float = true, --if a mob tries to swim in liquids
	
	--mob aesthetic variables
	visual = "mesh", --can be changed to anything for flexibility
	mesh = "character.b3d",
	textures = {"open_ai_santa.png"},
        -- sheared textures = {"sheeptest-sheared.png"},
	animation = { --the animation keyframes and speed
		speed_normal = 10,--animation speed
		stand_start = 0,--standing animation start and end
		stand_end = 60,
		walk_start = 168,--walking animation start and end
		walk_end = 187,
		-- jump start = 100,
		-- jump end = 120,
	},
	automatic_face_movement_dir = -90.0, --what direction the mob faces in
	makes_footstep_sound = true, --if a mob makes footstep sounds
	visual_size = {x=1,y=1}, --resizes a mob mesh if needed
	
	--mob behavior variables
	follow_item = "default:dry_grass_1", --if you're holding this a peaceful mob will follow you
	leash       = true,
	rides_cart  = true,
	hostile     = false,
	
	--safari ball variables
	ball_color = "FF0000",--color in hex, can be any color
	
	--user defined functions
	on_step = function(self,dtime)
		self.present_timer = self.present_timer + dtime
		local pos = self.object:getpos()
		if self.present_timer > 3 then
			minetest.add_item(pos, "default:coal_lump")
			minetest.add_particlespawner({
				amount = 80,
				time = 0.01,
				minpos = {x=pos.x-1, y=pos.y-0.5, z=pos.z-1},
				maxpos = {x=pos.x+1, y=pos.y+0.5, z=pos.z+1},
				minvel = {x=-1, y=1, z=-1},
				maxvel = {x=1, y=2, z=1},
				minacc = {x=0, y=-2, z=0},
				maxacc = {x=0, y=-3, z=0},
				minexptime = 1,
				maxexptime = 2,
				minsize = 1,
				maxsize = 2,
				collisiondetection = false,
				vertical = false,
				texture = "open_ai_safari_ball_particle.png",
			})

			minetest.sound_play("hohoho", {
				pos = pos,
				max_hear_distance = 20,
				gain = 0.4,
			})

			self.present_timer = 0 --comment this out for santa bleeding coal
			self.expire_timer = math.random(1,4)+math.random()
		end
	end,
	on_activate = function(self, staticdata, dtime_s)
		self.present_timer = 0
		self.expire_timer = math.random(1,4)+math.random()
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--print("hit")
	end,
	on_die = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--print("poof")
	end,
	on_rightclick = function(self, clicker)
		--print("right clicked")
	end,
	--when a mob gets hurt
	on_hurt = function(self,hp_change)
		--print(hp_change)
	end,
})
