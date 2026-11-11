import 'package:flutter/material.dart';
import '../helpers/user_info.dart';
import '../model/transaction.dart';
import '../service/transaction_service.dart';
import '../utils/app_utils.dart';
import '../widget/guest_login_placeholder.dart';

/// Halaman Riwayat Struk Transaksi yang menampilkan bukti/nota transaksi pembelian mobil.
class StrukPage extends StatefulWidget {
  /// Membuat instance [StrukPage].
  const StrukPage({super.key});

  @override
  State<StrukPage> createState() => _StrukPageState();
}

/// State pengelola riwayat transaksi dan penyaringan struk berdasarkan user/admin pada [StrukPage].
class _StrukPageState extends State<StrukPage> {
  List<Transaction> transactions = [];
  bool isAdmin = false;
  bool isLoading = true;
  bool isGuest = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);
    final userId = await UserInfo().getUserID();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        setState(() {
          isGuest = true;
          isLoading = false;
        });
      }
      return;
    }

    try {
      final role = await UserInfo().getRole();
      final email = await UserInfo().getEmail() ?? '';
      final allTx = await TransactionService().listData();

      bool adminRole = role == 'admin';

      List<Transaction> filtered;
      if (adminRole) {
        filtered = allTx;
      } else {
        filtered = allTx.where((tx) {
          if (userId.isNotEmpty && tx.userId == userId) return true;
          if (email.isNotEmpty && tx.buyerEmail.toLowerCase() == email.toLowerCase()) return true;
          return false;
        }).toList();
      }

      setState(() {
        transactions = filtered.reversed.toList();
        isAdmin = adminRole;
        isGuest = false;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  String _getMonthYearHeader(String dateStr) {
    if (dateStr.isEmpty) return 'Riwayat Transaksi';
    try {
      final clean = dateStr.trim();
      final datePart = clean.split(' ').first;
      final parts = datePart.split('-');
      if (parts.length >= 2) {
        final year = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        const months = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];
        if (monthNum >= 1 && monthNum <= 12) {
          return '${months[monthNum - 1]} $year';
        }
      }
    } catch (_) {}
    return 'Riwayat Transaksi';
  }

  Map<String, List<Transaction>> get _groupedTransactions {
    final Map<String, List<Transaction>> map = {};
    for (var tx in transactions) {
      final header = _getMonthYearHeader(tx.date);
      map.putIfAbsent(header, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return const GuestLoginPlaceholder(
        title: 'Riwayat Struk',
        message: 'Silakan login terlebih dahulu untuk melihat riwayat transaksi Anda.',
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 15),
                        const Text('Gagal Terhubung ke Jaringan',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () { setState(() => _error = null); _loadTransactions(); },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A469D), foregroundColor: Colors.white),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada riwayat transaksi', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView(
                    padding: const EdgeInsets.all(15),
                    children: _groupedTransactions.entries.map((entry) {
                      final monthHeader = entry.key;
                      final txList = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: Color(0xFF1A469D), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  monthHeader,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                                ),
                              ],
                            ),
                          ),
                          ...txList.map((tx) {
                            final itemsList = tx.itemsDetails.isNotEmpty
                                ? tx.itemsDetails.split('\n').where((s) => s.trim().isNotEmpty).toList()
                                : [];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'No. Resi: ${tx.resi}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF9C4),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                tx.date,
                                                style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 30),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text('Pembeli: ${tx.buyerName}', style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('Email: ${tx.buyerEmail}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 15),
                                    Text(
                                      'Item yang dibeli (${tx.totalItem} Item):',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8),
                                    if (itemsList.isNotEmpty)
                                      ...itemsList.map(
                                        (itemDetail) => Padding(
                                          padding: const EdgeInsets.only(left: 0, bottom: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  itemDetail,
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Mobil', style: TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    const Divider(height: 30),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Pembayaran',
                                          style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          AppUtils.formatRupiah(tx.totalPrice),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFF1A469D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
