 --PROJECT GOALS
 --[[
 List of individual goals
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
 
 Or in other words, mobs that add fun and aesthetic to the game, yet do not take away performance
 
 This is a huge undertaking, I will sometimes take breaks, days in between to avoid rage quitting, but will try to
 make updates as frequently as possible
 
 Rolling release to make updates in minetest daily (git) to bring out the best in the engine
 
 I use tab because it's the easiest for me to follow in my editor, I apologize if this is not the same for you
 
 I am also not the best speller, feel free to call me out on spelling mistakes
 
 CC0 to embrace the GNU principles followed by Minetest, you are allowed to relicense this to your hearts desires
 This mod is designed for the community's fun
 
 Idea sources
 https://en.wikipedia.org/wiki/Mob_(video_gaming)
 
 ]]--

--global to enable other mods/packs to utilize the ai
open_ai = {}

open_ai.register_mob(name,def)
	
end
