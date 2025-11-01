import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../../core/config/app_features.dart';

import '../../controllers/device_controller.dart';
import '../../core/models/pattern.dart';
import '../../widgets/signal_scope.dart';
import '../../core/services/app_settings.dart';

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  final _nameCtrl = TextEditingController();
  List<String> _programs = const [];
  bool _loading = false;
  PatternType _type = PatternType.none;
  double _freq = 1.0;
  double _amp = 1.0;
  double _off = 0.0;
  String? _pickedPath;
  double _duty = 0.5;
  bool _gammaComp = false;
  double _micThresh = 0.2;
  double _micAttack = 0.6;
  double _micRelease = 0.3;
  file_picker.PlatformFile? _ldyFile;
  bool _ldyAutorun = false;
  double _ldyProgress = 0.0;
  bool _ldyUploading = false;
  String? _ldyStatus;
  String? _ldyError;
  Timer? _patternDebounce;
  bool _isAdjustingPattern = false;

  Widget _desc(String text) {
    if (!AppSettings.I.showDescriptions) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    _programs = await DeviceController.I.listPrograms();
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _refresh();
    final current = DeviceController.I.pattern;
    _applyConfigToUi(current);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _patternDebounce?.cancel();
    super.dispose();
  }

  void _applyConfigToUi(PatternConfig cfg) {
    _type = cfg.type;
    _freq = cfg.freqHz;
    _amp = cfg.amplitude;
    _off = cfg.offset;
    _duty = cfg.duty ?? 0.5;
    _gammaComp = cfg.gammaComp ?? false;
    _micThresh = cfg.micThreshold ?? _micThresh;
    _micAttack = cfg.micAttack ?? _micAttack;
    _micRelease = cfg.micRelease ?? _micRelease;
  }

  void _maybeSyncPattern(PatternConfig cfg) {
    if (_isAdjustingPattern || cfg.type == PatternType.none) return;
    if (_patternEquals(cfg)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _applyConfigToUi(cfg));
    });
  }

  bool _patternEquals(PatternConfig cfg) {
    bool eq(double a, double b) => (a - b).abs() < 1e-3;
    return cfg.type == _type &&
        eq(cfg.freqHz, _freq) &&
        eq(cfg.amplitude, _amp) &&
        eq(cfg.offset, _off) &&
        eq((cfg.duty ?? _duty), _duty) &&
        (cfg.gammaComp ?? false) == _gammaComp &&
        eq((cfg.micThreshold ?? _micThresh), _micThresh) &&
        eq((cfg.micAttack ?? _micAttack), _micAttack) &&
        eq((cfg.micRelease ?? _micRelease), _micRelease);
  }

  double _computeLowLevel() {
    switch (_type) {
      case PatternType.sine:
        return (_off - _amp).clamp(0.0, 1.0);
      case PatternType.pulse:
        return _off.clamp(0.0, 1.0);
      case PatternType.micReactive:
        return 0.0;
      default:
        return 0.0;
    }
  }

  double _computeHighLevel() {
    switch (_type) {
      case PatternType.sine:
      case PatternType.pulse:
        return (_off + _amp).clamp(0.0, 1.0);
      case PatternType.micReactive:
        return 1.0;
      default:
        return 0.0;
    }
  }

  String _patternLabel(PatternType type) {
    switch (type) {
      case PatternType.none:
        return 'nessuna';
      case PatternType.sine:
        return 'sine';
      case PatternType.pulse:
        return 'pulse';
      case PatternType.micReactive:
        return 'mic';
      case PatternType.songWaveSpotify:
        return 'spotify';
      case PatternType.songWaveOpen:
        return 'open';
    }
  }

  String _formatPercent(double value) => '${(value * 100).round()}%';

  PatternConfig _currentPatternConfig() {
    switch (_type) {
      case PatternType.none:
        return const PatternConfig.none();
      case PatternType.sine:
        return PatternConfig(
          type: PatternType.sine,
          amplitude: _amp,
          offset: _off,
          freqHz: _freq,
          gammaComp: _gammaComp,
        );
      case PatternType.pulse:
        return PatternConfig(
          type: PatternType.pulse,
          amplitude: _amp,
          offset: _off,
          freqHz: _freq,
          duty: _duty,
          gammaComp: _gammaComp,
        );
      case PatternType.micReactive:
        return PatternConfig(
          type: PatternType.micReactive,
          amplitude: _amp,
          offset: _off,
          freqHz: _freq,
          gammaComp: _gammaComp,
          micThreshold: _micThresh,
          micAttack: _micAttack,
          micRelease: _micRelease,
        );
      case PatternType.songWaveSpotify:
      case PatternType.songWaveOpen:
        return PatternConfig(
          type: _type,
          amplitude: _amp,
          offset: _off,
          freqHz: _freq,
          gammaComp: _gammaComp,
        );
    }
  }

  void _startPattern() {
    final cfg = _currentPatternConfig();
    DeviceController.I.setPattern(cfg);
  }

  void _stopPattern() {
    _patternDebounce?.cancel();
    DeviceController.I.setPattern(const PatternConfig.none(), persist: false);
  }

  void _queuePatternUpdate({bool immediate = false}) {
    final ctrl = DeviceController.I;
    if (ctrl.pattern.type != _type || ctrl.pattern.type == PatternType.none) return;
    _patternDebounce?.cancel();
    if (immediate) {
      ctrl.setPattern(_currentPatternConfig());
      return;
    }
    _patternDebounce = Timer(const Duration(milliseconds: 160), () {
      ctrl.setPattern(_currentPatternConfig());
    });
  }

  void _onPatternAdjustmentStart() {
    _isAdjustingPattern = true;
    _patternDebounce?.cancel();
  }

  void _onPatternAdjustmentEnd() {
    _isAdjustingPattern = false;
    _queuePatternUpdate(immediate: true);
  }

  bool _canUploadLdy() {
    if (_ldyUploading) return false;
    final file = _ldyFile;
    if (file == null) return false;
    final total = file.bytes?.length ?? file.size;
    if (total == 0) return false;
    return _nameCtrl.text.trim().isNotEmpty;
  }

  Future<void> _pickLdyFile() async {
    try {
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: file_picker.FileType.custom,
        allowedExtensions: const ['ldy'],
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _ldyFile = result.files.single;
          _ldyProgress = 0;
          _ldyStatus = null;
          _ldyError = null;
        });
      }
    } catch (e) {
      setState(() {
        _ldyError = 'Errore durante la selezione del file: $e';
      });
    }
  }

  Future<void> _uploadSelectedLdy() async {
    final file = _ldyFile;
    if (file == null) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci il nome del programma prima di caricare.')),
      );
      return;
    }
    final total = file.bytes?.length ?? file.size;
    if (total <= 0) {
      setState(() => _ldyError = 'Il file selezionato è vuoto.');
      return;
    }

    Stream<List<int>>? stream = file.readStream;
    if (stream == null) {
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _ldyError = 'Impossibile leggere il file selezionato.');
        return;
      }
      stream = Stream.value(bytes);
    }

    setState(() {
      _ldyUploading = true;
      _ldyProgress = 0;
      _ldyStatus = null;
      _ldyError = null;
    });

    try {
      await DeviceController.I.uploadProgramStream(
        name: name,
        data: stream,
        length: total,
        autorun: _ldyAutorun,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _ldyProgress = progress.clamp(0.0, 1.0));
        },
      );
      if (!mounted) return;
      setState(() {
        _ldyUploading = false;
        _ldyProgress = 1.0;
        _ldyStatus = 'Caricamento completato';
      });
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ldyUploading = false;
        _ldyError = 'Caricamento fallito: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = DeviceController.I;
    final settings = AppSettings.I;
    return AnimatedBuilder(
      animation: Listenable.merge([ctrl, settings]),
      builder: (context, _) {
        final currentPattern = ctrl.pattern;
        _maybeSyncPattern(currentPattern);
        final bool patternActive = currentPattern.type != PatternType.none;
        final bool patternMatchesSelection = patternActive && currentPattern.type == _type;
        final double lowLevel = _computeLowLevel();
        final double highLevel = _computeHighLevel();
        final fallbackValue = ctrl.fallbackProgram != null && _programs.contains(ctrl.fallbackProgram)
            ? ctrl.fallbackProgram
            : null;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Visualizzazione segnale
            if (settings.showPreview)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Segnale (TX vs RX)', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                SignalScope(height: 120),
              ],
            ),
          ),
        ),
        if (settings.showPreview) const SizedBox(height: 8),
        // Modalità pattern locali
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Modalità', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (patternActive)
                      Chip(
                        label: Text(
                          patternMatchesSelection
                              ? 'In esecuzione'
                              : 'Attivo: ${_patternLabel(currentPattern.type)}',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      )
                    else
                      Chip(
                        label: const Text('Inattivo'),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<PatternType>(
                  key: ValueKey(_type),
                  initialValue: _type,
                  items: [
                    const DropdownMenuItem(value: PatternType.none, child: Text('Nessuna')),
                    const DropdownMenuItem(value: PatternType.sine, child: Text('Sine')),
                    const DropdownMenuItem(value: PatternType.pulse, child: Text('Pulse')),
                    const DropdownMenuItem(value: PatternType.micReactive, child: Text('Mic reattivo')),
                    if (AppFeatures.enableSpotify)
                      const DropdownMenuItem(value: PatternType.songWaveSpotify, child: Text('Spotify')),
                    if (AppFeatures.enableOpenProvider)
                      const DropdownMenuItem(value: PatternType.songWaveOpen, child: Text('Provider aperto')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _type = v);
                    if (v == PatternType.none) {
                      _stopPattern();
                    }
                  },
                ),
                if (_type == PatternType.sine || _type == PatternType.pulse) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('Frequenza'),
                    const Spacer(),
                    Text('${_freq.toStringAsFixed(2)} Hz'),
                  ]),
                  Slider(
                    value: _freq,
                    min: 0.05,
                    max: 20,
                    onChangeStart: (_) => _onPatternAdjustmentStart(),
                    onChanged: (v) {
                      setState(() => _freq = v);
                      _queuePatternUpdate();
                    },
                    onChangeEnd: (_) => _onPatternAdjustmentEnd(),
                  ),
                  _desc('Frequenza dell\'onda in Hertz: valori più alti = variazioni più rapide.'),
                  Row(children: [
                    const Text('Ampiezza'),
                    const Spacer(),
                    Text('${(_amp * 100).toStringAsFixed(0)}%'),
                  ]),
                  Slider(
                    value: _amp,
                    min: 0,
                    max: 1,
                    onChangeStart: (_) => _onPatternAdjustmentStart(),
                    onChanged: (v) {
                      setState(() => _amp = v);
                      _queuePatternUpdate();
                    },
                    onChangeEnd: (_) => _onPatternAdjustmentEnd(),
                  ),
                  _desc('Risultato: ${_formatPercent(lowLevel)} → ${_formatPercent(highLevel)}'),
                  Row(children: [
                    const Text('Offset'),
                    const Spacer(),
                    Text('${(_off * 100).toStringAsFixed(0)}%'),
                  ]),
                  Slider(
                    value: _off,
                    min: 0,
                    max: 1,
                    onChangeStart: (_) => _onPatternAdjustmentStart(),
                    onChanged: (v) {
                      setState(() => _off = v);
                      _queuePatternUpdate();
                    },
                    onChangeEnd: (_) => _onPatternAdjustmentEnd(),
                  ),
                  _desc('Livello di base su cui si applica l\'oscillazione.'),
                  if (_type == PatternType.pulse) ...[
                    Row(children: const [Text('Duty') , Spacer()]),
                    Slider(
                      value: _duty,
                      min: 0.05,
                      max: 0.95,
                      onChangeStart: (_) => _onPatternAdjustmentStart(),
                      onChanged: (v) {
                        setState(() => _duty = v);
                        _queuePatternUpdate();
                      },
                      onChangeEnd: (_) => _onPatternAdjustmentEnd(),
                    ),
                    _desc('Percentuale del periodo in cui la luce resta al massimo.'),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compensazione gamma'),
                    value: _gammaComp,
                    onChanged: (v) {
                      setState(() => _gammaComp = v);
                      _queuePatternUpdate(immediate: true);
                    },
                  ),
                  _desc('Corregge la risposta non lineare per rendere visibili anche i livelli bassi.'),
                  const SizedBox(height: 8),
                  const Text('Suggerimento: il pattern locale è calcolato in app e inviato via rete.'
                      ' Per un comportamento indipendente dall’app serve caricarlo come programma sul dispositivo.'),
                ],
                if (_type == PatternType.micReactive) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('Mic reattivo'),
                    const Spacer(),
                    Text('gain ${( (_amp*100).toStringAsFixed(0))}%'),
                  ]),
                  Slider(
                    value: _amp,
                    min: 0.0,
                    max: 2.0,
                    onChangeStart: (_) => _onPatternAdjustmentStart(),
                    onChanged: (v) {
                      setState(() => _amp = v);
                      _queuePatternUpdate();
                    },
                    onChangeEnd: (_) => _onPatternAdjustmentEnd(),
                  ),
                  _desc('Amplificazione del segnale del microfono (non influisce sul rumore sotto soglia).'),
                  Row(children: [
                    const Text('Soglia'),
                    const Spacer(),
                    Text('${(_micThresh*100).toStringAsFixed(0)}%'),
                  ]),
                  Slider(
                    value: _micThresh,
                    min: 0.0,
                    max: 0.5,
                    onChangeStart: (_) => _onPatternAdjustmentStart(),
                    onChanged: (v) {
                      setState(() => _micThresh = v);
                      _queuePatternUpdate();
                    },
                    onChangeEnd: (_) => _onPatternAdjustmentEnd(),
                  ),
                  _desc('Taglia il rumore di fondo: sotto questa percentuale non si accende.'),
                  Row(children: const [Text('Attack'), Spacer()]),
                  Slider(
                    value: _micAttack,
                    min: 0.05,
                    max: 1.0,
                    onChangeStart: (_) => _onPatternAdjustmentStart(),
                    onChanged: (v) {
                      setState(() => _micAttack = v);
                      _queuePatternUpdate();
                    },
                    onChangeEnd: (_) => _onPatternAdjustmentEnd(),
                  ),
                  _desc('Reattività in salita (valori alti = risposta più pronta).'),
                  Row(children: const [Text('Release'), Spacer()]),
                  Slider(
                    value: _micRelease,
                    min: 0.05,
                    max: 1.0,
                    onChangeStart: (_) => _onPatternAdjustmentStart(),
                    onChanged: (v) {
                      setState(() => _micRelease = v);
                      _queuePatternUpdate();
                    },
                    onChangeEnd: (_) => _onPatternAdjustmentEnd(),
                  ),
                  _desc('Velocità di spegnimento (valori alti = scende più lentamente).'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compensazione gamma'),
                    value: _gammaComp,
                    onChanged: (v) {
                      setState(() => _gammaComp = v);
                      _queuePatternUpdate(immediate: true);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('L’audio del microfono viene analizzato in tempo reale e tradotto in luce.'),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _type == PatternType.none ? null : _startPattern,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
                    OutlinedButton.icon(
                      onPressed: patternActive ? _stopPattern : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Programmi (.ldy)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome programma',
                          hintText: 'es. demo1',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                await ctrl.startProgram(name);
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('PROGRAM avviato')));
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
                    const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: ctrl.stopProgram,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Aggiorna lista'),
            ),
                    const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                await ctrl.deleteProgram(name);
                if (!mounted) return;
                _refresh();
                messenger.showSnackBar(const SnackBar(content: Text('PROGRAM eliminato')));
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
            ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Carica file .ldy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _ldyFile?.name ?? 'Nessun file selezionato',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _ldyUploading ? null : _pickLdyFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Scegli file'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Switch(
                      value: _ldyAutorun,
                      onChanged: _ldyUploading ? null : (v) => setState(() => _ldyAutorun = v),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Imposta come autorun all\'avvio del dispositivo.')),
                  ],
                ),
                if (_ldyUploading || _ldyProgress > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(value: _ldyUploading ? (_ldyProgress > 0 ? _ldyProgress : null) : 1.0),
                  ),
                if (_ldyStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_ldyStatus!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ),
                if (_ldyError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_ldyError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _canUploadLdy() ? _uploadSelectedLdy : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(_ldyUploading ? 'Caricamento...' : 'Carica su dispositivo'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (AppFeatures.enableOpenProvider)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Open provider (file locale)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: Text(
                        _pickedPath == null ? 'Nessun file selezionato' : _pickedPath!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final picker = await _pickAudioFile();
                          if (picker != null) setState(() => _pickedPath = picker);
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Scegli file'),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome programma (.ldy)',
                          hintText: 'es. brano1',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final path = _pickedPath;
                        final name = _nameCtrl.text.trim();
                        if (path == null || name.isEmpty) return;
                        setState(() => _loading = true);
                        try {
                          await ctrl.buildAndUploadProgramFromFile(filePath: path, name: name, sampleRateHz: 100, autorun: false);
                          if (mounted) {
                            await _refresh();
                          }
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Genera e carica (.ldy)'),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Il file audio viene analizzato in locale e convertito in un programma persistente.'),
                ],
              ),
            ),
          ),
        if (!AppFeatures.enableOpenProvider || !AppFeatures.enableSpotify) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Sorgenti musicali esterne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('La scelta del servizio (Spotify o provider aperto) verrà configurata più avanti.'
                      ' Per ora è disponibile Mic reattivo e i pattern Sine/Pulse.'),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fallback su dispositivo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Se il dispositivo resta senza app o si riavvia, può eseguire un programma locale (.ldy).'),
                const SizedBox(height: 8),
                Row(children: [
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.list),
                    label: const Text('Ricarica elenco'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(fallbackValue),
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Programma di fallback'),
                      initialValue: fallbackValue,
                      items: _programs.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) async {
                        await ctrl.setFallbackProgram(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (fallbackValue != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ctrl.startProgram(fallbackValue);
                        if (!mounted) return;
                        messenger.showSnackBar(const SnackBar(content: Text('Fallback avviato')));
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Avvia ora'),
                    ),
                ]),
                const SizedBox(height: 8),
                const Text('Nota: al momento la definizione automatica di un pattern audio‑reattivo offline richiede firmware dedicato.'),
              ],
            ),
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        if (_programs.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Nessun programma presente sul dispositivo'),
              subtitle: const Text('Usa "Carica file .ldy" o "Aggiorna lista" dopo averne aggiunti dal firmware.'),
            ),
          ),
        for (final p in _programs)
          Card(
            child: ListTile(
              title: Text(p),
              trailing: Wrap(spacing: 6, children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => ctrl.startProgram(p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async { await ctrl.deleteProgram(p); _refresh(); },
                ),
              ]),
              onTap: () => _nameCtrl.text = p,
            ),
          ),
          ],
        );
      },
    );
  }
}

// Deferred import helper
Future<String?> _pickAudioFile() async {
  try {
    final result = await file_picker.FilePicker.platform.pickFiles(type: file_picker.FileType.audio);
    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path;
    }
  } catch (_) {}
  return null;
}
