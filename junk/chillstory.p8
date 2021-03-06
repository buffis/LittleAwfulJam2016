pico-8 cartridge // http://www.pico-8.com
version 5
__lua__

--------
-- murder, death, chill
-- for "little awful jam 2016"
-- bjorn.kempen@gmail.com / https://github.com/buffis
-- music by pizza / http://pizzamakesgames.itch.io/
--
-- code is not very nice. no effort has been put into making
-- it look nice. that is ok, it's a gamejam game
--------

-- Constants
state_title     = 1
state_game      = 2
state_game_won  = 4
state_credits   = 5
state_dead      = 6
state_getready  = 7

dir_left = 4
dir_right = 6

move_step       = 2
gravity         = 1

-- Sprites
spr_chill_c = 22
spr_chill_h = 23
spr_chill_i = 24
spr_chill_l1 = 25
spr_chill_l2 = 26
spr_player1 = 0
spr_player1_up = 32
spr_player2 = 18
spr_player2_up = 20
spr_snowflake = 192
spr_small_snowflake = 200
spr_penguin1 = 42
spr_penguin2 = 44
spr_enemy1_1 = 97
spr_enemy1_2 = 65
spr_enemy2_1 = 99
spr_enemy2_2 = 67
spr_big_a = 128
spr_logo_1 = 71
spr_logo_2 = 87
spr_logo_3 = 103

-- Data
credit_text = {
	"     credits      ",
	"                  ",
	"                  ",
	"   code:  buffi   ",
	"   art:   buffi   ",
	"   music: pizza   ",
	"                  ",
	"                  ",
	"                  ",
	"  special thanks: ",
	"        li        ",
	"       emma       ",
	"    #sagamedev    ",
	"                  ",
	"                  ",
	"                  ",
	"  chillest dudes: ", -- judge pandering goes here
	"                  ",
	"  sharpenedspoon  ",
	"    poemdexter    ",
	"  internetjanitor ",
	"       tann       ",
	"    everdraed     "
}

-- pico-8 entry points

function _init()
	start_title()
	gameticks = 0
	god_mode = false
	menu_option = 0
end

function _update()
	gameticks += 1
	shakex = rnd(shake)
	shakey = rnd(shake)
	if     game_state == state_title    then update_title()
	elseif game_state == state_game     then update_game()
	elseif game_state == state_game_won then update_game_won()
	elseif game_state == state_credits  then update_credits()
	elseif game_state == state_dead     then update_dead()
	elseif game_state == state_getready then update_getready()
	end
end

function _draw()
	cls()
	if     game_state == state_title    then draw_title()
	elseif game_state == state_game     then draw_game()
	elseif game_state == state_game_won then draw_game_won()
	elseif game_state == state_credits  then draw_credits()
	elseif game_state == state_dead     then draw_dead()
	elseif game_state == state_getready then draw_getready()
	end
end

-- State transition logic

function start_title()
	input_wait_time = 10
	game_state = state_title
	music(15, 0, 7)
end

function start_game(start_score, deaths)
	ending_state = 0
	game_state = state_game
	is_shooting = false
	penguin_x = 140
	score = start_score or 0
	stage = 1
	looking_up = false
	death_count = deaths or 0
	bullet_sound_counter = 0
	shake = 1
	snowflake_speed = 4
	cur_music = get_game_music()
	music(cur_music, 0, 7)

	x = 64 y = 94
	bullet_wait = 0
	player_direction = dir_right
	
	clear_particles()
	clear_enemies()
end

function start_getready()
	get_ready_count = 10
	game_state = state_getready
	music(4, 0, 7)
end

function start_credits()
	game_state = state_credits
	x = 8
	y = -20
	credit_text_y = 130
	music(1, 0, 7)
end

-- "game update" logic below

function update_title()
	if input_wait_time == 0 then
		if btn(2) then
			menu_option = 0
		elseif btn(3) then
			menu_option = 1
		elseif btn(1) or btn(4) then
			play_sfx(56)
			if menu_option == 1 then
				god_mode = not god_mode
				input_wait_time = 10
			elseif menu_option == 0 then
				start_getready()
			end
		end
	else
		input_wait_time -= 1
	end

	-- Spawn particles from bottom of screen.
	if band(gameticks, 1) == 1 then
		particle_spawn(rnd(128), 130, 0, -1-rnd(2), 100, 1, 7)
	end
	particles_move()
	particles_prune()
end

function update_getready()
	get_ready_count -= 1
	if get_ready_count == 0 then
		start_game()
	end
end

function update_game()
	-- handle stuff happening
	handle_game()

	-- update enemies
	enemies_move()
	enemies_prune()

 	stage_update()

	-- update particles
	bullets_move()
	bullets_prune()
	particles_move()
	particles_prune()
end

stage_musics = {
	5,
	6,
	6,
	7,
	7,
	8,
	8,
	9,
	10,
	10
}
function get_game_music()
	return stage_musics[stage+1]
end

function update_dead()
	if shake > 1 then
		shake -= 0.4
	else
		shake = 1
	end

	if btn(2) and input_wait_time == 0 then
		menu_option = max(0, menu_option-1)
		input_wait_time = 6
	elseif btn(3) and input_wait_time == 0 then
		menu_option = min(2, menu_option+1)
		input_wait_time = 6
	elseif btn(4) and input_wait_time == 0 then
		play_sfx(56)
		if menu_option == 0 then
			continue_score = flr(score / 10)*10
			start_game(continue_score, death_count+1)
		elseif menu_option == 1 then
			start_game()
		elseif menu_option == 2 then
			start_title()
		end
		menu_option = 0
	elseif input_wait_time > 0 then
		input_wait_time -= 1
	end

	-- update enemies
	enemies_move()
	enemies_prune()

	-- update particles
	bullets_move()
	bullets_prune()
	particles_move()
	particles_prune()
end

