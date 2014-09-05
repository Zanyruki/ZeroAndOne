

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
name = "Electricity"
iconVisible = true
iconAnim = "x.lua"


--JS: Locally-global variables
iconAnimTime = 0.0
rigidBody = nil
angle = 0


ui = {
	name         = { order=1, type = "string", label = "Name" },
	iconVisible  = { order=3, type = "bool",   label = "Draw icon" },
	iconAnim     = { order=5, type = "anim",   label = "Icon" },
}


local debugComponent = false
local killMe = false
local collideWithPlayer = false
local collideWithPlayer2 = false
local hitElecNoise = ""

function init()
	iconAnim = ImageAnim( iconAnim )
	iconAnimTime = 0.0

	hitElecNoise = Sound( "HitByElec.wav" )

	--Create a default RigidBody for everything, which is then modified by other components
	--  ... except the World Settings actor
		rigidBody = g.physics:createBox( x, y, RigidBody_SENSOR, iconW/pixelsPerUnit, iconH/pixelsPerUnit, 1.0 ) 
		rigidBody:setCollisionCategory( CollisionCategory_Hazard )
		rigidBody:setCollisionMask( CollisionMask_NONE )

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

	if( collideWithPlayer ) then
		playerResolution( g.player )
		collideWithPlayer = false
	end
	if( collideWithPlayer2 ) then
		playerResolution( g.player2 )
		collideWithPlayer2 = false
	end
	
end

function beginContact( collidedWith )
	
	if( collidedWith == g.player ) then
		collideWithPlayer = true
	end
	if( collidedWith == g.player2 ) then
		collideWithPlayer2 = true
	end
	

end

function playerResolution( player )
	g.player.currentHealth = g.player.currentHealth - 1
		
		hitElecNoise:play(false)
		if( g.player.currentHealth > 0 ) then
			player.isStunned = true
			player.currentStunTime = visibleTime - iconAnimTime
		end
end

function render( dt )
	if ( iconVisible ) then
		if ( iconAnimTime ~= nil ) and ( x ~= nil ) and ( y ~= nil ) and ( angle ~= nil ) then
			iconAnim:draw( iconAnimTime, x, y, angle, Image_COORDS_GAME )
		end
	end
end





