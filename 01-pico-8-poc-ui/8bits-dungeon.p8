pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--8bits-dungeon
--by morarupasukaru
--last update: 22.04.2026

-- main
function _init()
	title.init()
	slow_pulse=pulse:new(0.1)
end

-->8
--pulse & spr_anime
pulse={}
function pulse:new(incr)
  local res = {}
  res.incr=incr
  res.val=0
		return setmetatable(res, {__index = self} )
end

function pulse:update()
	self.val+=self.incr
end

function pulse:bool()
  return flr(self.val)%2==1
end

spr_anime={}
spr_anime.__index=spr_anime

function spr_anime:update()
 if self.pulse:bool() != self.last then
  self.last=self.pulse:bool()
  self.idx+=1
  if self.idx > #self.sprites then
  	self.idx=1
  end
 end
end

function spr_anime:get()
  return self.sprites[self.idx]
end

function spr_anime:new(pulse,sprites)
  local res = {}
  res.idx=1
  res.sprites=sprites
  res.pulse=pulse
  res.last=false
		return setmetatable(res,self)
end

-->8
--title
title={}

title.init = 
function()
 title.save=true
 title.choice=0
 _draw=title.draw
 _update=title.update
end

title.draw =
function()
	cls()
 print("\^w\^tdungeon remake",10,30,5)
	line(10,45,119,45,1)
	rrect(32,60,64,30,1)
 
 local y=68
 if title.choice==0 then
		print("start game",45,68,10)
	else
		print("start game",45,68,1)
	end
	
	if title.save then
		if title.choice==1 then
		 y=78
			print("continue",45,78,10)
		else
			print("continue",45,78,1)
		end
	end
	if slow_pulse:bool() then
		print("■",40,y,10)
	end
end

title.update = function()
 slow_pulse:update()
	if btnp(⬇️) or btnp(⬆️) then
	 title.choice+=1
	 title.choice%=2
	end
	if btnp(🅾️) or btnp(❎) then
		game.init(title.choice==0)
	end
end
-->8
--game
game={}
game.init=
function(start)
	game.show_action_menu=false
	game.dmg_count=0
	game.ctrl=1
	game.ctrl_sel=game.ctrl
	actions.init()
	player.init()
	_draw=game.draw
	_update=game.update
end

game.draw=
function()
 -- todo:iterate over object to _draw
	cls()
	
	local show_dmg=
		game.dmg_count%2==1
	dungeon.draw(show_dmg)
	stats.draw(player.stats,show_dmg)
	actions.draw(show_dmg)
end

game.update=
function()
	if game.ctrl_sel==game.ctrl then
	 -- todo:iterate over object to _udpdate
		if btnp(🅾️) and player.stats.hp>0 then
		  game.dmg_count=5
		  game.dmg_time=time()
		  player.stats.hp-=3
		  if player.stats.hp<0 then
		  	player.stats.hp=0
		  end
		elseif game.dmg_count>0 and time()-game.dmg_time>0.05 then
		  game.dmg_count-=1
		  game.dmg_time=time()
		end
	end
	
	actions.update()
end

-->8
--stats
stats={}

