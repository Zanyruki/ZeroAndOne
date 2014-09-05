--#require Collision


--JS: File load and execution priority
priority = -950


--UI Variables
moveSpeed     = 5.0
jumpSpeed     = 10.0
friction      = 0.5
health        = 1
healthRegen   = 0
armor         = 0
startFullArmor = true
armorRegen    = 0
lives         = 1
stunTime      = 0.75


--Player animation state controllers
initialized = false
isAlive     = false
isIdle      = false
isMoving    = false
isJumping   = false
isFalling   = false
isClimbing  = false
isStunned   = false
isInCombat  = false
newState    = ""
frozenDuringCollision = false


--Player properties
maxHealth      = 4
currentHealth  = 4
useHealthRegen = false
healthRegen    = 0
maxArmor       = 1
currentArmor   = 0
startFullArmor = false
useArmorRegen  = false
armorRegen     = 0
maxLives       = 1
currentLives   = 0
stunTime       = 0
deathDelay     = 0
currentDeathDelay = 0
drawCollision  = false
score          = 0
damageType     = ""
damageToGive   = 0
damageReceived = 0
damagedBy = ""
maxSpeed  = vec2( 0, 0 )
newSpeed	= vec2( 0, 0 )
dir = 1
rotation  = 0
friction  = 0
bounceImpulse = 75
currentStunTime = 0
regensElapsedTime = 0
jumpDir = 1
combatType = ""
resourceUses = 0
triggerIsPressed = false
jumpIsPressed = false
onLadder = false
startClimb = false
topOfLadder = false
rightLadderOffDelay = 0
leftLadderOffDelay = 0
jumpDelay = 0
platformOn = nil
climbSound = ""
climbSoundPlaying = false
spawnDelay = 0

idleSound = ""
moveSound = ""
jumpSound = ""
lastSound = ""
newSound = ""
deathSound = ""
pickupSound = ""
shootSound = ""
noResouceSound = ""
loopSound = false

ui = {
	moveSpeed      = { order = 1,  type = "number",  label = "Movement Speed" },
	jumpSpeed      = { order = 2,  type = "number",  label = "Jump Speed" },
	friction       = { order = 3,  type = "number",  label = "Floor Friction" },
	health         = { order = 4,  type = "number",  label = "Max Health" },
	healthRegen    = { order = 5,  type = "number",  label = "Health Regen/Sec" },
	armor          = { order = 6,  type = "number",  label = "Max Armor" },
	startFullArmor = { order = 7,  type = "boolean", label = "Start with Full Armor" },
	armorRegen     = { order = 8,  type = "number",  label = "Armor Regen/Sec" },
	lives          = { order = 9, type = "number",  label = "Lives" },
	stunTime       = { order = 10, type = "number",  label = "Stun duration" },
	deathDelay     = { order = 11, type = "number",  label = "Respawn delay after death" },
	drawCollision  = { order = 12, type = "bool", 	label = "Show collision?" },
}


local debugComponent = false


