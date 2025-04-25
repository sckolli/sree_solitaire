-- grabber.lua
-- Grabber class for handling mouse input

GrabberClass = {}
GrabberClass.__index = GrabberClass

function GrabberClass:new()
  local self = setmetatable({}, GrabberClass)
  
  self.currentMousePos = nil
  self.previousMousePos = nil
  self.isMouseDown = false
  
  return self
end

function GrabberClass:update()
  
  self.previousMousePos = self.currentMousePos
  self.currentMousePos = {
    x = love.mouse.getX(),
    y = love.mouse.getY()
  }
  
  
  self.isMouseDown = love.mouse.isDown(1)
end