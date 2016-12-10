 --PROJECT GOALS
 --[[
 List of individual goals
 
 0 is mainly function ideas/notes on how to execute things
 
 0.) only check nodes using voxelmanip when in new floored position
 
 0.) do vector.floor to find position and see if it's in old position
 
 0.) use setacceleration and a goal velocity, and a mob acceleration var to config how fast a mob gets up to it's max speed
 
 0.) do smooth turning
 
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
		physical     = def.physical,
		max_velocity = def.max_velocity,
		acceleration = def.acceleration,
		
		--Behavioral variables
		behavior_timer = 0, --when this reaches behavior change goal, it changes states and resets
		behavior_timer_goal = 0,
		behavior_change_min = def.behavior_change_min,
		behavior_change_max = def.behavior_change_max,
		
		
		
		on_activate = function(self, staticdata, dtime_s)
			--debug for movement
			self.goal = {x=math.random(-self.max_velocity,self.max_velocity),y=math.random(-self.max_velocity,self.max_velocity),z=math.random(-self.max_velocity,self.max_velocity)}
			self.behavior_timer_goal = math.random(self.behavior_change_min,self.behavior_change_max)
			
		end,
		on_step = function(self,dtime)
			self.behavior_timer = self.behavior_timer + dtime
			
			--debug test to change behavior
			if self.behavior_timer >= self.behavior_timer_goal then
				print("Changed direction")
				self.goal = {x=math.random(-self.max_velocity,self.max_velocity),y=math.random(-self.max_velocity,self.max_velocity),z=math.random(-self.max_velocity,self.max_velocity)}
				self.behavior_timer = 0
			end
			
					
			local vel = self.object:getvelocity()
			--move mob to goal velocity using acceleration for smoothness
			self.object:setacceleration({x=(self.goal.x - vel.x)*self.acceleration,y=-10,z=(self.goal.z - vel.z)*self.acceleration})
			
		end,
	})
end

--this is a test mob which can be used to learn how to make mobs using open ai
open_ai.register_mob("open_ai:test",{
	--mob physical variables
	height = 2, --divide by 2 for even height
	width  = 1, --divide by 2 for even width
	physical = true, --if the mob collides with the world, false is useful for ghosts
	
	--mob movement variables
	max_velocity = 3, --set the max velocity that a mob can move
	acceleration = 3, --how quickly a mob gets up to max velocity
	behavior_change_min = 3, -- the minimum time a mob will wait to change it's behavior
	behavior_change_max = 5, -- the max time a mob will wait to change it's behavior
	
})
