# LightDome – Project Overview & Architecture

Questa documentazione descrive in modo completo cosa fa l’app, come è strutturata, le scelte tecniche e come interagisce con il firmware della cupola luminosa. È pensata per chi non ha mai visto il codice.

## Obiettivo

Un’app Flutter che controlla la cupola luminosa in rete locale, senza server esterni. L’utente può:
- regolare la luce in tempo reale (LIVE),
- gestire programmi luminosi `.ldy` (PROGRAM),
- configurare parametri di funzionamento (Impostazioni),
- vedere lo stato aggiornato del dispositivo (Dashboard).

Target prioritario: Android. Il progetto è già eseguibile anche su Web (Edge/Chrome). iOS è previsto.

## Architettura di alto livello

- UI a tab: Dashboard, Anteprima (facoltativa), Live, Programmi, Impostazioni.
- Controller centrale con stato (`DeviceController`).
- Servizi di rete e polling per sincronizzazione continua.
- Adapter HTTP condizionale: `dart:io` su mobile/desktop e `dart:html` su Web.
- Compatibilità con API firmware nuove (`/api/state`) e legacy (`/status`, `/set`, `/params`).
- Persistenza leggera dell'ultimo device (IP/mDNS) tramite `Prefs`.
- Pattern locali (Sine/Pulse) generati dall'app e inviati in streaming; Mic reattivo; servizi esterni (Spotify/Open provider) disabilitati di default via feature flag. I pacchetti Spotify non sono inclusi di default nel `pubspec` per evitare dipendenze native inutilizzate: vanno aggiunti manualmente quando realmente necessari.
 - Feature flag: `lib/core/config/app_features.dart`.

## Navigazione e Tema

- Entrypoint: `lib/main.dart`.
- Home: `lib/pages/home_scaffold.dart` (barra di navigazione con 4 tab).
- Tema scuro coerente (Material 3) via `ColorScheme.fromSeed(..., Brightness.dark)`; layout a card e spaziature migliorate per leggibilità.

## Modello Dati

File: `lib/core/models/device_state.dart`

`DeviceState` unifica lo stato proveniente dal firmware:
- `connected` (bool): se l’host risponde.
- `on` (bool): luce accesa/spenta.
- `mode` (string): `live`, `program`, `ram`, `idle`, `unknown`.
- `y` (double 0..1): intensità normalizzata da 0..1023 (o 0..255) → 0..1.
- `brightness` (double 0..1): master brightness (se disponibile).
- `gamma` (double 1.0..3.0): correzione gamma.
- `programName` (string?), `sr` (int): sample rate, `loop` (bool).
- `fwVersion` (string?), `uptime` (int?).

Parser:
- `fromApiJson(Map)`: usa `/api/state`.
- `fromStatusJson(Map)`: fallback legacy da `/status` (mappa campi diversa).

## Strato di Rete

Entry: `lib/core/api/http_client.dart` (export condizionale)

Implementazioni:
- `lib/core/api/http_client_io.dart` (Android/desktop)
  - `getText`, `getJson`, `postJson`, `postBytes`, `deleteText` su `HttpClient` con timeout (2 s letture, 4 s upload).

- `lib/core/api/http_client_web.dart` (Web)
  - Usa `HttpRequest` (XHR). Funzione `_send(req, timeout, body)` gestisce `onLoad/onError/onTimeout/onAbort` e garantisce che la Future sia completata una sola volta.
  - Considera OK gli status 2xx e 0 (contesti locali).

## API Firmware (wrapper)

File: `lib/core/api/device_api.dart`

Costruttore: `DeviceApi(base)` dove `base` è l’URL della cupola (es. `http://192.168.1.50` o `http://cupolaled.local`).

Metodi principali:
- `fetchState()`: prova `/api/state`, in fallback prova `/status`.
- LIVE
  - `setY(double y01)`: invia `/set?y=0..1023` (compat, risposta immediata). Input 0..1.
  - `off()`: alias per `/set?y=0`.
  - `setParams({brightnessPct, gamma, loop})`: invia `/params?...` (brightness 0..100, gamma 1.0..3.0, loop 0|1).
- Programmi
  - `listPrograms()`: parse testuale di `/prog/list`.
  - `startProgram(name)`, `stopProgram()`, `deleteProgram(name)`.

Scelte: priorità al percorso compatibile per mantenere bassa latenza e massima interoperabilità con firmware esistenti.

## Servizi Runtime

`lib/core/services/state_poller.dart`
- Polling dello stato (`fetchState`) a intervallo predefinito (~200 ms). Chiama callback `onUpdate(DeviceState)` alla risposta.
- Semplice da variare per profili foreground/background.

`lib/core/services/live_stream_service.dart`
- Rate-limiter per il controllo LIVE (slider intensità): invia al massimo ~60 Hz (timer a 16 ms) l’ultimo valore richiesto.
- Evita flood di richieste durante il drag, mantenendo fluidità.

`lib/core/services/pattern_runner.dart`
- Genera pattern "sine" e "pulse" a ~60 Hz basandosi su `PatternConfig`.
- Invia y normalizzato 0..1 via `DeviceApi.setY()`.
- Mic reattivo: integra `record` v5 per leggere l'ampiezza microfono in tempo reale e mapparla su `y`.
- Placeholder/flag per modalità future: `songWaveSpotify`, `songWaveOpen` (disabilitate). Per riattivarle servono le dipendenze opzionali (`spotify_sdk`, `spotify`, ecc.) e la configurazione delle chiavi.

