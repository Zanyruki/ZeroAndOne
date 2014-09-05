--#require Collision


--MM: Variables specific to this script
drawCollision = false
iconVisible = true


ui = {   --MM: This is the order the info should be displayed in the editor
		drawCollision       = { order = 1, type = "bool", label = "Show collision" },
		iconVisible			= { order = 2, type = "bool", label = "Draw icon", default = true },
}

local baseWidth     = 0		-- Dimensions of emitter base
local baseHeight    = 0
local debugComponent = false
local collided = false
local collidedFrames = 0
local collidedWith = ""
local valid = false
local isBeingClimbed = false


--MM: Function called every time the levels loads or reload
function init()
	if ( rigidBody == nil ) then
		debugPrint( self.id .. " : init : No collision defined. Make sure the Collision component is being used properly" )
		return
	end
	if( not iconVisible ) then
		rigidBody:setCollisionMask( CollisionMask_Hidden )
	end
	baseWidth = iconW / pixelsPerUnit
	baseHeight = iconH / pixelsPerUnit

	valid = true
end


--MM: Function called every frame
function fixedUpdate( dt )

	if (g.math.abs(rigidBody:posX() - g.player.rigidBody:posX()) < g.player.iconW/pixelsPerUnit/2) and
				(g.math.abs(rigidBody:posY() - g.player.rigidBody:posY()) < 2 * g.player.iconH/pixelsPerUnit) then
			if( rigidBody:posY() - g.player.rigidBody:posY() > ( baseHeight - 1) * .5 ) then
				g.player.topOfLadder = true
			end
		g.player.onLadder = true
		if g.player.startClimb then
			--isBeingClimbed = true
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
	
	if( isBeingClimbed ) then
		iconAnim = ImageAnim( "Plants/TallLadderWiggle" )
	end
	isBeingClimbed = false
	
end


--JS: Assumes collidedWith is the Player. Needs code for other cases.
function beginContact( collidedWith )

end
