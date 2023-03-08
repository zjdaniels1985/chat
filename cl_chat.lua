local chatInputActive = false
local chatInputActivating = false
local chatHidden = true
local chatLoaded = false
local streamer = false
local currchat = "ooc"
RegisterNetEvent('chatMessage')
RegisterNetEvent('chat:addTemplate')
RegisterNetEvent('chat:addMessage')
RegisterNetEvent('chat:addSuggestion')
RegisterNetEvent('chat:addSuggestions')
RegisterNetEvent('chat:removeSuggestion')
RegisterNetEvent('chat:clear')

-- internal events
RegisterNetEvent('__cfx_internal:serverPrint')

RegisterNetEvent('_chat:messageEntered')
local messagesOOC = {}
local messagesREPORT = {}
local messagesOTHER = {}
RegisterCommand('dump', function()

end)


function dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ',\n'
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

--deprecated, use chat:addMessage
AddEventHandler('chatMessage', function(author, ctype, text)
 
  local args = { text }
  if author ~= "" then
    table.insert(args, 1, author)
  end

  local ctype = ctype ~= false and ctype or "normal"
  -- messages[#messages + 1] = {
  --   template = '<div class="chat-message '..ctype..'"><div class="chat-message-body"><strong>{0}:</strong> {1}</div></div>',
  --   args = {author, text}
  -- }
  if author:sub(1, 3):lower() == "ooc" and streamer == false then 
    messagesOOC[#messagesOOC + 1] = {
      template = '<div class="chat-message '..ctype..'"><div class="chat-message-body"><strong>{0}:</strong> {1}</div></div>',
      args = {author, text}
    }
    UpdateChatState("ooc")
  elseif author:sub(1, 3):lower() == 'rep' then 
    messagesREPORT[#messagesREPORT + 1] = {
      template = '<div class="chat-message '..ctype..'"><div class="chat-message-body"><strong>{0}:</strong> {1}</div></div>',
      args = {author, text}
    }
    TriggerEvent("FRPCore:Notify",'New Report Message')
    UpdateChatState("report")
  elseif streamer == false then
    
    messagesOTHER[#messagesOTHER + 1] = {
      template = '<div class="chat-message '..ctype..'"><div class="chat-message-body"><strong>{0}:</strong> {1}</div></div>',
      args = {author, text}
    }
    UpdateChatState("other")
  end
  if author:sub(1, 3):lower() == 'ooc' and currchat == "ooc" and streamer == false then 
    SendNUIMessage({
      type = 'ON_MESSAGE',
      message = {
        template = '<div class="chat-message '..ctype..'"><div class="chat-message-body"><strong>{0}:</strong> {1}</div></div>',
        args = {author, text}
      }
    })
  elseif author:sub(1, 3):lower() == 'rep' and currchat == "report" then 
      SendNUIMessage({
        type = 'ON_MESSAGE',
        message = {
          template = '<div class="chat-message '..ctype..'"><div class="chat-message-body"><strong>{0}:</strong> {1}</div></div>',
          args = {author, text}
        }
      })
    elseif currchat == "other" then
      SendNUIMessage({
        type = 'ON_MESSAGE',
        message = {
          template = '<div class="chat-message '..ctype..'"><div class="chat-message-body"><strong>{0}:</strong> {1}</div></div>',
          args = {author, text}
        }
      })
  end

 

end)

function UpdateChatState(chattype)
  currchat = chattype
  -- SendNUIMessage({
  --   type = 'Update_Chat_Type',
  --   chatType = chattype
  -- })
end

AddEventHandler('__cfx_internal:serverPrint', function(msg)
  -- messages[#messages + 1] ={
  --   templateId = 'print',
  --   multiline = true,
  --   args = { msg }
  -- }
  if currchat == "other" then
  SendNUIMessage({
    type = 'ON_MESSAGE',
    message = {
      templateId = 'print',
      multiline = true,
      args = { msg }
    }
  })
end
end)