## Controller Centrale

File: `lib/controllers/device_controller.dart`

Responsabilità:
- Gestisce IP, istanze `DeviceApi`, `LiveStreamService`, `StatePoller` e lo `state` corrente.
- Espone metodi per UI: `setIp`, `disconnect`, `refreshOnce`, `sendY`, `off`, `setParams`, `listPrograms`, `startProgram`, `stopProgram`, `deleteProgram`.
- Notifica la UI (ChangeNotifier) ad ogni aggiornamento.

Scelte:
- Singolo punto di verità e incapsulamento dettagli di rete.
- Persistenza dell'ultimo dispositivo per ripristino automatico all'avvio.

## UI – Pagine

`lib/pages/tabs/dashboard_page.dart`
- Stato aggregato: connessione, on/off, modalità, y%, brightness%, gamma, programma, SR, loop, eventuali FW/uptime.
- Azioni rapide: `Aggiorna`, `Spegni`.

`lib/pages/tabs/live_page.dart`
- Slider Intensità (y 0..1):
  - Durante drag: UI usa valore locale `_localY` e invia valori a ~60 Hz (coalescing) per immediatezza.
  - Fuori drag: il valore visualizzato torna a seguire lo stato remoto.
- Brightness% (0..100) e Gamma (1.0..3.0): aggiornamento in tempo reale con debounce (Brightness 80 ms, Gamma 120 ms), più invio finale `onChangeEnd`.
- Pulsanti rapidi: OFF/25/50/75/100.
- Loop: `SwitchListTile` che invia subito il valore.

`lib/pages/tabs/programs_page.dart`
- Sezione "Modalità" con menu a tendina: `Nessuna`, `Sine`, `Pulse`, `Mic reattivo` (provider futuri via feature flag).
- Parametri mostrati solo se pertinenti (es. Duty solo per Pulse). Compensazione gamma opzionale.
- Campo nome, `Play`, `Stop`, `Delete` sul nome.
- Lista dei programmi (`/prog/list`) con azioni per elemento.
- Fallback su dispositivo: selezione di un programma locale da avviare se si desidera un comportamento autonomo.
- Card "Open provider (file locale)" mostrata solo se `enableOpenProvider == true`.
- Descrizioni dei controlli attivabili/disattivabili da Impostazioni.

`lib/pages/tabs/preview_page.dart`
- Anteprima visuale: alone radiale che segue l'intensità (TX) in tempo reale. Utile anche con dispositivo offline.

`lib/core/services/envelope_builder.dart`
- Estrae un inviluppo (waveform) da un file audio con `just_waveform` e lo campiona alla frequenza richiesta (usato quando abilitato l'Open provider).

`lib/core/ldy/ldy_encoder.dart`
- Codifica l'inviluppo in formato binario `.ldy` (header "LDY1" + frames uint16 LE) per salvataggio su LittleFS.

## Ambiente e permessi

- Windows: attivare la Modalità Sviluppatore (Settings → For Developers) per supportare i symlink richiesti dai plugin.
- Microfono: dichiarazioni e richiesta permessi includono `android.permission.RECORD_AUDIO` e `NSMicrophoneUsageDescription` su iOS. Il permesso è richiesto solo quando si avvia la modalità mic reattivo.

`lib/pages/tabs/settings_page.dart`
- Connessione: inserimento IP/mDNS (con schema opzionale), comandi `Connetti`/`Disconnetti`.
- Preferenze: tema scuro attivo; altre opzioni arriveranno.

## Compatibilità e Latenza

- Preferenza per `/api/state`; fallback a `/status` per legacy.
- LIVE via `/set?y=` e `/params` per immediatezza (HTTP GET veloci) compatibili col firmware condiviso.
- Latenza percepita: <100–150 ms grazie al coalescing ~60 Hz e alla UI locale durante il drag.
- Polling: ~200 ms (regolabile).

## Gestione errori

- HTTP timeout (2 s letture, 4 s upload) e gestione errori in web adapter (error/timeout/abort).
- Poller tollera errori (skippa il ciclo) senza bloccare l’UI.
- UI mostra stato di connessione e rimane utilizzabile anche in caso di momentaneo offline.

## Esecuzione

- Android: `flutter run -d android`
- Web (Edge/Chrome): `flutter run -d edge` oppure `flutter run -d chrome`

Onboarding: tab `Impostazioni` → IP/mDNS → `Connetti`.

## Roadmap (proposte)

- Persistenza del dispositivo e discovery mDNS.
- Upload `.ldy` con barra di progresso e autorun.
- OTA con progresso e reconnect automatico.
- WebSocket opzionale per ridurre polling.
- Preset/Scene, Performance Mode, Editor RAM.

## Note di implementazione

- Tema scuro coerente per evitare assert tra `ThemeData` e `ColorScheme`.
- Su Web, `HttpRequest.status` è stato gestito come nullable (`?? 0`) per compatibilità.
- Debounce su parametri per evitare saturazione rete; coalescing su y per fluidità.
