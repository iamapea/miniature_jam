pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- init -------------------
-- hello world!
function _init()
 -- game constants
 player_speed_x = 1
 jump_speed = 1
 bullet_speed = 1
 world_size_x = 127
 world_size_y = 127
 aim_speed = 0.01
 ground_color = 7
 ground_height = 20
 grav_acc_bullet = 0.01
 grav_acc_player = 0.04
 ground_color = 7
 -- visual parameters
 col_ch = 10 --crosshair
 col_bullet = 6
 -- create players
 p1 = new_player(20,108,5,1)
 p2 = new_player(108,108,9,.5)
 players = {p1,p2}
 -- bullets
 bullets = {}
 -- ground
 ground = init_ground()
end

function init_ground()
 g = {}
 iy=world_size_y-ground_height
 for i=iy, world_size_y do
  g_row = {}
  ix = 0
  add(g_row,new_ground(ix,i,ground_color))
  while ix < world_size_x do
   ix += 1
   add(g_row,new_ground(ix,i,ground_color))
  end
  add(g,g_row)
 end
 
 return g
end
-->8
-- update -----------------
function _update60()
 handle_input()
 for p in all(players) do
  move_player(p)
  collision_ground(p)
  collision_edge(p)
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
 --draw players
 for p in all(players) do
  pset(p.x,p.y,p.c)
  pset(p.x,p.y,p.c)
  --draw crosshair
  pset(p.x+cos(p.aim)*10,
       p.y+sin(p.aim)*10,col_ch)
 end
 --draw bullets
 for b in all(bullets) do
  pset(b.x,b.y,col_bullet)
 end
 --draw ground
 for row in all(ground) do
  for g in all(row) do
   if g.exists then
    pset(g.x,g.y,g.c)
   end
  end
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

function new_player(x,y,c,aim)
 it = {}
 it.x = x --position
 it.y = y
 it.vx = 0 --velocity
 it.vy = 0
 it.ay = grav_acc_player
 it.c = c --color
 it.aim = aim
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
 it.vx = cos(aim)*v --velocity
 it.vy = sin(aim)*v
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
  -- move up one pixel
  t.y = flr(t.y)-1
  t.is_airborne = false
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

function explode(t)
 t.exploded = true
 t.remove = true
 --check distance to ground pixels
 for row in all(ground) do
  for g in all(row) do
   if distance(g,t) < t.exp_rad then
    g.exists = false
   end
  end
 end
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
	  p.vx = -player_speed_x
	 elseif (btn(➡️,i) and
	 	      not btn(⬅️,i)) then
   p.vx = player_speed_x
	 else
	  p.vx = 0
	 end
	 -- aim
	 if btn(⬆️,i) then
	  p.aim += aim_speed
	 elseif btn(⬇️,i) then
	  p.aim -= aim_speed
	 end
	 -- shoot
	 if btn(❎,i) then
	  add(bullets,
	      new_bullet(p.x,p.y,bullet_speed,
	                 col_bullet,p.aim))
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