function InitializePlayer()
	if ( g.player ~= this ) then
		g.player = this -- store player as global
		g.interactButton = false
	end
	
	--sounds
	idleSound = Sound( "silence.wav" )
	idleSound:setVolume( .3 )
	moveSound = Sound( "ZeroMove.wav" )
	moveSound:setVolume( .25 )
	jumpSound = Sound( "ZeroJump.wav" )
	jumpSound:setVolume( .4 )

	deathSound = Sound( "OneDeath.wav" )
	pickupSound = Sound( "ZeroWaterPickup2.wav" )
	shootSound = Sound( "ZOWaterShoot.wav" )
	noResouceSound = Sound( "NoWater.wav" )

	lastSound = Sound( "silence.wav" )
	
	--JS: Player Collision is hardcoded to Circle for now, 
	--JS:   until we can fix bugs related to box movement colliding with ghost vertices
	if ( rigidBody ~= nil ) then
		g.physics:remove( rigidBody )
	end
	rigidBody = g.physics:createCircle( x, y, RigidBody_DYNAMIC, g.math.max( iconW/pixelsPerUnit, iconH/pixelsPerUnit ), 1.0 )
	rigidBody:setCollisionCategory( CollisionCategory_Zero )
	rigidBody:setCollisionMask( CollisionMask_Zero )	

	--JS: Set actor properties from UI values
	maxSpeed.x  = g.math.clamp( g.math.abs( moveSpeed ), 0.1, 128 )
	maxSpeed.y  = -g.math.clamp( g.math.abs( jumpSpeed ), 0, 128 )
	friction    = g.math.clamp( friction, 0, 1 )
	maxHealth   = g.math.clamp( health, 1, 65535 )
	healthRegen = g.math.clamp( healthRegen, 0, 65535 )
	maxArmor    = g.math.clamp( armor, 0, 65535 )
	armorRegen  = g.math.clamp( armorRegen, 0, 65535 )
	maxLives    = g.math.clamp( lives, 1, 65535 )
	maxStunTime = g.math.clamp( stunTime, 0, 65535 )

	--JS: Give this actor the correct starting properties
	SetPlayerPropertiesFromSession()
	damageReceived = 0
	currentDeathDelay = deathDelay
	spawnDelay = 2
	
	--[[
	--If this actor has no Combat component, set default combat to COLLISION, 1 damage per hit
	--TODO: replace single Combat component with 3 separates
	if ( this:isType( "Combat" ) == false ) then
		damageType = "COLLISION"
		damageToGive = 1
	end
	--]]

	initialized = true
	isAlive     = true
	
	fireDelay = 0

	--Set current level in session variables
	SetSessionVariable( "currentLevel", g.thisLevel )

	if ( debugComponent ) then
		debugPrint( this.id .. " : PLAYER : init: Initialized" )
	end

	--JFS: Ensure this actor is never "destroyed" during screen clipping, actor deletion etc.
	updateAlways = true

	checkpointX = g.player.x
	checkpointY = g.player.y
	if ( debugComponent ) then
		debugPrint( this.id .. " : PLAYER : init: Starting checkpoint: " .. checkpointX .. ", " .. checkpointY )
	end

	currentDeathDelay = deathDelay
	climbSound = Sound( "Climb2.wav")
	climbSound:setVolume( .3 )
end


function init()
	InitializePlayer()
end


