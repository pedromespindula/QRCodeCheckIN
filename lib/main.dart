import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const MeuApp());

const String nomeEvento = 'Semana da Computação 2026';
const String imagemEvento = 'https://picsum.photos/seed/flutterday/600/300';

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nomeEvento,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.lightBlueAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const PaginaEvento(),
    );
  }
}

class PaginaEvento extends StatefulWidget {
  const PaginaEvento({super.key});

  @override
  State<PaginaEvento> createState() => _PaginaEventoState();
}

class _PaginaEventoState extends State<PaginaEvento> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  String? _conteudoQr;
  String _nomeIngresso = '';
  String _emailIngresso = '';
  bool _lendo = false;
  final List<String> _presentes = [];
  IconData? _resultadoIcone;
  Color? _resultadoCor;
  String _resultadoTexto = '';

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _gerarIngresso() {
    final nome = _nomeController.text.trim().replaceAll('|', ' ');
    final email = _emailController.text.trim().replaceAll('|', ' ');
    setState(() {
      _nomeIngresso = nome;
      _emailIngresso = email;
      _conteudoQr = 'CHECKIN|$nome|$email';
    });
  }

  void _validar(String codigo) {
    final partes = codigo.split('|');
    final ingressoValido =
        partes.length == 3 && partes[0] == 'CHECKIN' && partes[1].trim().isNotEmpty;

    setState(() {
      _lendo = false;
      if (!ingressoValido) {
        _resultadoIcone = Icons.cancel;
        _resultadoCor = Colors.red;
        _resultadoTexto = '✖ QR inválido';
      } else if (_presentes.contains(partes[1])) {
        _resultadoIcone = Icons.warning_amber_rounded;
        _resultadoCor = Colors.orange;
        _resultadoTexto = '⚠ ${partes[1]} já fez check-in';
      } else {
        _presentes.add(partes[1]);
        _resultadoIcone = Icons.check_circle;
        _resultadoCor = Colors.green;
        _resultadoTexto = '✔ Check-in confirmado: ${partes[1]}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(nomeEvento)),
      body: _lendo ? _buildLeitor() : _buildPrincipal(),
    );
  }

  Widget _buildLeitor() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: (BarcodeCapture capture) {
              if (!_lendo) return;
              for (final barcode in capture.barcodes) {
                final valor = barcode.rawValue;
                if (valor != null) {
                  _validar(valor);
                  return;
                }
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton(
            onPressed: () => setState(() => _lendo = false),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }
  Widget _buildPrincipal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome do participante',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed:
                _nomeController.text.trim().isEmpty ? null : _gerarIngresso,
            child: const Text('Gerar ingresso'),
          ),
          if (_conteudoQr != null) ...[
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Image.network(
                    imagemEvento,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: Colors.lightBlueAccent.shade100,
                      alignment: Alignment.center,
                      child: const Icon(Icons.event, size: 48),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _nomeIngresso,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(_emailIngresso),
                        const SizedBox(height: 12),
                        QrImageView(
                          data: _conteudoQr!,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 32),
          FilledButton.tonalIcon(
            onPressed: () => setState(() => _lendo = true),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Ler ingresso'),
          ),
          if (_resultadoIcone != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_resultadoIcone, color: _resultadoCor, size: 32),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _resultadoTexto,
                    style: TextStyle(
                      color: _resultadoCor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Presentes: ${_presentes.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final nome in _presentes) Text('• $nome'),
            ],
          ),
        ],
      ),
    );
  }
}
