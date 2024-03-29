--disable_preview = true


-- 1..15
difficulty = 1

--[[
 set all of your variables
 inside the init function!
]]--
function _init()
 --difficulty
 diffjump=8
 thisdiff=ceil(difficulty/diffjump)

 -- these are required!
 name="JumpShip!"
 made_by="@bellicapax"
 oneliner="Teleport! 🅾️"
 if thisdiff==2 then oneliner = oneliner.."❎" end
 
 -- add a personal touch ◆
 outer_frame_color=7
 inner_frame_color=6

 --[[
  set status variable to inform
  master cart about outcome:
 
  status="won" / status="lost"
 ]]--
 status="lost"
 over=false
 brdr=3
 t=0 

 
 -- player
 pcon={spd=140,aspd=200,col={9,12,11,8,14},btn={4,5,2,0,1}}
 gcon={r={26,26,24,24,22,22,20,20}}
 players={}
 goals={}
 for i=1,thisdiff do
  players[i]=player(i)
  goals[i]=goal(i,flr(rnd(116))+3,flr(rnd(116))+3)
 end 
end

function _update60()
 --[[
  dt is time delta, scaled
  with difficulty, provided by
  the master cart
 ]]--
 local dt=dt or 1/60
 
 --[[
  use dt for all diff.dependent
  actions, and 1/60 otherwise
 ]]--
 t+=dt


 --[[
  use transition_done to check
  for on-screen collisions etc;
  this flag is set to true when
  the screen transition is over
  and the game is fully drawn
  on the screen
 ]]--
 if not transition_done or over then return end
 
 foreach(players,function(p) updateplayer(dt,p) end)
 local won=true
 for g in all(goals) do
  updategoal(g)
  won=won and g.done
 end
 if(won) then win() end
end

function _draw()
 cls(5)
 foreach(players,drawplayer)
 foreach(goals,drawgoal)
 if over then _printc(status.."!") end
end

function player(id)
p={}
p.id=id
p.color=pcon.col[id]
p.spr=32
p.sx=p.spr%16*8
p.sy=flr(p.spr/16)*8
p.x=rndpos(32)
p.y=rndpos(32)
p.a=0
p.dir=rnddir()
p.btn=pcon.btn[id]
p.cur=nil
p.spd=function(dt) return pcon.spd*dt end
return p
end

function goal(id)
 g={}
 g.id=id
 g.r=gcon.r[difficulty-(thisdiff-1)*diffjump]
 g.d=g.r*2
 g.r2=g.r*g.r
 for i=1,100 do
  g.x=rndpos(g.d)
  g.y=rndpos(g.d)
  if(playeroutcirc(g.x,g.y,g.r2,players[id])) then break end
 end
 g.col=pcon.col[id]
 g.done=false
 return g
end

function rndpos(w)
 return flr(rnd(127-brdr*2-w))+w/2+brdr
end

function rnddir()
 return flr(rnd(2))==0 and -1 or 1
end

function cur(x,y)
 c={}
 c.x=x
 c.y=y
 c.spr=33
 c.sx=c.spr%16*8
 c.sy=flr(c.spr/16)*8
 return c
end

function updateplayer(dt,p)  
 if(btn(p.btn)) then
  if(p.cur) then
    movecur(dt,p)
  else
   p.cur=cur(p.x,p.y)
  end
 else
  if(p.cur) then
   p.x=p.cur.x
   p.y=p.cur.y 
   p.cur=nil
   for op in all(players) do
    if playercoll(op,p) then
     lose()
     break
    end
   end
  end
  p.a+=p.dir*(1/360*dt*pcon.aspd)
  p.a=p.a%1
 end
end

function movecur(dt,p)
    local ang=(p.a+.5)%1
    local dx,dy=sin(ang)*p.spd(dt), cos(ang)*p.spd(dt)
    local nx,ny=p.cur.x+dx, p.cur.y+dy
    if(isonscrn(nx,ny)) then
     p.cur.x=nx
     p.cur.y=ny
    end
end

function isonscrn(x,y)
 return x>2 and x<118 and y>2 and y<118 
end

function playercoll(p1,p2)
 return p1.id!=p2.id and (abs(p1.x-p2.x)<8 and abs(p1.y-p2.y)<8)
end

function lose()
 status="lost"
 over=true
end

function win()
 status="won"
 over=true
end

function updategoal(g)
 for p in all(players) do
  if(p.id==g.id and playerincirc(g.x,g.y,g.r2,p)) then g.done=true end
 end
end

function pbnds(p)
 return {{p.x,p.y},{p.x+8,p.y},{p.x,p.y+8},{p.x+8,p.y+8}}
end

function playerincirc(x,y,r2,p)
 for b in all(pbnds(p)) do
  if magsqrd(x,y,b[1],b[2])>r2 then return false end
 end
 return true
end

function playeroutcirc(x,y,r2,p)
 for b in all(pbnds(p)) do
  if magsqrd(x,y,b[1],b[2])<=r2 then return false end
 end
 return true
