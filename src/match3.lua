function _init()
  poke(0x5f2d, 1) -- enable mouse
  offset=10
  gs=9
  N=5
  M=5
  mt={}
  for i=1,N do
    mt[i]={}
    for j=1,M do
      mt[i][j]=flr(rnd(4))+1
    end
  end	
end

function _update()
  mx = stat(32)
  my = stat(33)
end

function _draw()
	cls()
	draw_gems()
  --print(mx..','..my)
  drCsr()
  pPointedGem()
end

function draw_gems()
  for i=1,N do
    y=offset+((i-1)*gs)
    for j=1,M do
      gemId=mt[i][j]
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

function pPointedGem()
  gemRow=ceil((my-10)/9)
  gemCol=ceil((mx-10)/9)
  print(gemRow..','..gemCol)
end

