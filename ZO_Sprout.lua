

--[[
This file is the property of the SMU Guildhall. It may not be reproduced or
distributed in any form without the express permission of the SMU Guildhall.

Please contact Gary Brubaker (garyb@smu.edu) for further information.

(c)SMU Guildhall, 2012.

Notes:
--]]


dofile( self, APP_PATH .. "scripts/include/Developer.lua")
dofile( self, APP_PATH .. "scripts/include/GeneralFunctions.lua" )
dofile( self, APP_PATH .. "scripts/include/EventClientComponent.lua")
dofile( self, APP_PATH .. "scripts/include/Fade.lua")
dofile( self, APP_PATH .. "scripts/include/collision/Categories.lua" )
dofile( self, APP_PATH .. "scripts/include/collision/Masks.lua" )


--JS: File load and execution priority
priority = -9950


--JS: UI variables
name = "Sprout"
iconVisible = true
iconAnim = "Plant/Sprout.lua"
isWatered = false
isLit = false
plantHeight = "Tall"


--JS: Locally-global variables
iconAnimTime = 0.0
rigidBody = nil
angle = 0


ui = {
	name         = { order=1, type = "string", label = "Name" },
	iconVisible  = { order=2, type = "bool", label = "Draw icon" },
	iconAnim     = { order=3, type = "anim", label = "Icon", default = "Plant/Sprout.lua" },
	isWatered	 = { order=4, type = "bool", label = "Plant is Watered" },
	isLit		 = { order=5, type = "bool", label = "Plant is Lit" },
	plantHeight  = { order=6, type = "list", values = { "Tall", "Short"}, default = "Tall", label = "Plant Height" },
}


local baseWidth     = 0		-- Dimensions
local baseHeight    = 0
local grown = false
local canGrow = false
local growSound = ""
local waterGrowSound = ""
local lightGrowSound = ""

local debugComponent = false


function init()
	iconAnim = ImageAnim( iconAnim )
	if( isWatered ) then
		iconAnim = ImageAnim( "Plants/WateredSproutIdle.lua" )
	elseif( isLit ) then
		iconAnim = ImageAnim( "Plants/LitSproutIdle.lua" )
	end
	iconAnimTime = 0.0
	baseWidth = iconW / pixelsPerUnit
	baseHeight = iconH / pixelsPerUnit

	growSound = Sound( "VineGrow.wav" )
	waterGrowSound = Sound( "WaterGrow.wav" )
	lightGrowSound = Sound( "LightGrow.wav" )

	rigidBody = g.physics:createBox( x, y, RigidBody_SENSOR, baseWidth, baseHeight, 1.0 ) 
	rigidBody:setCollisionCategory( CollisionCategory_Trigger )
	rigidBody:setCollisionMask( CollisionMask_Plant )

	if ( g.table.getn( this.scripts ) > 1 ) then
		g.table.insert( inits, EventClientComponent_Init )
		g.table.insert( postUpdates, fade_postUpdate )

		--Register Listeners for all components on this actor
		--This will undoubtedly miss some specific listeners, 
		--  but any events containing component names on this actor will be included automatically
		--  e.g. any Player events on the Player actor will be added to the Listener list
		for ii = 1, g.table.getn( scripts ) do
			for _,v in g.pairs( g.eventMappings ) do
				local tmp = g.table.contains( v, scripts[ii], "eventName" )
				if ( tmp ~= false ) then
					thisEvent = new( g.eventStruct )
					thisEvent = g.EventSystem_LocateEventMapping( v.eventName )
					thisEvent.sender = this.name
					if ( this.id ~= nil ) then
						thisEvent.sender = thisEvent.sender .. "." .. this.id
					end
					thisEvent.destinationIDs = { this.id }
					EventClientComponent_RegisterListener( thisEvent )
				end
			end
		end
			
		--JS: Register Listeners for Fade system
		for _,v in g.pairs( g.eventMappings ) do
			local tmp = g.table.contains( v, "Fad", "eventName" )
			if ( tmp ~= false ) then
				thisEvent = new( g.eventStruct )
				thisEvent = g.EventSystem_LocateEventMapping( v.eventName )
				thisEvent.sender = this.name
				if ( this.id ~= nil ) then
					thisEvent.sender = thisEvent.sender .. "." .. this.id
				end
				thisEvent.destinationIDs = { this.id }
				EventClientComponent_RegisterListener( thisEvent )
			end
		end
	end
