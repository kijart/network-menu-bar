# Changelog

## [0.3.0](https://github.com/kijart/network-menu-bar/compare/0.2.0...0.3.0) (2026-11-13)


### Features

* add NetworkMonitor.stop() ([a9d26d9](https://github.com/kijart/network-menu-bar/commit/a9d26d967049759eafb755658d5971b544c28140))


### Bug Fixes

* ignore the OpenVPN state key when its client process is gone ([3cccbce](https://github.com/kijart/network-menu-bar/commit/3cccbce7cac0fe1f439c04c0684bb7b4a20927a0))
* prefer real adapters for the unplugged Ethernet row and drop repeated BSD names ([ad9bf37](https://github.com/kijart/network-menu-bar/commit/ad9bf37f881457bb0f07d09980e239cf38c13784))


### Performance

* read the network state off the main actor ([d8d5b9f](https://github.com/kijart/network-menu-bar/commit/d8d5b9f398854e3fbbf8acbf9dd3b592a9b8684c))

## [0.2.0](https://github.com/kijart/network-menu-bar/compare/0.1.1...0.2.0) (2026-11-11)


### Features

* add an About tab to Settings with the version and repository link ([87670b4](https://github.com/kijart/network-menu-bar/commit/87670b44e9ce0bc69d13716166f8e839b5722139))
* explain when launch at login waits for approval in System Settings ([92b0ead](https://github.com/kijart/network-menu-bar/commit/92b0ead6c40e2d8f6dc435d4f1b9f8b29d10063a))
* widen the menu up to 400 pt and wrap long network names ([6860a9f](https://github.com/kijart/network-menu-bar/commit/6860a9fe6f83007ac8e671c21be24a83ae5a64bf))


### Bug Fixes

* always open Settings on the General tab ([53cc275](https://github.com/kijart/network-menu-bar/commit/53cc275c650ac22e26a0832defad34374234fb4a))
* show the full-tunnel VPN as "via" when the primary interface stays physical ([f835d13](https://github.com/kijart/network-menu-bar/commit/f835d13100520fce646317ab22eced5e5735e88b))

## [0.1.1](https://github.com/kijart/network-menu-bar/compare/0.1.0...0.1.1) (2026-11-11)


### Bug Fixes

* accept only strict public IPv4 addresses from the lookup ([f3af7a9](https://github.com/kijart/network-menu-bar/commit/f3af7a9d9f450f036a4be65134cd590d44cb9943))
* name unknown tunnels "VPN (utunN)" and disambiguate duplicate rows ([6b51851](https://github.com/kijart/network-menu-bar/commit/6b5185182f202e17d2d29f6f3e91dc29ecf6b6b2))
* use a stateless session per public IP lookup ([8b00069](https://github.com/kijart/network-menu-bar/commit/8b000690a552e3fbf6cc10d63b7a16c13b7cdd2d))

## 0.1.0 (2026-11-06)


### Features

* add app icon ([b0676c7](https://github.com/kijart/network-menu-bar/commit/b0676c7083e6a15588d257ddbc66803fdcff0858))
* add NetworkMonitor with debounced refresh ([4ee431e](https://github.com/kijart/network-menu-bar/commit/4ee431e76d020536d486919678acbf06c6b7c5e1))
* classify interfaces into Ethernet, Wi-Fi and VPN rows ([62d5df8](https://github.com/kijart/network-menu-bar/commit/62d5df8c28a49e35b3f2e0b1998232b8a7351994))
* derive connection kind and menu bar text ([aeb991f](https://github.com/kijart/network-menu-bar/commit/aeb991fd7cb7c06a618411d44e92b93a04e9ea82))
* fetch public IP with fallback and validation ([73b67b7](https://github.com/kijart/network-menu-bar/commit/73b67b70df69db254ee2c55df018a91993a4c7aa))
* label OpenVPN Connect tunnels as OpenVPN ([27f8009](https://github.com/kijart/network-menu-bar/commit/27f8009e2db9d38f50e8f4302337dab4efa9f59b))
* menu bar icon and dropdown with compact and detailed layouts ([db22d8e](https://github.com/kijart/network-menu-bar/commit/db22d8e982c217bc07562735ee3201de0093e70c))
* network icons in the dropdown with a setting to hide them ([74218fe](https://github.com/kijart/network-menu-bar/commit/74218fea394e6103afe75ae3855f42409a0c4188))
* query checkip.amazonaws.com first for the public IP ([ee2064a](https://github.com/kijart/network-menu-bar/commit/ee2064a1ed1c888944a27a10f5496d763acda800))
* read system network state and add nmb-dump debug tool ([1b37604](https://github.com/kijart/network-menu-bar/commit/1b376041a070c334d32f8606c3f98b5eed7be614))
* redraw the app icon with the network nodes glyph ([a9f3dba](https://github.com/kijart/network-menu-bar/commit/a9f3dba1192e8eea188216edbbb66ac9e9a6b540))
* settings window, launch at login and language override ([ed6cf0f](https://github.com/kijart/network-menu-bar/commit/ed6cf0f1e9581cdcff16689bb74dab8b92eea0ae))
* ship a disk image and update the first-launch steps ([45a423f](https://github.com/kijart/network-menu-bar/commit/45a423fc6d339222ad1e37a4430056fef7c8d1d7))
* show the app as "Network Menu Bar" ([afa56ff](https://github.com/kijart/network-menu-bar/commit/afa56ffac8eaa54ed84c5b39269ba6fe23e0e361))
* show the app glyph in the menu bar, dimmed when offline ([f7f903d](https://github.com/kijart/network-menu-bar/commit/f7f903defee57ee8f176662d85f98d25fc008916))


### Bug Fixes

* detect offline from the path status and cap the public IP lookup at 5 s ([ed72370](https://github.com/kijart/network-menu-bar/commit/ed72370c547d76cb9f9f23ef5f4ccb792e92707a))
* name the app in the Quit button ([150c768](https://github.com/kijart/network-menu-bar/commit/150c76813184df6e1b9ccd81eb409749352b8f17))
* refresh on dynamic store changes and when the menu opens ([c224275](https://github.com/kijart/network-menu-bar/commit/c224275f488f35ec972d5bebdc5e9723c7085634))
