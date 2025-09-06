import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço simples para centralizar chamadas ao Supabase.
/// Mantém a página "scan" enxuta e facilita evoluções futuras.
class DbService {
  final SupabaseClient _client;
  DbService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  /// Busca um produto pelo código de barras.
  /// Retorna um map com as colunas selecionadas ou null se não encontrar.
  Future<Map<String, dynamic>?> getProdutoByBarcode(String ean) async {
    if (ean.trim().isEmpty) return null;

    // Ajuste as colunas conforme seu schema.
    final data = await _client
        .from('produto')
        .select('nome_produto, codigo_barras, preco_venda')
        .eq('codigo_barras', ean.trim())
        .maybeSingle();

    return data; // null = não achou
  }
}