function update_game_won()
	-- state 0 (stop shake and snowflakes)
	if ending_state == 0 then
		if shake > 1 then
			shake -= 0.1
		else
			shake = 1
		end
		if snowflake_speed > 0 then
			snowflake_speed -= 0.1
		else
			snowflake_speed = 0
		end
		if (shake == 1) and (snowflake_speed == 0) then
			ending_state += 1
		end
	end

	-- state 1 (player moves to position)
	if ending_state == 1 then
		if x < 55 then
			x += 0.5
			player_direction = dir_right
		elseif x > 57 then
			x -= 0.5
			player_direction = dir_left
		else
			x = 56
			player_direction = dir_right
			ending_state += 1
			ending_ticker = 0
		end
	end

	-- state 2 (wow)
	if ending_state == 2 then
		ending_ticker += 1
	end

	-- state 3 (everything is so chill)
	if ending_state == 3 then
		ending_ticker += 1
		penguin_y = y
	end

	-- state 4 (penguin enters)
	if ending_state == 4 then
		penguin_x -= 1
		if (penguin_x <= 70) then
			ending_state += 1
			ending_ticker = 0
		end
	end

	-- state 5 (i love you mr chill)
	if ending_state == 5 then
		ending_ticker += 1
	end

	-- state 6 (please have my babies)
	if ending_state == 6 then
		ending_ticker += 1
	end

	-- state 7 (face away)
	if ending_state == 7 then
		player_direction = dir_left
		x -= 0.2
		if x <= 40 then
			ending_state += 1
			x = 40
		end
	end

	-- state 8 (i have place to be)
	if ending_state == 8 then
		ending_ticker += 1
	end

	-- state 9 (people to chill)
	if ending_state == 9 then
		ending_ticker += 1
	end

	-- state 10 (besides)
	if ending_state == 10 then
		ending_ticker += 1
	end

	-- state 11 (theres no chill in children)
	if ending_state == 11 then
		ending_ticker += 1
	end
	
	-- state 12 (jump up)
	if ending_state == 12 then
		y -= 2
		x -= 1
		if y <= 80 then
			ending_state += 1
		end
	end

	-- state 13 (jump down)
	if ending_state == 13 then
		y += 2
		x -= 1
		if y >= 140 then
			ending_state += 1
			ending_ticker = 0
		end
	end

	-- state 14 (explode sad penguin)
	if ending_state == 14 then
		ending_ticker += 1
		if ending_ticker == 60 then
			-- spawn a penguin tear
			particle_spawn(penguin_x+4, penguin_y+5, 0, 0.5, 28, 2, 12)
		end
		if ending_ticker == 120 then
			make_explosion(penguin_x, penguin_y)
			penguin_x = 140
			penguin_y = 140
			play_sfx(55)
		end
		if ending_ticker == 190 then
			start_credits()
		end
	end

	enemies_prune()
	bullets_prune()
	particles_move()
	particles_prune()
end

function update_credits()
	y += 0.2
	particles_move()
	particles_prune()

	if band(gameticks, 3) == 3 and y < 130 then
		particle_spawn(rnd(128), 130, 0, -1-rnd(2), 100, 1, 7)
	end

	credit_text_y -= 0.5
end
has_spawned = false

function handle_game()
	if bullet_sound_counter > 0 then
		bullet_sound_counter -= 1
	end

	if (btn(0)) then
		x-=move_step
		player_direction = dir_left
	end
	if (btn(1)) then
		x+=move_step
		player_direction = dir_right
	end
	if (btn(2)) then
		looking_up = true
	else
		looking_up = false
	end
	-- if (btn(3)) then y+=move_step end
	if (btn(4) and bullet_wait == 0) then
		bullet_wait = 2
		if player_direction == dir_left then
			bx = x+5
			by = y + 3 + rnd(3)
			bvx = -4
			bvy = 0
		end
		if player_direction == dir_right then
			bx = x+6
			by = y + 3 + rnd(3)
			bvx = 4
			bvy = 0
		end

		if looking_up then
			bvy = -3
		end

		s = next_bullet()
		if s != 0 then
			if bullet_sound_counter == 0 then
				play_sfx(53)
			end
			bullet_spawn(bx, by, bvx, bvy, s)
		else
			bullet_wait = 1
		end
	end
	if bullet_wait > 0 then
		bullet_wait -= 1
	end

	x = max(x, 0)      y = max(y, 0)
	x = min(x, 127)    y = min(y, 127)

	if not has_spawned and band(gameticks, 31) == 31 then
		spawn_new_enemy()	
		has_spawned = true	
	end

	-- check player death
	handle_player_death()
end

function spawn_new_enemy()
	if bullet_sound_counter == 0 then
		play_sfx(54)
	end
	bullet_sound_counter = 10
	if stage == 0 then
		rrr = flr(rnd(2))
		if rrr == 0 then
			enemy_spawn(120, 100, -1.5, 0, 0, 0)
		elseif rrr == 1 then
			enemy_spawn(0, 100, 1.5, 0, 0, 0)
		end
	end
	if stage == 1 then
		rrr = flr(rnd(2))
		if rrr == 0 then
			enemy_spawn(120, 100, -2, 0, 4+rnd(2), 0)
		elseif rrr == 1 then
			enemy_spawn(0, 100, 2, 0, 4+rnd(2), 0)
		end
	end
	if stage == 2 then
		rrr = flr(rnd(2))
		if rrr == 0 then
			enemy_spawn(0, 70, 0.5 + rnd(1), -9-rnd(5), 5, 0)
		elseif rrr == 1 then
			enemy_spawn(120, 70, -0.5 - rnd(1), -9-rnd(5), 5, 0)
		end
	end
	if stage == 3 then
		rrr = flr(rnd(2))
		if rrr == 0 then
			enemy_spawn(0, 70, 2.5 + rnd(1), -11 - rnd(5), 5, 0)
		elseif rrr == 1 then
			enemy_spawn(x, 70, -2.5 - rnd(1),  -11 - rnd(5), 5, 0)
		end
	end
	if stage == 4 then
		enemy_spawn(rnd(100)+10, 66, rnd(5)-2, -10, 5, 0)
	end
	if stage == 5 then
		rrr = flr(rnd(2))
		if rrr == 0 then
			enemy_spawn(10+rnd(100), -15, 0, 0, 5, 0)
		elseif rrr == 1 then
			enemy_spawn(10+rnd(100), -15, 0, 0, 5, 0)
		end
	end
	if stage == 6 then
		movex = rnd(6)-3
		enemy_spawn(20+rnd(80), 40, movex, -8, 0, 0)
		enemy_spawn(20+rnd(80), 40, -movex, -8, 0, 0)
	end
	if stage == 7 then
		rrr = flr(rnd(2))
		if rrr == 0 then
			enemy_spawn(120, 70+rnd(40), -3, 3, 4+rnd(4), 0)
		elseif rrr == 1 then
			enemy_spawn(0, 70+rnd(40), 3, 3, 4+rnd(4), 0)
		end
	end
	if stage == 8 then
		rrr = flr(rnd(2))
		if rrr == 0 then
			enemy_spawn(120, 70, -8, -7, 3, 0)
		elseif rrr == 1 then
			enemy_spawn(0, 70, 8, -7, 3, 0)
		end
	end
	if stage == 9 then
		rrr = flr(rnd(7))
		if rrr == 0 then
			enemy_spawn(120, 70, -8, -7, 3, 0)
		elseif rrr == 1 then
			enemy_spawn(0, 70, 0.5 + rnd(1), -9 - rnd(5), 5, 0)
		elseif rrr == 2 then
			enemy_spawn(rnd(100)+10, 66, rnd(5)-2, -10, 5, 0)
		elseif rrr == 3 then
			enemy_spawn(120, 70+rnd(40), -3, 3, 4+rnd(4), 0)
		elseif rrr == 4 then
			enemy_spawn(0, 70+rnd(40), 3, 3, 4+rnd(4), 0)
		elseif rrr == 5 then
			enemy_spawn(120, 70, -8, -7, 3, 0)
		elseif rrr == 6 then
			enemy_spawn(0, 70, 8, -7, 3, 0)
		end
	end
