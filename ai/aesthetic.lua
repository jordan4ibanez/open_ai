ai_library.aesthetic = {}
ai_library.aesthetic.__index = ai_library.aestetic

--run on step
function ai_library.aesthetic:on_step(self,dtime)
	self.ai_library.aesthetic:set_animation(self,dtime)
	self.ai_library.aesthetic:check_for_hurt(self,dtime)
	self.ai_library.aesthetic:hurt_texture_normalize(self,dtime)
	self.ai_library.aesthetic:water_particles(self)
end

--show nametag of id for debug
function ai_library.aesthetic:debug_id(self)
	self.object:set_properties({nametag = self.id,nametag_color = "red"})
end

--water particles
function ai_library.aesthetic:water_particles(self)
	--falling into a liquid
	if self.liquid ~= 0 and (self.old_liquid and self.old_liquid == 0) then
		if self.vel.y < -3 then
			local pos = self.object:getpos()
			pos.y = pos.y + self.center + 0.1
			
			--play splash sound
			minetest.sound_play("open_ai_falling_into_water", {
				pos = pos,
				max_hear_distance = 10,
				gain = 1.0,
			})
			minetest.add_particlespawner({
				amount = 10,
				time = 0.01,
				minpos = {x=pos.x-0.5, y=pos.y, z=pos.z-0.5},
				maxpos = {x=pos.x+0.5, y=pos.y, z=pos.z+0.5},
				minvel = {x=0, y=0, z=0},
				maxvel = {x=0, y=0, z=0},
				minacc = {x=0, y=0.5, z=0},
				maxacc = {x=0, y=2, z=0},
				minexptime = 1,
				maxexptime = 2,
				minsize = 1,
				maxsize = 2,
				collisiondetection = true,
				vertical = false,
				texture = "bubble.png",
			})
		end
	end	
end


--check if mob is hurt and show damage
function ai_library.aesthetic:check_for_hurt(self,dtime)
	local hp = self.object:get_hp()
	
	if self.old_hp and hp < self.old_hp then
		--run texture function
		self.ai_library.aesthetic:hurt_texture(self,(self.old_hp-hp)/4)
		--allow user to do something when hurt
		if self.user_on_hurt then
			self.user_on_hurt(self,self.old_hp-hp)
		end
	end
end

--makes a mob turn red when hurt
function ai_library.aesthetic:hurt_texture(self,punches)
	self.fall_damaged_timer = 0
	self.fall_damaged_limit = punches
end

--makes a mob turn back to normal after being hurt
function ai_library.aesthetic:hurt_texture_normalize(self,dtime)
	--apply the particle effect
	if self.fall_damaged_timer ~= nil then
		minetest.add_particlespawner({
				amount = 2,
				time = 0.01,
				minpos = self.mpos,
				maxpos = self.mpos,
				minvel = {x=-5, y=5, z=-5},
				maxvel = {x=5, y=8, z=5},
				minacc = {x=0, y=-10, z=0},
				maxacc = {x=0, y=-10, z=0},
				minexptime = 1,
				maxexptime = 2,
				minsize = 1,
				maxsize = 1,
				collisiondetection = true,
				vertical = false,
				texture = "open_ai_dot_particle.png^[colorize:#" .. self.hit_color .. ":255",
			})
		if self.fall_damaged_timer >= self.fall_damaged_limit then
			self.fall_damaged_timer = nil
			self.fall_damaged_limit = nil
		end
	end
end

--how the mob sets it's mesh animation
function ai_library.aesthetic:set_animation(self,dtime)
	local vel = self.object:getvelocity()
	--only use jump animation for jump only mobs
	if self.jump_only == true then
		--set animation if jumping
		--future note, this is the function that should be used when setting the jump animation for normal mobs
		if vel.y == 0 and (self.old_vel and self.old_vel.y < 0) then
			self.object:set_animation({x=self.animation.jump_start,y=self.animation.jump_end}, self.animation.speed_normal, 0, false)
			minetest.after(self.animation.speed_normal/100, function(self)
				self.object:set_animation({x=self.animation.stand_start,y=self.animation.stand_end}, self.animation.speed_normal, 0, true)
			end,self)
			
		end
	--do normal walking animations
	else
		local speed = (math.abs(vel.x)+math.abs(vel.z))*self.animation.speed_normal --check this
		
		self.object:set_animation({x=self.animation.walk_start,y=self.animation.walk_end}, speed, 0, true)
		--run this in here because it is part of animation and textures
		self.ai_library.aesthetic:hurt_texture_normalize(self,dtime)
		--set the riding player's animation to sitting
		if self.attached and self.attached:is_player() and self.player_pose then
			self.attached:set_animation(self.player_pose, 30,0)
		end
	end
end


--a visual of the leash
function ai_library.aesthetic:leash_visual(self,distance,pos,vec)
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
end


--visual on death
function ai_library.aesthetic:on_die(self)
	minetest.add_particlespawner({
		amount = 100,
		time = 0.01,
		minpos = self.mpos,
		maxpos = self.mpos,
		minvel = {x=-5, y=5, z=-5},
		maxvel = {x=5, y=8, z=5},
		minacc = {x=0, y=-10, z=0},
		maxacc = {x=0, y=-10, z=0},
		minexptime = 1,
		maxexptime = 2,
		minsize = 1,
		maxsize = 1,
		collisiondetection = true,
		vertical = false,
		texture = "open_ai_dot_particle.png^[colorize:#" .. self.hit_color .. ":255",
	})
end

--taming visual
function ai_library.aesthetic:tamed(self)
	--add to particles class
	minetest.add_particlespawner({
		amount = 50,
		time = 0.001,
		minpos = self.mpos,
		maxpos = self.mpos,
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

--sitting visual
function ai_library.aesthetic:sat(self)
	--add to particles class
	minetest.add_particlespawner({
		amount = 50,
		time = 0.001,
		minpos = self.mpos,
		maxpos = self.mpos,
		minvel = {x=-6, y=3, z=-6},
		maxvel = {x=6, y=8, z=6},
		minacc = {x=0, y=-10, z=0},
		maxacc = {x=0, y=-10, z=0},
		minexptime = 1,
		maxexptime = 2,
		minsize = 1,
		maxsize = 1,
		collisiondetection = false,
		vertical = false,
		texture = "open_ai_slime_particle.png^[colorize:#ff0000:255",
	})
end
--standing visual
function ai_library.aesthetic:stood(self)
	--add to particles class
	minetest.add_particlespawner({
		amount = 50,
		time = 0.001,
		minpos = self.mpos,
		maxpos = self.mpos,
		minvel = {x=-6, y=3, z=-6},
		maxvel = {x=6, y=8, z=6},
		minacc = {x=0, y=-10, z=0},
		maxacc = {x=0, y=-10, z=0},
		minexptime = 1,
		maxexptime = 2,
		minsize = 1,
		maxsize = 1,
		collisiondetection = false,
		vertical = false,
		texture = "open_ai_slime_particle.png^[colorize:#00ff00:255",
	})
end

