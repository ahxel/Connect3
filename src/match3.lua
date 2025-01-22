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
  -- mouse x, y and button
  mx=stat(32)
  my=stat(33)
  mb=stat(34) 
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
    -- if seldGs then
    --   -- if 3 or more gems selected, remove selected them from the grid & ....
    --   if #seldGs>2 then
    --     -- remove gems
    --     -- check columns with nil cells
    --     -- if column has nil, store remaining gems in table, move those gems to the bottom of grid, then generate new gems to fill the column again
    --   else
    --     -- reset flags in grid matrix and reset selected gems table variable
    --     for k=1,#seldGs do
    --       mt[seldGs[k][1]][seldGs[k][2]][iSLCTD]=false
    --     end
    --     seldGs=nil
    --   end
    -- end

    -- reset flags of gems on the grid
    if seldGs then
      for k=1,#seldGs do
        mt[seldGs[k][1]][seldGs[k][2]][iSLCTD]=false
      end
      seldGs=nil
    end
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
  if seldGs then
    for k=1,#seldGs do
      gemx=((seldGs[k][1]-1)*9+offset)+3
      gemy=((seldGs[k][2]-1)*9+offset)+1  
      print(k,gemx,gemy,14)
    end
  end

  print(gemCol..','..gemRow,0,0,6)
  -- print(mx..','..my,0,0) -- mouse coords
  drCsr()
  
end

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