local function print_stats(hp,mp,lv,x,y)
 print("hp",x,y+2,7)
 local dx=(5-#tostr(hp))*4+1
 print(hp,x+dx,y+2,7)
 print("mp",x,y+8,7)
 dx=(5-#tostr(mp))*4+1
 print(mp,x+dx,y+8,7)
 print("lv",x,y+14,7)
 dx=(5-#tostr(lv))*4+1
 print(lv,x+dx,y+14,7)
end

local function draw_box_stats(hp,mp,lv,c,show_dmg)
 local x,w,h=0,26,21
 local y=show_dmg and 1 or 0
 rbox(x,y,w,h,c.border,c.fill,2)
 print_stats(hp,mp,lv,x+3,y)
end

stats.draw=function(stats,show_dmg)
 local c=colors.info
 if stats.hp==0 or show_dmg then
   c=colors.error
 elseif stats.hp/stats.max_hp<0.5 then
   c=colors.warn
 else
 	 c=colors.info
 end
 		
	draw_box_stats(stats.hp,stats.mp,stats.lv,c,show_dmg)
end
-->8
--dungeon
dungeon={}

dungeon.draw = function(show_dmg)
 local dy=show_dmg and 1 or 0
	rectfill(0,0+dy,127,127+dy,6)
	rectfill(32,32+dy,96,96+dy,6)
	rectfill(48,48+dy,96,80+dy,13)

 local color_line=1
 
	--depth1 - wall left
	line(0,0+dy,31,31+dy,color_line)
	line(0,0+dy,0,127+dy,color_line)
	line(0,127+dy,31,96+dy,color_line)
	line(31,31+dy,31,95+dy,color_line)
	
	--depth1 - floor
	line(0,127+dy,127,127+dy,color_line)
	line(31,96+dy,96,96+dy,color_line)
	line(96,96+dy,127,127+dy,color_line)

	--depth1 - wall right
	line(127,0+dy,127,127+dy,color_line)
	line(127,0+dy,96,31+dy,color_line)
	line(96,31+dy,96,96+dy,color_line)
	
	--depth1 - ceil
	line(0,0+dy,127,0+dy,color_line)
	line(31,31+dy,96,31+dy,color_line)
	
	--depth2 - wall left
	line(31,31+dy,47,47+dy,color_line)
	line(47,47+dy,47,80+dy,color_line)
	line(31,96+dy,47,80+dy,color_line)

	--depth2 - floor
	line(47,80+dy,96,80+dy,color_line)
	
	--depth2 - ceil
	line(47,47+dy,96,47+dy,color_line)	
end
-->8
--actions
actions={}

actions.init=
function()
	actions.sel=3
	actions.items={
		{sp=spr_anime:new(slow_pulse,{1,2}),txt="attack"},
		{sp=spr_anime:new(slow_pulse,{3,4}),txt="spell"},
		{sp=spr_anime:new(slow_pulse,{5,6}),txt="item"}
	}
	actions.show_menu=false
	actions.ctrl=2
	actions.x_desc=128
	actions.dy_menu=12
end

function actions:toggle_menu()
	actions.show_menu=not actions.show_menu
	--todo:extract controller
	if actions.show_menu then
	 actions.x_desc=128
		actions.dy_menu=12
		game.ctrl_sel=actions.ctrl
	else
		game.ctrl_sel=game.ctrl
	end
end

local function draw_action_desc(item,x,dy)
 local w,h=128-x,9
 local y,c1,c2=
 	114-h+dy,
 	colors.info.border,
 	colors.info.fill
 rbox(x,y,w,h,c1,c2,1)
 print(item.txt,x+2,y+2,7)
end

local function box_actions(items,x,dy)
 local w=#items*10+4
 x=x-w
 local y,h,c1,c2=
 	115+dy,12,
 	colors.info.border,
 	colors.info.fill
 rbox(x,y,w,h,c1,c2,1)
 for i=1,#items do
	 spr(items[i].sp:get(),x+3+(i-1)*10,y+2)
	end
	return x
end

local function draw_default_action(dy)
 box_actions({actions.items[actions.sel]},128,dy)
end

local function draw_action_choices(dy)
 local res=box_actions(actions.items,113,dy)
	if slow_pulse:bool() then
	 local dx=(actions.sel-1)*10+2
		local x1=res+dx
	 rect(x1,116+dy,x1+9,125+dy,10)
	end
	return res
end

actions.draw=
function(show_dmg)
 local dy=show_dmg and 1 or 0
 if actions.show_menu then
 	actions.dy_menu-=4
	 if actions.dy_menu < 0 then
	 	actions.dy_menu=0
	 end
 
	 local x=draw_action_choices(
	 	dy+actions.dy_menu)
 	actions.x_desc-=20
	 if actions.x_desc < x then
	 	actions.x_desc=x
	 end
	 draw_action_desc(
	 	actions.items[actions.sel],
	 	actions.x_desc,dy) 
	else
		if actions.dy_menu < 12 then
	 	actions.dy_menu+=4
	 	draw_action_choices(
	 		dy+actions.dy_menu)
	 end
		if actions.x_desc < 128 then
	 	actions.x_desc+=20
		 draw_action_desc(
		 	actions.items[actions.sel],
		 	actions.x_desc,dy) 	
		end
 end
 draw_default_action(dy)
end

actions.update=
function()
 slow_pulse:update()
	if btnp(❎) then
		actions.toggle_menu()
	end 
	
	if game.ctrl_sel==actions.ctrl then
	 if actions.show_menu then
	  if btnp(➡️) then
	 		actions.sel+=1
	 		if actions.sel>#actions.items then
	 			actions.sel=1
	 		end
			end
	 	if btnp(⬅️) then
	 		actions.sel-=1
	 		if actions.sel<1 then
	 			actions.sel=#actions.items
	 		end
			end
			actions.items[actions.sel].sp:update()
	 	if btnp(🅾️) then
				actions.toggle_menu()
			end
	 end
	end
end
-->8
--rbox
--todo:simplify theme
colors={
	error={
		border=15,
		fill=8
	},
	warn={
		border=15,
		fill=9
	},
	info={
		border=7,
		fill=12
	}
}

function rbox(x,y,w,h,c1,c2,r)
 rrect(x,y,w,h,r,c1)
 rrectfill(x+1,y+1,w-2,h-2,r-1,c2)
end
-->8
--player
player={}
player.init=
function()
	local stats={
		hp=24,
		max_hp=24,
		mp=0,
		max_mp=0,
		lv=1,
		exp=0,
		exp_nextlv=30
	}
	player.stats = stats
end
__gfx__
00000000660000000000000000000000a00a00000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000
000000006d600000000600600a0a00000a0000000000000000000440050505000505040000000000000000000000000000000000000000000000000000000000
0070070006d600000060060000000000000a00000044400000000040050504000505050000000000000000000000000000000000000000000000000000000000
00077000006d60d0060060000a099000a0a9900000d4d00000d0d000040505000505050000000000000000000000000000000000000000000000000000000000
0007700000065d000600600000094000000940000d888d000d000d00050405000505050000000000000000000000000000000000000000000000000000000000
007007000000d4500000000000000400000004000d888d000d000d00050505000405050000000000000000000000000000000000000000000000000000000000
00000000000d054500000d0000000040000000400d888d000d888d00050505000504050000000000000000000000000000000000000000000000000000000000
000000000000005466666d5500000004000000040ddddd000ddddd00000000000000000000000000000000000000000000000000000000000000000000000000
