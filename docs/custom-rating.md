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

## Publiceringsspärr

Vid läsning av projektets faktiska RTDB-regler den 6 oktober 2026 var både `.read` och `.write` `true` på rotnivå. **Publicera inte Rating-backend innan detta är åtgärdat.** Callable-validering skyddar inte data som samtidigt kan skrivas direkt via öppna databasregler. Ett deny på bara `customRatings` räcker inte, eftersom ett tillåtande uttryck på föräldern har företräde.

Reglerna behöver inventeras, ändras och emulator-testas för befintliga klientflöden (inklusive medlemskap, ägarskap, profiler och modultogglar). Rating-data ska vara server-only: ingen direkt klientläsning eller skrivning. Även Storage-regler för den nya bildsökvägen ska förhindra direkt klientmutation. Detta bredare säkerhetsarbete och produktionspublicering är inte utfört i denna implementation. Ingen testdata har skrivits till produktionsgrupper.

Efter säkerhetsarbetet: deploya callable `customRating` till `hejapp-a6614`, bygg webben med `/HejAppFlutter/` som base href och publicera frontend. Funktionens export finns i `functions/index.js`.

## Kontroller

```powershell
cd functions
node --test custom-rating.test.js calendar-box.test.js
cd ..
flutter test test/rating_test.dart test/calendar_box_test.dart
flutter analyze lib/features/rating
flutter build web --base-href /HejAppFlutter/ --release
```

Backendtester körs med isolerad databasadapter; de ersätter inte emulator-/produktionstest av faktiska säkerhetsregler. UI-tester täcker smala/breda vyer, demokonfiguration, dynamiska fält och saknade betyg.
