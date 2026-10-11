# Kutyajó Matek – bemutatkozó weboldal

Magyar nyelvű, mobilbarát statikus oldal, az app saját grafikáival. Külön támogatási, adatvédelmi és jogi oldalak; regisztráció és analitika nélkül. A tájékoztató a `00c220c` app-verzió forráskódjának működése alapján készült.

Élő oldal: **https://kutyajo-matek.vercel.app**

## Helyi indítás

Node.js 20 vagy újabb szükséges, külső csomagtelepítés nem kell.

```sh
cd website
npm run dev
```

Előnézet: http://localhost:4173. Másik port: `PORT=4180 npm run dev`.

```sh
npm run build
```

Az elkészült statikus fájlok a `dist/` mappába kerülnek. A támogatási és adatvédelmi tartalom JavaScript nélkül is olvasható.

## Vercel

A `G-Kondor/Kutyajo-matek` repót importáld új Vercel-projektként:

- Root Directory: `website`
- Framework Preset: Other
- Build Command: `npm run build`
- Output Directory: `dist`
- Environment Variables: nem szükséges

A `vercel.json` tartalmazza a beállításokat, a biztonsági fejléceket és a magyar URL-ek átirányítását. A production oldalnak bejelentkezés nélkül hozzáférhetőnek kell lennie az Apple és a felhasználók számára.

## Tartalom szerkesztése

- `content/site.json`: fejlesztő neve, e-mail, frissítés dátuma, App Store-link, támogatási kérdések.
- `content/privacy.html`: adatvédelmi tájékoztató. A `{{developer}}` és `{{supportEmail}}` helyére automatikusan a beállított adatok kerülnek.
- `build.mjs`: bemutatkozó és jogi oldal szövege, oldalszerkezet.
- `styles.css`: megjelenés.

Szerkesztés után indítsd újra az `npm run dev` parancsot, vagy futtasd a buildet. Vercelen az összekapcsolt production ágra küldött változás automatikusan újratelepül.

Ha megvan az App Store termékoldala, a `content/site.json` `appStoreUrl` mezőjébe írd a teljes `https://apps.apple.com/...` címet. A fő gomb letöltési linkre vált; addig a próbafeladatra mutat, megjelenés előtti jelzéssel.

## App Store-adatok

A mezők kitöltéséhez lásd az [APP_STORE.md](APP_STORE.md) útmutatót. Az útmutató nem része a nyilvános weboldalnak.

Az adatvédelmi szöveg 12 hónapos, ügy lezárása utáni megőrzést ír elő a támogatási levelekre. Ezt a levelezés kezelésében is tartsd be, vagy a tényleges gyakorlatodhoz igazítsd a szöveget. Ha az app később online fiókot, analitikát, reklámot vagy felhőt kap, a tájékoztatót és az App Store adatvédelmi válaszait is frissíteni kell.
