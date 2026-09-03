# Robert Veldman Tattoo & Art – Salon App

Een complete Flutter MVP voor iPhone en Android, ontworpen als tattoo-salonapp in een luxe zwart/gouden stijl die aansluit bij de WordPress-site.

## Wat werkt in deze versie

- Home / studio-presentatie
- Afspraak- en intakewizard
- Behandeling kiezen
- Datum en tijd kiezen
- Klantgegevens invoeren
- Tattoo-idee en plaats vastleggen
- Digitale toestemming / voorwaarden
- Afspraak als aanvraag opslaan
- Mijn afspraken
- Portfolio-scherm
- Nazorgscherm
- Accountscherm
- Robert-beheer via demo-PIN `2580`
- Beheerdashboard
- Agenda
- Klantenoverzicht
- Status voor toestemming en aanbetaling

De demo gebruikt een lokale `AppStore`, zodat alles direct doorloopbaar is zonder server.

## Starten

1. Installeer Flutter.
2. Open deze map in VS Code of Android Studio.
3. Voer uit:

```bash
flutter create .
flutter pub get
flutter run
```

`flutter create .` maakt de ontbrekende native Android/iOS projectmappen aan en laat de eigen `lib/`-code intact.

## Productieversie: aanbevolen backend

De logische volgende stap is Supabase:

- `profiles`: klant / admin rol
- `services`: behandelingen
- `appointments`: afspraken/intakes
- `consent_forms`: gezondheidsverklaringen en toestemming
- `payments`: aanbetalingen
- `portfolio_items`: optioneel, of ophalen uit WordPress REST API
- Supabase Storage: referentiefoto's van klanten

Daarna:

- echte login / registratie
- magic links of wachtwoordreset
- pushnotificaties
- automatische e-mailbevestiging
- blokkeringsregels in Roberts agenda
- Mollie/Stripe-betalingen voor aanbetaling
- WordPress REST API voor portfolio/nazorgcontent
- privacy-/AVG-afhandeling en bewaartermijnen

## Belangrijk voor productie

De demo-PIN is geen beveiliging. Gebruik in productie Supabase Auth + Row Level Security en een adminrol. Gezondheidsinformatie is gevoelige persoonsgegevens; sla alleen noodzakelijke gegevens op, beperk toegang en leg bewaartermijnen vast.
