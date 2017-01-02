--this is debug to spawn mobs
open_ai.spawn_step = 0
open_ai.spawn_timer = 1 --spawn every 15 seconds
open_ai.spawn_table = {}

minetest.register_globalstep(function(dtime)
	open_ai.spawn_step = open_ai.spawn_step + dtime
	print(open_ai.spawn_step)
	
	if open_ai.spawn_step > open_ai.spawn_timer then
		for _,player in ipairs(minetest.get_connected_players()) do
			if player:get_hp() > 0 then
				local pos = player:getpos()
				for _,mob in ipairs(open_ai.spawn_table) do
					--test for nodes to spawn mobs in
					local test_for_node = minetest.find_nodes_in_area_under_air({x=pos.x-20,y=pos.y-20,z=pos.z-20}, {x=pos.x+20,y=pos.y+20,z=pos.z+20}, "default:dirt_with_grass")
					--if the table has a node position then spawn the mob
					local positions = table.getn(test_for_node)
					if positions > 0 then
						--get a random node out of the table and add 1 y to it to spawn mob above it
						--use the mob height eventually to spawn on the node exactly
						local pos2 = test_for_node[math.random(1,positions)]
						pos2.y = pos2.y + 1
						minetest.add_entity(pos2, "open_ai:"..mob)
					end
				end
			end
		end
		open_ai.spawn_step = 0
	end
end)