end

function handle_player_death()
	was_hit = false
	function e_death(e)
		if (e.x > (x-12)) and (e.x < (x+10)) then
			if (e.y < (y+10)) and (e.y > (y-10)) then
				-- was_hit = true
				-- e.dead = true
			end
		end
	end
	foreach(enemies, e_death)
	if was_hit then
		make_explosion(x, y)
		if not god_mode then
			game_state = state_dead
			music(-1, 0, 7)
			play_sfx(55)
			input_wait_time = 30
			bullet_sound_counter = 10
		else
			death_count += 1
		end
	end
end

function sx(x)
	return x + shakex
end
function sy(y)
	return y + shakey
end

-- draw logic below

function draw_game()
	-- draw background
	draw_bg()

	draw_floor_and_roof()
	if is_shooting then
		draw_chillray()
	end

 	-- player
 	flipx = player_direction == dir_left

 	if band(gameticks, 4) > 0 then
 		sss = spr_player1
 		if looking_up then
 			sss = spr_player1_up
 		end
 	else
 		sss = spr_player2
 		if looking_up then
 			sss = spr_player2_up
 		end
 	end
 	

 	-- enemies
 	enemies_draw()

 	-- particles
	bullets_draw()
 	particles_draw()

	dumb_text_draw()

	color(7)
 	print("chill factor: " .. score .. "%", 33, 2)
 	if death_count > 0 then
		print("deaths: " .. death_count, 43, 10)
	end	
end


function draw_getready()
	color(7)
	print("in the year 2035 the world is", 5, 15)
	print("overrun by non-chill ghosts.", 7, 25)
	print("chill now only exists inside", 5, 45)
	print(" the souls of a select few.", 5, 55)

	print("are you a chill enough dude", 5, 75)
	print(" to chill all the ghosts,", 8, 85)
	print("and restore the chill factor", 5, 95)
	print("       of the world?", 5, 105)

	
	
end

function draw_credits()
	spr(spr_player1, x, y, 2, 2)
	particles_draw()

	color(7)
	if y < 130 then
		for i=1,#credit_text,1 do
			print(credit_text[i], 25, credit_text_y+i*10)
		end
	else
		print("and everything was chill", 15, 35)
		if y > 150 then
			print("the end", 50, 70)
		end
		if y > 160 then
			music(-1)
		end
	end
end

function draw_chill_game_text()
	for i=0,4,1 do
		color(rnd(14)+1)
		print("chill", 2*((gameticks+i*3*10)%64), (gameticks + i*2*40) % 128 )
	end
end

function draw_game_won()
	-- draw background
	draw_bg()
	draw_floor_and_roof()

 	-- player
 	flipx = player_direction == dir_left
 	if band(gameticks, 4) > 0 then
 		spr(0, sx(x), sy(y), 2, 2, flipx)
 	else
 		spr(18, sx(x), sy(y), 2, 2, flipx)
 	end

	color(7)
 	print("chill factor: 100%", 33, 2)

	palt(0, false)
 	palt(15, true)
 	penguin_s = spr_penguin1
	if band(gameticks, 4) > 0 then
		penguin_s = spr_penguin2
	end
	spr(penguin_s, penguin_x, penguin_y, 2, 2)
	palt()

	particles_draw()

 	if ending_state == 2 then
 		step_print("wow", 80, 50)
	elseif ending_state == 3 then
		step_print("everything is so chill", 200, 10)
	elseif ending_state == 5 then
		step_print("i love you mr chill", 130, 40)
	elseif ending_state == 6 then
		step_print("please have my babies", 120, 40)
	elseif ending_state == 8 then
		step_print("i have places to be", 140, 15)
	elseif ending_state == 9 then
		step_print("people to chill", 100, 20)
	elseif ending_state == 10 then
		step_print("besides", 50, 40)
	elseif ending_state == 11 then
		step_print("theres no chill in children", 150, 5)
	end
end

function step_print(slowtext, end_count, textx)
	was_printed = slow_print(slowtext, ending_ticker, end_count, textx, 80)
	if was_printed then
		ending_state += 1
		ending_ticker = 0
	end
end

function slow_print(slowtext, ticker, maxtick, textx, texty)
	chars_to_show = 1 + (ticker / 4)
	if chars_to_show >= #slowtext then
		print(slowtext, textx, texty)
	else
		print(sub(slowtext, 1, chars_to_show), textx, texty)
		play_sfx(53)
	end
	return ticker >= maxtick
end

function draw_dead()
	-- draw background
	draw_bg()
	draw_floor_and_roof()

 	-- enemies
 	enemies_draw()

 	-- particles
	bullets_draw()
 	particles_draw()

	color(7)
 	print("chill factor: " .. score .. "%", 33, 2)
 	print("game over", 45, 42)
 	print("continue ", 50, 72)
 	print("restart ", 50, 82)
 	print("main menu ", 50, 92)
 	if menu_option == 0 then
		rectfill(40, 72, 43, 75, 7)
	elseif menu_option == 1 then
		rectfill(40, 82, 43, 85, 7)
	elseif menu_option == 2 then
		rectfill(40, 92, 43, 95, 7)
	end
end


