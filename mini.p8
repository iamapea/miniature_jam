pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- init -------------------
-- hello world!
function _init()
 -- game constants
 player_speed_x = 0.3
 jump_speed = 1
 bullet_speed = 1
 world_size_x = 127
 world_size_y = 127
 aim_speed = 0.01
 ground_color = 13
 ground_height = 20
 grav_acc_bullet = 0.01
 grav_acc_player = 0.04
 cooldown_bullet = 60
 player_spawn_y = world_size_y-ground_height-20
 -- visual parameters
 col_players = {8,9}
 col_ch = 10 --crosshair
 col_bullet = 6
 -- create players
 p1 = new_player(20,player_spawn_y,
                 col_players[1],
                 -.5,0)
 p2 = new_player(108,player_spawn_y,
                 col_players[2],
                 .5,0)
 players = {p1,p2}
 -- bullets
 bullets = {}
 -- ground
 ground = init_ground()
 --screen shake variables
 intensity = 0
 shake_control = 5
end

function init_ground()
 g = {}
 iy=world_size_y-ground_height
 for i=iy, world_size_y+1 do
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
  collision_edge(p)
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
 cleanup_bullets()
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
  pset(p.x,p.y,p.c)
  pset(p.x,p.y,p.c)
  --draw crosshair
  pset(p.x+cos(p.aim/2+0.25)*10,
       p.y+sin(p.aim/2+0.25)*10,col_ch)
 end
 --draw bullets
 for b in all(bullets) do
  pset(b.x,b.y,col_bullet)
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

function new_player(x,y,c,aim,
                    cool)
 it = {}
 it.x = x --position
 it.y = y
 it.vx = 0 --velocity
 it.vy = 0
 it.ay = grav_acc_player
 it.c = c --color
 it.aim = aim
 it.cooldown = cool
 it.is_explosive = false
 it.is_airborne = true
 it.jumps = false
 it.exploded = false
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
 return it
end

-->8
-- physics -------------------
function collision_ground(t)
 -- if current pixel is ground
 if pget(t.x,t.y)==ground_color then
  if t.vy < 0 then
   --move down out of ground
   while  pget(t.x,t.y)==ground_color do
    t.y = flr(t.y)+1
   end
   t.vy = 0
  else
   --move up out of ground
   while  pget(t.x,t.y)==ground_color do
    t.y = flr(t.y)-1
   end
   t.is_airborne = false
  end
  if t.is_explosive then
   explode(t)
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
 collided = false
 if t.x < 0 then
  t.x = 0
  collided = true
 elseif t.x > 127 then
  t.x = world_size_x
  collided = true
 end
 if t.y >= world_size_y then
  t.y = world_size_y
  t.is_airborne = false
  collided = true
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

function explode(t)
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
 for i = 1,#players do
  p = players[i]
  if distance(p,t) < t.exp_rad then
   kill_player(i)
  end
 end
end

function kill_player(index)
 spawn_x = flr(rnd(100))+14
 if spawn_x > 64 then
  spawn_aim = .5
 else
  spawn_aim = -.5
 end
 cd_tmp=players[index].cooldown
 players[index] = 
   new_player(flr(rnd(120))+3,
              player_spawn_y,
              col_players[index],
              spawn_aim,cd_tmp)
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
	 end
	 -- jump
	 if not p.is_airborne and
	    btn(🅾️,i) then
	  p.jumps = true
	  p.is_airborne = true
	  p.vy = - jump_speed
	 end
	end --for i in 1,#players
end
-->8
-- util -----------------
function distance(a,b)
 return sqrt((a.x - b.x)^2 +
             (a.y - b.y)^2)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
