local Vehicles, myCar = {}, {}
local lsMenuIsShowed, HintDisplayed, isInLSMarker = false, false, false
local adminmenu = false
local isAdmin
local isJob = false
local isEmergency = false

local function ShowNotification(msg, notifyType)
    if not Config.Notify then return end

    local nType = notifyType or 'info'
    if Config.NotifyType == 'nx_notify' then
        if GetResourceState('nx_notify') == 'started' then
            exports['nx_notify']:Notify(msg, nType)
        else
            ESX.ShowNotification(msg)
        end
    else
        ESX.ShowNotification(msg)
    end
end

RegisterNetEvent('nx_tuning:showNotification')
AddEventHandler('nx_tuning:showNotification', function(msg, notifyType)
    ShowNotification(msg, notifyType)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerLoaded = true
    ESX.PlayerData = xPlayer
    TriggerEvent('nx_tuning:checkadmin')
end)

RegisterNetEvent('nx_tuning:checkadmin')
AddEventHandler('nx_tuning:checkadmin', function()
    if isAdmin == nil then
        ESX.TriggerServerCallback('nx_tuning:isAdmin', function(value) isAdmin = value end)
    end

    if next(Vehicles) == nil then
        ESX.TriggerServerCallback('nx_tuning:getVehiclesPrices', function(vehicles)
            Vehicles = vehicles
        end)
    end
end)

RegisterCommand("tuning", function()
    local playerPed = PlayerPedId()

    local function openTuning()
        if IsPedInAnyVehicle(playerPed, false) then
            if not lsMenuIsShowed then
                lsMenuIsShowed = true
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                FreezeEntityPosition(vehicle, true)
                myCar = ESX.Game.GetVehicleProperties(vehicle)

                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                TriggerServerEvent('nx_tuning:startModing', myCar, netId)

                ESX.UI.Menu.CloseAll()
                adminmenu = true
                GetAction({ value = 'main' })

                CreateThread(function()
                    while lsMenuIsShowed do
                        Wait(0)
                        DisableControlAction(2, 288, true)
                        DisableControlAction(2, 289, true)
                        DisableControlAction(2, 170, true)
                        DisableControlAction(2, 167, true)
                        DisableControlAction(2, 168, true)
                        DisableControlAction(2, 23, true)
                        DisableControlAction(0, 75, true)  -- Disable exit vehicle
                        DisableControlAction(27, 75, true) -- Disable exit vehicle
                    end
                    adminmenu = false
                end)
            end
        else
            ShowNotification("Du musst in einem ~r~Fahrzeug~s~ sitzen!", 'error')
        end
    end

    -- Admin Check beim Ausführen des Befehls
    if isAdmin == nil then
        print("[nx_tuning] Admin-Status unbekannt, frage Server ab...")
        ESX.TriggerServerCallback('nx_tuning:isAdmin', function(value)
            isAdmin = value
            if isAdmin then
                openTuning()
            else
                ShowNotification("~r~Keine Berechtigung:~s~ Du bist kein Admin.", 'error')
            end
        end)
    elseif isAdmin then
        openTuning()
    else
        ShowNotification("~r~Keine Berechtigung!", 'error')
    end
end, false)

RegisterNetEvent('nx_tuning:installMod')
AddEventHandler('nx_tuning:installMod', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local NetId = NetworkGetNetworkIdFromEntity(vehicle)
    myCar = ESX.Game.GetVehicleProperties(vehicle)

    local color1Type, color1Color = GetVehicleModColor_1(vehicle)
    local color2Type, color2Color = GetVehicleModColor_2(vehicle)
    myCar.color1Type = color1Type
    myCar.color2Type = color2Type

    TriggerServerEvent('nx_tuning:refreshOwnedVehicle', myCar, NetId)
end)

