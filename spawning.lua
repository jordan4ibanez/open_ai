--this is debug to spawn mobs
open_ai.spawn_step = 0
open_ai.spawn_timer = math.random(10,30)
minetest.register_globalstep(function(dtime)
	open_ai.spawn_step = open_ai.spawn_step + dtime
	
	if open_ai.spawn_step > open_ai.spawn_timer then
	for _,player in ipairs(minetest.get_connected_players()) do
		if player:get_hp() > 0 then
			local pos = player:getpos()
			for i = 1,math.random(3,5) do
				minetest.add_entity({x=pos.x+math.random(-20,20),y=pos.y+math.random(4,10),z=pos.z+math.random(-20,20)}, "open_ai:safari_ball_test")
			end
		end
	end
	open_ai.spawn_step = 0
	open_ai.spawn_timer = math.random(10,30)
	end
end)