function update( dt ) 
	if ( debugComponent ) or ( drawCollision ) then
		debugDrawCollision( this, {255,255,0} )
	end
	
	if( spawnDelay > 0 ) then
		spawnDelay = spawnDelay - dt
	end

    if( dir ~= nil) then
        if( dir == 1) then
            iconAnim:scaleX(1);
        else
            iconAnim:scaleX(-1);
        end
	end


	if ( initialized ) then
		if ( isAlive ) then
			--ApplyRegens()
			--Calculate result of any damage taken by this actor
			--CalculateDamage()	
		else
			frozenDuringCollision = false
			currentDeathDelay = currentDeathDelay - dt
		end

		if ( frozenDuringCollision ) then
			currentStunTime = currentStunTime + dt
			if ( currentStunTime >= maxStunTime ) then
				EnablePlayerInput()
				currentStunTime = 0
				frozenDuringCollision = false
			end
		end

		if ( isAlive == false ) and ( iconAnimTime >= 1 ) and ( currentDeathDelay <= 0 ) then
			deathAnimComplete = true
			local thisEvent = new( g.eventStruct )
			thisEvent = g.EventSystem_LocateEventMapping( "evtPlayerPostDeath" )
			if ( thisEvent ~= nil ) then
				thisEvent.sender = this.id
				thisEvent.destinationIDs = { this.id }
				EventClientComponent_PostEvent( thisEvent )
			end
		end

			-- if (isAlive == false) then
			-- 	g.player.x = g.player.checkpointX
		 -- 		g.player.y = g.player.checkpointY
		 -- 		g.player2.x = g.player.checkpointX
		 -- 		g.player2.y = g.player.checkpointY
		 -- 		isAlive = true
			-- end

		if (currentHealth <= 0) then

			-- players unable to move during death animatino
			--isStunned = true
			--currentStunTime = stunTime
			--g.player2.isStunned = true
			--g.player2.currentStunTime = g.player2.stunTime

			if (currentDeathDelay == deathDelay) then

				deathSound:play(false)

				-- player 1
				x = x + iconAnim:width() * 0.5 / pixelsPerUnit
				iconAnim = ImageAnim( "Zero/ZeroDeath.lua" )
				iconAnimTime = 0
				iconAnim:setWrap( ImageAnim_WRAP_STOP )
				baseWidth = iconAnim:width() / pixelsPerUnit
				baseHeight = iconAnim:height() / pixelsPerUnit
				x = x - baseWidth * 0.5
				g.physics:remove( rigidBody )
				rigidBody = g.physics:createBox( x, y, RigidBody_STATIC, baseWidth, baseHeight, 1.0 )

				-- player 2
				g.player2.x = g.player2.x + g.player2.iconAnim:width() * 0.5 / pixelsPerUnit
				g.player2.iconAnim = ImageAnim( "One/OneDeath.lua" )
				g.player2.iconAnimTime = 0
				g.player2.iconAnim:setWrap( ImageAnim_WRAP_STOP )
				g.player2.baseWidth = g.player2.iconAnim:width() / pixelsPerUnit
				g.player2.baseHeight = g.player2.iconAnim:height() / pixelsPerUnit
				g.player2.x = g.player2.x - baseWidth * 0.5
				g.physics:remove( g.player2.rigidBody )
				g.player2.rigidBody = g.physics:createBox( g.player2.x, g.player2.y, RigidBody_STATIC, baseWidth, baseHeight, 1.0 )
			end

			-- respawn after delay
			if (currentDeathDelay < 0) then 
				iconAnim = ImageAnim( "Zero/ZeroIdle.lua" )
				g.player2.iconAnim = ImageAnim( "One/OneIdle.lua" )
				PlayerRespawn()
				g.player2.PlayerRespawn()
				currentHealth = maxHealth
				currentDeathDelay = deathDelay

			else
				currentDeathDelay = currentDeathDelay - 1
			end

		end

		-- if ( currentHealth <= 0) then
		-- 	debugPrint( this.id .. " : PLAYER : init: currentHealth <= 0" )
		-- 	if (currentDeathDelay > 0) then
		-- 		debugPrint( this.id .. " : PLAYER : init: death delay" )
		-- 		currentDeathDelay = currentDeathDelay - 1
		-- 	else
		-- 		debugPrint( this.id .. " : PLAYER : init: reset to checkpoint: " .. g.player.checkpointX .. ", " .. g.player.checkpointY  )
		-- 		g.player.x = g.player.checkpointX
		-- 		g.player.y = g.player.checkpointY
		-- 		g.player2.x = g.player.checkpointX
		-- 		g.player2.y = g.player.checkpointY

		-- 		g.player.newSpeed.x = 0
		-- 		g.player.newSpeed.y = 0

		-- 		g.player.isJumping = false

		-- 		currentDeathDelay = deathDelay
		-- 		currentHealth = maxHealth
		-- 	end
		-- end
	end
end


