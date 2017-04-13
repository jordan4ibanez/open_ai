
--global to enable other mods/packs to utilize the ai
open_ai = {}
--open_ai.mob_count = 0
open_ai.max_mobs = 2000 -- limit the max number of mobs existing in the world
open_ai.defaults = {} --fix a weird entity glitch where entities share collision boxes
open_ai.spawn_table = {} --the table which mobs can globaly store data




dofile(minetest.get_modpath("open_ai").."/leash.lua")
dofile(minetest.get_modpath("open_ai").."/safari_ball.lua")
dofile(minetest.get_modpath("open_ai").."/spawning.lua")
dofile(minetest.get_modpath("open_ai").."/fishing.lua")
dofile(minetest.get_modpath("open_ai").."/commands.lua")
dofile(minetest.get_modpath("open_ai").."/items.lua")
dofile(minetest.get_modpath("open_ai").."/rayguns.lua")




--[[
TEMP NOTES

-After moving functions into classes - 

-Adjust collision radius to include scale-
-half collision multiplier and also add collision X and Z into collided object if not player to allow for bigger mobs to collide-
-Try to push away player somehow?-

-if data is nil then restore mob to original state or remove and spawn new mob of the same type-

-put all user functions next to eachother

-open voxelmanip to not jump over fences, check +- 1 x and z

class to get new variables, store old variables until next step, for jumping and stuff

try to make mobs emit light


got through user defined variables if nil then default to something

]]--


--[[
--decide wether an entity should jump or change direction
--if fish is on land, flop
liquid mob changing direction when hitting node
local x = (math.sin(self.yaw) * -1)
local z = (math.cos(self.yaw))
--reset the timer to change direction
if (x~= 0 and vel.x == 0) or (z~= 0 and vel.z == 0) then
	self.behavior_timer = self.behavior_timer_goal
end,
]]--

--The table that holds classes
ai_library = {}

--call all the library classes
dofile(minetest.get_modpath("open_ai").."/ai/helpers.lua")
dofile(minetest.get_modpath("open_ai").."/ai/activation.lua")
dofile(minetest.get_modpath("open_ai").."/ai/movement.lua")
dofile(minetest.get_modpath("open_ai").."/ai/variables.lua")
dofile(minetest.get_modpath("open_ai").."/ai/pathfind.lua")
dofile(minetest.get_modpath("open_ai").."/ai/collision.lua")
dofile(minetest.get_modpath("open_ai").."/ai/interaction.lua")
dofile(minetest.get_modpath("open_ai").."/ai/physical.lua")
dofile(minetest.get_modpath("open_ai").."/ai/aesthetic.lua")
dofile(minetest.get_modpath("open_ai").."/ai/behavior.lua")
dofile(minetest.get_modpath("open_ai").."/ai/build.lua")

--run the initialization for world with this freshly installed, or new worlds
--allows it to be put into new worlds, or put into worlds that already exist
ai_library.helpers:initialization()


open_ai.register_mob = function(name,def)
	--add mobs to spawn table - with it's spawn node - and if liquid mob
	local entity_name = minetest.get_current_modname()..":"..name
	open_ai.spawn_table[entity_name] = {}
	open_ai.spawn_table[entity_name].spawn_node = def.spawn_node
	open_ai.spawn_table[entity_name].liquid_mob = def.liquid_mob
	--store default collision box globally
	open_ai.defaults[entity_name] = {}
	open_ai.defaults[entity_name]["collisionbox"] = table.copy(def.collisionbox)
	
	minetest.register_entity(entity_name, {
		--Do simpler definition variables for ease of use
		mob          = true,
		name         = entity_name,
		
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
		visual        = def.visual,
		mesh          = def.mesh,
		textures      = def.textures,
		makes_footstep_sound = def.makes_footstep_sound,
		animation     = def.animation,
		visual_size   = {x=def.visual_size.x, y=def.visual_size.y},
		eye_offset    = def.eye_offset,
		visual_offset = def.visual_offset,
		player_pose   = def.player_pose,
		
		
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
		float        = def.float,
		liquid       = 0,
		hurt_velocity= def.hurt_velocity,
		liquid_mob   = def.liquid_mob,
		attached     = nil,
		attached_name= nil,
		jump_only    = def.jump_only,
		jumped       = false,
		scale_size   = 1,
		drops = def.drops,
		hit_color = def.hit_color and def.hit_color or "CC0000",
		stepheight = 1, 
		
		
		--Pathfinding variables
		path = {},
		target = nil,
		target_name = nil,
		following = false,
		
		--Internal variables
		age = 0,
		time_existing = 0, --this won't be saved for static data polling
		build_timer = 0,
		schematic_map = {x=1,y=1,z=1},
		
		--Inject the library into entity def
		ai_library = table.copy(ai_library),
		
		on_activate = function(self, staticdata, dtime_s)
			self.ai_library.activation:restore_variables(self,staticdata,dtime_s)
		end,
		get_staticdata = function(self)
			return(self.ai_library.activation:getstaticdata(self))
		end,
		on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
			return self.ai_library.interaction:on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
		end,
		on_rightclick = function(self, clicker) 
			self.ai_library.interaction:on_rightclick(self, clicker)
		end,
		
		--what mobs do on each server step
		on_step = function(self,dtime)
		
			self.ai_library.build:on_step(self,dtime)
		
			self.ai_library.variables:get_current_variables(self)
						
			self.ai_library.physical:on_step(self,dtime)

			self.ai_library.interaction:on_step(self)
			
			self.ai_library.behavior:on_step(self,dtime)
			
			self.ai_library.pathfind:on_step(self,dtime)
			
			self.ai_library.aesthetic:on_step(self,dtime)
			
			self.ai_library.movement:onstep(self,dtime)
						
			self.ai_library.variables:on_step(self,dtime)
			
			if self.user_defined_on_step then
				self.user_defined_on_step(self,dtime)
			end
			
			self.ai_library.variables:get_old_variables(self)
			
		end,
		
		--a function that users can define
		user_defined_on_step = def.on_step,	
		user_defined_on_punch = def.on_punch,
		user_defined_on_die   = def.on_die,		
		user_defined_on_rightclick = def.on_rightclick,
		user_defined_on_jump = def.on_jump,
		user_on_hurt = def.on_hurt,	
		user_defined_on_activate = def.on_activate,
		
	})
	
	open_ai.register_safari_ball(entity_name,def.ball_color,math.abs(def.collisionbox[2]))
	
end

--run api call
dofile(minetest.get_modpath("open_ai").."/mobs.lua")