function stage_update()
	new_stage = get_stage()
	if new_stage > stage then
		stage = new_stage
		new_music = get_game_music()
		if new_music != cur_music then
			cur_music = new_music
			music(new_music, 0, 7)
		end
		play_sfx(57)
		bullet_sound_counter = 20
	end
	if stage > 0 then
		shake = stage
	end
	if stage == 10 then
		score = 100
		game_state = state_game_won
		music(-1, 0, 7)
 	end
end


function dumb_text_draw()
	if stage == 1 then
 		big_print("chill", 25, 20)
		big_print("streak", 15, 40)
 	elseif stage == 2 then
 		big_print("monster", 10, 20)
		big_print("chill", 25, 40)
 	elseif stage == 3 then
 		big_print("chill", 25, 20)
		big_print("frenzy", 10, 40)
 	elseif stage == 4 then
 		big_print("chilling", 0, 20)
		big_print("spree", 25, 40)
 	elseif stage == 5 then
 		big_print("2 chill", 10, 20)
		big_print("4 me", 30, 40)
 	elseif stage == 6 then
 		big_print("#chill", 20, 20)
 	elseif stage == 7 then
 		big_print("chill", 25, 20)
 		big_print("cosby", 25, 40)
 	elseif stage == 8 then
 		big_print("licensed", 0, 20)
 		big_print("to chill", 0, 40)
 	elseif stage == 9 then
 		big_print("very", 30, 20)
 		big_print("chill", 25, 40)
 	end
end

function get_stage()
	return flr(score / 10)
end

function draw_title()
	particles_draw()

	color(8)
	logospr(spr_logo_1, 14, 14)
	logospr(spr_logo_2, 20, 35)
	logospr(spr_logo_3, 22, 57)

	
end

function draw_bg()
	rectfill(0, 0, 127, 127, 0)

	if stage >= 1 then
		draw_snow_bg()	
	end
	if stage >= 3 and game_state == state_game then
		particle_spawn(rnd(128), 0, 0, 4+rnd(2), 40, 1+rnd(2), 12)
	end
	if stage >= 5 and game_state == state_game then
		particle_spawn(16+rnd(94), rnd(128), rnd(10)-5, rnd(10)-5, 11, 3)
	end
	if stage >= 8 and game_state == state_game then
		draw_chill_game_text()
	end
end

function draw_snow_bg()
	
end

function draw_floor_and_roof()
	palt(0, false)
	palt(1, true)
	for t=-1,8,1 do
		if game_state == state_game_won then
			tmp = 16
		else
			tmp = 16-2*band(gameticks, 15)
		end
		tmp += t*16
		spr(4, sx(tmp), sy(110), 2, 1)
		spr(4, sx(tmp), sy(20), 2, 1)
	end
	palt()
end

function draw_chillray()
	ty = y + 1
	if player_direction == dir_left then
		spr_tmp = spr_chill_l2
		for t=x,0,-4 do
			if spr_tmp < spr_chill_c then
				spr_tmp = spr_chill_l2
			else
				spr(spr_tmp, sx(t+rnd(2)), sy(ty+rnd(6)))
				spr_tmp -= 1
			end
		end
	else
		spr_tmp = spr_chill_c
		for t=x+13,127,4 do
			if spr_tmp > spr_chill_l2 then
				spr_tmp = spr_chill_c
			else
				spr(spr_tmp, sx(t+rnd(2)), sy(ty+rnd(6)))
				spr_tmp += 1
			end
		end
	end
end

function intersects_bullet(enemy)
	ex = enemy.x
	ey = enemy.y
	function b_intersects(b)
		ymatch = b.y > (ey-5) and b.y < (ey+16+2)
		xmatch = b.x > (ex-2) and b.x < (ex+14)
		if ymatch and xmatch and not enemy.dead then
			enemy.dead = true
			score += 1
		end
	end
	foreach(bullets, b_intersects)
end

enemies = {}
function enemy_spawn(x, y, vx, vy, bounce, enemy_type)
	e = {x=x,y=y,vx=vx,vy=vy,bounce=bounce,enemy_type=enemy_type,dead=false}
	add(enemies, e)
end
function enemies_move()
	function e_move(e)
		e.x+=e.vx
		e.y+=e.vy
		e.vy += gravity
		if e.y > 95 and e.vy >= 0 then
			e.y = 95
			e.vy = -e.bounce
		end
		if e.x <= 0 then
			e.x = 0
			e.vx = -e.vx
		end
		if e.x >= 125 then
			e.x = 125
			e.vx = -e.vx
		end
		if intersects_bullet(e) then
			e.dead = true
		end
	end
	foreach(enemies, e_move)
end
function enemies_prune() -- todo: optimize maybe?
	new_e = {}
	for e in all(enemies) do
		if not e.dead then
			add(new_e, e)
		else 
			make_explosion(e.x, e.y)
			if game_state == state_game then
				play_sfx(58)
				bullet_sound_counter = 6
			end
		end
	end
	enemies = new_e
end
function enemies_draw()
	function e_draw(e)
		flipx = e.vx > 0
		-- TODO: this sprite handling should likely be moved into enemy object
		sss = spr_enemy1_1
		if band(stage, 1) == 1 then
			sss = spr_enemy2_1
		end
		if band(gameticks, 7) >= 4 then
			sss -= 32
		end
		spr(sss, sx(e.x), sy(e.y), 2, 2, flipx)
	end
	foreach(enemies, e_draw)
end
function clear_enemies()
	enemies = {}
end

cur_bul = spr_chill_c;
function next_bullet()
	if player_direction == dir_right then
		if cur_bul < spr_chill_c then
			cur_bul = spr_chill_l2
			return 0
		end
		t = cur_bul
		cur_bul -= 1
	end
	if player_direction == dir_left then
		if cur_bul > spr_chill_l2 then
			cur_bul = spr_chill_c
			return 0
		end
		t = cur_bul
		cur_bul += 1
	end

	return t
end


bullets = {}
function bullet_spawn(x, y, vx, vy, sprite)
	b = {x=x,y=y,vx=vx,vy=vy,sprite=sprite}
	add(bullets, b)
end
function bullets_move()
	function b_move(b)
		b.x+=b.vx
		b.y+=b.vy
	end
	foreach(bullets, b_move)
end
function bullets_prune() -- todo: optimize maybe?
	new_b = {}
	for b in all(bullets) do
		if b.x > -3 and b.x < 130 then
			add(new_b, b)
		end
	end
	bullets = new_b
