# Codex Cloud Handoff — N100 ImmortalWrt 25.12 + Nikki + Unraid

## Goal

Continue the N100 ImmortalWrt VM project in Codex cloud.

## Repository

- Repo: `gbosek/ImmortalWrt-ImageBuilder`
- Branch: `master`
- Custom workflow: `.github/workflows/build-N100-25.12.x.yml`
- Custom build script: `x86-64/build-n100-25.sh`

## Build status

The first N100 build completed successfully.

- Workflow: `Build N100 ImmortalWrt 25.12.x`
- Run: #1
- ImmortalWrt: 25.12.2
- RootFS: 1 GB
- Release tag: `N100-ImmortalWrt-25.12`
- Artifact: `immortalwrt-25.12.2-x86-64-generic-squashfs-combined-efi.img.gz`
- SHA256: `66d568bea5f98719ba78819b9156d690bb1c419f77b215b33f5300d2836ad91d`

## VM target

- Host: Unraid on Intel N100
- Create a new VM; keep the old ImmortalWrt VM untouched for rollback
- RAM: 1 GB
- vCPU: 2
- Firmware: OVMF / UEFI
- NIC: VirtIO
- Network bridge: br0
- N100 ImmortalWrt management IP: `192.168.10.2`
- Main router/gateway/DNS: `192.168.10.1`
- Unraid host: `192.168.10.99`
- Unraid currently uses `192.168.10.2` as its default gateway
- DHCP / DHCPv6 / RA on the N100 bypass router must remain disabled

## Included features

- Full Chinese LuCI
- package manager
- ttyd
- disk/file management
- scheduled reboot
- Nikki + Mihomo
- OpenClash kernel prerequisites only; OpenClash itself is not preinstalled
- `kmod-tun`
- `kmod-inet-diag`
- `kmod-nft-tproxy`
- `kmod-nft-socket`
- `luci-compat`
- `kmod-igc`
- no Docker
- no Cloudflared
- no PPPoE

## Nikki / Mihomo routing design

Use `gogyt/Mihomo/yaml/Rule.yaml` as a base, but do not use it unchanged.

Desired behavior:

- Private/LAN -> DIRECT
- China domains/IP -> DIRECT
- 115 cloud / 115 CDN / 115-related media traffic -> DIRECT
- AI (OpenAI/ChatGPT, Gemini, Claude, Copilot, Grok, etc.) -> dedicated AI group, default US
- Docker Hub / GHCR / lscr / quay and Unraid app/update dependencies -> dedicated Docker/Unraid proxy group
- TMDB / Fanart and similar metadata services -> dedicated media-metadata proxy group
- GitHub / raw.githubusercontent / api.github / codeload -> dedicated GitHub proxy group
- YouTube / Google / Telegram / streaming can have separate groups
- GFW -> proxy
- geolocation-!cn -> preferably DIRECT by default, with manual override
- avoid sending 115 media traffic through proxy
- avoid duplicate transparent-routing control between Nikki and a full standalone TUN config

The user's media stack includes Emby + 115 cloud 302 redirect style playback, plus services such as Symedia and MoviePilot V2. Containers mostly share Unraid host IP `192.168.10.99` with different ports, and FRP mappings depend on that, so do **not** redesign Docker networking around per-container static LAN IPs.

## Next tasks

1. Review the successful firmware and validate that Nikki + Mihomo and all intended LuCI packages actually landed in the image.
2. Prepare a safe Unraid import/deployment procedure for the new VM while preserving the old VM.
3. Provide commands to download/decompress/convert the released image for Unraid/KVM.
4. Build a custom `N100-Nikki.yaml` based on gogyt Rule.yaml with the routing behavior above.
5. Keep subscription URLs/secrets out of the public repository.
6. Do not enable Nikki and OpenClash simultaneously.
