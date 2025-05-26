# CellAdditions

**CellAdditions** is a modular addon for World of Warcraft, designed to extend the functionality of the [Cell](https://www.curseforge.com/wow/addons/cell) unit frame addon. It offers additional features such as clickable overlays and visual shadow effects that are fully configurable and easy to expand.

## 🔧 Features

- **Clicker Module**: Creates clickable overlays on unit frames with freely definable actions.
- **Shadow Module**: Adds dynamic shadow effects for better visual feedback.
- **Modular Architecture**: Easily extendable with additional modules.
- **Smooth Cell Integration**: Built to work seamlessly with the Cell addon.

## 📦 Installation

### Manual

1. Download this repository or extract the ZIP archive.
2. Move the `CellAdditions` folder to:   World of Warcraft/retail/Interface/AddOns/
3. Make sure the folder contains the `CellAdditions.toc` file.

### Addon Manager

If you're using an addon manager like CurseForge or WowUp, you currently need to install this addon manually, as it is not yet published.

## ⚙️ Dependencies

- [Cell](https://www.curseforge.com/wow/addons/cell) – must be installed and enabled.

## 🧪 Usage

After launching the game, CellAdditions will automatically load when Cell is active. The modules are built to integrate themselves into the Cell environment. Additional configuration options can be found directly in the code or extended via custom modules.

## 📁 File Structure
CellAdditions/<br/>
├── CellAdditions.toc<br/>
├── Core.lua<br/>
├── API/<br/>
│ └── FrameState.lua<br/>
├── Modules/<br/>
│ ├── Clicker.lua<br/>
│ └── Shadow.lua<br/>
├── Locales<br/>
│ ├── LoadLocales.xml<br/>
│ ├── deDE.lua<br/>
│ ├── enUS.lua<br/>
│ ├── esES.lua<br/>
│ ├── frFR.lua<br/>
│ ├── itIT.lua<br/>
│ ├── koKR.lua<br/>
│ ├── ptBR.lua<br/>
│ ├── ruRU.lua<br/>
│ ├── zhCN.lua<br/>
│ └── zhTW.lua<br/>
└── Media/<br/>
&ensp;&ensp;├── Textures<br/>
&ensp;&ensp;│ ├── TextureList.lua<br/>
&ensp;&ensp;│ └── healthbar1.tga<br/>
‎&ensp;&ensp;├── glowTex.tga<br/>
‎&ensp;&ensp;└── icon.tga

## 📸 Screenshots

SOON™

## 📜 License

This project is licensed under the MIT License. See the `LICENSE` file for details, if available.

---

**Note:** This addon is intended for developers and power users who want to extend Cell. For questions or contributions, feel free to open an issue or pull request.
