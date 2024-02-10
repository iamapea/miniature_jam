pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- init -------------------
function _init()
 -- game constants
 player_speed_x = 1
 world_size_x = 127
 world_size_y = 127
 -- create players
 p1 = new_player(20,108,8)
 p2 = new_player(108,108,9)
 players = {p1,p2}
end
-->8
-- update -----------------
function _update()
 handle_input()
 for p in all(players) do
  move(p)
  check_collisions(p)
 end
end

function move(t)
 t.x += t.vx
end
-->8
-- draw --------------------
function _draw()
 cls(1) --clear screen black (0)
 
 pset(p1.x,p1.y,p1.c)
 pset(p2.x,p2.y,p2.c)
end
-->8
-- things ----------------
function new_player(x,y,c)
 it = {}
 it.x = x --position
 it.y = y
 it.c = c --color
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
	end --for i in 1,#players
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
