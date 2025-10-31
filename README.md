# LightDome – App Flutter per Cupola Luminosa

Client Flutter per controllare, via rete locale (LAN), il firmware della cupola luminosa su ESP8266/ESP32. Nessun cloud, bassa latenza, UI a tab per controllo LIVE, programmi e impostazioni.

Per una panoramica completa di architettura, moduli, API e scelte progettuali vedi:

- Documentazione estesa: `docs/PROJECT_OVERVIEW.md`

## Requisiti

- Flutter SDK installato
- Dispositivo della cupola raggiungibile in LAN (IP o mDNS)

## Esecuzione rapida

- Android: `flutter run -d android`
- Web (Edge/Chrome): `flutter run -d edge` oppure `flutter run -d chrome`

## Onboarding

1. Apri l’app → tab `Impostazioni`.
2. Inserisci IP o mDNS del dispositivo (es. `http://192.168.1.50` o `http://cupolaled.local`).
3. Premi `Connetti`.

## Funzioni principali

- Dashboard: stato in tempo reale, `Aggiorna`, `Spegni`.
- Live: slider intensità (coalescing ~60 Hz), brightness%, gamma, loop, preset rapidi OFF/25/50/75/100.
- Programmi: elenco, Play/Stop/Delete su file `.ldy` presenti nel device.
- Impostazioni: gestione connessione (IP/mDNS). 

## Compatibilità Firmware

- Stato: `/api/state` (preferito) con fallback `/status`.
- LIVE: `/set?y=` (0..1023), `/params?brightness=0..100&gamma=1.0..3.0&loop=0|1`.
- Programmi: `/prog/list`, `/prog/start`, `/prog/stop`, `/prog/delete`.

## Roadmap rapida

- Persistenza device + discovery mDNS
- Upload `.ldy` con progress
- OTA e reconnect automatico
- WebSocket opzionale per ridurre polling
