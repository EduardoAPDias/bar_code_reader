import 'package:flutter/material.dart';                 // Widgets/UI
import 'package:mobile_scanner/mobile_scanner.dart';    // Leitor de código de barras
import 'package:intl/intl.dart';                        // Formatação BRL
import '../services/db.dart';                           // Nosso serviço de banco

/// Tela de leitura (scanner) conectada ao Supabase.
/// Mantém o mesmo comportamento do mock, mas consulta o DB de verdade.
class Scan extends StatefulWidget {
  const Scan({super.key});
  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  final MobileScannerController _controller = MobileScannerController();
  final DbService _db = DbService(); // serviço do Supabase

  bool _paused = false;      // para pausar novas leituras enquanto mostramos o resultado
  String? _lastCode;         // último EAN lido
  String? _priceText;        // texto exibido (preço formatado ou mensagem)

  // Formata double como moeda BRL (ex.: R$ 9,99).
  String _formatPrice(num value) {
    final f = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return f.format(value);
  }

  /// Consulta o banco e retorna o texto a ser exibido no painel inferior.
  /// - Se achar o produto: retorna preço formatado
  /// - Se não achar: "Produto não encontrado"
  /// - Se der erro: mensagem amigável
  Future<String> _lookupPriceFromDb(String ean) async {
    try {
      final row = await _db.getProdutoByBarcode(ean);
      if (row == null) return 'Produto não encontrado';

      final preco = row['preco_venda'];
      if (preco is num) return _formatPrice(preco);

      // Caso a coluna exista mas venha nula ou tipo inesperado
      return 'Preço indisponível';
    } catch (e) {
      return 'Erro ao consultar: $e';
    }
  }

  // Libera a câmera ao sair da tela
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Callback disparado quando o scanner detecta códigos.
  /// Mantemos a lógica: pausa, mostra o código, busca no DB e mostra o resultado.
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_paused) return;                   // já pausado? ignora
    if (capture.barcodes.isEmpty) return;  // nada detectado? sai

    final b = capture.barcodes.first;
    final code = b.rawValue ?? b.displayValue;
    if (code == null || code.isEmpty) return;

    // Pausa a leitura visualmente, exibe código e um "carregando..."
    setState(() {
      _paused = true;
      _lastCode = code;
      _priceText = 'Buscando preço...';
    });

    // Opcional: parar a câmera para não ficar detectando de novo.
    // (Se preferir, comente a linha abaixo e apenas confie na flag _paused)
    await _controller.stop();

    // Busca no Supabase e atualiza o texto do preço
    final resultText = await _lookupPriceFromDb(code);
    if (!mounted) return;
    setState(() {
      _priceText = resultText;
    });
  }

  /// Retoma a leitura: limpa painel e religa a câmera.
  Future<void> _resumeScanning() async {
    setState(() {
      _paused = false;
      _lastCode = null;
      _priceText = null;
    });
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.75; // moldura 75% da largura

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        backgroundColor: const Color.fromRGBO(77, 203, 239, 1),
      ),
      body: Stack(
        children: [
          // 1) Câmera + detecção
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 2) Moldura/overlay
          IgnorePointer(
            child: Center(
              child: Container(
                width: frameSize,
                height: frameSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 3) Painel inferior com resultado após leitura
          if (_lastCode != null) ...[
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.65)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Código: $_lastCode',
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      _priceText ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _resumeScanning,
                      child: const Text('Ler outro'),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