AddEventHandler('chat:addMessage', function(message)
    messagesOTHER[#messagesOTHER + 1]= message
  -- messages[#messages + 1] = message
  if currchat == "other" then
  SendNUIMessage({
    type = 'ON_MESSAGE',
    message = message
  })
end
end)

AddEventHandler('chat:addSuggestion', function(name, help, params)
  local categ_d = ' [ OTHER ]'
  if name == '/report' or name == '/reporttoggle' or name == '/reportr' then categ_d = ' [REPORT]' end
  SendNUIMessage({
    type = 'ON_SUGGESTION_ADD',
    suggestion = {
      name = name,
      help = help..categ_d,
      params = params or nil
    }
  })
end)

AddEventHandler('chat:addSuggestions', function(suggestions)
  for _, suggestion in ipairs(suggestions) do
    SendNUIMessage({
      type = 'ON_SUGGESTION_ADD',
      suggestion = suggestion
    })
  end
end)

AddEventHandler('chat:removeSuggestion', function(name)
  SendNUIMessage({
    type = 'ON_SUGGESTION_REMOVE',
    name = name
  })
end)

RegisterCommand('clear', function()
  SendNUIMessage({
    type = 'ON_CLEAR'
  })
  if currchat == 'ooc' then
    messagesOOC = {}
  elseif currchat == 'report' then 
    messagesREPORT = {}
  elseif currchat == 'other' then 
    messagesOTHER = {}
  end
  -- chatInputActive = true
  -- chatInputActivating = true
  -- SendNUIMessage({
  --   type = 'ON_OPEN'
  -- })
end)

AddEventHandler('chat:addTemplate', function(id, html)
  SendNUIMessage({
    type = 'ON_TEMPLATE_ADD',
    template = {
      id = id,
      html = html
    }
  })
end)

AddEventHandler('chat:clear', function(name)
  ExecuteCommand('clear')
end)

local isLoggedIn = false

RegisterNetEvent('FRPCore:Client:OnPlayerLoaded', function()
  if not isLoggedIn then 
    streamer = GetResourceKvpInt("streamer_familia")
    if streamer == 1 then 
      streamer = true
    else
      streamer = false
    end
  end
  -- isLoggedIn = true
end)

RegisterCommand("streamer", function()
  streamer = GetResourceKvpInt("streamer_familia")
  if streamer == 1 then 
    streamer = false
    TriggerEvent("FRPCore:Notify",'You have disabled streamer mode')
    SetResourceKvpInt('streamer_familia', 0)
  else
    streamer = true
    TriggerEvent("FRPCore:Notify",'You have enabled streamer mode')
    SetResourceKvpInt('streamer_familia', 1)
  end
end)

RegisterNUICallback('chatResult', function(data, cb)
  chatInputActive = false
  SetNuiFocus(false, false)

  if not data.canceled then
    local id = PlayerId()

    --deprecated
    local r, g, b = 0, 0x99, 255

    if data.message:sub(1, 1) == '/' then
      ExecuteCommand(data.message:sub(2))
    else
      print(currchat)
      if currchat ~= "ooc" then 
        ExecuteCommand(currchat.." "..data.message:sub(1))
      end
    end
  end

  cb('ok')
end)

local function refreshCommands()
  if GetRegisteredCommands then
    local registeredCommands = GetRegisteredCommands()

    local suggestions = {}

    for _, command in ipairs(registeredCommands) do
        if IsAceAllowed(('command.%s'):format(command.name)) then
            table.insert(suggestions, {
                name = '/' .. command.name,
                help = ''
            })
        end
    end

    TriggerEvent('chat:addSuggestions', suggestions)
  end
end

local function refreshThemes()
  local themes = {}

  for resIdx = 0, GetNumResources() - 1 do
    local resource = GetResourceByFindIndex(resIdx)

    if GetResourceState(resource) == 'started' then
      local numThemes = GetNumResourceMetadata(resource, 'chat_theme')

      if numThemes > 0 then
        local themeName = GetResourceMetadata(resource, 'chat_theme')
        local themeData = json.decode(GetResourceMetadata(resource, 'chat_theme_extra') or 'null')

        if themeName and themeData then
          themeData.baseUrl = 'nui://' .. resource .. '/'
          themes[themeName] = themeData
        end
      end
    end
  end

  SendNUIMessage({
    type = 'ON_UPDATE_THEMES',
    themes = themes
  })
end

AddEventHandler('onClientResourceStart', function(resName)
  Wait(500)
  refreshCommands()
  refreshThemes()
end)

AddEventHandler('onClientResourceStop', function(resName)
  Wait(500)

  refreshCommands()
  refreshThemes()
end)

RegisterNUICallback('loaded', function(data, cb)
  TriggerServerEvent('chat:init');

  refreshCommands()
  refreshThemes()

  chatLoaded = true

  cb('ok')
end)


RegisterNUICallback('changeChatType', function(data, cb)
  currchat = data.chat
  if currchat == 'ooc' then 
    SendNUIMessage({
      type = 'ON_CLEAR'
    })
    for k, v in pairs(messagesOOC) do 
      SendNUIMessage({
        type = 'ON_MESSAGE',
        message = v
      })
    end
  elseif currchat == 'report' then 
    SendNUIMessage({
      type = 'ON_CLEAR'
    })
    for k, v in pairs(messagesREPORT) do 
      SendNUIMessage({
        type = 'ON_MESSAGE',
        message = v
      })
    end
    elseif currchat == 'other' then 
      SendNUIMessage({
        type = 'ON_CLEAR'
      })
      for k, v in pairs(messagesOTHER) do 
        SendNUIMessage({
          type = 'ON_MESSAGE',
          message = v
        })
      end
  end


  
  

end)


Citizen.CreateThread(function()
  SetTextChatEnabled(false)
  SetNuiFocus(false, false)

  while true do
    Wait(3)

    if not chatInputActive then
      if IsControlPressed(0, 245) --[[ INPUT_MP_TEXT_CHAT_ALL ]] then
        chatInputActive = true
        chatInputActivating = true

        SendNUIMessage({
          type = 'ON_OPEN'
        })
      end
    end

    if chatInputActivating then
      if not IsControlPressed(0, 245) then
        SetNuiFocus(true)

        chatInputActivating = false
      end
    end

    if chatLoaded then
      local shouldBeHidden = false

      if IsScreenFadedOut() or IsPauseMenuActive() then
        shouldBeHidden = true
      end

      if (shouldBeHidden and not chatHidden) or (not shouldBeHidden and chatHidden) then
        chatHidden = shouldBeHidden

        SendNUIMessage({
          type = 'ON_SCREEN_STATE_CHANGE',
          shouldHide = shouldBeHidden
        })
      end
    end
  end
end)