hump_camera = require 'engine/external/hump_camera'
-- This mixin handles drawing of the game world through a viewport and the functions needed to make that happen.
-- The arguments passed in to create a camera are:
-- x, y - the camera's position in world coordinates, the camera is always centered around its x, y coordinates
-- w, h - the camera's size, generally this should be game.w, game.h
-- A global instance of this called "camera" is available by default.
camera2d = class:use(shake)
function camera2d:new(x, y, w, h)
  self.x, self.y = x or 0, y or 0
  self.r, self.sx, self.sy = 0, 1, 1
  self.w, self.h = w or game.w, h or game.h
  self.camera = hump_camera(self.x, self.y)
  self.parallax_base_pos = vec2(0, 0)
  self.mouse = vec2(0, 0)
  self.last_mouse = vec2(0, 0)
  self.mouse_dt = vec2(0, 0)
  self.impulse = vec2(0, 0)
  self.impulse_damping = 0.9
  self.smooth = self.camera.smooth
  self:shake_init()
end

-- Attaches the camera, meaning all further draw operations will be affected by its transform.
-- Accepts two values that go from 0 to 1 that represent how much parallaxing there should be for the next operations.
-- A value of 1 means no parallaxing, meaning the elements drawn will move at the same rate as all other elements, while a value of 0 means maximum parallaxing, which means the elements won't move at all.
function camera2d:attach(parallax_x, parallax_y)
  self.parallax_base_pos:set(self.x, self.y)
  self.x = self.parallax_base_pos.x*(parallax_x or 1)
  self.y = self.parallax_base_pos.y*(parallax_y or parallax_x or 1)
  self.camera:lookAt(self.x, self.y)
  self.camera:attach(nil, nil, self.w, self.h)
end

-- Detaches the camera, meaning all further draw operations won't be affected by its transform.
function camera2d:detach()
  self.camera:detach()
  self.x, self.y = self.parallax_base_pos.x, self.parallax_base_pos.y
  self.camera:lookAt(self.x, self.y)
end

-- Returns the values passed in in world coordinates. This is useful when transforming things from screen space to world space, like when the mouse clicks on something.
-- If you look at camera:get_mouse_position you'll see that it uses this function on the values returned by love.mouse.getPosition (which return values in screen coordinates).
-- camera:get_world_coords(love.mouse.getPosition())
function camera2d:get_world_coords(x, y)
  return self.camera:worldCoords(x, y, game.sx, game.sy, nil, nil, self.w, self.h)
end

-- Returns the values passed in in local coordinates. This is useful when transforming things from world space to screen space, like when displaying UI according to the position of game objects.
-- x, y = camera:get_local_coords(player.x, player.y)
function camera2d:get_local_coords(x, y)
  return self.camera:cameraCoords(x, y, game.sx, game.sy, nil, nil, self.w, self.h)
end

function camera2d:update(dt)
  self.mouse.x, self.mouse.y = self:get_mouse_position()
  self.mouse_dt.x, self.mouse_dt.y = self.mouse.x - self.last_mouse.x, self.mouse.y - self.last_mouse.y
  self:shake_update(dt)

  self.x, self.y = math.position_damping(self.x, self.y, self.impulse.x, self.impulse.x, self.impulse_damping, dt)
  self.impulse:set(math.velocity_damping(self.impulse.x, self.impulse.y, self.impulse_damping, dt))
  self.camera:lookAt(self.x, self.y)
  self.last_mouse.x, self.last_mouse.y = self.mouse.x, self.mouse.y
  self.camera:rotateTo(self.r)
end

-- Returns the mouse's position in world coordinates
-- x, y = camera:get_mouse_position()
function camera2d:get_mouse_position()
  return self:get_world_coords(love.mouse.getPosition())
end

-- Returns the angle from a point to the mouse
-- x, y = camera:angle_to_mouse(point.x, point.y)
function camera2d:angle_to_mouse(x, y)
  local mx, my = self:get_mouse_position()
  return math.angle_to(x, y, mx, my)