end

function magsqrd(a,b,x,y)
 return (x-a)*(x-a)+(y-b)*(y-b)
end

function drawplayer(p)
 rspr(p.sx,p.sy,p.x,p.y,p.a,1,p.color)
 if(p.cur) then
  rspr(p.cur.sx,p.cur.sy,p.cur.x,p.cur.y,0,1,p.color)
 end
end

function drawgoal(g)
 circ(g.x,g.y,g.r,g.col)
end

function rspr(sx,sy,x,y,a,w,col)
    local ca,sa=cos(a),sin(a)
    local srcx,srcy
    local ddx0,ddy0=ca,sa
    local mask=shl(0xfff8,(w-1))
    w*=4
    ca*=w-0.5
    sa*=w-0.5
    local dx0,dy0=sa-ca+w,-ca-sa+w
    w=2*w-1
    for ix=0,w do
        srcx,srcy=dx0,dy0
        for iy=0,w do
            if band(bor(srcx,srcy),mask)==0 then
                local c=sget(sx+srcx,sy+srcy)
                if(c!=0) then 
                    pset(x+ix,y+iy,col)
                end
            end
            srcx-=ddy0
            srcy+=ddx0
        end
        dx0+=ddx0
        dy0+=ddy0
    end
end


--------------------------------
--------------------------------
--------------------------------
--------------------------------
--------------------------------

--[[
 code below adds the preview
 mode. this is so the games can
 be played standalone wherever
 uploaded. of course, feel free
 to customize it!
]]--

--------------------------------
--------------------------------
--------------------------------
--------------------------------
--------------------------------
transition_done=true
if disable_preview then goto no_preview end

assert(_init, '"_init" function not declared')
assert(_update60, '"_update60" function not declared')
assert(_draw, '"_draw" function not declared')

_time_in_seconds=5
_game_t=0
_lives=3
_score=0

_minigame={
 _init=_init,
 _update60=_update60,
 _draw=_draw
}

_coroutines = {}
_transitions = {
 { t=-1, target=-1, a=0.08 },
 { t=0,  target=0,  a=0.12 },
}

function _len(str)
 local len=#str
 
 for i=1,#str do
  if(sub(str,i,i)>="█") len+=1
 end
 
 return len
end

function _printc(str, ...)
 local y=peek(0x5f27)+6
 print(str, 64-_len(str)*2, y, ...)
 poke(0x5f27, y)
end

function _init()
 _minigame._init()
 status=nil
 
 assert(name, '"name" variable not declared')
 assert(made_by, '"made_by" variable not declared')
 assert(oneliner, '"oneliner" variable not declared')

 local difficulty=difficulty or 1
 assert(mid(1,15,flr(difficulty))==difficulty, 'difficulty should be a integer number in range 1..8')

 _set_difficulty(difficulty)
 
 repeat
  cls()
  
  sspr(77, 123, 51, 5, 64-(13*4), 14, 51*2, 5*2)
  
  cursor(0, 27)
  color(7)

  color(8)
  _printc(name)
  _printc("by " .. made_by, 7)

  cursor(0, 33)
  color(12)
  _printc("   " .. made_by)

  _printc("", 7)
  _printc "this minigame was made for"
  _printc "picoware, a collaborative"
  _printc "minigame jam."
  _printc ""
  _printc "to play the full game, visit:"
  
  color(10)
  _printc "is.gd/picoware"

  color(7)
  _printc ""
  _printc "🅾️❎: z/x      "
  _printc "⬆️⬇️⬅️➡️: arrows keys    "
  _printc ""
  _printc "press   to continue"

  print("🅾️", 48, 111.5 + sin(time()*2), 9)

  flip()
 until btnp(🅾️)

 _states[1]()
end

function _update60()
 foreach(_coroutines, function(co)
  coresume(co)
  if (costatus(co)=="dead") del(_coroutines, co)
 end)

 foreach(_transitions, function(tr)
  tr.t+=(tr.target - tr.t)*tr.a
 end)

 transition_done = _transitions[2].t > 0.95

 if _playing then
  dt=_speedup/60
  _game_t-=1/60   
  _minigame._update60()
 end
end

