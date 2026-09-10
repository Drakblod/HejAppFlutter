# Kalenderlådan — testversion

En egen gruppmodul (`calendarBox`), aktiverad som standard om gruppen inte uttryckligen stängt av den. Den befintliga mötesplaneraren är kvar.

## Testa

1. Öppna Kalenderlådan → Lägg i kalenderlådan.
2. Klistra in: `Konsert på Kulturhuset den 24 oktober 2026 kl 18:30. En kväll med livemusik.`
3. Välj Tolka och skapa förslag. Kontrollera titel, datum, tid och plats.
4. Bekräfta granskningen och spara. Eventet visas under 2026-10-24.
5. Testa en JPG/PNG/WebP-skärmdump under 4 MB. Om år saknas ska datum lämnas för manuell granskning.
6. Prova även Fyll i manuellt. Saknat datum och ogiltiga datum ska stoppas.
7. Öppna gruppen med ett annat medlemskonto och uppdatera kalendern. Samma event ska visas.

## Omfattning

- Text och bild skickas till OpenAI först vid uttryckligt tryck på Tolka. Skärmdumpen lagras inte av appen; Responses-anropet använder `store: false`.
- Backend returnerar bara ett utkast. Spara kräver en separat bekräftad begäran.
- En källänk kan sparas och öppnas, men hämtas inte automatiskt. Inklistrad länk ensam stöds inte ännu, inte heller mobilens Dela → HEJ.
- Datum och klockslag lagras som lokal datum/tid på eventets plats. Ingen automatisk tidszonskonvertering. Tom tid betyder okänd tid, inte heldagsevent.
- Ett event per import. Granska alltid förslaget, särskilt om källan innehåller flera event.
- Kommande inkluderar hela dagens event. Listan uppdateras efter sparande och manuellt med uppdateringsknappen; ingen livesynk i denna version.
- Ingen redigering eller radering efter sparande i första testversionen. Kontrollera utkastet noga.
- Upp till 500 senast skapade event per grupp. 20 AI-tolkningsförsök per användare och UTC-dygn; manuell registrering fungerar även efter gränsen.

## Drift

`calendarBox` är en callable Firebase-funktion i us-central1. Alla anrop kontrollerar inloggning och gruppmedlemskap på servern. Den använder samma `OPENAI_API_KEY`-secret som bakgrundsfunktionen. Inga hemligheter finns i den nya klientkoden.

Publicera backend: `firebase deploy --only functions:calendarBox --project hejapp-a6614`.
Publicering av webbappen sker via befintlig GitHub Actions-workflow på `ios`.

Tester: `node --test functions/calendar-box.test.js` och `flutter test test/calendar_box_test.dart`.

API-underlag: [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs).
