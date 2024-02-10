pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- init -------------------
-- hello world!
function _init()
 -- game constants
 player_speed_x = 1
 bullet_speed = 1
 world_size_x = 127
 world_size_y = 127
 aim_speed = 0.01
 grav_acc = 0.01
 ground_color = 7
 ground_height = 20
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
  move(p)
  check_collisions(p)
 end
 for b in all(bullets) do
  move(b)
  check_collisions(b)
 end
end

function move(t)
 t.vy += t.ay
 t.x += t.vx
 t.y += t.vy
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
 for row in all(ground) do
  for g in all(row) do
   pset(g.x,g.y,g.c)
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
 return it
end

function new_player(x,y,c,aim)
 it = {}
 it.x = x --position
 it.y = y
 it.vx = 0 --velocity
 it.vy = 0
 it.ay = grav_acc
 it.c = c --color
 it.aim = aim
 return it
end

function new_bullet(x,y,v,c,aim)
 it = {}
 it.x = x
 it.y = y
 it.vx = cos(aim)*v --velocity
 it.vy = sin(aim)*v
 it.ay = grav_acc
 return it
end
-->8
-- physics -------------------
function check_collisions(t)
 collision_edge(t)
end

function collision_edge(t)
 if t.x < 0 then
  t.x = 0
 elseif t.x > 127 then
  t.x = world_size_x
 end
 if t.y > world_size_y then
  t.y = world_size_y
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
	end --for i in 1,#players
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
