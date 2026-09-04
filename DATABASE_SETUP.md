# Database koppelen

Deze versie gebruikt Supabase voor:

- diensten uit `services` laden;
- nieuwe klanten opslaan/bijwerken;
- afspraakaanvragen opslaan in `appointments`;
- statuswaarden in de database zoals `requested`, `confirmed`, `completed`, `cancelled` en `no_show`.

## 1. Lokale configuratie maken

Kopieer:

```bash
cp config/supabase.json.example config/supabase.json
```

Vul daarna in `config/supabase.json` alleen deze twee clientgegevens in:

```json
{
  "SUPABASE_URL": "https://jouw-project.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

`config/supabase.json` staat in `.gitignore` en hoort dus niet naar GitHub.

Gebruik **geen** database password, `service_role` key of secret key in de Flutter-app.

## 2. Starten

Debug:

```bash
flutter pub get
flutter run --dart-define-from-file=config/supabase.json
```

Op de iPhone als release-build:

```bash
flutter run --release --dart-define-from-file=config/supabase.json
```

## 3. Veilige afspraakfunctie

Run `supabase/setup.sql` één keer in Supabase > SQL Editor. Daarmee:

- kan de app actieve/boekbare services lezen;
- blijven `customers` en `appointments` afgeschermd voor anonieme directe reads;
- slaat de app boekingen op via `create_appointment_request(...)`.

Zonder deze SQL probeert de app voor het prototype nog een directe insert. Dat werkt alleen als jouw huidige tabelrechten/RLS dat toestaan.

## 4. Diensten toevoegen

Voorbeeld:

```sql
insert into services
(name, description, category, duration_minutes, price_from, deposit_amount, active, bookable)
values
('Tattoo afspraak', 'Ontwerp en tattoo sessie', 'tattoo', 180, 250.00, 75.00, true, true),
('Intake / ontwerpbespreking', 'Idee, stijl, plek en planning bespreken', 'consult', 45, 0.00, 0.00, true, true),
('Touch-up / controle', 'Controle of kleine bijwerking', 'touch_up', 45, null, 0.00, true, true);
```

## Beheer

De demo-PIN `2580` is alleen lokale prototypebeveiliging. Voor echte toegang tot alle klanten en afspraken moet Robert later via Supabase Auth inloggen met een owner-rol. Dan kunnen daarvoor aparte RLS policies worden toegevoegd.
