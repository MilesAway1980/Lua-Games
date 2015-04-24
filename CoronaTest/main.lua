-- 
-- Abstract: ManyCrates sample project
-- Demonstrates simple body construction by generating 100 random physics objects
-- 
-- Version: 1.1
-- 
-- Sample code is MIT licensed, see http://www.coronalabs.com/links/code/license
-- Copyright (C) 2010 Corona Labs Inc. All Rights Reserved.
--
-- Supports Graphics 2.0
---------------------------------------------------------------------------------------

local centerX = display.contentCenterX
local centerY = display.contentCenterY
local _W = display.contentWidth
local _H = display.contentHeight

local physics = require("physics")
physics.start()

display.setStatusBar( display.HiddenStatusBar )

local leftBlock = display.newImage( "blockX.png" )
leftBlock.x = 20
leftBlock.y = 100
physics.addBody( leftBlock, "static", { friction = 0.5 } )

local rightBlock = display.newImage( "blockX.png" )

rightBlock.x = 440
rightBlock.y = 100
physics.addBody( rightBlock, "static", { friction = 0.5 } )

block = {}
joint = {}
for i = 1,20 do
	block[i] = display.newImage( "caution.png" )
	
    block[i].x = 20 + (i * 20)
	block[i].y = 100
	block[i].myIndex = i -- for touch handler above
	--block[i]:addEventListener( "touch", breakJoint ) -- assign touch listener to board
	
	physics.addBody( block[i], { density = 2, friction = 0.3, bounce = 0.3 } )
    
	block[i].angularDamping = 5
	block[i].linearDamping = 100

	-- create joints between boards
	if (i > 1) then
		prevLink = block[i - 1] -- each board is joined with the one before it
	else
		prevLink = leftBlock -- first board is joined to left pole
	end
    
	joint[i] = physics.newJoint( "pivot", prevLink, block[i], 6 + (i * 20), 150 )
end

joint[#joint + 1] = physics.newJoint( "pivot", block[20], rightBlock, 6 + (21 * 20), 150 )

function newBlock()	
	rand = math.random( 100 )

	if (rand < 33) then
		newBlock = display.newImage("block.png");
		newBlock.x = (_W / 4) + math.random( _W / 2 )
		newBlock.y = -100
		physics.addBody( newBlock, { density = 0.1, friction = 0.3, bounce = 0.3} )
		
	elseif (rand < 66) then
		newBlock = display.newImage("block2.png");
		newBlock.x = (_W / 4) + math.random( _W / 2 )
		newBlock.y = -100
		physics.addBody( newBlock, { density = 0.2, friction = 0.3, bounce = 0.2} )
    else
		newBlock = display.newImage("block3.png");
		newBlock.x = (_W / 4) + math.random( _W / 2 )
		newBlock.y = -100
		physics.addBody( newBlock, { density = 0.3, friction = 0.2, bounce = 0.5} )	
		
	end	
end

local dropBlocks = timer.performWithDelay( 500, newBlock, 200 )