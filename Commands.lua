local TP = TrinketPriority
TP.Commands = {}

local Commands = TP.Commands

function Commands.Register()
  SLASH_TRINKET1 = "/trinket"
  SLASH_TRINKET2 = "/trinkets"

  SlashCmdList["TRINKET"] = function(msg)
    local command, rest = string.match(msg or "", "^(%S*)%s*(.*)$")
    command = string.lower(command or "")
    rest = string.lower(rest or "")

    if command == "" or command == "go" then
      TP.Priority.Request()
    elseif command == "profile" then
      if rest == "" then
        TP.Print("Perfil activo: " .. TP.GetActiveProfileName())
        TP.Print("Uso: /trinket profile 1|2|3")
      elseif TP.Profiles then
        TP.Profiles.Switch(rest)
      end
    elseif command == "adduse" then
      local slot = tonumber(rest)
      if slot ~= 13 and slot ~= 14 then
        TP.Print("Uso: /trinket adduse 13|14")
      else
        TP.Config.AddUseFromSlot(slot)
      end
    elseif command == "passive" then
      local slot = tonumber(rest)
      if slot ~= 13 and slot ~= 14 then
        TP.Print("Uso: /trinket passive 13|14")
      else
        TP.Config.SetPassiveFromSlot(slot)
      end
    elseif command == "removeuse" then
      TP.Config.RemoveUse(tonumber(rest))
    elseif command == "removepassive" then
      TP.Config.RemovePassive()
    elseif command == "up" then
      TP.Config.MoveUse(tonumber(rest), -1)
    elseif command == "down" then
      TP.Config.MoveUse(tonumber(rest), 1)
    elseif command == "clear" then
      TP.Config.Clear()
    elseif command == "list" or command == "status" then
      TP.Config.List()
    elseif command == "options" or command == "ui" then
      TP.UI.Toggle()
    elseif command == "overlay" then
      if TP.Overlay and TP.Overlay.Toggle then
        TP.Overlay.Toggle()
      end
    elseif command == "help" then
      TP.Print("/trinket - ejecuta priority")
      TP.Print("/trinket profile 1|2|3 - cambia perfil")
      TP.Print("/trinket adduse 13|14 - añade equipado")
      TP.Print("/trinket passive 13|14 - establece pasivo")
      TP.Print("/trinket removeuse N - elimina prioridad N")
      TP.Print("/trinket removepassive - elimina pasivo")
      TP.Print("/trinket up|down N - mueve una prioridad")
      TP.Print("/trinket list - muestra perfil y listas")
      TP.Print("/trinket overlay - bloquea/desbloquea el movimiento del overlay")
    else
      TP.UI.Toggle()
    end
  end
end