--JS: This is pretty messy, feels like it could be cleaned up a lot :/
function fixedUpdate( dt )
	if ( initialized ) then
		--if ( isAlive == false ) and ( rigidBody:isOnGround() ) then
		--	rigidBody:setLinearVelocity( 0, 0 )
		--end

		if ( not isAlive ) and ( currentDeathDelay > 0 ) and ( rigidBody:isOnGround() ) then
			vx = rigidBody:linearVelocityX()
			vy = rigidBody:linearVelocityY()
			rigidBody:setLinearVelocity( vx * ( 1 - friction ), vy * ( 1 - friction ) )
			return
		end

		if ( isAlive ) and ( frozenDuringCollision == false ) then
			if ( inputEnabled == false ) then
				EnablePlayerInput()
			end
			
			if( currentStunTime <= 0 ) then
				isStunned = false
				--iconAnim = ImageAnim( "Zero/ZeroIdle.lua" )
				
			else
				currentStunTime = currentStunTime - dt
			end
			
			if( jumpDelay > 0 ) then
				jumpDelay = jumpDelay - dt
			end

			vx = rigidBody:linearVelocityX()
			vy = rigidBody:linearVelocityY()
			
			if isClimbing and onLadder then
				vy = -.2
				isFalling = false
			end

			if ( newSpeed.x ~= 0 ) then
				vx = newSpeed.x
				newSpeed.x = 0
			else
				--JS: No movement key pressed, apply "friction" to current movement
				vx = vx * ( 1 - friction )
				if ( vx > -0.1 ) and ( vx < 0.1 ) then
					vx = 0
					isMoving = false
				end
			end

			if ( newSpeed.y ~= 0 ) then
				--Ensure that we push player upwards, regardless of variable sign sent to us
				vy = newSpeed.y
				newSpeed.y = 0
			else
				if ( vy >= -0.1 ) and ( vy <= 0.1 ) then
					vy = 0
				end
			end

			if ( isJumping ) and ( vy > 0 ) then
				jumpDir = -1
			end
			if ( isJumping ) and ( jumpDir == -1 ) and ( onLadder or rigidBody:isOnGround() ) then
				isJumping = false
			end
				
			if ( isClimbing ) then 
				climbDir = -1
			end

			if (inResourceArea == true) then

				if (resourceUses < 5) then
 					pickupSound:play( false )
				end

				resourceUses = 5
			end


			if ( vy > 2.5 ) and ( isJumping == true ) then 
				isFalling = true
			else
				isFalling = false
			end
			
			rigidBody:setLinearVelocity( vx, vy )
			if( spawnDelay <= 0 ) then
				if( x < g.worldWidthLeft ) then
					rigidBody:setPos( g.worldWidthLeft, y )
				elseif( x > g.worldWidthRight ) then
					rigidBody:setPos( g.worldWidthRight, y )
				end
			end
			--rigidBody:setPos( newX, newY )--]]
		end
		
		--Gamepad Controls
		if( g.controller1.connected and ( not isStunned ) and ( currentHealth > 0 ) ) then
		
			if( g.controller1.thumbLX > .25 ) then
				if( isClimbing ) then
					if( g.controller1.thumbLX > 0.9 ) then
						rightLadderOffDelay = rightLadderOffDelay + dt
						if( rightLadderOffDelay > .15 ) then
							isClimbing = false
						end
					end
				else
					newSpeed.x = maxSpeed.x
					dir = 1
					isMoving = true
				end
			else
				rightLadderOffDelay = 0
			end
			
			if( g.controller1.thumbLX < -.25 ) then
				if( isClimbing ) then
					if( g.controller1.thumbLX < -0.9 ) then
						leftLadderOffDelay = leftLadderOffDelay + dt
						if( leftLadderOffDelay > .15 ) then
							isClimbing = false
						end
					end
				else
					newSpeed.x = -maxSpeed.x
					dir = -1
					isMoving = true
				end
			else
				leftLadderOffDelay = 0
			end
			
			if( g.controller1.thumbLY > .25 and jumpDelay <= 0 ) then
				if( onLadder and isClimbing ) then 
					if( not climbSoundPlaying ) then
						climbSound:play(true)
						climbSoundPlaying = true
					end
					if( not topOfLadder ) then
						newSpeed.y = maxSpeed.y/2
						climbDir = 1
					end
				else
					startClimb = true
				end
				
			elseif( g.controller1.thumbLY < -.25 and onLadder ) then
				if( onLadder and isClimbing ) then
					topOfLadder = false
					newSpeed.y = -maxSpeed.y/2
					climbDir = 1
				end
				if( rigidBody:isOnGround() ) then
					isClimbing = false
				end
			else
				startClimb = false
				
			end
			if( g.controller1.A ) then
				if( not jumpIsPressed ) then
					if ( rigidBody:isOnGround() or isClimbing ) then
						jumpIsPressed = true
						if( isClimbing ) then
							jumpDelay = .8
						end
						newSpeed.y = maxSpeed.y
						isJumping = true
						isClimbing = false
						jumpDir = 1	 
					end
				end
			else
				jumpIsPressed = false
			end
			if (g.controller1.X) then

				g.interactButton = true
			else
				g.interactButton = false
			end
			if (g.controller1.B) then
				isClimbing = false
			end
		

			if (triggerIsPressed == true) then
				if (g.controller1.leftTrigger < 0.5 and g.controller1.rightTrigger < 0.5) then
					triggerIsPressed = false
				end
			end

			if ((g.controller1.leftTrigger > 0.5 or g.controller1.rightTrigger > 0.5) and triggerIsPressed == false) then
				if (resourceUses > 0) then
					resourceUses = g.player.resourceUses - 1;
				
					shootSound:play( false )
				
					combatType = "SHOOT"

					--bullet = spawn( g.player.rigidBody:posX() + ( ( g.math.max( g.player.rigidBody:width() / 2, g.player.rigidBody:height() ) / 2 ) ), g.player.rigidBody:posY(), dmgRangedActorTemplate, "Objects" );	
					bullet = spawn( g.player.rigidBody:posX(), g.player.rigidBody:posY(), dmgRangedActorTemplate, "Objects" );
					if ( bullet.rigidBody == nil ) then
						if ( debugComponent ) then
							debugPrint( this.id .. " : EVENTFUNCTIONS_GENERAL : eventFn_CombatShoot : Cannot find a ranged actor template called " .. dmgRangedActorTemplate )
						end
						return
					end
				
					bullet.whoFired = this
					bullet.iconVisible = true
					bullet.iconAnim = ImageAnim( dmgBulletAnim )
					bullet.iconAnimTime = 0.0
					self.animLength = self.dmgAnimShootLength

					bullet:Shoot()

					triggerIsPressed = true
				else
					
					noResouceSound:play( false )

					triggerIsPressed = true
				end
			end
		end
		
		onLadder = false
		topOfLadder = false
		
		newState = "idle"
		newSound = idleSound
		loopSound = true
		
		if ( isMoving ) then
			newState = "move"
			newSound = moveSound
		end
		if ( isJumping ) then
			newState = "jump" 
			isClimbing = false
			newSound = jumpSound
			loopSound = false
			if( debugComponent ) then
				--debugPrint( this.id .. " : PLAYER : isJumping" )
			end
		end
		if ( isClimbing ) then
			newState = "climb"
			if( debugComponent ) then
				--debugPrint( this.id .. " : PLAYER : isClimbing" )
			end
		elseif( climbSoundPlaying ) then
			climbSoundPlaying = false
			climbSound:stop()
		end
		if ( isFalling ) then
			newState = "fall"
			isClimbing = false
		end
		if ( isStunned ) then 
			newState = "stun"
		end
		if ( isInCombat ) then
			newState = "combat"
		end
		if ( currentHealth <= 0 ) then
			if( climbSoundPlaying ) then
				climbSoundPlaying = false
				climbSound:stop()
			end
			if( g.player2.climbSoundPlaying ) then
				g.player2.climbSoundPlaying = false
				g.player2.climbSound:stop()
			end
			
			newState = "dead"
		end

		if rigidBody:isOnGround() == false then
			platformOn = nil
		end

		if platformOn ~= nil then
			rigidBody:setPos( rigidBody:posX() + platformOn:getVelocityX() * dt, rigidBody:posY() + platformOn:getVelocityY() * dt)
		end
		
		if( newSound ~= lastSound ) then
			lastSound:stop()
			newSound:play( loopSound )
			lastSound = newSound
		end
		
	end