RegisterNetEvent('nx_tuning:restoreMods', function(netId, props)
    local xVehicle = NetworkGetEntityFromNetworkId(netId)
    if props ~= nil then
        if DoesEntityExist(xVehicle) then
            ESX.Game.SetVehicleProperties(xVehicle, props)

            if props.color1Type then
                SetVehicleModColor_1(xVehicle, props.color1Type, props.color1, 0)
            end
            if props.color2Type then
                SetVehicleModColor_2(xVehicle, props.color2Type, props.color2)
            end
        end
    end
end)

RegisterNetEvent('nx_tuning:cancelInstallMod')
AddEventHandler('nx_tuning:cancelInstallMod', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if (GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId()) then
        vehicle = GetPlayersLastVehicle(PlayerPedId())
    end
    ESX.Game.SetVehicleProperties(vehicle, myCar)

    -- Manually restore paint types if present
    if myCar.color1Type then
        SetVehicleModColor_1(vehicle, myCar.color1Type, myCar.color1, 0)
    end
    if myCar.color2Type then
        SetVehicleModColor_2(vehicle, myCar.color2Type, myCar.color2)
    end

    if not (myCar.modTurbo) then
        ToggleVehicleMod(vehicle, 18, false)
    end
    if not (myCar.modXenon) then
        ToggleVehicleMod(vehicle, 22, false)
    end
    if not (myCar.windowTint) then
        SetVehicleWindowTint(vehicle, 0)
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if lsMenuIsShowed then
            TriggerEvent('nx_tuning:cancelInstallMod')
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if lsMenuIsShowed then
            TriggerEvent('nx_tuning:cancelInstallMod')
        end
    end
end)

function OpenLSMenu(elems, menuName, menuTitle, parent)
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), menuName, {
        css = 'boost',
        title = menuTitle,
        align = 'top-left',
        elements = elems
    }, function(data, menu)
        local isRimMod, found = false, false
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

        if data.current.modType == "modFrontWheels" then
            isRimMod = true
        end

        if adminmenu then
            getcofing = Config.Adminmenus
        else
            getcofing = Config.Menus
        end

        for k, v in pairs(getcofing) do
            if k == data.current.modType or isRimMod then
                if data.current.label == TranslateCap('by_default') or string.match(data.current.label, TranslateCap('installed')) then
                    ShowNotification(TranslateCap('already_own', data.current.label), 'info')

                    local NetId = NetworkGetNetworkIdFromEntity(vehicle)
                    myCar = ESX.Game.GetVehicleProperties(vehicle)
                    TriggerServerEvent('nx_tuning:refreshOwnedVehicle', myCar, NetId)
                else
                    local vehiclePrice = 50000


                    if isJob then
                        for i = 1, #Vehicles, 1 do
                            if GetEntityModel(vehicle) == joaat(Vehicles[i].model) then
                                mechanicprice = Vehicles[i].price
                                vehiclePrice = math.floor(mechanicprice / Config.JobPrice)
                                break
                            end
                        end
                    else
                        for i = 1, #Vehicles, 1 do
                            if GetEntityModel(vehicle) == joaat(Vehicles[i].model) then
                                vehiclePrice = Vehicles[i].price
                                break
                            end
                        end
                    end

                    if adminmenu then
                        vehiclePrice = 0.0
                    end

                    if isRimMod then
                        price = math.floor(vehiclePrice * data.current.price / 100)
                        TriggerServerEvent('nx_tuning:buyMod', price, isJob)
                    elseif v.modType == 11 or v.modType == 12 or v.modType == 13 or v.modType == 15 or v.modType == 16 then
                        local multiplier = 0
                        if type(v.price) == 'table' and v.price[data.current.modNum + 1] then
                            multiplier = v.price[data.current.modNum + 1]
                        elseif type(v.price) == 'number' then
                            multiplier = v.price
                        else
                            multiplier = 0
                            print("[NX_TUNING] KRITISCH: Kein Kaufpreis für ModType " ..
                                tostring(v.modType) .. " Index " .. tostring(data.current.modNum + 1))
                        end

                        price = math.floor(vehiclePrice * multiplier / 100)
                        TriggerServerEvent('nx_tuning:buyMod', price, isJob)
                    elseif v.modType == 17 then
                        price = math.floor(vehiclePrice * v.price[1] / 100)
                        TriggerServerEvent('nx_tuning:buyMod', price, isJob)
                    else
                        price = math.floor(vehiclePrice * v.price / 100)
                        TriggerServerEvent('nx_tuning:buyMod', price, isJob)
                    end
                end

                menu.close()
                found = true
                break
            end
        end

        if not found then
            GetAction(data.current)
        end
    end, function(data, menu)
        menu.close()
        TriggerEvent('nx_tuning:cancelInstallMod')

        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        SetVehicleDoorsShut(vehicle, false)

        if parent == nil then
            lsMenuIsShowed = false
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            FreezeEntityPosition(vehicle, false)
            TriggerServerEvent('nx_tuning:stopModing', myCar.plate)
            myCar = {}
        end
    end, function(data, menu)
        UpdateMods(data.current)
    end)
