# strema-dist

Binary helper releases

## manifest.json

Latest announced DZYGA component versions, fetched by devices directly from
`https://raw.githubusercontent.com/gruz/strema-dist/master/manifest.json`
(cached on device). Currently:

- `dzyga_firmware` — newest known controller firmware version (string, e.g.
  `"2.8L2"`). Devices compare it with the version read from the OLED menu
  and show an update reminder when they differ. We only know the version
  string — the .uf2 itself is per-device and comes from the developer.
