function _init()
 poke(0x5f2d, 1) -- enable mouse

 -- game over parameters
 targetGemCount=30
 timeLimit=60 --seconds

 -- game vars
 gameMode=1 -- 1=target gem count,2=timed
 gemCtr=0
 gameOver=false

 -- progress bar vars
 progressBar=0 
 barLen=126
 if gameMode==1 then barColor=14 else barColor=11 end

 -- sprite coords and size for sspr
 sprX=118
 sprY=22
 sprS=10

 -- timer vars
 fLimit=timeLimit*30
 tFrames=0
 frames=0
 seconds=0
 minutes=0

 -- gem data structure indices
 iGEMID=1 -- gem id for gem color
 iSLCTD=2 -- is gem selected flag

 -- grid variables
 offset=10 -- offset of grid's top-left corner
 gs=10 -- px size of 1 grid unit
 gridCols=11
 gridRows=11
 mt={} -- grid matrix

 -- table to track selected gems
 seldGs=nil

 -- initialize grid matrix
 for i=1,gridCols do
  mt[i]={}
  for j=1,gridRows do
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
 
 if gameOver then
  return
 end

 tFrames+=1
 frames=((frames+1)%30)
 if frames==0 then
  seconds=((seconds+1)%60)
  if seconds==0 then
   minutes+=1
  end
 end

 if gameMode==2 then
  if tFrames>=fLimit then
   gameOver=true
   progressBar=0
  else
   prcnt=1-(tFrames/fLimit)
   if prcnt<0.10 then
    barColor=8
   elseif prcnt<0.35 then
    barColor=9
   end
   progressBar=barLen*prcnt
  end
 end

 pointedGem() -- get row and col of gem
 
 if mb==1 then -- if mouse is clicked/held down
  if gemCol>0 and gemCol<gridCols+1 and gemRow>0 and gemRow<gridRows+1 then
   -- check if gem is already selected
   if not mt[gemCol][gemRow][iSLCTD] then
    -- add to table of selected gems
    if seldGs==nil then
     seldGs={{gemCol,gemRow}}
     -- flip flag
     mt[gemCol][gemRow][iSLCTD]=true
    else
     firstGID=mt[seldGs[1][1]][seldGs[1][2]][iGEMID] -- gem id/gem color to match
     -- check if gem is (1)same color and (2)adjacent
     thisGID=mt[gemCol][gemRow][iGEMID]
     if firstGID==thisGID then
      pow1=(gemCol-seldGs[#seldGs][1])*(gemCol-seldGs[#seldGs][1])
      pow2=(gemRow-seldGs[#seldGs][2])*(gemRow-seldGs[#seldGs][2])
      gDst=sqrt(pow1+pow2)
      if gDst==1 then
       seldGs[#seldGs+1]={gemCol,gemRow}
       -- flip flag
       mt[gemCol][gemRow][iSLCTD]=true
      end
     end          
    end       
   else
    -- todo: code for deselecting a gem
    -- check if the already selected gem the cursor is pointing at is the 2nd to the last gem in the selGs array
    -- if yes, deselect the last gem in the selGs array
    dummyVar=nil
   end
  end
 else
  if seldGs then
   -- if 3 or more gems selected, remove selected them from the grid & ....
   if #seldGs>2 then
    gemCtr+=#seldGs

    if gameMode==1 then
     if gemCtr>=targetGemCount then
      gameOver=true
      progressBar=barLen
     else
      progressBar=barLen*(gemCtr/targetGemCount)
     end
    end


    -- remove gems
    for k=1,#seldGs do
     mt[seldGs[k][1]][seldGs[k][2]][iGEMID]=nil
    end

    -- drop floating gems and refill the grid with gems
    for i=1,gridCols do
     for j=1,gridRows do
      -- check if column has an empty cell
      if mt[i][j][iGEMID]==nil then
       colHldr={}
       for k=1,gridRows do
        -- copy remaining gems
        if mt[i][k][iGEMID] then colHldr[#colHldr+1]=mt[i][k] end
       end

       for k=1,gridRows do
        if #colHldr>0 then
         mt[i][gridRows-k+1]=colHldr[#colHldr] -- old gem/s
         colHldr[#colHldr]=nil
        else
         mt[i][gridRows-k+1]={flr(rnd(4))+1,false} -- new gem/s
        end
       end
       break
      end
     end
    end
   else
    -- reset flags in grid matrix and reset selected gems table variable
    for k=1,#seldGs do
     mt[seldGs[k][1]][seldGs[k][2]][iSLCTD]=false
    end
   end
   seldGs=nil
  end
 end
end

function _draw()
 cls()
 dProgBox()
 dProgBar()
 draw_gems()
 if gameOver then
  if gameMode==1 then
   draw_time(49,16)
  else
   draw_score(49,16)
  end
 end

 -- -- mark selected gem/s ###TEMP CODE
 -- if seldGs then
 --  for k=1,#seldGs do
 --   gemx=((seldGs[k][1]-1)*9+offset)+3
 --   gemy=((seldGs[k][2]-1)*9+offset)+1  
 --   print(k,gemx,gemy,14)
 --  end
 -- end

  -- highlight selected gem/s
  if seldGs then
   for k=1,#seldGs do
    gemx=(seldGs[k][1]-1)*gs+offset-1
    gemy=(seldGs[k][2]-1)*gs+offset-1
    sspr(sprX,sprY,sprS,sprS,gemx,gemy)
   end
  end

 drawCursor()
end

-- user functions
function draw_gems()
 for i=1,gridCols do
  x=offset+((i-1)*gs)
  for j=1,gridRows do
   gemId=mt[i][j][iGEMID]
   y=offset+((j-1)*gs)
   draw_1gem()
  end
 end
end

function draw_1gem()
 spr(gemId,x,y)
end

function drawCursor()
 palt(0,false)
 palt(8,true)
 spr(6,mx,my)
 palt()
end

function dProgBox()
 rect(0,0,127,2,7)
end

function dProgBar()
 if progressBar>0 then line(1,1,progressBar,1,barColor) end
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
 print(gemCtr,x+13,y+1,7)
end

-- get col,row of gem that the cursor is pointing at
function pointedGem()
 gemCol=ceil((mx-offset)/gs)
 gemRow=ceil((my-offset)/gs)
end