end
function bullets_draw()
	function b_draw(b)
		spr(b.sprite, sx(b.x), sy(b.y))
	end
	foreach(bullets, b_draw)
end

------
-- cool utils below.
---

function logospr(s,dx,dy)
  sspr(8*(s%16),8*flr(s/16),8*6,8,dx,dy,8*6*2,8*2)
end

function zoomspr(s,dx,dy,zoom)
  sspr(8*(s%16), 8*flr(s/16),8,8,dx,dy,8*zoom,8*zoom)
end

function big_print(bigtext,tx,ty)
	for t=1,#bigtext,1 do
		sss = spr_big_a
		sss += char_num(sub(bigtext, t, t))
		zoomspr(sss, sx(tx), sy(ty), 2)
		tx += 16
	end
	-- spr_big_a + 
end

-- pico-8 lua is literally the worst
char_data = {
	a = 0 , b = 1 , c = 2 , d = 3 , e = 4 , f = 5 , g = 6 , h = 7 ,
	i = 8 , j = 9 , k = 10 , l = 11 , m = 12 , n = 13 , o = 14 ,
	p = 15 , q = 16 , r = 17 , s = 18 , t = 19 , u = 20 , v = 21 ,
	w = 22 , x = 23 , y = 24 , z = 25 ,
}
-- yup, still the worst
char_data[" "] = 26
char_data["#"] = 27
char_data["2"] = 28
char_data["4"] = 29
function char_num(s)
	-- there must be a better way to do this, why is there no ord() function?!?
	return char_data[s]
end

function make_explosion(ex, ey)
	for t=1,25,1 do
		particle_spawn(ex, ey, rnd(10)-5, rnd(10)-5, 12, 1+rnd(4))
	end
end

-- simple particle engine
particles = {}
function particle_spawn(x, y, vx, vy, ticks, size, colr)
	p = {x=x,y=y,vx=vx,vy=vy,ticks=ticks,size=size,colr=colr}
	add(particles, p)
end
function particles_move()
	function p_move(p)
		p.x+=p.vx
		p.y+=p.vy
		p.ticks-=1
	end
	foreach(particles, p_move)
end
function particles_prune() -- todo: optimize maybe?
	new_p = {}
	for p in all(particles) do
		if p.ticks > 0 then
			add(new_p, p)
		end
	end
	particles = new_p
end
function particles_draw()
	function p_draw(p)
		colr = p.colr
		if not p.colr then
			colr = rnd(16)
		end
		rectfill(sx(p.x),sy(p.y),sx(p.x+p.size-1),sy(p.y+p.size-1),colr)
	end
	foreach(particles, p_draw)
end
function clear_particles()
	particles = {}
end
-- end of particle engine --
function play_sfx(sfxsample)
	sfx(sfxsample, 3)
end

