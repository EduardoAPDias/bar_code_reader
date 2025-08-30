import 'package:flutter/material.dart';                 // Widgets e UI do Flutter
import 'package:mobile_scanner/mobile_scanner.dart';    // Plugin do leitor de código de barras/QR
import 'package:intl/intl.dart';                        // Formatação (moeda, datas, etc.)

// Tela de leitura (scanner). Usamos StatefulWidget porque o estado muda
// quando um código é lido (exibir resultado, pausar/retomar câmera).
class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  // Controlador do plugin de câmera/scan. Com ele podemos iniciar/parar
  // a câmera e ajustar configurações se quisermos.
  final MobileScannerController _controller = MobileScannerController();

  // Flag para sabermos se estamos "pausados" (após detectar um código).
  // Quando pausado, não processamos novas leituras até o usuário pedir.
  bool _paused = false;

  // Armazenam o último código lido e o texto do preço encontrado.
  String? _lastCode;
  String? _priceText;

  // ==== DADOS MOCKADOS (apenas para protótipo) ====
  // Mapa EAN -> preço. Em produção, substitua por consulta ao seu banco (Supabase).
  final Map<String, double> _mockPrices = {
    '7891000055123': 9.99,
    '7894900011517': 4.59,
    '7896004000018': 12.90,
  };

  // Formata um double como moeda BRL (ex.: R$ 9,99).
  String _formatPrice(double value) {
    final f = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return f.format(value);
  }

  // Busca o preço a partir do EAN usando o mock.
  // Se não existir no mapa, retorna "Produto não encontrado".
  String _lookupPrice(String ean) {
    final price = _mockPrices[ean];
    if (price == null) return 'Produto não encontrado';
    return _formatPrice(price);
  }

  // Sempre que um controller/stream/câmera é criado, é boa prática liberar
  // os recursos no dispose para evitar vazamento de memória.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Callback disparado toda vez que o plugin detecta 1 ou mais códigos.
  // Recebemos um BarcodeCapture com a lista de códigos no frame atual.
  Future<void> _onDetect(BarcodeCapture capture) async {
    // Se já estamos pausados (acabamos de ler algo), ignoramos novas leituras.
    if (_paused) return;

    // Segurança: pode acontecer de vir vazio.
    if (capture.barcodes.isEmpty) return;

    // Pegamos o primeiro código detectado (para protótipo é suficiente).
    final b = capture.barcodes.first;

    // rawValue: valor bruto decodificado. displayValue: representação amigável.
    final code = b.rawValue ?? b.displayValue;

    // Se por algum motivo não conseguimos extrair a string, saímos.
    if (code == null || code.isEmpty) return;

    // Atualizamos a UI:
    // - marcamos como pausado (não ler mais nada por enquanto)
    // - guardamos o código lido
    // - calculamos o texto do preço (mock ou "não encontrado")
    setState(() {
      _paused = true;
      _lastCode = code;
      _priceText = _lookupPrice(code);
    });

    // Paramos a câmera (opcional) para evitar leituras repetidas
    // enquanto mostramos o resultado.
    await _controller.stop();
  }

  // Retoma a leitura: limpa o resultado mostrado e liga a câmera de novo.
  Future<void> _resumeScanning() async {
    setState(() {
      _paused = false;
      _lastCode = null;
      _priceText = null;
    });
    await _controller.start(); // Reinicia a câmera/leitor.
  }

  @override
  Widget build(BuildContext context) {
    // Pegamos o tamanho da tela para dimensionar uma "moldura" central.
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.75; // quadrado com 75% da largura da tela

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        backgroundColor: const Color.fromRGBO(77, 203, 239, 1),
      ),
      body: Stack(
        children: [
          // 1) Câmera + detecção
          // O MobileScanner renderiza a imagem da câmera e faz a detecção.
          // onDetect é chamado toda vez que códigos forem reconhecidos.
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 2) Moldura visual (overlay) — apenas estética/guia para o usuário.
          // IgnorePointer garante que toques passem "através" do overlay.
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

          // 3) Painel inferior com o resultado (só aparece se já lemos um código).
          if (_lastCode != null) ...[
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65), // fundo semi-transparente
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ocupa só o necessário
                  children: [
                    // Mostra o EAN/código detectado
                    Text(
                      'Código: $_lastCode',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    // Mostra o preço formatado ou "não encontrado"
                    Text(
                      _priceText ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botão para retomar a leitura (liga a câmera novamente)
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
