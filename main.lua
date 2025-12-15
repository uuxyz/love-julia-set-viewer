function love.load()
    love.window.setMode(0, 0, {fullscreen = true, vsync = true, resizable = true})
    love.window.setTitle("Mandelbrot & Julia Explorer")

    lightPos = {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2}
    lightRadius = 400
    lightHue = 0.0

    mandelbrot = {
        zoom = 0.7,
        offset = {x = -0.7, y = 0.0}
    }
    julia = {
        zoom = 1.0,
        offset = {x = 0.0, y = 0.0}
    }

    panning_view = nil -- Can be "mandelbrot" or "julia"

    lightShader = love.graphics.newShader("shadow.glsl")
end

function love.update(dt)
    lightPos.x, lightPos.y = love.mouse.getPosition()
    lightHue = (lightHue + dt * 0.1) % 1.0
    -- WASD logic removed
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
    if button == 3 then -- Middle mouse button
        if x < love.graphics.getWidth() / 2 then
            panning_view = "mandelbrot"
        else
            panning_view = "julia"
        end
        love.mouse.setRelativeMode(true)
    end
end

function love.mousereleased(x, y, button)
    if button == 3 then -- Middle mouse button
        panning_view = nil
        love.mouse.setRelativeMode(false)
    end
end

function love.mousemoved(x, y, dx, dy)
    if panning_view then
        local view = (panning_view == "mandelbrot") and mandelbrot or julia
        local screen_h = love.graphics.getHeight()
        view.offset.x = view.offset.x - dx / (screen_h * view.zoom)
        -- Flipping the sign for dy to achieve "content-style" vertical dragging
        view.offset.y = view.offset.y - dy / (screen_h * view.zoom)
    end
end

function love.wheelmoved(x, y) -- x and y are scroll amounts
    local screen_w = love.graphics.getWidth()
    local screen_h = love.graphics.getHeight()
    local mouse_x, mouse_y = love.mouse.getPosition() -- Correctly get mouse position

    if mouse_x < screen_w / 2 then
        -- Left side: Mandelbrot. Zoom to its own center to not affect Julia set.
        if y > 0 then
            mandelbrot.zoom = mandelbrot.zoom * 1.2
        elseif y < 0 then
            mandelbrot.zoom = mandelbrot.zoom / 1.2
        end
    else
        -- Right side: Julia. Zoom to cursor.
        local view = julia
        local view_center_x = screen_w * 0.75
        local gl_mouse_y = screen_h - mouse_y

        local mouse_world_before = {
            x = (mouse_x - view_center_x) / (screen_h * view.zoom) + view.offset.x,
            y = (gl_mouse_y - screen_h / 2) / (screen_h * view.zoom) + view.offset.y,
        }

        if y > 0 then
            view.zoom = view.zoom * 1.2
        elseif y < 0 then
            view.zoom = view.zoom / 1.2
        end

        local mouse_world_after = {
            x = (mouse_x - view_center_x) / (screen_h * view.zoom) + view.offset.x,
            y = (gl_mouse_y - screen_h / 2) / (screen_h * view.zoom) + view.offset.y
        }
        
        view.offset.x = view.offset.x + (mouse_world_before.x - mouse_world_after.x)
        view.offset.y = view.offset.y + (mouse_world_before.y - mouse_world_after.y)
    end
end

function love.draw()
    love.graphics.setShader(lightShader)
    
    lightShader:send("lightPos", {lightPos.x, lightPos.y})
    lightShader:send("lightRadius", lightRadius)
    lightShader:send("resolution", {love.graphics.getWidth(), love.graphics.getHeight()})
    lightShader:send("lightHue", lightHue)
    lightShader:send("ambientColor", {0.1, 0.1, 0.1})

    -- Send fractal parameters to shader
    lightShader:send("mandelbrot_zoom", mandelbrot.zoom)
    lightShader:send("mandelbrot_offset", {mandelbrot.offset.x, mandelbrot.offset.y})
    lightShader:send("julia_zoom", julia.zoom)
    lightShader:send("julia_offset", {julia.offset.x, julia.offset.y})

    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setShader()

    -- Draw crosshair for Mandelbrot center
    local centerX = love.graphics.getWidth() / 4
    local centerY = love.graphics.getHeight() / 2
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.line(centerX - 10, centerY, centerX + 10, centerY)
    love.graphics.line(centerX, centerY - 10, centerX, centerY + 10)
    
    -- Draw text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Mandelbrot Set (Left)", 5, 5, love.graphics.getWidth()/2 - 10, "center")
    love.graphics.printf("Julia Set (Right)", love.graphics.getWidth()/2 + 5, 5, love.graphics.getWidth()/2 - 10, "center")
    
    local c_text = "C = (" .. string.format("%.4f", mandelbrot.offset.x) .. ", " .. string.format("%.4f", mandelbrot.offset.y) .. ")"
    love.graphics.printf(c_text, love.graphics.getWidth()/2 + 5, 25, love.graphics.getWidth()/2 - 10, "center")

    love.graphics.print("Mouse: Move light source", 10, love.graphics.getHeight() - 60)
    love.graphics.print("Middle-click + Drag: Pan view (Left/Right)", 10, love.graphics.getHeight() - 40)
    love.graphics.print("Mouse Wheel: Zoom view (Left/Right)", 10, love.graphics.getHeight() - 20)
end