function _draw()
 local function shadow(str, x, y, col)
  for xx=-1,1 do for yy=-1,1 do
   if (xx*yy==0) print(str, x+xx, y+yy, 7)
  end end
  print(str, x, y, col or 0)
 end

 camera() cls()

 -- cull lounge (cool lounge b/)
 if _transitions[2].t<0.99 then
 
  shadow("single mode", 43, 22)

  -- jelpi
  sspr(57+flr(0.6 + 0.5 * sin(time()))*7,121,7,7,40,71,14,14)

  -- sofa
  sspr(50,124,8,4,32,79,16,8)

  -- tv
  sspr(70,120,7,8,70,55,28,32)

  -- wires
  line(52,81,53,84,5)
  line(57,86)
  line(86,86)
  line(89,85)
  line(91,79)

  -- static  
  for x=79,79+13 do for y=60,60+13 do
   pset(x,y,({6,7,13})[ceil(rnd(3))])
  end end

  local function lpad(str)
   if (#str<3) return lpad('0'..str)
   return str
  end
  
  -- score
  shadow(lpad(tostr(_score)), 59, 98)

  -- lives
  for i=0,2 do
   -- ded
   if i >= _lives then
    pal(8,1) pal(7,13)
   end
   sspr(44,122,6,6,40+18*i,35,12,12)
   pal()
  end
 end

-- camera()

  -- clip to tv
  if _transitions[2].t>0.01 then
   local tt=1-_transitions[2].t
--   local x,y,w=79.5*tt,56.5*tt,128*(1-tt)+14*tt
   local x,y,w=86.5*tt,67.5*tt,128*(1-tt)
  
   __cls=cls
   cls=function(col)
    rectfill(x,y,x+w-1,y+w-1,col)
    clip(x,y,w,w)
   end

   _minigame._draw()

   cls=__cls

   camera()

   -- frame
   pal(12, outer_frame_color)
   pal(7, inner_frame_color)

   sspr(39, 120, 1, 8,  0,  0, 128, 8)
   sspr(39, 120, 1, 8,  0,127, 128,-8)
   sspr(32, 127, 8, 1,  0,  0, 8, 128)
   sspr(32, 127, 8, 1,127,  0,-8, 128)
   
   for x=0,1 do for y=0,1 do
    spr(244, x*119, y*119, 1, 1, x==1, y==1)
   end end

   pal()

   -- overlay
   local tmult=2*_speedup
   local firex=(flr(_game_t*tmult)/tmult) / _time_in_seconds
   firex=12+max(0,firex)*100

   -- connecting lines
   line(12,116,firex-1,116,7)
   line(12,117,firex-1,117,5)
   line(12,118,firex-1,118,7)

   -- bomb and fuse
   spr(241,5,114)
   spr(242+(10*time())%2,firex,114)

   clip()
  end

 shadow(
  oneliner,
  65-_len(oneliner)*2+128*_transitions[1].t,
  107)

 if _show_speedup then
  shadow("speed up!", 47, 107, 8+(time()*15)%4)
 end
end

function _finish_game()
 music(-1, 300)

 _draw = function()
  cls(0) color(7)

  cursor(0, 27)
  color(8)
  _printc "you lost!"
  
  color(7)
  _printc ""
  _printc "now is the perfect time to visit"
  color(12)
  _printc "is.gd/picoware"
  color(7)
  _printc "to play the full version of"

  -- picoware
  sspr(77, 123, 51, 5, 64-(13*4), 70, 51*2, 5*2)

  cursor(0,80)
  color(9+0.5+sin(time()))
  _printc "thank you for playing!"
 end


 _update60 = function()
  --if (btnp(🅾️)) run()
 end
end

function _set_difficulty(diff)
 difficulty=diff
 _difficulty=diff
 
 _speedup=({1, 1.0995, 1.2065, 1.3219, 1.4475, 1.5850, 1.7370, 1.9069, 2.0995, 2.3219, 2.5850, 2.9069, 3.3219, 3.9069, 4.9069})[diff]
 _time_in_seconds=5/_speedup

 foreach({63, 58, 57}, function(track)
  poke(0x3200+68*track+65, 16-diff)
 end)
end

function _timeout(func, t)
 t+=time()
 
 add(_coroutines, cocreate(function()
  repeat yield() until time() > t
  func()
 end))
end

_states={
 -- "lounge"
 function()
  _playing=false

  _transitions[2].target=0

  music(62, 0, 4)
  sfx(-1)
  
  local dt=2

  if status=="won" then
   _score=min(999, _score+1)
   sfx(62)

   if _score%3==0 and _difficulty<15 then
    _timeout(_states[3], 2) -- speedup
    dt+=2.5
   end
  elseif status=="lost" then
   _lives-=1

   if _lives==0 then
    _timeout(_finish_game, 2)
   end

   sfx(61)
  end
  
  -- oneliner slide in
  _timeout(function()
   _transitions[1].t=-1
   _transitions[1].target=0
  end, dt)

  _timeout(_states[2], dt+0.5)

 end,

 -- ingame
 function()
  _playing=true
  _game_t=_time_in_seconds
  dt=_speedup/60
  _minigame._init()

  _transitions[2].target=1

  music(63, 0, 4)
   
  _timeout(_states[1], _time_in_seconds)

  -- one liner slide out
  _timeout(function()
   _transitions[1].target=1
  end, _time_in_seconds)
 end,

 -- show speedup for a while
 function()
  sfx(56)
  _set_difficulty(_difficulty+1)
  _show_speedup=true

  _timeout(function()
   _show_speedup=false
  end, 1.5)
 end,
}

::no_preview::


