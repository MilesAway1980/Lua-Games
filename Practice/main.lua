function love.load()  
  
  player = {}
  
  player.Action = {}
  player.Action.facing = "left"  
  player.Action.jet = false
  player.Action.fall = true
  player.Action.running = false 
  player.Action.shooting = false
  
  player.ableToJump = 0
  player.maxRunSpeed = 100
  player.jetFuel = {}
  player.jetFuel.max = 250
  player.jetFuel.current = 0
  player.maxbullets = 5 
  player.bulletRefireRate = .3
  player.bulletTimer = 0
  player.bullets = {}
  
  spriteTileSize = 20  
  scale = 1.5
  scaledSprite = spriteTileSize * scale
  
  frame = 1  
  
  tiles = 1
  sprites = 2
  powerups = 3
    
  local image = {}
  image[tiles] = love.image.newImageData("MapTiles.png")
  image[sprites] = love.image.newImageData("CharSprites.png")
  image[powerups] = love.image.newImageData("PowerUpSprites.png")
  
  allSprites = {}  
  
  for which = 1, 3 do
    
    allSprites[which] = {}
    
    local count = 1    
    local width, high = image[which]:getWidth(), image[which]:getHeight()
    
    for y = 0, math.floor(high / spriteTileSize) - 1 do
      for x = 0, math.floor(width / spriteTileSize) - 1 do
              
        local sprite = love.image.newImageData(spriteTileSize, spriteTileSize)
        sprite:paste(image[which], 0, 0, x * spriteTileSize, y * spriteTileSize, spriteTileSize, spriteTileSize)
              
        allSprites[which][count] = love.graphics.newImage(sprite)
        count = count + 1            
      end
    end
  end
  
  animations = {}
  local animatedTiles = {15, 36, 66, 76}
  
  for i, which in ipairs(animatedTiles) do    
    animations[which] = {}
    for j = 0, 9 do      
      animations[which][j + 1] = which + j
    end
  end  
  
  charLoc = {}
  charLoc["x"] = 5
  charLoc["y"] = 10  
  
  quickMap = getQuickMap()
              
  love.physics.setMeter(scaledSprite)
  world = love.physics.newWorld(0, 9.81 * scaledSprite, true)
  world:setCallbacks(beginContact, endContact, preSolve, postSolve)
  
  text = ""
  persisting = 0
  
  nonBlockingTiles = {36, 66, 76}  
  
  objects = {}  
  objects.blocks = {}  
  
  for y = 1,20 do    
    for x = 1,20 do
      local blocksMovement = true
      for check = 1, #nonBlockingTiles do
        if (nonBlockingTiles[check] == quickMap[y][x]) then
          blocksMovement = false
        end
      end
      
      if (blocksMovement == true) then
        if (objects.blocks[y] == nil) then
          objects.blocks[y] = {}
        end
        objects.blocks[y][x] = {}
        if quickMap[y][x] ~= 0 then
          objects.blocks[y][x].body = love.physics.newBody(world, x * scaledSprite, y * scaledSprite, "static")
          objects.blocks[y][x].shape = love.physics.newRectangleShape(scaledSprite, scaledSprite)
          objects.blocks[y][x].fixture = love.physics.newFixture(objects.blocks[y][x].body, objects.blocks[y][x].shape, 10)
          objects.blocks[y][x].fixture:setUserData("Block: " .. x .. "," .. y)
        end      
      end
    end
  end
  
  objects.player = {}
  objects.player.body = love.physics.newBody(world, charLoc["x"] * scaledSprite, charLoc["y"] * scaledSprite, "dynamic")
  objects.player.shape = love.physics.newRectangleShape(scaledSprite, scaledSprite)
  objects.player.fixture = love.physics.newFixture(objects.player.body, objects.player.shape, 8)
  objects.player.fixture:setUserData("player")
  
  
  love.window.setMode(22 * scaledSprite, 22 * scaledSprite)
  
end

