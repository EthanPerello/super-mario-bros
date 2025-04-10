--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height, levelNum, score)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    local keylockcolor = math.random(4)
    local keyPlaced = false
    local lockPlaced = false

    local hasKey = false

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness if not the first two columns
        if math.random(7) == 1 and x > 2 and x < width-1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and x < width-1 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false,
                            exists = true
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 and x < width-1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false,
                        exists = true
                    }
                )

            -- chance to generate key
            elseif (math.random(30) == 1 or x == width) and keyPlaced == false then
                table.insert(objects,
                    GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = keylockcolor,
                        collidable = true,
                        consumable =true,
                        exists = true,

                        onConsume = function(player, object)
                            gSounds['pickup']:play()
                            hasKey = true
                        end
                    }
                )
                keyPlaced = true
            end

            -- chance to spawn a block
            if math.random(10) == 1 and x < width-1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,
                        exists = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,
                                        exists = true,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            -- random chance to place the lock block
            elseif (math.random(30) == 1 or x == width) and lockPlaced == false then
                table.insert(objects,

                    -- lock block
                    GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * 16,
                        y = (blockHeight - 1) * 16,
                        width = 16,
                        height = 16,
                        frame = 4 + keylockcolor,
                        collidable = true,
                        solid = true,
                        exists = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- get rid of block if we have the key
                            if hasKey == true then
                                obj.exists = false
                                obj.solid = false
                                obj.collidable = false

                                gSounds['powerup-reveal']:play()

                                table.insert(objects,

                                    -- flagpole
                                    GameObject {
                                        texture = 'flags',
                                        x = (width - 2) * 16,
                                        y = (4 - 1) * 16,
                                        width = 16,
                                        height = 16,
                                        frame = 1,
                                        collidable = true,
                                        consumable = true,
                                        solid = false,
                                        exists = true,

                                        -- collision function takes itself
                                        onConsume = function(player, obj)
                                            gStateMachine:change('play', {levelNum=levelNum+1, score=player.score})
                                        end
                                    }
                                )
                                table.insert(objects,

                                    -- flagpole
                                    GameObject {
                                        texture = 'flags',
                                        x = (width - 2) * 16,
                                        y = (5 - 1) * 16,
                                        width = 16,
                                        height = 16,
                                        frame = 10,
                                        collidable = true,
                                        consumable = true,
                                        solid = false,
                                        exists = true,

                                        -- collision function takes itself
                                        onConsume = function(player, obj)
                                            gStateMachine:change('play', {levelNum=levelNum+1, score=player.score})
                                        end
                                    }
                                )
                                table.insert(objects,

                                    -- flagpole
                                    GameObject {
                                        texture = 'flags',
                                        x = (width - 2) * 16,
                                        y = (6 - 1) * 16,
                                        width = 16,
                                        height = 16,
                                        frame = 19,
                                        collidable = true,
                                        consumable = true,
                                        solid = false,
                                        exists = true,

                                        -- collision function takes itself
                                        onConsume = function(player, obj)
                                            gStateMachine:change('play', {levelNum=levelNum+1, score=player.score})
                                        end
                                    }
                                )
                                table.insert(objects,

                                    -- flagpole
                                    GameObject {
                                        texture = 'flags',
                                        x = (width - 1.5) * 16,
                                        y = (4.3 - 1) * 16,
                                        width = 16,
                                        height = 16,
                                        frame = 16,
                                        collidable = true,
                                        consumable = true,
                                        solid = false,
                                        exists = true,

                                        -- collision function takes itself
                                        onConsume = function(player, obj)
                                            gStateMachine:change('play', {levelNum=levelNum+1, score=player.score})
                                        end
                                    }
                                )
                            else
                                gSounds['empty-block']:play()
                            end
                        end
                    }
                )
                lockPlaced = true
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end