end

-- Moves the camera by the given amount
-- camera:move(10, 10)
function camera2d:move(dx, dy)
  self.camera:move(dx, dy)
end

-- Rotates the camera by the given amount
-- camera:rotate(math.pi/2) -> rotates by math.pi/2 from the current angle
function camera2d:rotate(r)
  self.camera:rotate(r)
end

-- Rotates the camera to the given angle
-- camera:rotate_to(math.pi/2) -> rotates to math.pi/2 regardless of current angle
function camera2d:rotate_to(r)
  self.camera:rotateTo(r)
end

-- Zooms the camera by the given amount
-- camera:zoom(2) -> zooms the camera in by 2x from the current zoom level
function camera2d:zoom(s)
  self.camera:zoom(s)
end

-- Zooms the camera to the given scale
-- camera:zoom(2) -> zooms the camera to 2x zoom regardless of current zoom level
function camera2d:zoom_to(s)
  self.camera:zoomTo(s)
end

-- Applies an impulse to the camera with force f and towards angle r
-- This movement stops over time according to the damping value, which is 0.9 by default, the closer to 0 the faster it stops
-- Because this is an impulse, you should only call it once, if you call this every frame the camera will just fly off into infinity
-- camera:apply_impulse(100, math.pi/2) -> impulses the camera downwards force 100
function camera2d:apply_impulse(f, r, damping)
  self.impulse_damping = impulse_damping or 0.9
  self.impulse:add(f*math.cos(r), f*math.sin(r))
end

-- Locks the camera horizontally to the given x position
-- smoother is one of the following: camera.smooth.linear(value) or camera.smooth.damped(value), as explained here https://hump.readthedocs.io/en/latest/camera.html#camera-movement-control
-- camera:lock_x(player.x, cameras[1].smooth.linear(10))
function camera2d:lock_x(x, smoother, ...)
  self.camera:lockX(x, smoother, ...)
  self.x, self.y = self.camera.x, self.camera.y
end

-- Locks the camera vertically to the given y position
-- smoother is one of the following: camera.smooth.linear(value) or camera.smooth.damped(value), as explained here https://hump.readthedocs.io/en/latest/camera.html#camera-movement-control
-- camera:lock_y(player.y, cameras[1].smooth.linear(10))
function camera2d:lock_y(y, smoother, ...)
  self.camera:lockY(y, smoother, ...)
  self.x, self.y = self.camera.x, self.camera.y
end

-- Locks the camera to the given x, y position
-- smoother is one of the following: camera.smooth.linear(value) or camera.smooth.damped(value), as explained here https://hump.readthedocs.io/en/latest/camera.html#camera-movement-control
-- camera:lock_xy(player.x, player.y, cameras[1].smooth.linear(10))
function camera2d:lock_xy(x, y, smoother, ...)
  self.camera:lockPosition(x, y, smoother, ...)
  self.x, self.y = self.camera.x, self.camera.y
end

-- Locks the camera to the given x, y position with the deadzone rectangle x1, y1, x2, y2 defined with x, y as its center
-- smoother is one of the following: camera.smooth.linear(value) or camera.smooth.damped(value), as explained here https://hump.readthedocs.io/en/latest/camera.html#camera-movement-control
-- camera:lock_with_deadzone(player.x, player.y, -40, -40, 40, 40, camera.smooth.linear(10)) -> the camera will lock to the player with a deadzone of 80 units around it where it won't move
function camera2d:lock_with_deadzone(x, y, x1, y1, x2, y2, smoother, ...)
  x1, y1 = self:get_local_coords(x + x1, y + y1)
  x2, y2 = self:get_local_coords(x + x2, y + y2)
  self.camera:lockWindow(x, y, x1, y1, x2, y2, smoother, ...)
  self.x, self.y = self.camera.x, self.camera.y
end