function love.draw()
  
  frame = frame + 1
  if (frame > 60) then
    frame = 1
  end
  
  local curAnimationTile = math.ceil(frame / 6) 
  
  charLoc["x"] = objects.player.body:getX()
  charLoc["y"] = objects.player.body:getY()
  
  --print(objects.player.body:getX() .. ", " .. objects.player.body:getY())
  
  local curCharSprite = getCurCharSprite()
  love.graphics.draw(allSprites[sprites][curCharSprite], charLoc["x"], charLoc["y"], 0, scale, scale)
  
  moveChar()
  moveBullets()
  
  for y = 1,20 do
    for x = 1,20 do
      if quickMap[y][x] ~= 0 then
        local tile = quickMap[y][x]
        local mapTile
        if (animations[tile] ~= nil) then          
          mapTile = allSprites[tiles][animations[tile][curAnimationTile]]
        else
          mapTile = allSprites[tiles][tile]
        end
        if (mapTile ~= nil) then
          love.graphics.draw(mapTile, x * scaledSprite, y * scaledSprite, 0, scale, scale)
        end
      end
    end
  end
  
  local bulletCount = 0
  for b = 1, player.maxbullets do    
    if (player.bullets[b] ~= nil) then
      bulletCount = bulletCount + 1
      love.graphics.setColor(0, 200, 200, 255)
      love.graphics.circle("fill", player.bullets[b]["x"], player.bullets[b]["y"], 5)
    end
  end
  love.graphics.setColor(255, 255, 255, 255)
  
  --if (text ~= nil) then
    love.graphics.print(bulletCount .. " / " .. player.maxbullets .. "  -  " .. player.bulletTimer .. " : " .. player.bulletRefireRate, 10, 10)
  --end
  
  local width = 200 * (player.jetFuel.current / player.jetFuel.max)
  
  love.graphics.setColor(200, 0, 0, 255)
  love.graphics.rectangle("fill", 30, love.graphics.getHeight() - 25, width + 10, 15)
  love.graphics.setColor(255,255,255,255)
  love.graphics.rectangle("line", 30, love.graphics.getHeight() - 25, 210, 15)
  love.graphics.print("Jet Fuel", 120, love.graphics.getHeight() - 23)
end

function love.update(dt)
  world:update(dt)  
  player.bulletTimer = player.bulletTimer + dt  
end

function moveChar()
  down = love.keyboard.isDown("down")
  left = love.keyboard.isDown("left")
  right = love.keyboard.isDown("right")
  up = love.keyboard.isDown("up") 
  space = love.keyboard.isDown(" ")
  ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
  --leftArrow = love.keyboard.isDown("<") or love.keyboard.isDown(",")
  --rightArrow = love.keyboard.isDown(">") or love.keyboard.isDown(".")
  
  if (player.ableToJump == true) then
    player.Action.fall = false
  else
    player.Action.fall = true
  end
  
  if (down) then
  end
  
  if (up) then
    if (player.jetFuel.current > 0) then
      player.jetFuel.current = player.jetFuel.current - 2
      player.Action.jet = true
      player.ableToJump = false
      objects.player.body:applyForce(0, -3000)    
    end
  else
    player.Action.jet = false
    if (player.ableToJump == true) then
      player.jetFuel.current = player.jetFuel.current + 10
    else
      player.jetFuel.current = player.jetFuel.current + 1
    end
    
    if (player.jetFuel.current > player.jetFuel.max) then
      player.jetFuel.current = player.jetFuel.max
    end
  end
  
  if (left) then
    player.Action.facing = "left"    
    player.Action.running = true
    objects.player.body:applyForce(-2000, 0)    
  end
  
  if (right) then   
    player.Action.facing = "right"    
    player.Action.running = true
    objects.player.body:applyForce(2000, 0)
  end
  
  if ((left == false) and (right == false)) then
    player.Action.running = false
  end
  
  if (space) then
    if (spaceDown == false) then
      spaceDown = true      
      if (player.ableToJump == true) then      
        objects.player.body:applyLinearImpulse(0, -2000)
        player.ableToJump = false
      end    
    end
  else
    spaceDown = false
  end 
  
  if (ctrl) then
    if (player.bulletTimer > player.bulletRefireRate) then
      shootBullet()
      player.bulletTimer = 0      
    end    
    player.Action.shooting = true
  else
    player.Action.shooting = false
  end  
end

function shootBullet()
  for i = 1, player.maxbullets do    
    if player.bullets[i] == nil then
      player.bullets[i] = {}
      if (player.Action.facing == "left") then
        player.bullets[i]["dir"] = "left"
        player.bullets[i]["x"] = objects.player.body:getX() - (scaledSprite / 2)
      else
        player.bullets[i]["dir"] = "right"
        player.bullets[i]["x"] = objects.player.body:getX() + (scaledSprite / 2)
      end
      player.bullets[i]["y"] = objects.player.body:getY() + (scaledSprite / 2)
      break
    end
  end