__gfx__
0022200000000000665006565560056566605000605060000000000000000000cc90eb400000000000000000000000000000000000000000222303a0e0500000
0020000000000000605000565060006560005000005060000c0c0c0000000000c0990b40000000000000000000000000000000000000000020030300e0500000
002000000000000060555656506665656000555060506000c0ccc0c000000000cc99eb400000000000000000000000000000000000000000200333a0e0500000
0022200000000000665056565560656566605050605060000c0c0c0000000000000000000000000000000000000000000000000000000000222303aaee550000
000000000000000011111111111111111111111111111111ccccccc0000000000000000000000000000000000000000000000000000000000000000000000000
0030300000000000111111111111111111111111111111110c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000
003030000000000011111111111111111111111111111111c0ccc0c0000000000000000000000000000000000000000000000000000000000000000000000000
003330aaa0a00000111111111111111111111111111111110c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000
003030a0000000000022200000000000002220000000000044440000800800000d000000b0000000500000000000000000000000000000000000000000000000
00300000000000000020000000000000002000000000000040000000800800000d000000b0000000500000000000000000000000000000000000000000000000
0000d000000000000020000000000000002000000000000040000000888800000d000000b0000000500000000000000000000000000000000000000000000000
00e0d000000000000022200000000000002220000000000044440000800800000d000000bbb00000555000000000000000000000000000000000000000000000
00e0d0000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e0ddd00000000000303000000000000030300aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00eee00000000000003030aaa0a00000003030aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000003330a000000000003330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022200000000000003030000000000000303000000000000d000000b000000000000000bb00000bffffffffffffffffffffffffffffffff0000000000000000
0020000000000000000030000000000000003000000000000d000000b000000000000000b907700bffff66666fffffffffff66666fffffff0000000000000000
002000000000000000e000000000000000e00000000000000d000000b0000000000000009970770bfff6000066fffffffff6000066ffffff0000000000000000
002220000000000000e0d0000000000000e0d000000000000d000000bbb0000000000000b977770bff907770006ffffffff07770006fffff0000000000000000
0000000000a0000000e0d0000000000000e0d00000000000000000000000000000000000bb07700bf9970770006fffffff970770006fffff0000000000000000
0030300aa000000000eee0000000000000eee00000000000000000000000000000000000bb00000b99970070006ffffff9970070006fffff0000000000000000
003030aa000000000000ddd0000000000000ddd000000000000000000000000000000000bb00009bf9977770006fffff99977770006fffff0000000000000000
003330000000000000000000000000000000000000000000000000000000000000000000b999b99bfff97770006ffffff9997770006fffff0000000000000000
00303000000000000000000000000000000000000000000050000000000000000000000000000000ff667770006fffffff667770006fffff0000000000000000
00300000000000000000000000000000000000000000000050000000000000000000000000000000ff600000006fffffff600000006fffff0000000000000000
0000d000000000000000000000000000000000000000000050000000000000000000000000000000ff600000006fffffff600000006fffff0000000000000000
00e0d000000000000000000000000000000000000000000055500000000000000000000000000000ff600000006fffffff600000006fffff0000000000000000
00e0d000000000000000000000000000000000000000000000000000000000000000000000000000fff60000006ffffffff60000006fffff0000000000000000
00e0ddd0000000000000000000000000000000000000000000000000000000000000000000000000fff99000996ffffffff99009996fffff0000000000000000
00eee000000000000000000000000000000000000000000000000000000000000000000000000000ff999666996fffffffff9669966fffff0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000ff999ff999fffffffff99f999fffffff0000000000000000
000000000000fffffffffc000000fffffffffc000000000000000000088808880000000000888000088888000888888000888888000000000000000000000000
00000000000ff5555555ffc0000ffeeeeeeeffc00000000000000000888888880880000088888800088888808888888008888888000000000000000000000000
000000000ffff5555555fffc0ffffeeeeeeefffc0000000000000000888888880880088088008800088088808880000008800888000000000000000000000000
000000000f5ff5155155f5fc0feffe11e11efefc0000000000000000880880880880088088808800088008808888880008888888000000000000000000000000
000000000f5f55155155f5fc0fefee11e11efefc00000000000000008880008808800880088888800eeeeee08888880008888880000000000000000000000000
000000000f555555555555fc0feeeeeeeeeeeefc0000000000000000eee000ee0eee0ee00eeeeeee0eeeee00eee000000eeeeeee000000000000000000000000
000000000f555555555555fc0feeeeeeeeeeeefc00000000000000000ee000ee00eeeee00ee00eee0eee0000eeeeeee00ee00eee000000000000000000000000
000000000ff555511555fffc0ffeee1111eefffc0000000000000000000000e000eeee00000000ee0000000000eeeee00ee0000e000000000000000000000000
0000000000ff55511555fffc00ffee1111eefffc0000000000000000099999000999999900099000000009999900009900000000000000000000000000000000
00000000000f55511555fc00000fee1111eefc000000000000000000999999900999999900099900999999999990009900000000000000000000000000000000
00000000000f55555555fc00000feeeeeeeefc000000000000000000999099990999900000999900999999000990009900000000000000000000000000000000
00000000000f55555555ffc0000feeeeeeeeffc00000000000000000999009990999999000999990000099000990999900000000000000000000000000000000
00000000000f55fff5555fc0000feefffeeeefc00000000000000000999000990990999000990990000099000999999900000000000000000000000000000000
00000000000f5ffcff55ffc0000feffcffeeffc000000000000000000ee00eee0ee000000eeeeee00000ee000eeeeeee00000000000000000000000000000000
00000000000fffc00f555fc0000fffc00feeefc000000000000000000eeeeeee0eeeeee0eeeeeeee0000ee000ee000ee00000000000000000000000000000000
00000000000000000fffffc0000000000fffffc000000000000000000eeeeee00eeeeee0eee000ee0000ee000ee000ee00000000000000000000000000000000
000000000000fffffffffc000000fffffffffc0000000000000000000ccccc00ccc00cc0000cc0000cc000000cc0000000000000000000000000000000000000
00000000000ff5555555ffc0000ffeeeeeeeffc000000000000000000cccccc0ccc00ccc000cc0000cc000000cc0000000000000000000000000000000000000
00000000000ff5555555ffc0000ffeeeeeeeffc00000000000000000ccc0ccc00cc00ccc00ccc0000cc000000cc0000000000000000000000000000000000000
00000000000ff5155155fc00000ffe11e11efc000000000000000000ccc000000cc000cc00ccc0000cc000000cc0000000000000000000000000000000000000
00000000ffff55155155fffcffffee11e11efffc0000000000000000cc0000000ccccccc00ccc0000cc000000cc0000000000000000000000000000000000000
00000000f5555555555555fcfeeeeeeeeeeeeefc0000000000000000eeee0000eeeeeeee00eee0000ee0eee00eeee00000000000000000000000000000000000
00000000f5555555555555fcfeeeeeeeeeeeeefc0000000000000000eeeeeee0eee000ee000ee0000eeeeee00eeeeee000000000000000000000000000000000
00000000f5f555511555f5fcfefeee1111eefefc000000000000000000eeeee0ee0000ee000ee0000eeee0000000eee000000000000000000000000000000000
00000000ffff55511555fffcffffee1111eefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000f55511555fc00000fee1111eefc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ff55555555fc0000ffeeeeeeeefc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000f555555555ffc000feeeeeeeeeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000f5555fff55ffc000feeeefffeeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ff55ffcff5fc0000ffeeffcffefc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000f555fc0fffc00000feeefc0fffc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000fffffc0fffc00000fffffc0fffc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ccc00000ccccc000ccc0000cccccc000cccc0000000cc00000ccc0ccc00000000cc00000ccccc00cc000cc0cc0000000000000000000000000ccc0ccccccc0
00cccc00ccccccc00ccccccccccccccc0ccccc0000ccccc00cccccccccc000cc000cc00000ccccc00cc00ccc0cc000000ccc0ccc00cc00cc00ccccc0cccccccc
0cccccc0ccc00cc00cccccccccc00ccc0ccc00000cccccc00ccccccc0cc000cc000cc00000000ccc0cccccc00cc000000ccccccc00ccc0cc0cccccc0ccc00ccc
ccc0ccc00cc00cc00cc000cc0cc000cc0ccccc000cc000000cc000000cc000cc000cc00000000ccc0ccccc000cc000000ccccccc0cccc0ccccccccc00ccccccc
ccc00ccc0ccccccc0cc000000cc00ccc0ccccc000cccccc00cc0cc000ccccccc000cc000000000cc0cccc0000cc00000cccccccc0cccccccccc00ccc0cccccc0
cccccccc0cc00ccc0cccc0000ccccccc0cc000000cccccc00cc0ccc00ccccccc00ccc00000cc0ccccccccc000cc00000cc0cc0cc0cc0ccc0ccc00ccc0cc00000
cccccccc0ccccccc0ccccccc0cccccc00cccccc00ccc00000cccccc00ccc00cc00ccc00000cccccccccccc000ccccc00cc0000cc0cc0ccc00ccccccc0ccc0000
cc00000c0cccccc0000ccccc0cccc0000cccccc00ccc00000cccccc00cc000cc00cc000000ccccc0cc00cccc0ccccc00cc0000cc0cc00cc00cccccc00ccc0000
00ccc00000cccc0000cccccc0cccc0000cc00cc0cc00000000000000ccc000000cc000cccccccccc000000000cc00cc0cccccccccc0000cc0000000000000000
ccccccc0ccccccc00ccccccccccccccc0cc00cc0ccc00ccc000000cccccc0ccc0ccc0ccccccccccc00000000ccc00cc0cccc0cccccc000cc0000000000000000
ccc0ccc0ccccccc00ccc00cccccccccc0cc00cc0ccc0cccccc0000cc0ccccccc0ccccccc000cccc000000000cccccccccc0000ccccc00ccc0000000000000000
cc00ccc0cc00ccc00ccccc00000cc000ccc0ccc00cc0ccc0cc0000cc00ccccc000ccccc000cccc00000000000ccccccc0000cccc0ccccccc0000000000000000
cc000c00ccccccc00ccccccc000cc000cc00cc000ccccc00cc0cc0cc00ccccc0000ccc00ccccc000000000000cc00cc0000ccccc0ccccccc0000000000000000
cc00cc000ccccc000000cccc000cc000ccc0cc000ccccc00cc0cc0cc0ccccccc000cc000ccc0000000000000cccccccc0ccccc0000000ccc0000000000000000
cccccccc0ccccccc0cc00ccc000cc000cccccc0000ccc000cccccccc0ccc0ccc000cc000cccccccc00000000cccccccccccccccc000000cc0000000000000000
cccc00cc0cc00ccc0ccccccc000cc0000ccccc0000ccc000cccccccc0cc000cc000cc00000cccccc000000000cc00cc0cccccccc000000cc0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000110110110000000000000000000000005505505500000000000000000c0c0c000000000000000000000000000000000000000000000000000000
0000000000001111111100000000000000000000000055555555000000000000000000ccc0000000000000000000000000000000000000000000000000000000
00000000000001111110000000000000000000000000055555500000000000000000c00c00c00000000000000000000000000000000000000000000000000000
000000000000001111000000000000000000000000000055550000000000000000c00c0c0c00c000000000000000000000000000000000000000000000000000
0000011001011001100110100110000000000550050550055005505005500000000c00cdc00c0000000000000000000000000000000000000000000000000000
00000111010111011011101011100000000005550505550550555050555000000c00c00d00c00c00000000000000000000000000000000000000000000000000
0000001111001111111100111100000000000055550055555555005555000000cccccdddddccccc0000000000000000000000000000000000000000000000000
00000001110011111111001110000000000000055500555555550055500000000c00c00d00c00c00000000000000000000000000000000000000000000000000
0000011111101011110101111110000000000555555050555505055555500000000c00cdc00c0000000000000000000000000000000000000000000000000000
000000000111100110011110000000000000000005555005500555500000000000c00c0c0c00c000000000000000000000000000000000000000000000000000
00110001001110011001110010001100005500050055500550055500500055000000c00c00c00000000000000000000000000000000000000000000000000000
0011100111111101101111111001110000555005555555055055555550055500000000ccc0000000000000000000000000000000000000000000000000000000
000111000100111111110010001110000005550005005555555500500055500000000c0c0c000000000000000000000000000000000000000000000000000000
00001110001001111110010001110000000055500050055555500500055500000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111111111111100005555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111111111111100005555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000
00001110001001111110010001110000000055500050055555500500055500000000000000000000000000000000000000000000000000000000000000000000
00011100010011111111001000111000000555000500555555550050005550000000000000000000000000000000000000000000000000000000000000000000
00111001111111011011111110011100005550055555550550555555500555000000000000000000000000000000000000000000000000000000000000000000
00110001001110011001110010001100005500050055500550055500500055000000000000000000000000000000000000000000000000000000000000000000
00000000011110011001111000000000000000000555500550055550000000000000000000000000000000000000000000000000000000000000000000000000
00000000111010111101011111100000000000005550505555050555555000000000000000000000000000000000000000000000000000000000000000000000
00001111110011111111001110000000000055555500555555550055500000000000000000000000000000000000000000000000000000000000000000000000
00000011100011111111001111000000000000555000555555550055550000000000000000000000000000000000000000000000000000000000000000000000
00000111100111011011101011100000000005555005550550555050555000000000000000000000000000000000000000000000000000000000000000000000
00001110100110011001101001100000000055505005500550055050055000000000000000000000000000000000000000000000000000000000000000000000
00001100100000111100000000000000000055005000005555000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000001111110000000000000000000000000055555500000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000011111111000000000000000000000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000011011011000000000000000000000000550550550000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000001010101010000000000000000000000010100000202000000000000000000000000000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
012800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013c0020005340053000530005350b5340b5300b5300b535100341003010030100350c0340c0300c0300c0300c0300c0300c0300c0300c0300c0300c0300c0300c0300c0300c0300c0300c0300c0300c0300c030
013c00200753407530075300753504534045300453004535090340903009030090350503405030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030
010f00000523405030050300503005030050300503005030042340403004030040300403004030040300403007234070300703007030070300703007030070300623406030060300603006030060300603006030
01010020004100e4100441011410004100e4100441011410004100e4100441011410004100e4100441011410004100e4100441011410004100e4100441011410004100e4100441011410004100e4100441011410
010100200241010410054101341002410104100541013410024101041005410134100241010410054101341002410104100541013410024101041005410134100241010410054101341002410104100541013410
010f00000c2340c0300c0300c0300c0300c0300c0300c0300b2340b0300b0300b0300b0300b0300b0300b0300e2340e0300e0300e0300e0300e0300e0300e0300d2340d0300d0300d0300d0300d0300d0300d030
010f001000133000000c62524605001630c62500000000000c625000000c62524625001630c0000c6350000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00000522405220052200522005220052200522005220042240422004220042200422004220042200422007224072200722007220072200722007220072200622406220062200622006224062200622006220
010f00000c2240c2200c2200c2200c2200c2200c2200c2200b2240b2200b2200b2200b2200b2200b2200b2200e2240e2200e2200e2200e2200e2200e2200e2200d2240d2200d2200d2200d2240d2200d2200d220
010f0020001430c6250c6250c620001630c6350c6350c615001430c6350c6350c635001630c6450c6450c615001430c6350c6350c635001630c6350c6350c615246350c6350c6350c635246350c6450c6450c630
012000000013000130001300013004130041300413004130041300413004130041300513005130051300513000120001200970000120001200920000120001000012000120091000012000120171000012000120
0120000013020130200e0200e0200c0200c0200c0200c020100201102010020110201302011020130201102012020120100f0200f0100f0200f01012020120101002011020100201102010020110201002011020
012000000012000120091000012000120000000012000000091200912000000091200912000000091200000007120071200000007120071200000007120000000b1200b120000000b1200b120000000b12000000
011000000c2101121018210112100c2101121018210112100c2101121018210112100c2101121018210113100c4101131018210114100c3101121018410113100c2101131018210113100c210113101821011310
001000001821018210181101811018210181101811018110181101811018110181101811018110181101811018210181101821018110182101811018210181101a2101a1101a2101a11018210181101821018110
001000000c0100c0100e0100e010130100c0100e01013010130100c0100e0100c010130100c010130100c0100e0100c010130100c010130100c0100e0100c010130100c010130100c0100e0100c010130100c010
001000001f1201f2101f1201f210182201f210182201f2101d1201d1101d1201d1101d1101d1201d1101d1201a1201a1101a1201a110181201a110181201f1101d2201d1101d2201d110182201f210182201f210
010f00000003000035000300003500030000300003500035000350003500030000350003000030000300003500030000350003000035000300003000035000350003000035000300003500030000350003000035
010f00000532505320053250532005325053200532505320043250432004325043200432504320043250432007325073200732507320073250732007325073200632506327063250632706325063270632506327
010f00000c3200c3200c3200c3200c3200c3200c3200c3200b3200b3200b3200b3200b3200b3200b3200b3200e3200e3200e3200e3200e3200e3200e3200e3200d3200d3200d3200d3200d3200d3200d3200d320
010f00000c234004200c4201842024420184200c4200042017234004200b4201742023420174200b420174200e234024200e4201a420264201a4200e420024200d234014200d420194200d424014200d42019420
010f00000523405030050300503005030050300503005030042340403004030040300403004030040300403007234070300703007030070300703007030070300623406030060300603006034060300603006030
010f00000522405420114201d420294241d42011220054200422404420104201c420284241c42010420044200722407420134201f4202b4241f420134200742006224124201e4201242006224124201e42012420
010f00000c2240c2200c2200c2200c2200c2200c2200c2200b2240b2200b2200b2200b2200b2200b2200b2200e2240e2200e2200e2200e2200e2200e2200e2200d2240d2200d2200d2200d2240d2200d2200d220
010f000005324114201d4201142029424113201d3201132004224104201c4201042028424104201c4201042007224134201f4201342007424134201f4201342006224124201e420124202a224124201e42012420
010f00000c2240c4200c4200c4200c4240c4200c4200c4200b2240b2200b2200b2200b2240b2200b2200b2200e2240e2200e2200e2200e2240e2200e2200e2200d2240d2200d2200d2200d2240d2200d2200d220
001000000042102421004210242100421024210042102421004210242100421024210042102421004210242100421024210042102421004210242100421024210042102421004210242100421024210042102421
010f000029310293112931129311293111d311293112931628311283112831128311283112831628316283112b3112b3112b3112b3112b3112b3162b3162b3112a3112a3112a3112a3112a3112a3162e3161e311
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000191101b1102011022110191201b1202012022120191301b1302013022130191401b14020140221401915019150191501915019150191501e1501e1501b1501b1501b1501b1501b1501b1502015020150
01100000191501b1501e15020150191501b1501e150201501b1501b1501b1501b1501b1501b1501e1501e1502015020150201502015020150201501e1501e1501b1501b1501b1501b1501b1501b1502015020150
0110000022150221002215022150201502010020150201501e1501e1001e1501e1501b1501b1501b1501b150191501b1501e15020150191501b15020150221501b1501b1501b1501b1501b1501b1501e1501e150
011000001b1501b0701b1501b0701b1501b0701b1501b0701e1501e0701e1501e0701e1501e0701e1501e070191401b1402014022140191301b1302013022130191201b1202012022120191101b1102011022110
011000000c673186551865518655186551867519655186750c6730110018655180000c3730110024655246050c6730110024655246050c2730000024655246050c6730310024655031000c473031002465524655
011000000c6551864524635306250c655246451863530665246550c655246651864530655246650c64530655246650c645306550c665246450c65518665246450c665246450c65518665246450c6551866524645
011000000141003410084100a4100142003420084200a4200143003430084300a4300144003440084400a44001450014500145001450014500145006450064500345003450034500345003450034500845008450
011000000145003450064500845001450034500645008450034500345003450034500345003450064500645008450084500845008450084500845006450064500345003450034500345003450034500845008450
011000000a4500a4000a4500a450084500840008450084500645006400064500645003450034500345003450014500345006450084500145003450084500a4500345003450034500345003450034500645006450
01100000032500307003250030700325003070032500307006250060700625006070062500607006250060700124003240082400a2400123003230082300a2300122003220082200a2200121003210082100a210
01100000011000110001100011000110001100011000110001100011000110001100011000110001100011000c3730110324633246330c3730000324633246030c3730310324633031030c373031032463324633
011000001866318663186631866318653186531865318653186431864318633186331862318623186131861300005000050000500000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c6350c6350c6450c6450c6550c6550c6650c665
010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000193430a403263001b0000c3000c3000e3000d3000f30010300193000d3000f3000c3000c3000e00010000110000c0000e00010000362000f00018000190000c0000d0000a2000a2000a2002220018000
00030000095300b5300c5300d5300f53011530135301a5401f5402154024100291002e10031100311002f1002d100261002210026400224001d4000e40007400074000a400344000e400144001a4002240024400
00050000215703157033570355702e57021570235702957030570325702d570265702057022570255702b5702e57030570305702f5702d5702c57029570235701c57016570105700d5700b570085700757004570
000900001f3701f37032370323702e3002a300293000d3000d3000d3000d3000c3000c3000c3000c3000c3000c3000b3000b3000c3000c3000c3000c3000c3000c3000c3000c3000c3000c3000c3000c3000c300
000400000c37011370163702a3702d37018370183701e3702b370333702b3002e3002f300353002f3001d0001e00023000290002c000250001f00021000250002b0003100036000390003a0003c0003d0003e000
000a0000263201f32022320223001a1001a1001a1001a1001a1001a1001a1001a1001b1001b1001c1001c1001c1001c1001d1001e1001e1001e1001e1001e1001e100171001d1001d1001c1001c1001910018100
010a0000120030f0030f0030f0030f7060f003120030f0030c0000f003120030e000100000e0000e000100000e0000e0000e00011000110000c0000e000110000c000110000c0000e00011000110000c00011000
000a0004110220c02210022100021060610603144000a4001040012400174001b400254002c4002e4001140014400154001640017400000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 4e0f5011
00 410f1011
00 0e0f1051
02 0e0f5051
00 01020044
03 06031244
03 15161244
03 08091244
03 17181244
03 13171844
03 1c191a51
02 4e4f4344
02 4f424344
00 41424344
00 41424344
01 1f252b44
00 20262344
00 21272444
02 22282a44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