end

function UpdateMods(data)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if data.modType then
        local props = {}

        if data.wheelType then
            props['wheels'] = data.wheelType

            if GetVehicleClass(vehicle) == 8 then
                props['modBackWheels'] = data.modNum
            end

            ESX.Game.SetVehicleProperties(vehicle, props)
            props = {}
        elseif data.modType == 'neonColor' then
            if data.modNum[1] == 0 and data.modNum[2] == 0 and data.modNum[3] == 0 then
                props['neonEnabled'] = { false, false, false, false }
            else
                props['neonEnabled'] = { true, true, true, true }
            end
            ESX.Game.SetVehicleProperties(vehicle, props)
            props = {}
        elseif data.modType == 'tyreSmokeColor' then
            props['modSmokeEnabled'] = true
            ESX.Game.SetVehicleProperties(vehicle, props)
            props = {}
        elseif data.modType == 'xenonColor' then
            if data.modNum then
                props['modXenon'] = true
            else
                props['modXenon'] = false
            end
            ESX.Game.SetVehicleProperties(vehicle, props)
            props = {}
        elseif data.modType == 'interiorColor' then
            props['interiorColor'] = data.modNum
            ESX.Game.SetVehicleProperties(vehicle, props)
            props = {}
        elseif data.modType == 'dashboardColor' then
            props['dashboardColor'] = data.modNum
            ESX.Game.SetVehicleProperties(vehicle, props)
            props = {}
        end

        local isChameleon = (data.modNum ~= nil and type(data.modNum) == 'number' and ((data.modNum >= 161 and data.modNum <= 176) or (data.modNum >= 223 and data.modNum <= 242)))

        if isChameleon then
            if data.modType == 'color1' then
                SetVehicleModColor_1(vehicle, 12, data.modNum, 0)
            elseif data.modType == 'color2' then
                SetVehicleModColor_2(vehicle, 12, data.modNum)
            elseif data.modType == 'pearlescentColor' then
                local _, pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
                SetVehicleExtraColours(vehicle, data.modNum, wheelColor)
            end
        else
            props[data.modType] = data.modNum
            ESX.Game.SetVehicleProperties(vehicle, props)
        end
    end
end

