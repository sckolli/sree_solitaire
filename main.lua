

io.stdout:setvbuf("no")
require "card"
require "grabber"
require "pile"
require "deck"

CARD_WIDTH = 73
CARD_HEIGHT = 97
CARD_OVERLAP = 25
ANIMATION_SPEED = 0.2
DOUBLE_CLICK_TIME = 0.5


function love.load()
  
  math.randomseed(os.time())
  
  
  love.window.setTitle("Klondike Solitaire")
  love.window.setMode(960, 640)
  love.graphics.setBackgroundColor(0, 0.5, 0.2, 1)
  
 
  gameFont = love.graphics.newFont(14)
  love.graphics.setFont(gameFont)
  
 
  loadCardImages()
  
  
  grabber = GrabberClass:new()
  
  
  initializeGame()
  
 
  lastClickTime = 0
  lastClickCard = nil
end

function loadCardImages()
  cardBack = love.graphics.newImage("assets/card_back.png")

  
  cards = {}
  local suits = {"clubs", "diamonds", "hearts", "spades"}
  local values = {
    [1] = "A",  
    [2] = "02",
    [3] = "03",
    [4] = "04",
    [5] = "05",
    [6] = "06",
    [7] = "07",
    [8] = "08",
    [9] = "09",
    [10] = "10",
    [11] = "J",  
    [12] = "Q",  
    [13] = "K"   
  }

  for _, suit in ipairs(suits) do
    cards[suit] = {}
    for value = 1, 13 do
      local filename = string.format(
        "assets/card_%s_%s.png",
        suit,
        values[value]
      )
      cards[suit][value] = love.graphics.newImage(filename)
    end
  end
end



function initializeGame()
  
  piles = {
    tableau = {},  
    foundation = {},  
    stock = nil,    
    waste = nil    
  }
  
 
  for i = 1, 7 do
    piles.tableau[i] = PileClass:new(100 + (i-1) * (CARD_WIDTH + 20), 150, "tableau", i)
  end
  
  
  for i = 1, 4 do
    piles.foundation[i] = PileClass:new(480 + (i-1) * (CARD_WIDTH + 20), 50, "foundation", i)
  end
  
  
  piles.stock = PileClass:new(100, 50, "stock", 0)
  piles.waste = PileClass:new(200, 50, "waste", 0)
  
  
  deck = DeckClass:new()
  deck:shuffle()
  
  
  for i = 1, 7 do
    for j = 1, i do
      local card = deck:dealCard()
      
      if j == i then
        card:flip()
      end
      piles.tableau[i]:addCard(card)
    end
  end
  
  
  while true do
    local card = deck:dealCard()
    if not card then break end
    piles.stock:addCard(card)
  end
  
  
  updateAllCardPositions()
  
  
  dragging = {
    active = false,
    cards = {},
    sourcePile = nil,
    offsetX = 0,
    offsetY = 0
  }
  
  
  gameWon = false
  
  
  score = 0
  moves = 0
end

function updateAllCardPositions()
  
  for _, pileType in pairs(piles) do
    if type(pileType) == "table" then
      if pileType.type then 
        pileType:updateCardPositions()
      else 
        for _, pile in ipairs(pileType) do
          pile:updateCardPositions()
        end
      end
    end
  end
end

function love.update(dt)
  grabber:update()
  
  if not gameWon then
   
    updateGame(dt)
  end
end

function updateGame(dt)
  
  checkForMouseMoving()
  
 
  for _, pileType in pairs(piles) do
    if type(pileType) == "table" then
      if pileType.type then 
        pileType:update(dt)
      else 
        for _, pile in ipairs(pileType) do
          pile:update(dt)
        end
      end
    end
  end
  
  
  if dragging.active then
    local mouseX, mouseY = grabber.currentMousePos.x, grabber.currentMousePos.y
    for i, card in ipairs(dragging.cards) do
      
      card.x = mouseX - dragging.offsetX
      card.y = mouseY - dragging.offsetY + (i-1) * CARD_OVERLAP
    end
  end
  
  
  checkForWin()
end

