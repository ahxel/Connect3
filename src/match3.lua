function _init()
  poke(0x5f2d, 1) -- enable mouse
  
  -- gem data structure indices
  iGEMID=1 -- gem id for gem color
  iSLCTD=2 -- is gem selected flag

  -- grid variables
  offset=10 -- offset of grid's top-left corner
  gs=9 -- size of 1 grid unit
  gridRows=5
  gridCols=5
  mt={} -- grid matrix

  -- table to track selected gems
  selectedGems=nil

  -- initialize grid matrix
  for i=1,gridRows do
    mt[i]={}
    for j=1,gridCols do
      mt[i][j]={flr(rnd(4))+1,false}
    end
  end
end

function _update()
  -- mouse x, y and button
  mx=stat(32)
  my=stat(33)
  mb=stat(34) 
  pointedGem() -- get row and col of gem
  cGemR=nil
  cGemC=nil
  if mb==1 then
    if gemrow>0 and gemrow<gridrows+1 and gemcol>0 and gemcol<gridcols+1 then
      cgemr=gemrow
      cgemc=gemcol
    end
  end

  if mb==1 then -- if mouse is clicked/held down
    if gemRow>0 and gemRow<gridRows+1 and gemCol>0 and gemCol<gridCols+1 then
      -- check if gem is already selected
      if not mt[gemRow][gemCol][iSLCTD] then
        -- add to table of selected gems
        if selectedGems==nil then
          selectedGems={{gemRow,gemCol}}
        else
          selectedGems[#selectedGems+1]={gemRow,gemCol}
        end
        -- flip flag
        mt[gemRow][gemCol][iSLCTD]=true
      end           
    end
  else
    selectedGems=nil
  end

end

function _draw()
	cls()
	draw_gems()
  
  -- -- mark clicked gem
  -- if cGemR and cGemC then
  --   -- gemCenterX=(cGemC*9+offset)-6
  --   -- gemCenterY=(cGemR*9+offset)-6
  --   -- rectfill(gemCenterX,gemCenterY,gemCenterX+1,gemCenterY+1,14)

  --   gemx=((cGemC-1)*9+offset)+3
  --   gemy=((cGemR-1)*9+offset)+1
  --   print('1',gemx,gemy,14)    
  -- end
  
  -- mark selected gem/s
  if selectedGems then
    for k=1,#selectedGems do
      gemx=((selectedGems[k][2]-1)*9+offset)+3
      gemy=((selectedGems[k][1]-1)*9+offset)+1  
      print(k,gemx,gemy,14)
    end
  end

  print(gemRow..','..gemCol,0,0,6)
  -- print(mx..','..my,0,0) -- mouse coords
  drCsr()
  
end

function draw_gems()
  for i=1,gridRows do
    y=offset+((i-1)*gs)
    for j=1,gridCols do
      gemId=mt[i][j][iGEMID]
      x=offset+((j-1)*gs)
      draw_1gem()
    end
  end
end

function draw_1gem()
  spr(gemId,x,y)
end

-- draw cursor
function drCsr()
  palt(0,false)
  palt(8,true)
  spr(6,mx,my)
  palt()
end

-- row, col of gem that the cursor is pointing at
function pointedGem()
  gemRow=ceil((my-10)/9)
  gemCol=ceil((mx-10)/9)
end

