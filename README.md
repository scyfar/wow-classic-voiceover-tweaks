# VoiceOverTweaks

Small quality-of-life tweaks for the
[VoiceOver (Classic)][vo] addon:
delay an NPC's first line so it doesn't talk over Blizzard's own greeting,
and silence NPCs or individual lines you're tired of hearing.

## Requirements

This addon does nothing on its own — it requires **VoiceOver** to be installed:

- [VoiceOver (Classic) on CurseForge][vo]

## Usage

Everything is controlled through `/vot` and a settings panel.

- `/vot delay <seconds>` – set a delay for your current target
- `/vot delay reset` – remove your target's delay override
- `/vot silence` – silence your current target entirely
- `/vot silence reset` – unsilence your current target
- `/vot options` – open the settings panel

The settings panel also lets you browse, search, and remove all your delay overrides and
silenced NPCs/lines, and manage per-character profiles.

Right-click a line in VoiceOver's own sound queue popup to silence just that line instead
of the whole NPC.

## TBC Anniversary

VoiceOverTweaks also works on **TBC Anniversary**, but you'll need the TBC build of
VoiceOver instead:

- [VoiceOver (TBC & WoTLK)](https://www.curseforge.com/wow/addons/voiceover-tbc-wotlk)

> [!NOTE]
> Since the TBC addon is only an **extension** to the [original addon][vo], the original
> is still required, including the sound pack from the original:
> [VoiceOver Sounds - Vanilla](https://www.curseforge.com/wow/addons/voiceover-sounds-vanilla).
>
> The original addons probably must be manually downloaded and added to the AddOn folder, since
> these are not tagged for TBC and might not get found through mod installers.

## License

VoiceOverTweaks is open source. All code in this repository is licensed under the ISC
([LICENSE](LICENSE) or
[https://opensource.org/license/isc](https://opensource.org/license/isc)).

<!-- link references -->
[vo]: https://www.curseforge.com/wow/addons/voiceover
[vo-tbc]: https://www.curseforge.com/wow/addons/voiceover-tbc-wotlk