function love.draw()
  
  for _, pile in ipairs(piles.foundation) do
    pile:drawOutline()
  end
  
  for _, pile in ipairs(piles.tableau) do
    pile:drawOutline()
  end
  
  piles.stock:drawOutline()
  piles.waste:drawOutline()
  
 
  for _, pile in ipairs(piles.foundation) do
    pile:draw()
  end
  
  for _, pile in ipairs(piles.tableau) do
    pile:draw()
  end
  
  piles.stock:draw()
  piles.waste:draw()
  
  
  if dragging.active then
    for _, card in ipairs(dragging.cards) do
      card:draw()
    end
  end
  
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Score: " .. score, 10, 10)
  love.graphics.print("Moves: " .. moves, 10, 30)
  
 
  if gameWon then
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("You Win! Final Score: " .. score, 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
    love.graphics.printf("Press 'R' to play again", 0, love.graphics.getHeight()/2 + 20, love.graphics.getWidth(), "center")
  end
end

function checkForMouseMoving()
  if grabber.currentMousePos == nil then
    return
  end
  

  for _, pileType in pairs(piles) do
    if type(pileType) == "table" then
      if pileType.type then 
        pileType:checkForMouseOver(grabber)
      else 
        for _, pile in ipairs(pileType) do
          pile:checkForMouseOver(grabber)
        end
      end
    end
  end
end

function love.mousepressed(x, y, button)
  if button == 1 and not gameWon then 
    local currentTime = love.timer.getTime()
    
    
    if piles.stock:isPointInside(x, y) then
      if #piles.stock.cards > 0 then
        drawCardsFromStock()
        moves = moves + 1
      else
        resetStock()
        moves = moves + 1
      end
      return
    end
    
  
    if not dragging.active then
      local cardsToDrag, sourcePile = getCardsAt(x, y)
      
      if cardsToDrag and #cardsToDrag > 0 then
        
        local isDoubleClick = false
        if lastClickCard == cardsToDrag[1] and currentTime - lastClickTime < DOUBLE_CLICK_TIME then
          isDoubleClick = tryAutoMoveToFoundation(cardsToDrag[1], sourcePile)
          if isDoubleClick then
            lastClickCard = nil
            lastClickTime = 0
            return
          end
        end
        
        
        if cardsToDrag[1].faceUp then
          
          dragging.active = true
          dragging.cards = cardsToDrag
          dragging.sourcePile = sourcePile
          
          
          dragging.offsetX = x - cardsToDrag[1].x
          dragging.offsetY = y - cardsToDrag[1].y
          
          
          if #cardsToDrag == 1 then
            sourcePile:removeCard(cardsToDrag[1])
          else
            sourcePile:removeCards(#sourcePile.cards - #cardsToDrag + 1)
          end
          
          
        end
      end
      
      
      if cardsToDrag and #cardsToDrag > 0 then
        lastClickCard = cardsToDrag[1]
        lastClickTime = currentTime
      else
        lastClickCard = nil
      end
    end
  end
end

function love.mousereleased(x, y, button)
  if button == 1 and dragging.active then
    local targetPile = getPileAt(x, y)
    local validMove = false
    
    if targetPile then
      validMove = isValidMove(dragging.cards, targetPile)
      
      if validMove then
        
        for _, card in ipairs(dragging.cards) do
          targetPile:addCard(card)
        end
        
      
        if dragging.sourcePile.type == "tableau" and #dragging.sourcePile.cards > 0 and 
           not dragging.sourcePile.cards[#dragging.sourcePile.cards].faceUp then
          dragging.sourcePile.cards[#dragging.sourcePile.cards]:flip()
          
          score = score + 5
        end
        
       
        updateScoreForMove(dragging.sourcePile, targetPile)
        
        
        moves = moves + 1
      else
       
        for _, card in ipairs(dragging.cards) do
          dragging.sourcePile:addCard(card)
        end
      end
    else
      
      for _, card in ipairs(dragging.cards) do
        dragging.sourcePile:addCard(card)
      end
    end
    
   
    dragging.active = false
    dragging.cards = {}
    dragging.sourcePile = nil
    
   
    updateAllCardPositions()
  end
end

function love.keypressed(key)
  if key == "r" or key == "n" then
    
    initializeGame()
  end
end

function drawCardsFromStock()
  
  if #piles.stock.cards == 0 then
    return
  end
  
  
  for i = 1, cardsToMove do
    local card = table.remove(piles.stock.cards)
    card:flip() 
    piles.waste:addCard(card)
  end
  
  updateAllCardPositions()
end

function resetStock()
 
  if #piles.stock.cards == 0 and #piles.waste.cards > 0 then
    
    while #piles.waste.cards > 0 do
      local card = table.remove(piles.waste.cards)
      card:flip() 
      piles.stock:addCard(card)
    end
    
    updateAllCardPositions()
    
    
    score = math.max(0, score - 100)
  end
end

function getCardsAt(x, y)
  
  if #piles.waste.cards > 0 then
    local topCard = piles.waste.cards[#piles.waste.cards]
    if topCard:isPointInside(x, y) then
      return {topCard}, piles.waste
    end
  end
  
  
  for _, pile in ipairs(piles.foundation) do
    if #pile.cards > 0 then
      local topCard = pile.cards[#pile.cards]
      if topCard:isPointInside(x, y) then
        return {topCard}, pile
      end
    end
  end
  
  
  for _, pile in ipairs(piles.tableau) do
    local foundIndex = nil
    
   
    for i = #pile.cards, 1, -1 do
      local card = pile.cards[i]
      
      
      if card.faceUp then
        
        local hitBoxHeight = (i == #pile.cards) and CARD_HEIGHT or CARD_OVERLAP
        
        if x >= card.x and x <= card.x + CARD_WIDTH and
           y >= card.y and y <= card.y + hitBoxHeight then
          foundIndex = i
          break
        end
      end
    end
    
    if foundIndex then
      
      local cardStack = {}
      for j = foundIndex, #pile.cards do
        table.insert(cardStack, pile.cards[j])
      end
      return cardStack, pile
    end
  end
  
  return nil, nil
end

function getPileAt(x, y)
  
  for _, pile in ipairs(piles.foundation) do
    if pile:isPointInside(x, y) then
      return pile
    end
  end
  
  
  for _, pile in ipairs(piles.tableau) do
    if x >= pile.x and x <= pile.x + CARD_WIDTH and
       y >= pile.y and y <= pile.y + 400 then 
      return pile
    end
  end
  
  
  if piles.waste:isPointInside(x, y) then
    return piles.waste
  end
  
  return nil
end

function isValidMove(cards, targetPile)
  
  if targetPile.type == "foundation" then
    if #cards > 1 then
      return false
    end
    
    local card = cards[1]
    
    if #targetPile.cards == 0 then
      
      return card.value == 1 -- Ace
    else
      local topCard = targetPile.cards[#targetPile.cards]
     
      return card.suit == topCard.suit and card.value == topCard.value + 1
    end
  
  
  elseif targetPile.type == "tableau" then
    local bottomCard = cards[1] 
    
    if #targetPile.cards == 0 then
      
      return bottomCard.value == 13 
    else
      local topCard = targetPile.cards[#targetPile.cards]
      
      local oppositeColor = (
        (bottomCard:isRed()) and not (topCard:isRed())
      ) or (
        not bottomCard:isRed() and topCard:isRed()
      )
      
      return oppositeColor and bottomCard.value == topCard.value - 1
    end
  end
  
 
  return false
end

function tryAutoMoveToFoundation(card, sourcePile)
  
  if not card or not card.faceUp then
    return false
  end
  
 
  for _, foundationPile in ipairs(piles.foundation) do
    
    if isValidMove({card}, foundationPile) then
      
      if sourcePile.type == "waste" then
        sourcePile:removeCard(card)
      else
        sourcePile:removeCard(card)
        
        
        if sourcePile.type == "tableau" and #sourcePile.cards > 0 and not sourcePile.cards[#sourcePile.cards].faceUp then
          sourcePile.cards[#sourcePile.cards]:flip()
          
          score = score + 5
        end
      end
      
      
      foundationPile:addCard(card)
      
     
      updateScoreForMove(sourcePile, foundationPile)
      
    
      moves = moves + 1
      
     
      updateAllCardPositions()
      
      return true
    end
  end
  
  return false
end

function updateScoreForMove(sourcePile, targetPile)
  
  if targetPile.type == "foundation" then
    
    if sourcePile.type == "tableau" then
      score = score + 10
    elseif sourcePile.type == "waste" then
      score = score + 10
    end
  elseif targetPile.type == "tableau" then
    
    if sourcePile.type == "waste" then
      score = score + 5
    
    elseif sourcePile.type == "foundation" then
      score = score - 15
    end
  end
end

function checkForWin()
  
  local complete = true
  
  for _, pile in ipairs(piles.foundation) do
    if #pile.cards < 13 then
      complete = false
      break
    end
  end
  
  if complete then
    gameWon = true
    
    score = score + 700
  end
end