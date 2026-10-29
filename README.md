# NX-Tuning

A customizable vehicle tuning and modification script for FiveM running on the **ESX** framework.

Created by **Next-Solutions** • [Join our Discord](https://discord.gg/mB45RPuFdE)

---

## 🌟 Features

- **Comprehensive Vehicle Customization**:
  - Full body modifications (bumpers, skirts, spoilers, exhausts, hoods, grills, etc.)
  - Performance upgrades (engine, brakes, transmission, suspension, turbo)
  - Custom paints, pearlescent, wheel colours, dashboard & interior colors
  - Neon lights & Xenon headlights with custom RGB color palette
  - Window tints, custom license plates, horns, wheel types & tires
- **Job & Mechanic Integration**:
  - Configurable tuning spots (`Config.Zones`) with optional job lock (e.g. mechanic only)
  - Configurable price discounts for mechanics (`Config.JobPrice`)
  - Emergency vehicle support (police/ambulance zones)
- **Admin Tuning Mode**:
  - `/tuning` command for admins with instant free upgrades and custom test functionality
- **Configurable Notification System**:
  - Toggle notifications on or off (`Config.Notify = true/false`)
  - Switch between notify systems: `nx_notify` or native `esx`
- **Database Saving**:
  - Vehicle mods persist automatically using `oxmysql` and `owned_vehicles`
- **Multi-language Support**:
  - Localization files included (`de`, `en`)

---

## 📋 Requirements

- [es_extended](https://github.com/esx-framework/esx_core)
- [oxmysql](https://github.com/overextended/oxmysql)
- Optional: `nx_notify` / `nx_helpnotify`

---

## 🚀 Installation

1. Download or clone this repository:
   ```bash
   git clone https://github.com/Next-Solut/NX-Tuning.git
   ```
2. Place the folder into your FiveM server's resources directory:
   ```
   resources/[custom]/nx_tuning
   ```
3. Add the resource to your `server.cfg`:
   ```cfg
   ensure nx_tuning
   ```
4. Configure [config.lua] to suit your server's needs.

---

## ⚙️ Configuration

In `config.lua` you can customize:

```lua
Config.DrawDistance                 = 10.0
Config.Locale                       = GetConvar('esx:locale', 'de')
Config.IsMechanicJobOnly            = false
Config.DefaultWheelsPriceMultiplier = 2
Config.Performancetuning            = true
Config.JobPrice                     = 2    -- Divides price by 2 for mechanics
Config.SpawnServerside              = true

-- Notification Settings
Config.Notify                       = false -- Enable or disable notifications (true/false)
Config.NotifyType                   = 'esx' -- Notification system: 'nx_notify' or 'esx'
```

---

Created by **Next-Solutions** • Powered by Saf-Solutions

## 💬 Support & Community

Need help or want more scripts? Join the Next-Solutions Discord:
👉 **[https://discord.gg/mB45RPuFdE](https://discord.gg/mB45RPuFdE)**
