# Kutyaszorzás

Kedves, offline iOS-matek-játék Laurának és Izabellának. A gyerekek ötös körökben gyakorolják a százas számkörön belüli szorzást és osztást, hibátlan körönként pedig új kutyust gyűjtenek.

## Játékszabály

- A kezdőképernyőn Laura és Izabella külön profilja választható, bejelentkezés nélkül.
- Három játékmód van: szorzás, osztás és vegyes.
- Minden kör 5 feleletválasztós feladatból áll.
- Hibátlan kör után egy új kutyus jár a 40 darabos gyűjteményből.
- A harmadik elrontott kör után egy már megszerzett kutyus elveszik.
- A két profil eredményei külön, az eszközön maradnak meg.

## Indítás

1. Nyisd meg a `DogMath.xcodeproj` fájlt Xcode-ban.
2. Válassz egy iPhone szimulátort.
3. Indítsd a projektet a Run gombbal vagy `⌘R`-rel.

Az app iOS 17 vagy újabb rendszert céloz, külső csomagfüggősége nincs.

## Git-szinkron

A helyi `main` ág az `origin/main` ágat követi. A szokásos munkafolyamat:

```bash
git pull --rebase
git add .
git commit -m "Rövid leírás"
git push
```

## Grafika

A 40 kutyaportré és az appikon az OpenAI beépített képgenerálójával készült ehhez a projekthez. A forráslapok az `ArtworkSource/DogSheets` mappában, az alkalmazás által használt képek a `DogMath/Resources/Dogs` mappában találhatók.