end


function render( dt ) 
	if ( initialized ) and ( isAlive ) then
		if ( debugComponent ) then
			if ( rigidBody:linearVelocityX() > 0 ) then
				drawLine( rigidBody:posX(), rigidBody:posY(), rigidBody:posX() + (iconW/pixelsPerUnit)/1.5, rigidBody:posY(), 0, 255, 0 )
			elseif ( rigidBody:linearVelocityX() < 0 ) then
				drawLine( rigidBody:posX(), rigidBody:posY(), rigidBody:posX() -	 (iconW/pixelsPerUnit)/1.5, rigidBody:posY(), 0, 255, 0 )
			end
		end
	end
end


function beginContact( collidedWith ) 
	if ( initialized ) and ( isAlive ) then
		if ( frozenDuringCollision ) then
			if ( debugComponent ) then
				debugPrint( this.id .. " : PLAYER : beginContact : Already colliding. Skipping beginContact" )
			end
			return
		end

		--Don't collide with hidden actors
		if ( collidedWith.iconVisible == false ) then
			if ( debugComponent ) then
				debugPrint( this.id .. " : PLAYER : beginContact : Actor " .. collidedWith.name .. "." .. collidedWith.id .. " is hidden. Skipping beginContact" )
			end
			return
		end

		if ( ( collidedWith:isType( "MovingPlatform" ) ) or ( collidedWith:isType( "MovingPlatformAccel" ) ) or ( collidedWith:isType( "MovingPlatformCircle" ) ) or ( collidedWith:isType( "MovingPlatformAccelSimple" ) ) )   and ( collidedWith.iconVisible )  then
			if ( debugComponent ) then
				debugPrint( this.id .. " : PLAYER : beginContact : Resolving Player-BASE collision" )
			end
				
			
			--ResolveMovingPlatformCollision( self , collidedWith )
			platformOn = collidedWith
		end

		if ( collidedWith:isType( "AI" ) ) and ( collidedWith.iconVisible ) then
			--Player and AI collided, so resolve it
			--  Usually ends with player being damaged, although damageType="COLLISION" lets player win by jumping on enemy head
			--Melee-type and Shoot-type damage are resolved in Bullet.lua since it's the bullet that actually collides
			--if ( damageType == "COLLISION" ) then
				if ( debugComponent ) then
					debugPrint( this.id .. " : PLAYER : beginContact : Resolving Player-AI collision" )
				end
				ResolveAICollision( self, collidedWith )
			--end
		end

		--if ( collidedWith:isType( "Hazard" ) ) then
		--	if ( debugComponent ) then
		--		debugPrint( this.id .. " : PLAYER : beginContact : Resolving Player-Hazard collision" )
		--	end
		--	ResolveHazardCollision( self, collidedWith )
		--end
		
		--if ( collidedWith:isType( "Ladder" ) ) then
		--	if ( debugComponent ) then
		--		debugPrint( this.id .. " : PLAYER : beginContact : Resolving Player-Ladder collision" )
		--	end
			--isClimbing = true
		--end
	end
