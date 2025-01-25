--a simple connect-3/match-3 game
--by ahxel

function _init()
 poke(0x5f2d, 1) -- enable mouse

 -- game over parameters
 targetGemCount=100
 timeLimit=60 --seconds

 -- game vars
 scene=1 -- 1=menu,2=game
 gameMode=1 -- 1=required gem count,2=timed,3=zen/endless(TBC)
 numOfModes=2
 gemCtr=0
 gameOver=false

 -- progress bar vars
 progressBar=0 
 barLen=126

 -- menu vars
 btns={{51,66,73,74,"START"},{37,96,41,102,"LBTN"},{82,96,86,102,"RBTN"},{119,0,127,8,"I"}}
 clickBuffer=0
 bufferRate=10

 -- sprite coords and size for gem sprite
 gSprX=0
 gSprY=8
 gSprS=10

 -- sprite coords and size for highlight sprite
 sprX=40
 sprY=8
 sprS=12

 -- timer vars
 fLimit=timeLimit*30
 tFrames=0
 frames=0
 seconds=0
 minutes=0
 animRate=0.125
 animT=1

 -- gem data structure indices
 iGEMID=1 -- gem id for gem color
 iSLCTD=2 -- is gem selected flag

 -- grid variables
 offset=10 -- offset of grid's top-left corner
 gs=12 -- px size of 1 grid unit
 gridCols=9
 gridRows=9
 mt={} -- grid matrix

 -- table to track selected gems
 seldGs=nil

 -- initialize grid matrix
 for i=1,gridCols do
  mt[i]={}
  for j=1,gridRows do
   mt[i][j]=gemC()
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
 if scene==1 then drawMenu() else drawGame() end
 drawCursor()
end

-- main functions

function menu()
 if clickBuffer>0 then clickBuffer-=1 end
 pButton=getPointedButton()
 if mb==1 then
  if pButton=="START" then
   sfx(00)
   if gameMode==1 then barColor=14 else barColor=11 end
   scene=2
   return
  elseif (pButton=="LBTN" or pButton=="RBTN") and clickBuffer==0 then
   sfx(00)
   clickBuffer=bufferRate
   gameMode=(gameMode%numOfModes)+1
  end
 end
end

function drawMenu()
 sBtnClr,sBtnSpr,lBtnSpr,rBtnSpr=btnDefaults()
 showInfo=false
 if pButton=="START" then
  sBtnClr,sBtnSpr=sBtnHighlight()
 elseif pButton=="LBTN" then
  lBtnSpr=13
 elseif pButton=="RBTN" then
  rBtnSpr=14
 elseif pButton=="I" then
  showInfo=true 
 end

 -- title etc.
 sspr(0,20,77,27,24,25)
 sspr(0,47,62,8,1,120)
 sspr(0,47,62,8,65,120)
 
 if showInfo then
  sspr(52,8,17,10,0,0)
  sspr(69,8,46,8,73,0)
 else 
  sspr(115,8,9,9,119,0)
 end

 -- start button
 rectfill(52,66,72,74,sBtnClr)
 spr(sBtnSpr,50,67)
 spr(sBtnSpr+1,73,67)
 print('START',53,68,7)

 print('GAME MODE',45,88,6)
 print(gameMode==1 and "NORMAL" or "TIMED",51,97,7)
 spr(lBtnSpr,37,96)
 spr(rBtnSpr,83,96)

 tutStr=gameMode==1 and "   (CLEAR 100 GEMS)" or "(PLAY FOR 60 SECONDS)"
 print(tutStr,20,105,5)
end

function game()
 if animT<1 then
  animT+=animRate
 else
  -- mark all gems are not to be animated
  for i=1,gridCols do
   for j=1,gridRows do
    mt[i][j][3]=false 
   end
  end
 end

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
 
 if mb==1 and animT==1 then -- if mouse is clicked/held down (accept input only when not animating)
  if gemCol>0 and gemCol<gridCols+1 and gemRow>0 and gemRow<gridRows+1 then
   -- check if gem is already selected
   if not mt[gemCol][gemRow][iSLCTD] then
    -- add to table of selected gems
    if seldGs==nil then
     sfx(01)
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
       sfx(01)
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

    -- play sfx then remove gems
    if #seldGs>=11 then
     sfx(04)
     sfx(02,-1,0,4)
    elseif #seldGs>=7 then
     sfx(02)
    else
     sfx(02,-1,0,4)
    end
    for k=1,#seldGs do
     mt[seldGs[k][1]][seldGs[k][2]][iGEMID]=nil
    end


    -- drop floating gems and refill the grid with gems
    for i=1,gridCols do
     for j=1,gridRows do
      -- check if column has an empty cell
      if mt[i][gridRows-j+1][iGEMID]==nil then
       colHldr={}
       for k=1,gridRows do
        -- copy remaining gems
        if mt[i][k][iGEMID] then
         mt[i][k][3]=true -- mark for animation
         mt[i][k][4][1]=k -- store origin row
         colHldr[#colHldr+1]=mt[i][k]
        end
       end

       -- put old gems in the bottom of the matrix, generate new ones for the top
       for k=1,gridRows do
        if #colHldr>0 then
         mt[i][gridRows-k+1]=colHldr[#colHldr] -- old gem/s
         colHldr[#colHldr]=nil
         mt[i][gridRows-k+1][4][2]=gridRows-k+1 -- store destination row
        else
         mt[i][gridRows-k+1]=newGemC(gridRows-k+1) -- new gem/s
        end
       end
       animT=0
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

function drawGame()
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
 
 -- highlight selected gem/s
 if seldGs then
  for k=1,#seldGs do
   gemx=(seldGs[k][1]-1)*gs+offset-1
   gemy=(seldGs[k][2]-1)*gs+offset-1
   sspr(sprX,sprY,sprS,sprS,gemx,gemy)
  end
 end
end

-- other functions
function getPointedButton()
 for i=1,#btns do
  if mx>btns[i][1] and mx<btns[i][3] and my>btns[i][2] and my<btns[i][4] then
   return btns[i][5]
  end
 end
 return nil
end

function draw_gems()
 for i=1,gridCols do
  x=offset+((i-1)*gs)
  for j=1,gridRows do
   gemId=mt[i][j][iGEMID]
   -- if animT==1 then
   --  y=offset+((j-1)*gs)
   -- else
   --  y=offset+(lerp(mt[i][j][4][1]*gs,mt[i][j][4][2]*gs,animT))
   -- end 
   if animT<1 and mt[i][j][3] then
    y=offset+(lerp((mt[i][j][4][1]-1)*gs,(mt[i][j][4][2]-1)*gs,animT))
   else
    y=offset+((j-1)*gs)
   end
   draw_1gem()
  end
 end
end

function draw_1gem()
 sspr(gSprX+((gemId-1)*gSprS),gSprY,gSprS,gSprS,x,y)
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

function btnDefaults()
 return 3,7,11,12
end

function sBtnHighlight()
 return 11,9
end

function lerp(A,B,t)
 return A+(B-A)*t
end

function gemC()
 -- (1) color (2) is selected (3) is animate (4) animation data (5) is skip drawing (temp data)
 return {flr(rnd(4))+1,false,false,{}}
end

function newGemC(destRow)
 -- (1) color (2) is selected (3) is animate (4) animation data (5) is skip drawing (temp data)
 return {flr(rnd(4))+1,false,true,{-2,destRow}}
end