end


function fixedUpdate( dt )

	if( canGrow ) then
		growPlant()
	end
	if( grown ) then
	
		if (g.math.abs(rigidBody:posX() - g.player.rigidBody:posX()) < g.player.iconW/pixelsPerUnit/2) and
					(g.math.abs(rigidBody:posY() - g.player.rigidBody:posY()) < 2 * g.player.iconH/pixelsPerUnit) then
			if( rigidBody:posY() - g.player.rigidBody:posY() > ( baseHeight - 1) * .5 ) then
				g.player.topOfLadder = true
			end
			g.player.onLadder = true
			if g.player.startClimb then
				g.player.isClimbing = true
				g.player.isFalling = false
				g.player.isJumping = false
				g.player.rigidBody:setPos( rigidBody:posX(), g.player.rigidBody:posY() )
			end
		end
	
		if (g.math.abs(rigidBody:posX() - g.player2.rigidBody:posX()) < g.player2.iconW/pixelsPerUnit/2) and
					(g.math.abs(rigidBody:posY() - g.player2.rigidBody:posY()) < 2 * g.player2.iconH/pixelsPerUnit) then
			if( rigidBody:posY() - g.player2.rigidBody:posY() > ( baseHeight - 1) * .5 ) then
				g.player2.topOfLadder = true
			end
			g.player2.onLadder = true
			if g.player2.startClimb then
				g.player2.isClimbing = true
				g.player2.isFalling = false
				g.player2.isJumping = false
				g.player2.rigidBody:setPos( rigidBody:posX(), g.player2.rigidBody:posY() )
			end
		end
	end
	

		iconAnimTime = iconAnimTime + dt

end

--JS: Assumes collidedWith is the Player. Needs code for other cases.
function beginContact( collidedWith )

		if( collidedWith.name == "Button" ) then
			debugPrint("POOP" )
		end
		
		if( not grown ) then
			if( collidedWith.name == "WaterBullet" ) then
				isWatered = true
				
				if( isLit ) then
					canGrow = true
				else
					
					waterGrowSound:play( false )
					iconAnim = ImageAnim( "Plants/WateredSproutIdle.lua" )
				end
			
			end
			
			if( collidedWith.name == "LightBullet" ) then
				isLit = true
				if( isWatered ) then
					canGrow = true
				else
					lightGrowSound:play( false )
					iconAnim = ImageAnim( "Plants/LitSproutIdle.lua" )
				end
			end
		end
		
end

function growPlant()
	grown = true
	canGrow = false
	
	y = y + iconAnim:height() * 0.5 / pixelsPerUnit

	--thisAnim.animation = ImageAnim( "Plants/VineGrowth.lua" )
	if( plantHeight == "Tall" ) then
		iconAnim = ImageAnim( "Plants/VineGrow.lua" )
	else
		iconAnim = ImageAnim( "Plants/VineGrowSmall.lua" )
	end
	iconAnimTime = 0
	iconAnim:setWrap( ImageAnim_WRAP_STOP )
	baseWidth = iconAnim:width() / pixelsPerUnit
	baseHeight = iconAnim:height() / pixelsPerUnit
	y = y - baseHeight * 0.5
	g.physics:remove( rigidBody )
	rigidBody = g.physics:createBox( x, y, RigidBody_SENSOR, baseWidth, baseHeight, 1.0 )
	rigidBody:setCollisionCategory( CollisionCategory_Trigger )
	rigidBody:setCollisionMask( CollisionMask_GrownPlant )
	growSound:play(false)
end


function render( dt )
	if ( iconVisible ) then
		if ( iconAnimTime ~= nil ) and ( x ~= nil ) and ( y ~= nil ) and ( angle ~= nil ) then
			iconAnim:draw( iconAnimTime, x, y, angle, Image_COORDS_GAME )
		end
	end
end