end

function moveBullets()
  for i = 1,player.maxbullets do
    if (player.bullets[i] ~= nil) then
      if (player.bullets[i]["dir"] == "left") then
        player.bullets[i]["x"] = player.bullets[i]["x"] - scaledSprite / 4
      else
        player.bullets[i]["x"] = player.bullets[i]["x"] + scaledSprite / 4
      end
      
      if (player.bullets[i]["x"] < 0 or player.bullets[i]["x"] > love.graphics.getWidth()) then
        player.bullets[i] = nil
      end      
    end    
  end
end

function getCurCharSprite()
  
  local curAnimationTile = (math.ceil(frame / 7.5) - 1)
    
  if (player.Action.facing == "left") then
    if (player.Action.shooting == true) then
      if (player.Action.jet == true) then
        return 42 
      else
        if (player.Action.fall == true) then
          return 38
        else
          if (player.Action.running == true) then
            return 40
          else
            return 36
          end
        end
      end
    else
      if (player.Action.jet == true) then
        return 21 + curAnimationTile      
      else
        if (player.Action.fall == true) then
          return 3
        else
          if (player.Action.running == true) then
            return 5 + curAnimationTile
          else
            return 1
          end
        end
      end      
    end
  else
    if (player.Action.shooting == true) then
      if (player.Action.jet == true) then             
        return 43
      else
        if (player.Action.fall == true) then
          return 39
        else
          if (player.Action.running == true) then
            return 41
          else
            return 37
          end
        end
      end
    else
      if (player.Action.jet == true) then
        local jetAnimationTile = curAnimationTile
        if (jetAnimationTile > 6) then
          jetAnimationTile = 6
        end      
        return 29 + jetAnimationTile
      else
        if (player.Action.fall == true) then
          return 4
        else
          if (player.Action.running == true) then
            return 13 + curAnimationTile
          else
            return 2
          end
        end
      end
    end
  end
end

function beginContact(objectA, objectB, collision)
    x, y = collision:getNormal()
    if (objectA:getUserData() == "player" or objectB:getUserData() == "player") then
      if (y ~= 0) then
        player.ableToJump = true
      else
        player.ableToJump = false
      end
    end
    --x,y = coll:getNormal()
    
    text = x .. " , " .. y
    
end


function endContact(objectA, objectB, collision)
    --persisting = 0    -- reset since they're no longer touching
    --text = text.."\n"..a:getUserData().." uncolliding with "..b:getUserData()
    x, y = collision:getNormal()
    if (objectA:getUserData() == "player" or objectB:getUserData() == "player") then
      if (y ~= 0) then
        --player.ableToJump = false
      else
        --player.ableToJump = true
      end
    end
    --x,y = coll:getNormal()
    
    text = x .. " , " .. y
    
end

function preSolve(a, b, coll)
    --[[
    if persisting == 0 then    -- only say when they first start touching
        text = text.."\n"..a:getUserData().." touching "..b:getUserData()
    elseif persisting < 20 then    -- then just start counting
        text = text.." "..persisting
    end
    persisting = persisting + 1    -- keep track of how many updates they've been touching for
    --]]
end

function postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
-- we won't do anything with this function
end

function getQuickMap() 
  return      {
                { 01, 01, 01, 01, 01, 01, 01, 01, 01, 04, 05, 01, 01, 01, 01, 01, 01, 01, 01, 01 },
                { 01, 00, 76, 76, 00, 00, 00, 00, 00, 06, 07, 00, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 15, 15, 15, 15 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 08, 08 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 09, 09, 09, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 08, 08, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 66, 66, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01, 01, 00, 00, 00, 00, 00, 00, 01 },
                { 01, 00, 00, 15, 15, 15, 15, 15, 00, 00, 00, 01, 02, 36, 36, 36, 36, 36, 36, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01, 02, 36, 36, 36, 36, 36, 36, 01 },
                { 01, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01, 02, 36, 36, 36, 36, 36, 36, 01 },
                { 04, 05, 00, 00, 00, 00, 00, 00, 00, 00, 00, 01, 01, 36, 36, 36, 36, 36, 36, 01 },
                { 06, 07, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01 }
              }
end