end


--JS: Player has one only way to win in CombatCollision, every other way sees Enemy winning
--JS:   So set default winner=enemy/loser=player then specifically check for player-win case
function ResolveAICollision( player, enemy )
	--Bools to stop actor movement during collision resolution
	player.frozenDuringCollision = true
	enemy.frozenDuringCollision = true
	DisablePlayerInput()

	--Setup default win case, happens 75% of the time with damageType="COLLISION" and 100% of the time otherwise
	local winner = enemy
	local loser  = player

	--Setup some temp variables
	local ppos = vec2( 0, 0 )
	ppos.x = rigidBody:posX()
	ppos.y = rigidBody:posY()
	local epos = vec2( 0, 0 )
	epos.x = enemy.rigidBody:posX()
	epos.y = enemy.rigidBody:posY()
	
	--if ( damageType == "COLLISION" ) then
	if ( this:isType( "CombatCollision" ) ) then
		--Player win case - player bounced on enemy head?
		if ( player.rigidBody:isOnGround() == false ) then
			if ( ppos.x >= epos.x - ((enemy.iconW/pixelsPerUnit)/2)) and ( ppos.x <= epos.x + ((enemy.iconW/pixelsPerUnit)/2)) and ( ppos.y <= epos.y ) then
				winner = player
				loser = enemy
				debugPrint( this.id .. " : PLAYER : ResolveAICollision : Player wins" )
			end
		end
	end

	--Winner damages loser!
	loser.damageReceived = loser.damageReceived + winner.damageToGive
	
	--If player wins, bounce player up 1.5x normal jump height
	--Otherwise actors push away from each other
	player.rigidBody:setLinearVelocity( 0, 0 )
	enemy.rigidBody:setLinearVelocity( 0, 0 )
	if ( winner == player ) then
		player.rigidBody:setLinearVelocity( rigidBody:linearVelocityX(), maxSpeed.y * 1.5 )
		player.frozenDuringCollision = false
		player.isJumping = true
		player.jumpDir = 1
		player.currentAnim = ""
	else
		if ( ppos.x <= epos.x ) then
			player.rigidBody:applyLinearImpulse( -3, -6 )
			enemy.rigidBody:applyLinearImpulse( 3, -6 )
		else
			player.rigidBody:applyLinearImpulse( 3, -6 )
			enemy.rigidBody:applyLinearImpulse( -3, -6 )
		end
	end
