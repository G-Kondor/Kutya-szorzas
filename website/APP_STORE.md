# App Store Connect – a képen jelzett hiányok

Fejlesztő: **Gergő Kondor**  
Támogatási e-mail: **kondorgergo@gmail.com**

A kész, nyilvános oldal: https://kutyajo-matek.vercel.app. Az alábbi tartós production URL-eket használhatod az App Store Connectben.

| App Store mező | Weboldal / érték |
| --- | --- |
| Marketing URL | `https://kutyajo-matek.vercel.app/` |
| Privacy Policy URL | `https://kutyajo-matek.vercel.app/privacy` |
| Hungarian – Support URL | `https://kutyajo-matek.vercel.app/support` |
| Copyright | `2026 Gergő Kondor` (ha te vagy a jogosult) |

## A weboldalhoz kapcsolódó mezők

1. **App Privacy → Privacy Policy → Edit:** a teljes `https://…/privacy` cím, majd Save.
2. **Distribution → aktuális verzió → Hungarian → Support URL:** a teljes `https://…/support` cím, majd Save.
3. **Marketing URL:** opcionálisan a teljes kezdőlapi cím.
4. **Copyright:** `2026 Gergő Kondor`, ha a jogok téged illetnek. Az Apple mezőjébe nem szükséges © jel vagy webcím.

A publikált forráskód alapján az app nem továbbít profiladatot: a név, a választható kép, az eredmények és a nyelv helyben maradnak. A feltöltött build tényleges működésének és minden beépített szolgáltatásának meg kell egyeznie az App Privacy válaszokkal. Az opcionális Apple-diagnosztikát külön az Apple kezeli.

## A további hibákat az App Store Connectben kell rendezni

### Content Rights

**App Information → Content Rights → Set Up / Edit.** A tényleges tartalom és a felhasználási jogok szerint válaszolj. A projekt README-je szerint a kutyusportrék és az appikon OpenAI képgenerálással készültek. A generált képek ténye önmagában nem dönti el az Apple kérdésére adott választ; ellenőrizd az összes felhasznált képet, hangot, szöveget és azok feltételeit. A weboldali jogi tájékoztató nem helyettesíti ezt a nyilatkozatot.

### Contact Information

**Distribution → aktuális verzió → App Review Information → Contact Information.**

- First Name: `Gergő`
- Last Name: `Kondor`
- Email: `kondorgergo@gmail.com`
- Phone Number: az Apple számára elérhető saját telefonszámod, országkóddal. Ezt nem tettük ki a weboldalra.

### Age Ratings

**App Information → Age Ratings → Set Up / Edit.** Minden kötelező kérdésen menj végig a beküldött app tényleges funkciói alapján. A jelenlegi forráskódban nincs reklám, vásárlás, chat, nyilvános felhasználói tartalom vagy korlátlan webböngészés. A gyermekeknek szánt célközönség nem helyettesíti a kérdőív kitöltését, és nem jelent automatikus korhatárbesorolást.

## Beküldés előtt

Nyisd meg kijelentkezve a kezdőlapot, a `/privacy` és `/support` oldalakat. Ellenőrizd a nevet, e-mailt és a tájékoztató egyezését a beküldött builddel. Mentsd az összes App Store Connect mezőt, majd próbáld újra az Add for Review gombot.

## Apple-források

- [Platform version information: Support URL, Marketing URL, Copyright](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
- [App information: Content Rights és korhatár](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