function GetAction(data)
    local elements = {}
    local menuName = ''
    local menuTitle = ''
    local parent = nil

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local currentMods = ESX.Game.GetVehicleProperties(vehicle)
    if data.value == 'modSpeakers' or data.value == 'modTrunk' or data.value == 'modHydrolic' or data.value ==
        'modEngineBlock' or data.value == 'modAirFilter' or data.value == 'modStruts' or data.value == 'modTank' then
        SetVehicleDoorOpen(vehicle, 4, false)
        SetVehicleDoorOpen(vehicle, 5, false)
    elseif data.value == 'modDoorSpeaker' then
        SetVehicleDoorOpen(vehicle, 0, false)
        SetVehicleDoorOpen(vehicle, 1, false)
        SetVehicleDoorOpen(vehicle, 2, false)
        SetVehicleDoorOpen(vehicle, 3, false)
    else
        SetVehicleDoorsShut(vehicle, false)
    end

    local vehiclePrice = 50000


    if isJob then
        for i = 1, #Vehicles, 1 do
            if GetEntityModel(vehicle) == joaat(Vehicles[i].model) then
                mechanicprice = Vehicles[i].price
                vehiclePrice = math.floor(mechanicprice / Config.JobPrice)
                break
            end
        end
    else
        for i = 1, #Vehicles, 1 do
            if GetEntityModel(vehicle) == joaat(Vehicles[i].model) then
                vehiclePrice = Vehicles[i].price
                break
            end
        end
    end

    if adminmenu then
        getcofing = Config.Adminmenus
        vehiclePrice = 0.0
    else
        getcofing = Config.Menus
    end

    for k, v in pairs(getcofing) do
        if data.value == k then
            menuName = k
            menuTitle = v.label
            parent = v.parent

            if v.modType then
                if v.modType == 22 or v.modType == 'xenonColor' then
                    table.insert(elements, {
                        label = " " .. TranslateCap('by_default'),
                        modType = k,
                        modNum = false
                    })
                elseif v.modType == 'neonColor' or v.modType == 'tyreSmokeColor' then
                    table.insert(elements, {
                        label = " " .. TranslateCap('by_default'),
                        modType = k,
                        modNum = { 0, 0, 0 }
                    })
                elseif v.modType == 'color1' or v.modType == 'color2' or v.modType == 'pearlescentColor' or v.modType == 'wheelColor' or v.modType == 'interiorColor' or v.modType == 'dashboardColor' then
                    local num = myCar[v.modType]
                    table.insert(elements, {
                        label = " " .. TranslateCap('by_default'),
                        modType = k,
                        modNum = num
                    })
                elseif v.modType == 17 then
                    table.insert(elements, {
                        label = " " .. TranslateCap('no_turbo'),
                        modType = k,
                        modNum = false
                    })
                elseif v.modType == 23 then
                    table.insert(elements, {
                        label = " " .. TranslateCap('by_default'),
                        modType = "modFrontWheels",
                        modNum = -1,
                        wheelType = -1,
                        price = Config.DefaultWheelsPriceMultiplier
                    })
                else
                    table.insert(elements, {
                        label = " " .. TranslateCap('by_default'),
                        modType = k,
                        modNum = -1
                    })
                end

                if v.modType == 14 then -- HORNS
                    for j = 0, 51, 1 do
                        local _label = ''
                        if j == currentMods.modHorns then
                            _label = GetHornName(j) ..
                                ' - <span style="color:cornflowerblue;">' .. TranslateCap('installed') ..
                                '</span>'
                        else
                            price = math.floor(vehiclePrice * v.price / 100)
                            _label = GetHornName(j) .. ' - <span style="color:green;">$' .. price .. ' </span>'
                        end
                        table.insert(elements, {
                            label = _label,
                            modType = k,
                            modNum = j
                        })
                    end
                elseif v.modType == 'plateIndex' then -- PLATES
                    for j = 0, 12, 1 do
                        if (j == 2 and not adminmenu and not isEmergency) or (j == 5 and not adminmenu) then
                            -- skip restricted plates
                        else
                            local _label = ''
                            if j == currentMods.plateIndex then
                                _label = GetPlatesName(j) ..
                                    ' - <span style="color:cornflowerblue;">' .. TranslateCap('installed') ..
                                    '</span>'
                            else
                                price = math.floor(vehiclePrice * v.price / 100)
                                _label = GetPlatesName(j) .. ' - <span style="color:green;">$' .. price .. ' </span>'
                            end
                            table.insert(elements, {
                                label = _label,
                                modType = k,
                                modNum = j
                            })
                        end
                    end
                elseif v.modType == 22 then -- NEON
                    local _label = ''
                    if currentMods.modXenon then
                        _label = TranslateCap('neon') ..
                            ' - <span style="color:cornflowerblue;">' .. TranslateCap('installed') .. '</span>'
                    else
                        price = math.floor(vehiclePrice * v.price / 100)
                        _label = TranslateCap('neon') .. ' - <span style="color:green;">$' .. price .. ' </span>'
                    end
                    table.insert(elements, {
                        label = _label,
                        modType = k,
                        modNum = true
                    })
                elseif v.modType == 'xenonColor' then -- XENON COLOR
                    local xenonColors = GetXenonColors()
                    price = math.floor(vehiclePrice * v.price / 100)
                    for i = 1, #xenonColors, 1 do
                        table.insert(elements, {
                            label = xenonColors[i].label .. ' - <span style="color:green;">$' .. price .. '</span>',
                            modType = k,
                            modNum = xenonColors[i].index
                        })
                    end
                elseif v.modType == 'neonColor' or v.modType == 'tyreSmokeColor' then -- NEON & SMOKE COLOR
                    local neons = GetNeons()
                    price = math.floor(vehiclePrice * v.price / 100)
                    for i = 1, #neons, 1 do
                        table.insert(elements, {
                            label = '<span style="color:rgb(' .. neons[i].r .. ',' .. neons[i].g .. ',' .. neons[i].b ..
                                ');">' .. neons[i].label .. ' - <span style="color:green;">$' .. price .. '</span>',
                            modType = k,
                            modNum = { neons[i].r, neons[i].g, neons[i].b }
                        })
                    end
                elseif v.modType == 'color1' or v.modType == 'color2' or v.modType == 'pearlescentColor' or v.modType == 'wheelColor' or v.modType == 'interiorColor' or v.modType == 'dashboardColor' then -- RESPRAYS
                    local colors = GetColors(data.color)
                    for j = 1, #colors, 1 do
                        local _label = ''
                        price = math.floor(vehiclePrice * v.price / 100)
                        _label = colors[j].label .. ' - <span style="color:green;">$' .. price .. ' </span>'
                        table.insert(elements, {
                            label = _label,
                            modType = k,
                            modNum = colors[j].index
                        })
                    end
                elseif v.modType == 'windowTint' then -- WINDOWS TINT
                    for j = 1, 5, 1 do
                        local _label = ''
                        if j == currentMods.modHorns then
                            _label = GetWindowName(j) ..
                                ' - <span style="color:cornflowerblue;">' .. TranslateCap('installed') ..
                                '</span>'
                        else
                            price = math.floor(vehiclePrice * v.price / 100)
                            _label = GetWindowName(j) .. ' - <span style="color:green;">$' .. price .. ' </span>'
                        end
                        table.insert(elements, {
                            label = _label,
                            modType = k,
                            modNum = j
                        })
                    end
                elseif v.modType == 23 then -- WHEELS RIM & TYPE
                    local props = {}

                    props['wheels'] = v.wheelType
                    ESX.Game.SetVehicleProperties(vehicle, props)

                    local modCount = GetNumVehicleMods(vehicle, v.modType)
                    for j = 0, modCount, 1 do
                        local modName = GetModTextLabel(vehicle, v.modType, j)
                        if modName then
                            local _label = ''
                            if j == currentMods.modFrontWheels then
                                _label = GetLabelText(modName) .. ' - <span style="color:cornflowerblue;">' ..
                                    TranslateCap('installed') .. '</span>'
                            else
                                price = math.floor(vehiclePrice * v.price / 100)
                                _label = GetLabelText(modName) .. ' - <span style="color:green;">$' .. price ..
                                    ' </span>'
                            end
                            table.insert(elements, {
                                label = _label,
                                modType = 'modFrontWheels',
                                modNum = j,
                                wheelType = v.wheelType,
                                price = v.price
                            })
                        end
                    end
                elseif v.modType == 11 or v.modType == 12 or v.modType == 13 or v.modType == 15 or v.modType == 16 then
                    SetVehicleModKit(vehicle, 0)
                    local modCount = GetNumVehicleMods(vehicle, v.modType)

                    for j = 0, modCount - 1, 1 do
                        local _label = ''
                        if j == currentMods[k] then
                            _label = TranslateCap('level', j + 1) ..
                                ' - <span style="color:cornflowerblue;">' .. TranslateCap('installed') .. '</span>'
                        else
                            local priceMultiplier = 0
                            if type(v.price) == 'table' and v.price[j + 1] then
                                priceMultiplier = v.price[j + 1]
                            elseif type(v.price) == 'number' then
                                priceMultiplier = v.price
                            else
                                priceMultiplier = 0
                                print("[NX_TUNING] Warnung: Kein Preis für ModType " ..
                                    tostring(v.modType) .. " Level " .. j + 1 .. " in der Config gefunden!")
                            end

                            price = math.floor(vehiclePrice * priceMultiplier / 100)
                            _label = TranslateCap('level', j + 1) ..
                                ' - <span style="color:green;">$' .. price .. ' </span>'
                        end

                        table.insert(elements, {
                            label = _label,
                            modType = k,
                            modNum = j
                        })

                        if j == modCount - 1 then
                            break
                        end
                    end
                elseif v.modType == 17 then -- TURBO
                    local _label = ''
                    if currentMods[k] then
                        _label = 'Turbo - <span style="color:cornflowerblue;">' .. TranslateCap('installed') .. '</span>'
                    else
                        _label =
                            'Turbo - <span style="color:green;">$' .. math.floor(vehiclePrice * v.price[1] / 100) ..
                            ' </span>'
                    end
                    table.insert(elements, {
                        label = _label,
                        modType = k,
                        modNum = true
                    })
                else
                    local modCount = GetNumVehicleMods(vehicle, v.modType) -- BODYPARTS
                    for j = 0, modCount, 1 do
                        local modName = GetModTextLabel(vehicle, v.modType, j)
                        if modName then
                            local _label = ''
                            if j == currentMods[k] then
                                _label = GetLabelText(modName) .. ' - <span style="color:cornflowerblue;">' ..
                                    TranslateCap('installed') .. '</span>'
                            else
                                price = math.floor(vehiclePrice * v.price / 100)
                                _label = GetLabelText(modName) .. ' - <span style="color:green;">$' .. price ..
                                    ' </span>'
                            end
                            table.insert(elements, {
                                label = _label,
                                modType = k,
                                modNum = j
                            })
                        end
                    end
                end
            else
                if data.value == 'primaryRespray' or data.value == 'secondaryRespray' or data.value == 'pearlescentRespray' or data.value == 'modFrontWheelsColor' or data.value == 'interiorRespray' or data.value == 'dashboardRespray' then
                    for i = 1, #Config.Colors, 1 do
                        if data.value == 'primaryRespray' then
                            table.insert(elements, {
                                label = Config.Colors[i].label,
                                value = 'color1',
                                color = Config.Colors[i].value
                            })
                        elseif data.value == 'secondaryRespray' then
                            table.insert(elements, {
                                label = Config.Colors[i].label,
                                value = 'color2',
                                color = Config.Colors[i].value
                            })
                        elseif data.value == 'pearlescentRespray' then
                            table.insert(elements, {
                                label = Config.Colors[i].label,
                                value = 'pearlescentColor',
                                color = Config.Colors[i].value
                            })
                        elseif data.value == 'modFrontWheelsColor' then
                            table.insert(elements, {
                                label = Config.Colors[i].label,
                                value = 'wheelColor',
                                color = Config.Colors[i].value
                            })
                        elseif data.value == 'interiorRespray' then
                            table.insert(elements, {
                                label = Config.Colors[i].label,
                                value = 'interiorColor',
                                color = Config.Colors[i].value
                            })
                        elseif data.value == 'dashboardRespray' then
                            table.insert(elements, {
                                label = Config.Colors[i].label,
                                value = 'dashboardColor',
                                color = Config.Colors[i].value
                            })
                        end
                    end
                else
                    for l, w in pairs(v) do
                        if l ~= 'label' and l ~= 'parent' then
                            table.insert(elements, {
                                label = w,
                                value = l
                            })
                        end
                    end
                end
            end
            break
        end
    end

    table.sort(elements, function(a, b)
        return a.label < b.label
    end)

    OpenLSMenu(elements, menuName, menuTitle, parent)
