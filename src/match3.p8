pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- basic connect-3/match-3 game

function _init()
 poke(0x5f2d, 1) -- enable mouse

 -- game over parameters
 targetgemcount=100
 timelimit=60 --seconds

 -- game vars
 scene=1 -- 1=menu,2=game
 gamemode=1 -- 1=required gem count,2=timed,3=zen/endless(tbc)
 numofmodes=2
 gemctr=0
 gameover=false

 -- progress bar vars
 progressbar=0 
 barlen=126

 -- menu vars
 btns={{51,66,73,74,"start"},{37,96,41,102,"lbtn"},{82,96,86,102,"rbtn"}}
 clickbuffer=0
 bufferrate=10

 -- sprite coords and size for circle sprite
 sprx=118
 spry=22
 sprs=10

 -- timer vars
 flimit=timelimit*30
 tframes=0
 frames=0
 seconds=0
 minutes=0
 animrate=0.125
 animt=1

 -- gem data structure indices
 igemid=1 -- gem id for gem color
 islctd=2 -- is gem selected flag

 -- grid variables
 offset=10 -- offset of grid's top-left corner
 gs=10 -- px size of 1 grid unit
 gridcols=11
 gridrows=11
 mt={} -- grid matrix

 -- table to track selected gems
 seldgs=nil

 -- initialize grid matrix
 for i=1,gridcols do
  mt[i]={}
  for j=1,gridrows do
   mt[i][j]=gemc()
  end
 end
end

function _update()
 -- todo: check if there's any 3-match in the grid, otherwise, scramble the grid

 -- mouse x, y and button
 mx=stat(32)
 my=stat(33)
 mb=stat(34)

 if scene==1 then
  menu()
 else
  game()
 end
end

function _draw()
 cls()
 if scene==1 then drawmenu() else drawgame() end
 drawcursor()
end

-- main functions

function menu()
 if clickbuffer>0 then clickbuffer-=1 end
 pbutton=getpointedbutton()

 sbtnclr,sbtnspr,lbtnspr,rbtnspr=btndefaults()

 if pbutton=="start" then
  sbtnclr,sbtnspr=sbtnhighlight()
  if mb==1 then
   if gamemode==1 then barcolor=14 else barcolor=11 end
   scene=2
   return
  end
 elseif pbutton=="lbtn" then
  lbtnspr=13
  if mb==1 and clickbuffer==0 then
   clickbuffer=bufferrate
   gamemode=(gamemode%numofmodes)+1
  end
 elseif pbutton=="rbtn" then
  rbtnspr=14
  if mb==1 and clickbuffer==0 then
   clickbuffer=bufferrate
   gamemode=(gamemode%numofmodes)+1
  end
 end
end

function drawmenu()
 -- start button
 rectfill(52,66,72,74,sbtnclr)
 spr(sbtnspr,50,67)
 spr(sbtnspr+1,73,67)
 print('start',53,68,7)

 print('game mode',45,88,6)
 print(gamemode==1 and "normal" or "timed",51,97,7)
 spr(lbtnspr,37,96)
 spr(rbtnspr,83,96)

 tutstr=gamemode==1 and "   (clear 100 gems)" or "(play for 60 seconds)"
 print(tutstr,20,105,5)
end