end


function ResolveHazardCollision( player, hazard )
	player.frozenDuringCollision = true
	DisablePlayerInput()

	local ppos = vec2( 0, 0 )
	ppos.x = player.rigidBody:posX()
	ppos.y = player.rigidBody:posX()
	local epos = vec2( 0, 0 )
	epos.x = hazard.rigidBody:posX()
	epos.y = hazard.rigidBody:posY()
	
	player.rigidBody:setLinearVelocity( 0, 0 )
	--if ( player.isJumping ) then
	--	player.rigidBody:applyLinearImpulse( 3 * dir, -6 )
	--else
		if ( ppos.x <= epos.x ) then
			player.rigidBody:applyLinearImpulse( -3, -6 )
		else
			player.rigidBody:applyLinearImpulse( 3, -6 )
		end
	--end
end


function updateCurrentState()
	
end


function ApplyRegens( self )
	--MM: Only worry about elapsed time if something is regenerating
	if ( healthRegen > 0 ) or ( armorRegen > 0 ) then
		--MM: Add to elapsed time
		regensElapsedTime = regensElapsedTime + dt;
		
		--MM: Only regen every second
		if ( regensElapsedTime >= 1 ) then
			--MM: Reset elapsed time with out losing any time
			regensElapsedTime = regensElapsedTime - 1; 
				
			--MM: Regen Health
			if ( healthRegen > 0 ) then
				currentHealth = currentHealth + healthRegen;
				g.math.clamp( currentHealth, 0, maxHealth )
			end		
			
			--MM: Regen Armor
			if ( armorRegen > 0 ) then
				currentArmor = currentArmor + armorRegen;
				g.math.clamp( currentArmor, 0, maxArmor )
			end		
		end
	end
end


function CalculateDamage( self )
	--MM: Damage goes through armor first, THEN health
	--JS: Any damageReceived at all?
	if ( damageReceived > 0 ) and ( currentHealth > 0 ) then
		--MM: Apply damage to armor first
		if ( currentArmor > 0 ) then
			if ( currentArmor > damageReceived ) then
				currentArmor = currentArmor - damageReceived;
				damageReceived = 0
			else
				--MM: Damage remaining after applying to armor
				damageReceived = damageReceived - currentArmor;  
				currentArmor = 0;
			end
		end

		--MM: If there is still damage remaining after armor, apply it to health
		if ( damageReceived > 0 ) then
			if ( currentHealth > damageReceived ) then
				currentHealth = currentHealth - damageReceived; 
				damageReceived = 0
			else --MM: Actor dies
				currentHealth = 0
				frozenDuringCollision = false
				isAlive = false

				local thisEvent = g.eventStruct;
				thisEvent = g.EventSystem_LocateEventMapping("evtPlayerPreDeath");
				if ( thisEvent ~= nil ) then
					thisEvent.sender = this.id;
					thisEvent.destinationIDs = { this.id } --MM: Sends only to this actor
					EventClientComponent_PostEvent( thisEvent );
				end
			end
		end
	end
end


function SetPlayerPropertiesFromSession( self )
	debugPrint( this.id .. " : PLAYER : Setting player properties from Session" )

	--JS: Game Start or Level Load/Reload?
	currentHealth  = GetSessionVariable( "Player.currentHealth" ) or maxHealth
	currentArmor   = GetSessionVariable( "Player.currentArmor" ) or maxArmor
	currentLives   = GetSessionVariable( "Player.currentLives" ) or maxLives
	score          = GetSessionVariable( "Player.score" ) or 0

	local checkpoint = GetSessionVariable( "checkpoint" )
	if ( checkpoint.posX ~= nil ) then
		rigidBody:setPos( checkpoint.posX, checkpoint.posY )
	else
		local tmp = {}
		tmp.posX = rigidBody:posX()
		tmp.posY = rigidBody:posY()
		tmp.name = this.id
		SetSessionVariable( "checkpoint", tmp )
	end
end


function PlayerRespawn()
	debugPrint( this.id .. " : PLAYER : Respawning at last checkpoint" )
	
	InitializePlayer()

	iconAnimTime = 0
	deathAnimComplete = false
end