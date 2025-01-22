pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
 poke(0x5f2d, 1) -- enable mouse

 -- gem data structure indices
 igemid=1 -- gem id for gem color
 islctd=2 -- is gem selected flag

 -- grid variables
 offset=10 -- offset of grid's top-left corner
 gs=9 -- px size of 1 grid unit
 gridcols=7
 gridrows=5
 mt={} -- grid matrix

 -- table to track selected gems
 seldgs=nil

 -- initialize grid matrix
 for i=1,gridcols do
  mt[i]={}
  for j=1,gridrows do
   mt[i][j]={flr(rnd(4))+1,false}
  end
 end
end

function _update()
 -- todo: check if there's any 3-match in the grid, otherwise, scramble the grid

 -- mouse x, y and button
 mx=stat(32)
 my=stat(33)
 mb=stat(34) 
 pointedgem() -- get row and col of gem

 if mb==1 then -- if mouse is clicked/held down
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
    -- remove gems
    -- todo: code for score
    for k=1,#seldgs do
     mt[seldgs[k][1]][seldgs[k][2]][igemid]=nil
    end

    -- drop floating gems and refill the grid with gems
    for i=1,gridcols do
     for j=1,gridrows do
      -- check if column has an empty cell
      if mt[i][j][igemid]==nil then
       colhldr={}
       for k=1,gridrows do
        -- copy remaining gems
        if mt[i][k][igemid] then colhldr[#colhldr+1]=mt[i][k] end
       end

       for k=1,gridrows do
        if #colhldr>0 then
         mt[i][gridrows-k+1]=colhldr[#colhldr] -- old gem/s
         colhldr[#colhldr]=nil
        else
         mt[i][gridrows-k+1]={flr(rnd(4))+1,false} -- new gem/s
        end
       end
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

function _draw()
 cls()
 draw_gems()

 -- mark selected gem/s ###temp code
 if seldgs then
  for k=1,#seldgs do
   gemx=((seldgs[k][1]-1)*9+offset)+3
   gemy=((seldgs[k][2]-1)*9+offset)+1  
   print(k,gemx,gemy,14)
  end
 end

 drawcursor()
end

-- user functions
function draw_gems()
 for i=1,gridcols do
  x=offset+((i-1)*gs)
  for j=1,gridrows do
   gemid=mt[i][j][igemid]
   y=offset+((j-1)*gs)
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

-- get col,row of gem that the cursor is pointing at
function pointedgem()
 gemcol=ceil((mx-offset)/gs)
 gemrow=ceil((my-offset)/gs)
end


__gfx__
00000000008888000099990000bbbb0000cccc000000000000000888776000000000000000000000000000000000000000000000000000000000000000000000
0000000008788880097999900b7bbbb00c7cccc00000000007760888760000000000000000000000000000000000000000000000000000000000000000000000
007007008778888897799999b77bbbbbc77ccccc0000000007600888657000000000000000000000000000000000000000000000000000000000000000000000
000770008788888897999999b7bbbbbbc7cccccc000aa00006570088000700000000000000000000000000000000000000000000000000000000000000000000
000770008888888899999999bbbbbbbbcccccccc000aa00000007088000000000000000000000000000000000000000000000000000000000000000000000000
007007008888888299999994bbbbbbb3ccccccc10000000088800088000000000000000000000000000000000000000000000000000000000000000000000000
0000000008888820099999400bbbbb300ccccc100000000088888888000000000000000000000000000000000000000000000000000000000000000000000000
000000000028820000499400003bb300001cc1000000000088888888000000000000000000000000000000000000000000000000000000000000000000000000