function game()
 if animt<1 then
  animt+=animrate
 else
  -- mark all gems are not to be animated
  for i=1,gridcols do
   for j=1,gridrows do
    mt[i][j][3]=false 
   end
  end
 end

 if gameover then
  return
 end

 tframes+=1
 frames=((frames+1)%30)
 if frames==0 then
  seconds=((seconds+1)%60)
  if seconds==0 then
   minutes+=1
  end
 end

 if gamemode==2 then
  if tframes>=flimit then
   gameover=true
   progressbar=0
  else
   prcnt=1-(tframes/flimit)
   if prcnt<0.10 then
    barcolor=8
   elseif prcnt<0.35 then
    barcolor=9
   end
   progressbar=barlen*prcnt
  end
 end

 pointedgem() -- get row and col of gem
 
 if mb==1 and animt==1 then -- if mouse is clicked/held down (accept input only when not animating)
  if gemcol>0 and gemcol<gridcols+1 and gemrow>0 and gemrow<gridrows+1 then
   -- check if gem is already selected
   if not mt[gemcol][gemrow][islctd] then
    -- add to table of selected gems
    if seldgs==nil then
     seldgs={{gemcol,gemrow}}
     -- flip flag
     mt[gemcol][gemrow][islctd]=true
    else
     firstgid=mt[seldgs[1][1]][seldgs[1][2]][igemid] -- gem id/gem color to match
     -- check if gem is (1)same color and (2)adjacent
     thisgid=mt[gemcol][gemrow][igemid]
     if firstgid==thisgid then
      pow1=(gemcol-seldgs[#seldgs][1])*(gemcol-seldgs[#seldgs][1])
      pow2=(gemrow-seldgs[#seldgs][2])*(gemrow-seldgs[#seldgs][2])
      gdst=sqrt(pow1+pow2)
      if gdst==1 then
       seldgs[#seldgs+1]={gemcol,gemrow}
       -- flip flag
       mt[gemcol][gemrow][islctd]=true
      end
     end          
    end       
   else
    -- todo: code for deselecting a gem
    -- check if the already selected gem the cursor is pointing at is the 2nd to the last gem in the selgs array
    -- if yes, deselect the last gem in the selgs array
    dummyvar=nil
   end
  end
 else
  if seldgs then
   -- if 3 or more gems selected, remove selected them from the grid & ....
   if #seldgs>2 then
    gemctr+=#seldgs

    if gamemode==1 then
     if gemctr>=targetgemcount then
      gameover=true
      progressbar=barlen
     else
      progressbar=barlen*(gemctr/targetgemcount)
     end
    end

    -- remove gems
    for k=1,#seldgs do
     mt[seldgs[k][1]][seldgs[k][2]][igemid]=nil
    end

    -- drop floating gems and refill the grid with gems
    for i=1,gridcols do
     for j=1,gridrows do
      -- check if column has an empty cell
      if mt[i][gridrows-j+1][igemid]==nil then
       colhldr={}
       for k=1,gridrows do
        -- copy remaining gems
        if mt[i][k][igemid] then
         mt[i][k][3]=true -- mark for animation
         mt[i][k][4][1]=k -- store origin row
         colhldr[#colhldr+1]=mt[i][k]
        end
       end

       -- put old gems in the bottom of the matrix, generate new ones for the top
       for k=1,gridrows do
        if #colhldr>0 then
         mt[i][gridrows-k+1]=colhldr[#colhldr] -- old gem/s
         colhldr[#colhldr]=nil
         mt[i][gridrows-k+1][4][2]=gridrows-k+1 -- store destination row
        else
         mt[i][gridrows-k+1]=newgemc(gridrows-k+1) -- new gem/s
        end
       end
       animt=0
       break
      end
     end
    end
   else
    -- reset flags in grid matrix and reset selected gems table variable
    for k=1,#seldgs do
     mt[seldgs[k][1]][seldgs[k][2]][islctd]=false
    end
   end
   seldgs=nil
  end
 end
end

function drawgame()
 dprogbox()
 dprogbar()
 draw_gems()
 if gameover then
  if gamemode==1 then
   draw_time(49,16)
  else
   draw_score(49,16)
  end
 end
 
 -- highlight selected gem/s
 if seldgs then
  for k=1,#seldgs do
   gemx=(seldgs[k][1]-1)*gs+offset-1
   gemy=(seldgs[k][2]-1)*gs+offset-1
   sspr(sprx,spry,sprs,sprs,gemx,gemy)
  end
 end
end

-- other functions
function getpointedbutton()
 for i=1,#btns do
  if mx>btns[i][1] and mx<btns[i][3] and my>btns[i][2] and my<btns[i][4] then
   return btns[i][5]
  end
 end
 return nil
end

function draw_gems()
 for i=1,gridcols do
  x=offset+((i-1)*gs)
  for j=1,gridrows do
   gemid=mt[i][j][igemid]
   -- if animt==1 then
   --  y=offset+((j-1)*gs)
   -- else
   --  y=offset+(lerp(mt[i][j][4][1]*gs,mt[i][j][4][2]*gs,animt))
   -- end 
   if animt<1 and mt[i][j][3] then
    y=offset+(lerp((mt[i][j][4][1]-1)*gs,(mt[i][j][4][2]-1)*gs,animt))
   else
    y=offset+((j-1)*gs)
   end
   draw_1gem()
  end
 end
end

function draw_1gem()
 spr(gemid,x,y)
end

function drawcursor()
 palt(0,false)
 palt(8,true)
 spr(6,mx,my)
 palt()
end

function dprogbox()
 rect(0,0,127,2,7)
end

function dprogbar()
 if progressbar>0 then line(1,1,progressbar,1,barcolor) end
end

function draw_time(x,y)
 local s=seconds
 local m=minutes%60
 local h=flr(minutes/60)

 rectfill(x,y,x+32,y+6,0)
 print((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(s<10 and "0"..s or s),x+1,y+1,7)
end

function draw_score(x,y)
 rectfill(x,y,x+32,y+6,0)
 print(gemctr,x+13,y+1,7)
end

-- get col,row of gem that the cursor is pointing at
function pointedgem()
 gemcol=ceil((mx-offset)/gs)
 gemrow=ceil((my-offset)/gs)
end

function btndefaults()
 return 3,7,11,12
end

function sbtnhighlight()
 return 11,9
end

function lerp(a,b,t)
 return a+(b-a)*t
end

function gemc()
 -- (1) color (2) is selected (3) is animate (4) animation data (5) is skip drawing (temp data)
 return {flr(rnd(4))+1,false,false,{}}
end

function newgemc(destrow)
 -- (1) color (2) is selected (3) is animate (4) animation data (5) is skip drawing (temp data)
 return {flr(rnd(4))+1,false,true,{-2,destrow}}
end
__gfx__
00000000008888000099990000bbbb0000cccc00000000000000088803000000300000000b000000b00000000009000090000000000a0000a000000000000000
0000000008788880097999900b7bbbb00c7cccc000000000077608883300000033000000bb000000bb000000009900009900000000aa0000aa00000000000000
007007008778888897799999b77bbbbbc77ccccc00000000076008883300000033000000bb000000bb00000009990000999000000aaa0000aaa0000000000000
000770008788888897999999b7bbbbbbc7cccccc000aa000065700883300000033000000bb000000bb0000009999000099990000aaaa0000aaaa000000000000
000770008888888899999999bbbbbbbbcccccccc000aa000000070883300000033000000bb000000bb00000009990000999000000aaa0000aaa0000000000000
007007008888888299999994bbbbbbb3ccccccc100000000888000883300000033000000bb000000bb000000009900009900000000aa0000aa00000000000000
0000000008888820099999400bbbbb300ccccc10000000008888888803000000300000000b000000b00000000009000090000000000a0000a000000000000000
000000000028820000499400003bb300001cc1000000000088888888000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777700
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888888888888888888888888888888888888888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88888888888888888888888888888888888888888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8888eee8888888888888888888888888888888888888888888888888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee888888888888888888888888888888888888888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116611666166616161111116611661166166616661171161611111616117111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616161616161111161116111616161616111711161611111616111711111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116161661166616161111166616111616166116611711116111111666111711111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616161616661111111616111616161616111711161611711116111711111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661616161616661666166111661661161616661171161617111666117111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111bbb1bbb11bb1bbb1bbb1bbb1b111b1111711616111116161111161611111ccc1ccc1111161611111c1111111ccc11711111111111111111111111111111
11111b1b1b111b1111b11b1111b11b111b111711161611111616111116161171111c111c1111161611711c1111111c1c11171111111111111111111111111111
11111bb11bb11b1111b11bb111b11b111b11171111611111166611111161177711cc1ccc1111166617771ccc11111c1c11171111111111111111111111111111
11111b1b1b111b1111b11b1111b11b111b111711161611711116117116161171111c1c111171111611711c1c11711c1c11171111111111111111111111111111
11111b1b1bbb11bb11b11b111bbb1bbb1bbb11711616171116661711161611111ccc1ccc1711166611111ccc17111ccc11711111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111bbb1bbb1bbb1bb11bbb11711166166616661166166616661111161611111cc11ccc1111161611111cc111111ccc11711111111111111111111111111111
11111b1b1b1b11b11b1b11b1171116111611166616111161161611111616117111c1111c11111616117111c11111111c11171111111111111111111111111111
11111bbb1bb111b11b1b11b1171116111661161616111161166111111161177711c111cc11111666177711c11111111c11171111111111111111111111111111
11111b111b1b11b11b1b11b1171116161611161616111161161611711616117111c1111c11711116117111c11171111c11171111111111111111111111111111
11111b111b1b1bbb1b1b11b111711666166616161166116116161711161611111ccc1ccc1711166611111ccc1711111c11711111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111dd1ddd1ddd111111dd11dd1d1111111ddd11dd1d1d111111dd1ddd111111dd1ddd1ddd11111ddd1d1d1ddd1ddd11111ddd1d1d1ddd111111dd
1111111111111d111d1111d111111d111d1d1d1111111d1d1d1d1d1d11111d1d1d1111111d111d111ddd111111d11d1d1d1d11d1111111d11d1d1d1111111d11
1ddd1ddd11111d111dd111d111111d111d1d1d1111111dd11d1d1d1d11111d1d1dd111111d111dd11d1d111111d11ddd1ddd11d1111111d11ddd1dd111111d11
1111111111111d1d1d1111d111111d111d1d1d1111d11d1d1d1d1ddd11111d1d1d1111111d1d1d111d1d111111d11d1d1d1d11d1111111d11d1d1d1111111d11
1111111111111ddd1ddd11d1111111dd1dd11ddd1d111d1d1dd11ddd11111dd11d1111111ddd1ddd1d1d111111d11d1d1d1d11d1111111d11d1d1ddd111111dd
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116661166166616611666166616611166166616661171117111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616116116161161161116161611161116661711111711111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116661616116116161161166116161611166116161711111711111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116111616116116161161161116161616161116161711111711111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116111661166616161161166616661666166616161171117111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111116616661666116611661611111111bb1bbb1bbb1b1111711171166616161111116616661666116616661666117111171166116611711111111111111111
111116111611166616111616161117771b111b1111b11b1117111711166616161111161616111611161116111161111711711611161111171111111111111111
111116111661161616111616161111111b111bb111b11b1117111711161611611777161616611661166616611161111711711611166611171111111111111111
111116161611161616111616161117771b111b1111b11b1117111711161616161111161616111611111616111161111711711616111611171111111111111111
1111166616661616116616611666111111bb1bbb1bbb1bbb11711171161616161111166116111611166116661161117117111666166111711111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111116616661666166611661616111111bb1bbb1bbb1b1111711171166616161111116616661666116616661666117111171166116611711111111111111111
111116111611166616161616161617771b111b1111b11b1117111711166616161111161616111611161116111161111711711611161111171111111111111111
111116111661161616611616161611111b111bb111b11b1117111711161616661777161616611661166616611161111711711611166611171111111111111111
111116161611161616161616166617771b111b1111b11b1117111711161611161111161616111611111616111161111711711616111611171111111111111111
1111166616661616161616611666111111bb1bbb1bbb1bbb11711171161616661111166116111611166116661161117117111666166111711111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116661666166116611666166616661616161116661166117111711111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161161161616161611161116161616161111611611171111171111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116611161161616161661166116661616161111611666171111171111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161161161616161611161116161616161111611116171111171111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661161161616661666161116161166166611611661117111711111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee1eee1e1e1eee1ee111111ccc11111ccc11111cc11cc111111cc11ccc111111111111111111111111111111111111111111111111111111111111
11111e1e1e1111e11e1e1e1e1e1e1111111c1111111c111111c111c1111111c1111c111111111111111111111111111111111111111111111111111111111111
11111ee11ee111e11e1e1ee11e1e111111cc1111111c111111c111c1111111c11ccc111111111111111111111111111111111111111111111111111111111111
11111e1e1e1111e11e1e1e1e1e1e1111111c1171111c117111c111c1117111c11111111111111111111111111111111111111111111111111111111111111111
11111e1e1eee11e111ee1e1e1e1e11111ccc1711111c17111ccc1ccc17111ccc171c111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111771111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111777111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111777711111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111771111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111117111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111111661666166616611616166611661616161116661166161616661171117111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116111616116116161616116116111616161111611611161611611711111711111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116661661116116161666116116111666161111611611166611611711111711111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111161616116116161616116116161616161111611616161611611711111711111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116611666116116161616166616661616166616661666161611611171117111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee1eee1e1e1eee1ee111111cc11cc111111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e1e1e1111e11e1e1e1e1e1e111111c111c111111c1c11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11ee111e11e1e1ee11e1e111111c111c111111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e1e1e1111e11e1e1e1e1e1e111111c111c11171111c11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e1e1eee11e111ee1e1e1e1e11111ccc1ccc1711111c11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee188881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e88881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e88881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e88881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee88881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822282228222888282228222822288888888888888888888888888888888888882288228828882228882822282288222822288866688
82888828828282888888888288828282882888828882828288888888888888888888888888888888888888288828828888828828828288288282888288888888
82888828828282288888882282228282882888228222828288888888888888888888888888888888888888288828822282228828822288288222822288822288
82888828828282888888888282888282882888828288828288888888888888888888888888888888888888288828828282888828828288288882828888888888
82228222828282228888822282228222828882228222822288888888888888888888888888888888888882228222822282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

