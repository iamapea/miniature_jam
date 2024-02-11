pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- init -------------------
-- hello world!
function _init()
 state = "play"
 -- game constants
 player_speed_x = 0.3
 jump_speed = 1
 bullet_speed = 1
 world_size_x = 127
 world_size_y = 127
 aim_speed = 0.015
 ground_color = 13
 ground_height = 20
 grav_acc_bullet = 0.01
 grav_acc_player = 0.05
 cooldown_bullet = 60
 lives = 5
 player_spawn_y = world_size_y-ground_height-50
 -- visual parameters
 col_players = {8,12}
 col_ch = 6 --crosshair
 col_bullet = 6
 -- create players
 p1 = new_player(1,20,player_spawn_y,
                 col_players[1],
                 -.5,0,lives)
 p2 = new_player(2,108,player_spawn_y,
                 col_players[2],
                 .5,0,lives)
 players = {p1,p2}
 -- bullets
 bullets = {}
 -- ground
 ground = init_ground()
 --screen shake variables
 intensity = 0
 shake_control = 5
 --state variables
 winner = nil --idx of player when state == over
end

function init_ground()
 g = {}
 iy=world_size_y-ground_height
 for i=iy, world_size_y+2 do
  g_row = {}
  ix = -2
  add(g_row,new_ground(ix,i,ground_color))
  while ix <= world_size_x+2 do
   add(g_row,new_ground(ix,i,ground_color))
   ix += 1
  end
  add(g,g_row)
 end
  
 return g
end
-->8
-- update -----------------
function _update60()
 --run shake when intensity high
 if intensity > 0 then shake() end

 --up, increase shake
 --if btnp(⬆️)
 --and shake_control < 10 then
 -- shake_control += 1
 --end

 --down, decrease shake
 --if btnp(⬇️)
 --and shake_control > 0 then
 -- shake_control -= 1
 --end

 --x, trigger shake
 --if btnp(❎) then intensity += shake_control end 

 handle_input()
 for p in all(players) do
  move_player(p)
  collision_ground(p)
  if collision_edge(p)==2 then
   --collision bottom screen edge
   handle_death(p.n)
  end
  if (p.cooldown>0) p.cooldown-=1
  p.jumps = false
 end
 for b in all(bullets) do
  move_bullet(b)
  collision_ground(b)
		if collision_edge(b) then
		 b.remove = true
		end  
 end
 collision_bullets(p)
 cleanup_bullets()
 update_state()
end

function move_player(t)
 if not t.jumps and
    is_on_ground(t) then
  t.vy = 0
 else
  t.vy += t.ay
 end
 t.x += t.vx
 t.y += t.vy
end

function move_bullet(t)
 t.vy += t.ay
 t.x += t.vx
 t.y += t.vy
end

function cleanup_bullets()
 --collect exploded bullets
 i_delete = {}
 for i = 1,#bullets do
  if bullets[i].remove then
   add(i_delete,i)
  end
 end
 --delete those from table
 for i in all(i_delete) do
  deli(bullets,i)
 end
end
-->8
-- draw --------------------
function _draw()
 cls(1) --clear screen black (0)
 --draw ground
 for row in all(ground) do
  for g in all(row) do
   if g.exists then
    pset(g.x,g.y,g.c)
   end
  end
 end
 --draw players
 for p in all(players) do
  if p.exists then
	  pset(p.x,p.y,p.c)
	  --draw crosshair
	  pset(p.x+cos(p.aim/2+0.25)*10,
	       p.y+sin(p.aim/2+0.25)*10,col_ch)
	 end
 end
 --draw bullets
 for b in all(bullets) do
  pset(b.x,b.y,col_bullet)
 end
 --draw lives
 pos_x = {3,124}
 pos_y = {3,3}
 for i = 1,#players do
  print(players[i].lives,
        pos_x[i],pos_y[i],
        players[i].c)
 end
 -- game over screen
 if state == "over" then
  print("player "..winner.." wins!",
        40,64,players[winner].c)
 end
 -- debug
 --print(players[1].aim)
end