end

CreateThread(function()
    for k, v in pairs(Config.Zones) do
        if v.job == false then
            local blip = AddBlipForCoord(v.Pos.x, v.Pos.y, v.Pos.z)

            SetBlipSprite(blip, 72)
            SetBlipScale(blip, 0.6)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(v.Name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    while true do
        local Sleep = 1500
        local Near = false
        local playerPed = PlayerPedId()

        if IsPedInAnyVehicle(playerPed, false) then
            local coords = GetEntityCoords(playerPed)
            local currentZone, zone, lastZone

            for k, v in pairs(Config.Zones) do
                local zonePos = vector3(v.Pos.x, v.Pos.y, v.Pos.z)
                if #(coords - zonePos) < 10.0 then
                    Near = true
                    Sleep = 0
                    if not lsMenuIsShowed then
                        exports['nx_helpnotify']:showHelpNotification(v.Hint)
                        if IsControlJustReleased(0, 38) then
                            local vehicle = GetVehiclePedIsIn(playerPed, false)
                            if GetVehicleBodyHealth(vehicle) > 980 then
                                if v.emergency == true and ESX.PlayerData.job and (ESX.PlayerData.job.name == 'police' or ESX.PlayerData.job.name == 'ambulance') then
                                    isJob = false
                                    isEmergency = true
                                    lsMenuIsShowed = true
                                    FreezeEntityPosition(vehicle, true)
                                    myCar = ESX.Game.GetVehicleProperties(vehicle)

                                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                    TriggerServerEvent('nx_tuning:startModing', myCar, netId)

                                    ESX.UI.Menu.CloseAll()
                                    GetAction({
                                        value = 'main'
                                    })
                                elseif v.job == false and not v.emergency then
                                    isJob = false
                                    isEmergency = false
                                    lsMenuIsShowed = true
                                    FreezeEntityPosition(vehicle, true)
                                    myCar = ESX.Game.GetVehicleProperties(vehicle)

                                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                    TriggerServerEvent('nx_tuning:startModing', myCar, netId)

                                    ESX.UI.Menu.CloseAll()
                                    GetAction({
                                        value = 'main'
                                    })
                                elseif (v.job == true and not v.emergency and ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic') or (v.job == true and not v.emergency and ESX.PlayerData.job and ESX.PlayerData.job.name == 'cardealer') then
                                    isJob = true
                                    isEmergency = false
                                    lsMenuIsShowed = true

                                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                                    FreezeEntityPosition(vehicle, true)
                                    myCar = ESX.Game.GetVehicleProperties(vehicle)

                                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                    TriggerServerEvent('nx_tuning:startModing', myCar, netId)

                                    ESX.UI.Menu.CloseAll()
                                    GetAction({
                                        value = 'main'
                                    })
                                else
                                    ShowNotification('Du bist hier ~r~nicht~s~ angestellt!', 'error')
                                end
                                CreateThread(function()
                                    while true do
                                        local Sleep = 1000
                                        if lsMenuIsShowed then
                                            Sleep = 0
                                            DisableControlAction(2, 288, true)
                                            DisableControlAction(2, 289, true)
                                            DisableControlAction(2, 170, true)
                                            DisableControlAction(2, 167, true)
                                            DisableControlAction(2, 168, true)
                                            DisableControlAction(2, 23, true)
                                            DisableControlAction(0, 75, true)  -- Disable exit vehicle
                                            DisableControlAction(27, 75, true) -- Disable exit vehicle
                                        end
                                        Wait(Sleep)
                                    end
                                end)
                            else
                                ShowNotification('Dein Fahrzeug darf nicht beschädigt sein!', 'error')
                            end
                        end
                    end
                end
            end
            if not Near and HintDisplayed then
                HintDisplayed = false
                ESX.HideUI()
            end
        end
        Wait(Sleep)
    end
end)
