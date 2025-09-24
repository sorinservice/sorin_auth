--// SorinHub Auth Gate (no UI)
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local Analytics   = game:GetService("RbxAnalyticsService")
local LP          = Players.LocalPlayer

-- === CONFIG ===
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVkbnZhbmV1cHNjbXJnd3V0YW12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjEyMzAsImV4cCI6MjA3MDEzNzIzMH0.7duKofEtgRarIYDAoMfN7OEkOI_zgkG2WzAXZlxl5J0"
local ENDPOINT = "https://udnvaneupscmrgwutamv.supabase.co/functions/v1/auth_check_SorinHub"

-- === Helpers ===
local function getClientIdSafe()
    local ok, id = pcall(function() return Analytics:GetClientId() end)
    return ok and tostring(id) or "unavailable"
end

local function getExecutorName()
    if identifyexecutor then
        local ok, name = pcall(identifyexecutor)
        if ok and type(name) == "string" then return name end
    end
    if syn then return "Synapse"
    elseif KRNL_LOADED then return "KRNL"
    elseif is_sirhurt_closure then return "SirHurt"
    elseif secure_load then return "Sentinel" end
    return "Unknown"
end

local function postJson(url, body)
    local req = (syn and syn.request) or (http and http.request) or request or http_request
    if not req then return nil, "no http_request available" end
    local res = req({
        Url = url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY
        },
        Body = HttpService:JSONEncode(body)
    })
    if not res.Success then
        return nil, tostring(res.StatusCode) .. " " .. tostring(res.Body)
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(res.Body)
    end)
    if not ok then return nil, "json decode failed" end
    return decoded, nil
end

-- === Gather Data ===
local robloxId   = LP.UserId
local robloxName = LP.DisplayName or LP.Name
local clientId   = getClientIdSafe()
local executor   = getExecutorName()
local placeId    = game.PlaceId

-- === Call Auth ===
local result, err = postJson(ENDPOINT, {
    robloxId   = robloxId,
    robloxName = robloxName,
    clientId   = clientId,
    executor   = executor,
    placeId    = placeId,
})

if not result then
    LP:Kick("SorinHub: Auth check failed. Try again later.")
    return
end

if result.allowed then
    -- ✅ Authorized → echten Loader starten
    loadstring(game:HttpGet("https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/refs/heads/main/gameshub-loader.lua"))()
else
    -- ❌ Nicht erlaubt → loggen + kicken
    task.wait(1)
    LP:Kick("SorinHub: You are not whitelisted. Your information was logged.")
end