function shake()
 local shake_x=rnd(intensity) - (intensity /2)
 local shake_y=rnd(intensity) - (intensity /2)

 --offset the camera
 camera( shake_x, shake_y )

 --ease shake and return to normal
 intensity *= .9
 if intensity < .3 then 
  intensity = 0 
  camera(0,0)
 end
end
-->8
-- things ----------------
function new_ground(x,y,c)
 it = {}
 it.x = x --position
 it.y = y
 it.vx = 0 --velocity
 it.vy = 0
 it.ay = grav_acc
 it.c = c --color
 it.exists = true
 return it
end

function new_player(n,x,y,c,aim,
                    cool,lives)
 it = {}
 it.n = n --player number
 it.x = x --position
 it.y = y
 it.vx = 0 --velocity
 it.vy = 0
 it.ay = grav_acc_player
 it.c = c --color
 it.aim = aim
 it.cooldown = cool
 it.lives = lives
 it.is_explosive = false
 it.is_airborne = true
 it.jumps = false
 it.exploded = false
 it.exists = true
 it.remove = false
 return it
end

function new_bullet(x,y,v,c,aim)
 it = {}
 it.x = x
 it.y = y
 it.vx = cos(aim/2+0.25)*v --velocity
 it.vy = sin(aim/2+0.25)*v
 it.ay = grav_acc_bullet
 it.exp_rad = 4 --explosion radius
 it.is_explosive = true
 it.exploded = false
 it.remove = false
 it.launch_time = time()
 return it
end

-->8
-- physics -------------------
function collision_ground(t)
 -- if current pixel is ground
 if pget(t.x,t.y)==ground_color then
  if t.is_explosive then
   explode(t)
  end
  --todo fix going into ground when at lower screen edge
  if t.vy < 0 and 
     t.y < world_size_y-1 then
   t.y = flr(t.y)+1
   t.vy = 0
  else
   --move up out of ground
   while  pget(t.x,t.y)==ground_color do
    t.y = flr(t.y)-1
   end
   t.is_airborne = false
  end
 end
end

function is_on_ground(t)
 -- if pixel below is ground
 if pget(t.x,t.y+1)==ground_color then
  t.is_airborne = false
  return true
 else
  t.is_airborne = true
  return false
 end
end

function collision_edge(t)
 --returns 1 for coll left/right
 -- .. and 2 for coll bottom
 collided = false
 if t.x < 0 then
  t.x = 0
  collided = 1
 elseif t.x > 127 then
  t.x = world_size_x
  collided = 1
 end
 if t.y >= world_size_y then
  t.y = world_size_y
  t.is_airborne = false
  collided = 2
 end
 return collided
end

function collision_left(t)
 if pget(t.x-1,t.y)==ground_color and
    pget(t.x-1,t.y-1)==ground_color and
   (pget(t.x-1,t.y-2)==ground_color or
    pget(t.x,  t.y-1)==ground_color) then
  return true
 end
 return false
end

function collision_right(t)
 if pget(t.x+1,t.y)==ground_color and
    pget(t.x+1,t.y-1)==ground_color and
   (pget(t.x+1,t.y-2)==ground_color or
    pget(t.x,  t.y-1)==ground_color) then
  return true
 end
 return false
end

function collision_bullets()
 i_bullets_exp = {}
 --ceck collision between bullets
 for i = 1,#bullets do
  for j = 1,#bullets do
   if not i == j then
    if distance(bullets[i],
                bullets[j]) < 1.5 then
     add(i_bullets_exp,i)
     add(i_bullets_exp,j)
     --todo fix
    end
   end
  end
  for j = 1,#players do
   if distance(bullets[i],
               players[j]) < 1.5 and
      time()-bullets[i].launch_time > 0.1 then
    add(i_bullets_exp,i)
   end
  end
 end
 -- explode collided bullets
 for i in all(i_bullets_exp) do
  explode(bullets[i])
 end
end

function explode(t)
 sfx(0)
 sfx(2)
 t.exploded = true
 t.remove = true
 -- trigger screen shake
 intensity += shake_control
 --check distance to ground pixels
 for row in all(ground) do
  for g in all(row) do
   if distance(g,t) < t.exp_rad then
    g.exists = false
   end
  end
 end
 --check distance to players
 i_dead_players = {}
 for i = 1,#players do
  p = players[i]
  if distance(p,t) < t.exp_rad then
   if handle_death(i) then
    add(i_dead_players,i)
   end
  end
 end
 --remove players w/o lives left
 for i in all(i_dead_players) do
  players[i].exists = false
 end
