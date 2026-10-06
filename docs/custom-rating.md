# Custom Rating / Ranking

## Aktivering

1. Gruppinställningar → Modules → aktivera **Betyg & ranking**.
2. Öppna modulen i gruppmenyn → **Konfigurera modulen**.
3. Välj tom mall eller **Demo: Sardinarkivet**. Import av de 14 angivna objekten är valbar och sker bara när ett nytt arkiv sparas.
4. Anpassa modulnamn, objekttyp, primär skala, kriterier och metadatafält.
5. Lägg till objekt med bild, metadata och egen recension. Andra medlemmar kan lägga till egna recensioner från detaljsidan.

Saknade betyg visas som **Ej betygsatt**, aldrig som noll. Saknad metadata visas som **Ej angivet**. Demoobjekten har inga fabricerade kriteriebetyg eller bilder. Historiska demobetyg märks som importerad demodata, inte som importörens recension. De ingår som ett omdöme i snittet tillsammans med senare individuella recensioner. Importdatumet är inte ett påstått testdatum.

## Arkitektur

- Befintlig GoRouter för detaljsidor, Riverpod för state, Firebase callable + Realtime Database för lagring.
- `customRatings/{groupId}/{moduleId}` innehåller `config` och `items`. Första UI-versionen använder `moduleId = main` (ett arkiv per grupp). Datamodellen är förberedd för fler instanser.
- Varje objekt har stabilt ID, `moduleId`, titel, valfri bild, metadata, skapare, tidsstämplar och `reviews/{uid}`. Recensioner är separata från objektets metadata och innehåller primärt betyg, kriteriebetyg och kommentar.
- Aggregering använder bara ifyllda värden per kriterium. Primära nollbetyg räknas. Saknade betyg sorteras sist; lika snitt sorteras på namn.
- `config.revision`, objektversion och recensionens ändringstid skyddar mot överskrivning av samtidiga ändringar. Ändring av befintliga skalor, typer och borttagning av fält blockeras när objekt finns. Etiketter, synlighet och highlights kan ändras; nya valfria fält kan läggas till.
- Administratör eller ägare konfigurerar; medlemmar skapar objekt och egna recensioner; objektets skapare och administratörer får redigera eller ta bort objekt.
- Bilder laddas upp genom backend till `rating_images/{groupId}/{moduleId}/{itemId}/…`. JPG/PNG/WebP, högst 2 MB. Download-token-länkar följer appens befintliga bildmönster och kan delas av någon som redan har länken. Ersatta/borttagna bilder rensas best-effort.
- Gruppen läser arkivet via en callable. Uppdateras efter egna sparningar samt vid manuell uppdatering/pull-to-refresh; ingen ny realtidslyssnare/pollning.
- Gränser i första versionen: 300 objekt, högst 16 kriterier och 16 metadatafält. Hela arkivet laddas för ranking; större arkiv kräver paginering och serveraggregering.

## List / Collection senare

Återanvänd de generella metadatafältens stabila ID:n och typdefinitioner för en framtida Collection. Överför titel, bild och `metadataValues` via en servervaliderad importåtgärd, skapa ett ratingobjekt med eget ID och behåll en serverkontrollerad `sourceReference` till ursprungsobjektet. Lägg inte till påhittade recensioner vid överföring. Ingen List/Collection-modul ingår i den här leveransen.

## Säkerhet och publicering

Vid läsning av projektets faktiska RTDB-regler den 6 oktober 2026 var både `.read` och `.write` `true` på rotnivå. Även Storage var öppet. De nya reglerna i `database.rules.json` och `storage.rules` ersätter detta med explicit åtkomst. Rating och Kalenderlådan är server-only. Ett deny på bara `customRatings` hade inte räckt med ett tillåtande uttryck på föräldern.

Reglerna har emulator-testats för gruppskapande, anslutning via inbjudningskod, utträde, medlemsborttagning, gruppborttagning, profiler, innehåll, omröstningar, uppgifter och privata chattar. Ägarskap och administratörsflaggor kan inte övertas av en vanlig medlem. Grupp-ID:n med kvarvarande privata data kan inte återanvändas efter borttagning. Rating-backend har också körts mot riktiga emulatortransaktioner.

Uppladdningar och privat-chatt-skrivningar går via `workspaceAccess`. Befintliga nedladdningslänkar med token fungerar fortfarande för den som har länken. Uppladdningar begränsas till 6 MB och 100 per användare/dag; Rating-bilder har fortfarande sin separata gräns på 2 MB. Privata chattar kan bara läsas av deltagarna och meddelandets avsändare hämtas från autentiseringen, inte klientens indata.

Publiceringsordning: deploya `customRating` och `workspaceAccess`, publicera databas- och Storage-regler, bygg webben med `/HejAppFlutter/` och pusha till `ios`. Äldre öppna klienter behöver laddas om eftersom direktuppladdningar och direkta DM-skrivningar nu nekas. Rating aktiveras per grupp i inställningarna; inga verkliga grupper får demoobjekt automatiskt.

Verifiering 2026-10-06: 11 emulator-/integrationstester, 21 Node-tester och 12 Flutter-tester passerade. Release-build för webben lyckades. Efter backend- och regeldeploy verifierades autentiserad konfiguration, objekt, recensioner, nekad direktåtkomst, bild-uppladdning/nedladdning och privatmeddelanden i produktion med isolerade testkonton. Testkonton, testgrupp, bild och meddelanden togs bort efteråt. Kör `node scripts/smoke-rating-production.cjs --run` endast när ett sådant produktionstest uttryckligen är avsett.

Driftuppföljning: Firebase CLI varnade vid deployment om Node 20:s kommande avveckling och misslyckad städning av byggbilder. Funktionerna deployades framgångsrikt, men runtime-uppgradering och kontroll av artifact-lagringen bör hanteras separat.

Avgränsning: den äldre mötesplaneraren behåller sina delade röstarrayer inom gruppen. Inloggade användare kan läsa enskilda profiler och kontrollera gruppnamnet vid känd inbjudningskod. Detta är inte en fullständig säkerhetsrevision eller historisk granskning av tidigare öppet innehåll. Oanvända legacy-noder saknar klientåtkomst som standard. Återställ inte de tidigare öppna rotreglerna vid felsökning.

## Kontroller

```powershell
cd functions
node --test custom-rating.test.js calendar-box.test.js workspace-access.test.js
cd ..
node scripts/build-database-rules.cjs --check
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only database,storage --project demo-hej-security "npm --prefix security-tests test"
flutter test test/rating_test.dart test/calendar_box_test.dart
flutter analyze lib/features/rating
flutter build web --base-href /HejAppFlutter/ --release
```

Backendtester körs med isolerad databasadapter; de ersätter inte emulator-/produktionstest av faktiska säkerhetsregler. UI-tester täcker smala/breda vyer, demokonfiguration, dynamiska fält och saknade betyg.