end

function handle_death(idx)
 -- if a player has no lives,
 --its index is returned
 sfx(3)
 spawn_x = flr(rnd(100))+14
 if spawn_x > 64 then
  spawn_aim = .5
 else
  spawn_aim = -.5
 end
 players[idx].lives -= 1
 if players[idx].lives == 0 then
  return idx
 else
  respawn(idx)
 end
 return nil
end

function respawn(idx)
 cd_tmp=players[idx].cooldown
 lives_tmp=players[idx].lives
 players[idx] = 
  new_player(idx,flr(rnd(120))+3,
             player_spawn_y,
             col_players[idx],
             spawn_aim,cd_tmp,
             lives_tmp)
end
-->8
-- input --------------------
function handle_input()
 for i = 0,#players-1 do 
  -- i: 0-indexed
  p = players[i+1]
  -- accelerate x
	 if (btn(⬅️,i) and
	 	  not btn(➡️,i)) then
	 	if (p.aim<0) p.aim=-p.aim
	  p.vx = -player_speed_x
   if (collision_left(p)) p.vx=0
	 elseif (btn(➡️,i) and
	 	      not btn(⬅️,i)) then
	 	if (p.aim>0) p.aim=-p.aim
   p.vx = player_speed_x
   if (collision_right(p)) p.vx=0
	 else
	  p.vx = 0
	 end
	 -- aim
	 if btn(⬆️,i) then
	  if p.aim>0+aim_speed and
	     p.aim<1 then
    p.aim -= aim_speed
   elseif p.aim < -aim_speed then
	   p.aim += aim_speed
	  end
	 elseif btn(⬇️,i) then
	  if p.aim>0 and
	     p.aim<1-aim_speed then
	   p.aim += aim_speed
   elseif p.aim<0 and p.aim>-1+aim_speed then
    p.aim -= aim_speed
   end
	 end
	 -- shoot
	 if btn(❎,i) and
	    p.cooldown == 0 then
	  add(bullets,
	      new_bullet(p.x,p.y,bullet_speed,
	                 col_bullet,p.aim))
	  p.cooldown += cooldown_bullet
	  sfx(1)
	 end
	 -- jump
	 if not p.is_airborne and
	    not p.jumps and
	    btn(🅾️,i) then
	  p.jumps = true
	  p.is_airborne = true
	  p.vy = - jump_speed
	  sfx(0)
	 end
	end --for i in 1,#players
end
-->8
-- game state and util -------
function update_state()
 if state == "play" then
  --only surviving player wins
  i_existing = {}
  for i = 1,#players do
   if players[i].exists then
    add(i_existing,i)
   end
  end
  if #i_existing == 1 then
   music(0)
   winner = i_existing[1]
   state = "over"
  end
 end
end

function distance(a,b)
 return sqrt((a.x - b.x)^2 +
             (a.y - b.y)^2)
end

-- sound effects:
--0: jump
--1: shoot
--2: explode
--3: hit
-- music:
--0: game over
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100001a130161300b1300713005130011300113000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
4801000003620076500d650196502764038620346003c6003d6003d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a03000037650206501865014650116500c6500765003630026200061000610006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
1102000000000000000000000000000000000011550155501a550285502c500005000050000500005000050000500005000050000500005000050000000000000000000000000000000000000000000000000000
010c000000000000000000000000000000000018050180401803018035000001a0501a0401a0301a0350000010050100401003010030100201002500000000000000000000000000000000000000001800000000
010c00000000000000000000000000000000001c0501c0401c0301c035000001e0501e0401e0301e035000001c0501c0401c0301c0301c0201c02500000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000001f0501f0401f0301f035000001e0501e0401e0301e0350000023050230402303023030230202302500000000000000000000000000000000000000000000000000
010c0000000000000000000000000000000000280502804028030280350000026050260402603026035000002c0502c0402c0302c0302c0202c02500000000000000000000000000000000000000000000000000
__music__
00 04050607

