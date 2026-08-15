import 'package:flutter/material.dart';

class BuatOrderDialog extends StatefulWidget {
  final VoidCallback onOrderCreated;

  const BuatOrderDialog({super.key, required this.onOrderCreated});

  @override
  State<BuatOrderDialog> createState() => _BuatOrderDialogState();
}

class _BuatOrderDialogState extends State<BuatOrderDialog> {
  static const Color _bgDark = Color(0xFFFAF5F7);       
  static const Color _cardDark = Color(0xFFFCE7F3);     
  static const Color _goldAccent = Color(0xFFEC4899);   
  static const Color _textBlack = Color(0xFF111827);

  	// ============================================================
  	    // STATE FORM TRANSAKSI
  	    // ============================================================
  	    
  	    // Pelanggan yang sedang dipilih.
  	    Map<String, dynamic>? _selectedCustomer;
  	    
  	    // Daftar layanan yang dipilih.
  	    final List<Map<String, dynamic>> _selectedServices = [];

  	    // Catatan transaksi
  	    String _note = '';
  	    
  	    // Aroma parfum.
  	    String _selectedParfum = 'Sakura';
  	    
  	    // Persentase diskon.
  	    double _selectedDiscount = 0; 

  	    // Data Top Customers yang tampil di Menu Transaksi.
  	    final List<Map<String, String>> _topCustomers = [];   

	// ============================================================
	// FORM TRANSAKSI BARU
	// ============================================================
	// Fungsi ini menggantikan form lama yang hanya punya:
	// Nama Pelanggan + No HP + Total Biaya.
	//
	// Sekarang form memiliki:
	// 1. Pelanggan + pencarian
	// 2. Layanan + pencarian
	// 3. Catatan
	// 4. Aroma parfum
	// 5. Diskon
	// 6. Perhitungan subtotal, diskon, total
	// 7. Tombol PESAN
	// ============================================================
	
	// ============================================================
	// FORM TRANSAKSI BARU
	// ============================================================
	//
	// UI baru mengikuti desain:
	// - Dialog floating
	// - Rounded corner
	// - Background soft lavender
	// - Pelanggan + tombol CARI
	// - Keranjang layanan
	// - Tambah layanan
	// - Aroma parfum
	// - Catatan
	// - Diskon
	// - Total price
	// - Tombol PESAN
	//
	// ============================================================
	
	void _showFormOrder(BuildContext context, String type) {
	
	  // ==========================================================
	  // DATA CUSTOMER SEMENTARA
	  // ==========================================================
	  //
	  // Nanti bagian ini bisa kita sambungkan langsung
	  // ke tabel customers di Supabase.
	  //
	  final List<Map<String, dynamic>> customers = [
	    {
	      'name': 'Aila Nasuha',
	      'phone': '0812xxxx',
	      'address': 'Jl. Mawar',
	    },
	    {
	      'name': 'Bu Ratna',
	      'phone': '081234567890',
	      'address': 'Jl. Mawar',
	    },
	    {
	      'name': 'Pak Hendra',
	      'phone': '082233445566',
	      'address': 'Jl. Melati',
	    },
	    {
	      'name': 'Siti Nurhaliza',
	      'phone': '083344556677',
	      'address': 'Jl. Kenanga',
	    },
	  ];
	
	  // ==========================================================
	  // DATA LAYANAN SEMENTARA
	  // ==========================================================
	  //
	  // Nanti bisa kita ambil dari tabel services Supabase.
	  //
	  final List<Map<String, dynamic>> services = [
	    {
	      'name': 'Setrika',
	      'unit': 'Kg',
	      'price': 4000.0,
	    },
	    {
	      'name': 'Cuci Kering',
	      'unit': 'Kg',
	      'price': 7000.0,
	    },
	    {
	      'name': 'Cuci Lipat',
	      'unit': 'Kg',
	      'price': 6000.0,
	    },
	    {
	      'name': 'Cuci Setrika',
	      'unit': 'Kg',
	      'price': 10000.0,
	    },
	    {
	      'name': 'Cuci Selimut',
	      'unit': 'Pcs',
	      'price': 15000.0,
	    },
	    {
	      'name': 'Cuci Bed Cover',
	      'unit': 'Pcs',
	      'price': 25000.0,
	    },
	    {
	      'name': 'Cuci Sepatu',
	      'unit': 'Pcs',
	      'price': 20000.0,
	    },
	  ];
	
	  // ==========================================================
	  // CONTROLLER CATATAN
	  // ==========================================================
	
	  final catatanController = TextEditingController();
	
	  // ==========================================================
	  // SHOW DIALOG
	  // ==========================================================
	  //
	  // Kita sengaja menggunakan showDialog(),
	  // bukan showModalBottomSheet().
	  //
	  // Hasilnya lebih mirip dengan desain SS:
	  // dialog berada di tengah layar.
	  //
	  showDialog(
	    context: context,
	    barrierDismissible: false,
	    builder: (dialogContext) {
	
	      // ========================================================
	      // STATE FORM
	      // ========================================================
	
	      Map<String, dynamic>? selectedCustomer;
	
	      final List<Map<String, dynamic>> selectedServices = [];
	
	      String selectedParfum = 'Standard / Original';
	
	      double selectedDiscount = 0;
	
	      // ========================================================
	      // STATEFUL BUILDER
	      // ========================================================
	      //
	      // Semua perubahan pada form akan refresh UI dialog.
	      //
	      return StatefulBuilder(
	        builder: (context, setModalState) {
	
	          // ====================================================
	          // FORMAT RUPIAH
	          // ====================================================
	
	          String formatRupiah(double value) {
	            final number = value.round().toString();
	
	            final chars =
	                number.split('').reversed.toList();
	
	            final chunks = <String>[];
	
	            for (int i = 0; i < chars.length; i += 3) {
	              final end = (i + 3 < chars.length)
	                  ? i + 3
	                  : chars.length;
	
	              chunks.add(
	                chars.sublist(i, end).reversed.join(),
	              );
	            }
	
	            return 'Rp ${chunks.reversed.join('.')}';
	          }
	
	          // ====================================================
	          // HITUNG SUBTOTAL
	          // ====================================================
	          //
	          // Rumus:
	          //
	          // subtotal =
	          // harga × quantity
	          //
	          // semua layanan dijumlahkan.
	          //
	          double calculateSubtotal() {
	            double subtotal = 0;
	
	            for (final service in selectedServices) {
	              final price =
	                  (service['price'] as num).toDouble();
	
	              final quantity =
	                  (service['quantity'] as num).toDouble();
	
	              subtotal += price * quantity;
	            }
	
	            return subtotal;
	          }
	
	          // ====================================================
	          // HITUNG DISKON
	          // ====================================================
	
	          double calculateDiscount(double subtotal) {
	            return subtotal * selectedDiscount / 100;
	          }
	
	          // ====================================================
	          // HITUNG TOTAL
	          // ====================================================
	          //
	          // total = subtotal - diskon
	          //
	          double calculateTotal() {
	            final subtotal = calculateSubtotal();
	
	            final discount =
	                calculateDiscount(subtotal);
	
	            return subtotal - discount;
	          }
	
	          // ====================================================
	          // SEARCH CUSTOMER
	          // ====================================================
	
	          Future<void> searchCustomer() async {
	
	            final result =
	                await showDialog<Map<String, dynamic>>(
	              context: context,
	
	              builder: (searchContext) {
	
	                final searchController =
	                    TextEditingController();
	
	                return StatefulBuilder(
	                  builder: (
	                    searchContext,
	                    setSearchState,
	                  ) {
	
	                    final keyword =
	                        searchController.text
	                            .toLowerCase()
	                            .trim();
	
	                    final filteredCustomers =
	                        customers.where((customer) {
	
	                      final name =
	                          customer['name']
	                              .toString()
	                              .toLowerCase();
	
	                      final phone =
	                          customer['phone']
	                              .toString()
	                              .toLowerCase();
	
	                      return name.contains(keyword) ||
	                          phone.contains(keyword);
	
	                    }).toList();
	
	                    return AlertDialog(
	                      backgroundColor: _bgDark,
	
	                      shape:
	                          RoundedRectangleBorder(
	                        borderRadius:
	                            BorderRadius.circular(20),
	                      ),
	
	                      title: const Text(
	                        'Cari Pelanggan',
	                        style: TextStyle(
	                          fontWeight: FontWeight.bold,
	                          color: _textBlack,
	                        ),
	                      ),
	
	                      content: SizedBox(
	                        width: 400,
	                        height: 380,
	
	                        child: Column(
	                          children: [
	
	                            // ==================================
	                            // SEARCH BOX
	                            // ==================================
	
	                            TextField(
	                              controller:
	                                  searchController,
	
	                              autofocus: true,
	
	                              onChanged: (_) {
	                                setSearchState(() {});
	                              },
	
	                              decoration:
	                                  InputDecoration(
	                                hintText:
	                                    'Nama / No. HP',
	
	                                prefixIcon:
	                                    const Icon(
	                                  Icons.search_rounded,
	                                ),
	
	                                filled: true,
	
	                                fillColor:
	                                    Colors.white,
	
	                                border:
	                                    OutlineInputBorder(
	                                  borderRadius:
	                                      BorderRadius.circular(
	                                    12,
	                                  ),
	
	                                  borderSide:
	                                      BorderSide.none,
	                                ),
	                              ),
	                            ),
	
	                            const SizedBox(
	                              height: 12,
	                            ),
	
	                            // ==================================
	                            // CUSTOMER LIST
	                            // ==================================
	
	                            Expanded(
	                              child:
	                                  ListView.builder(
	                                itemCount:
	                                    filteredCustomers
	                                        .length,
	
	                                itemBuilder:
	                                    (context, index) {
	
	                                  final customer =
	                                      filteredCustomers[
	                                          index];
	
	                                  return ListTile(
	                                    shape:
	                                        RoundedRectangleBorder(
	                                      borderRadius:
	                                          BorderRadius
	                                              .circular(
	                                        12,
	                                      ),
	                                    ),
	
	                                    leading:
	                                        CircleAvatar(
	                                      backgroundColor:
	                                          _cardDark,
	
	                                      child:
	                                          const Icon(
	                                        Icons
	                                            .person_rounded,
	                                        color:
	                                            _goldAccent,
	                                      ),
	                                    ),
	
	                                    title: Text(
	                                      customer['name'],
	                                      style:
	                                          const TextStyle(
	                                        fontWeight:
	                                            FontWeight.bold,
	                                      ),
	                                    ),
	
	                                    subtitle: Text(
	                                      '${customer['phone']} • ${customer['address']}',
	                                    ),
	
	                                    onTap: () {
	                                      Navigator.pop(
	                                        searchContext,
	                                        customer,
	                                      );
	                                    },
	                                  );
	                                },
	                              ),
	                            ),
	                          ],
	                        ),
	                      ),
	                    );
	                  },
	                );
	              },
	            );
	
	            // ================================================
	            // CUSTOMER TERPILIH
	            // ================================================
	
	            if (result != null) {
	              setModalState(() {
	                selectedCustomer = result;
	              });
	            }
	          }
	
	          // ====================================================
	          // SEARCH / TAMBAH LAYANAN
	          // ====================================================
	
	          Future<void> searchService() async {
	
	            final result =
	                await showDialog<Map<String, dynamic>>(
	              context: context,
	
	              builder: (searchContext) {
	
	                final searchController =
	                    TextEditingController();
	
	                return StatefulBuilder(
	                  builder: (
	                    searchContext,
	                    setSearchState,
	                  ) {
	
	                    final keyword =
	                        searchController.text
	                            .toLowerCase()
	                            .trim();
	
	                    final filteredServices =
	                        services.where((service) {
	
	                      final name =
	                          service['name']
	                              .toString()
	                              .toLowerCase();
	
	                      return name.contains(keyword);
	
	                    }).toList();
	
	                    return AlertDialog(
	                      backgroundColor: _bgDark,
	
	                      shape:
	                          RoundedRectangleBorder(
	                        borderRadius:
	                            BorderRadius.circular(20),
	                      ),
	
	                      title: const Text(
	                        'Tambah Layanan',
	                        style: TextStyle(
	                          fontWeight: FontWeight.bold,
	                          color: _textBlack,
	                        ),
	                      ),
	
	                      content: SizedBox(
	                        width: 400,
	                        height: 380,
	
	                        child: Column(
	                          children: [
	
	                            // ==================================
	                            // SEARCH LAYANAN
	                            // ==================================
	
	                            TextField(
	                              controller:
	                                  searchController,
	
	                              autofocus: true,
	
	                              onChanged: (_) {
	                                setSearchState(() {});
	                              },
	
	                              decoration:
	                                  InputDecoration(
	                                hintText:
	                                    'Cari layanan...',
	
	                                prefixIcon:
	                                    const Icon(
	                                  Icons.search_rounded,
	                                ),
	
	                                filled: true,
	
	                                fillColor:
	                                    Colors.white,
	
	                                border:
	                                    OutlineInputBorder(
	                                  borderRadius:
	                                      BorderRadius.circular(
	                                    12,
	                                  ),
	
	                                  borderSide:
	                                      BorderSide.none,
	                                ),
	                              ),
	                            ),
	
	                            const SizedBox(
	                              height: 12,
	                            ),
	
	                            // ==================================
	                            // LIST LAYANAN
	                            // ==================================
	
	                            Expanded(
	                              child:
	                                  ListView.builder(
	                                itemCount:
	                                    filteredServices
	                                        .length,
	
	                                itemBuilder:
	                                    (context, index) {
	
	                                  final service =
	                                      filteredServices[
	                                          index];
	
	                                  return ListTile(
	                                    shape:
	                                        RoundedRectangleBorder(
	                                      borderRadius:
	                                          BorderRadius
	                                              .circular(
	                                        12,
	                                      ),
	                                    ),
	
	                                    leading:
	                                        Container(
	                                      padding:
	                                          const EdgeInsets
	                                              .all(8),
	
	                                      decoration:
	                                          BoxDecoration(
	                                        color:
	                                            _cardDark,
	
	                                        borderRadius:
	                                            BorderRadius
	                                                .circular(
	                                          10,
	                                        ),
	                                      ),
	
	                                      child:
	                                          const Icon(
	                                        Icons
	                                            .local_laundry_service_rounded,
	                                        color:
	                                            _goldAccent,
	                                      ),
	                                    ),
	
	                                    title: Text(
	                                      service['name'],
	                                      style:
	                                          const TextStyle(
	                                        fontWeight:
	                                            FontWeight.bold,
	                                      ),
	                                    ),
	
	                                    subtitle: Text(
	                                      '${formatRupiah((service['price'] as num).toDouble())} / ${service['unit']}',
	                                    ),
	
	                                    trailing:
	                                        const Icon(
	                                      Icons
	                                          .add_circle_outline_rounded,
	                                      color:
	                                          _goldAccent,
	                                    ),
	
	                                    onTap: () {
	                                      Navigator.pop(
	                                        searchContext,
	                                        service,
	                                      );
	                                    },
	                                  );
	                                },
	                              ),
	                            ),
	                          ],
	                        ),
	                      ),
	                    );
	                  },
	                );
	              },
	            );
	
	            // ==================================================
	            // MASUKKAN LAYANAN KE KERANJANG
	            // ==================================================
	
	            if (result != null) {
	
	              setModalState(() {
	
	                final existingIndex =
	                    selectedServices.indexWhere(
	                  (item) =>
	                      item['name'] ==
	                      result['name'],
	                );
	
	                if (existingIndex >= 0) {
	
	                  // Kalau layanan sudah ada,
	                  // quantity ditambah 1.
	                  final oldQuantity =
	                      (selectedServices[
	                              existingIndex]
	                          ['quantity'] as num)
	                      .toDouble();
	
	                  selectedServices[
	                          existingIndex]
	                      ['quantity'] =
	                      oldQuantity + 1;
	
	                } else {
	
	                  // Kalau belum ada,
	                  // masukkan layanan baru.
	                  selectedServices.add({
	                    ...result,
	                    'quantity': 1.0,
	                  });
	                }
	              });
	            }
	          }
	
	          // ====================================================
	          // NILAI TRANSAKSI
	          // ====================================================
	
	          final subtotal =
	              calculateSubtotal();
	
	          final discount =
	              calculateDiscount(subtotal);
	
	          final total =
	              calculateTotal();
	
	          // ====================================================
	          // UI FORM TRANSAKSI
	          // ====================================================
	
	          return Dialog(
	            backgroundColor: Colors.transparent,
	
	            insetPadding:
	                const EdgeInsets.symmetric(
	              horizontal: 18,
	              vertical: 24,
	            ),
	
	            child: ConstrainedBox(
	              constraints:
	                  const BoxConstraints(
	                maxWidth: 470,
	                maxHeight: 760,
	              ),
	
	              child: Container(
	
	                decoration:
	                    BoxDecoration(
	
	                  // ==========================================
	                  // BACKGROUND UTAMA
	                  // ==========================================
	
	                  color: const Color(
	                    0xFFF5F0F7,
	                  ),
	
	                  borderRadius:
	                      BorderRadius.circular(24),
	
	                  boxShadow: [
	                    BoxShadow(
	                      color:
	                          Colors.black.withOpacity(
	                        0.18,
	                      ),
	
	                      blurRadius: 30,
	
	                      offset:
	                          const Offset(0, 12),
	                    ),
	                  ],
	                ),
	
	                child: SafeArea(
	                  child: SingleChildScrollView(
	
	                    padding:
	                        const EdgeInsets.fromLTRB(
	                      20,
	                      12,
	                      20,
	                      18,
	                    ),
	
	                    child: Column(
	                      crossAxisAlignment:
	                          CrossAxisAlignment.start,
	
	                      children: [
	
	                        // ==================================================
	                        // 1. HEADER
	                        // ==================================================
	
	                        Row(
	                          mainAxisAlignment:
	                              MainAxisAlignment
	                                  .spaceBetween,
	
	                          children: [
	
	                            const Text(
	                              'Form Transaksi',
	                              style: TextStyle(
	                                fontSize: 17,
	                                fontWeight:
	                                    FontWeight.w600,
	                                color:
	                                    _textBlack,
	                              ),
	                            ),
	
	                            IconButton(
	                              visualDensity:
	                                  VisualDensity
	                                      .compact,
	
	                              icon:
	                                  const Icon(
	                                Icons.close_rounded,
	                                color:
	                                    Colors.black54,
	                              ),
	
	                              onPressed: () {
	                                Navigator.pop(
	                                  dialogContext,
	                                );
	                              },
	                            ),
	                          ],
	                        ),
	
	                        const SizedBox(
	                          height: 4,
	                        ),
	
	                        // ==================================================
	                        // 2. PELANGGAN
	                        // ==================================================
	
	                        const Text(
	                          'Pelanggan',
	                          style: TextStyle(
	                            fontSize: 11,
	                            color:
	                                Colors.black45,
	                            fontWeight:
	                                FontWeight.w500,
	                          ),
	                        ),
	
	                        const SizedBox(
	                          height: 5,
	                        ),
	
	                        Container(
	                          height: 58,
	
	                          padding:
	                              const EdgeInsets
	                                  .symmetric(
	                            horizontal: 12,
	                          ),
	
	                          decoration:
	                              BoxDecoration(
	                            color:
	                                Colors.white,
	
	                            borderRadius:
	                                BorderRadius.circular(
	                              13,
	                            ),
	                          ),
	
	                          child: Row(
	                            children: [
	
	                              // ==========================================
	                              // CUSTOMER INFO
	                              // ==========================================
	
	                              Expanded(
	                                child:
	                                    selectedCustomer ==
	                                            null
	
	                                        ? const Text(
	                                            'Pilih pelanggan...',
	                                            style:
	                                                TextStyle(
	                                              color:
	                                                  Colors.black38,
	                                              fontSize:
	                                                  12,
	                                            ),
	                                          )
	
	                                        : Column(
	                                            mainAxisAlignment:
	                                                MainAxisAlignment
	                                                    .center,
	
	                                            crossAxisAlignment:
	                                                CrossAxisAlignment
	                                                    .start,
	
	                                            children: [
	
	                                              Text(
	                                                selectedCustomer![
	                                                    'name'],
	                                                style:
	                                                    const TextStyle(
	                                                  fontWeight:
	                                                      FontWeight.w600,
	                                                  fontSize:
	                                                      12,
	                                                ),
	                                              ),
	
	                                              const SizedBox(
	                                                height: 2,
	                                              ),
	
	                                              Text(
	                                                selectedCustomer![
	                                                    'phone'],
	                                                style:
	                                                    const TextStyle(
	                                                  color:
	                                                      Colors.black45,
	                                                  fontSize:
	                                                      10,
	                                                ),
	                                              ),
	                                            ],
	                                          ),
	                              ),
	
	                              // ==========================================
	                              // TOMBOL CARI
	                              // ==========================================
	
	                              SizedBox(
	                                height: 32,
	
	                                child:
	                                    ElevatedButton(
	                                  onPressed:
	                                      searchCustomer,
	
	                                  style:
	                                      ElevatedButton
	                                          .styleFrom(
	                                    backgroundColor:
	                                        const Color(
	                                      0xFF2563EB,
	                                    ),
	
	                                    foregroundColor:
	                                        Colors.white,
	
	                                    elevation: 0,
	
	                                    padding:
	                                        const EdgeInsets
	                                            .symmetric(
	                                      horizontal: 14,
	                                    ),
	
	                                    shape:
	                                        RoundedRectangleBorder(
	                                      borderRadius:
	                                          BorderRadius
	                                              .circular(
	                                        9,
	                                      ),
	                                    ),
	                                  ),
	
	                                  child:
	                                      const Text(
	                                    'CARI',
	                                    style:
	                                        TextStyle(
	                                      fontSize: 10,
	                                      fontWeight:
	                                          FontWeight.bold,
	                                    ),
	                                  ),
	                                ),
	                              ),
	                            ],
	                          ),
	                        ),
	
	                        const SizedBox(
	                          height: 12,
	                        ),
	
	                        // ==================================================
	                        // 3. DAFTAR LAYANAN
	                        // ==================================================
	
	                        Row(
	                          mainAxisAlignment:
	                              MainAxisAlignment
	                                  .spaceBetween,
	
	                          children: [
	
	                            const Text(
	                              'Daftar Layanan (Keranjang)',
	                              style: TextStyle(
	                                fontSize: 11,
	                                color:
	                                    Colors.black45,
	                                fontWeight:
	                                    FontWeight.w500,
	                              ),
	                            ),
	
	                            TextButton.icon(
	                              onPressed:
	                                  searchService,
	
	                              style:
	                                  TextButton.styleFrom(
	                                foregroundColor:
	                                    const Color(
	                                  0xFF159A9C,
	                                ),
	
	                                padding:
	                                    EdgeInsets.zero,
	
	                                minimumSize:
	                                    Size.zero,
	
	                                tapTargetSize:
	                                    MaterialTapTargetSize
	                                        .shrinkWrap,
	                              ),
	
	                              icon:
	                                  const Icon(
	                                Icons
	                                    .add_circle_outline_rounded,
	                                size: 16,
	                              ),
	
	                              label:
	                                  const Text(
	                                '+ Tambah Layanan',
	                                style:
	                                    TextStyle(
	                                  fontSize: 10,
	                                  fontWeight:
	                                      FontWeight.w600,
	                                ),
	                              ),
	                            ),
	                          ],
	                        ),
	
	                        const SizedBox(
	                          height: 4,
	                        ),
	
	                        // ==================================================
	                        // CONTAINER KERANJANG
	                        // ==================================================
	                        //
	                        // Tingginya dibatasi.
	                        // Kalau layanan banyak, bagian ini scroll.
	                        //
	
	                        Container(
	
	                          constraints:
	                              const BoxConstraints(
	                            minHeight: 90,
	                            maxHeight: 220,
	                          ),
	
	                          width:
	                              double.infinity,
	
	                          padding:
	                              const EdgeInsets
	                                  .all(10),
	
	                          decoration:
	                              BoxDecoration(
	                            color:
	                                Colors.white,
	
	                            borderRadius:
	                                BorderRadius.circular(
	                              14,
	                            ),
	                          ),
	
	                          child:
	                              selectedServices.isEmpty
	
	                                  // ========================================
	                                  // BELUM ADA LAYANAN
	                                  // ========================================
	
	                                  ? InkWell(
	                                      onTap:
	                                          searchService,
	
	                                      borderRadius:
	                                          BorderRadius
	                                              .circular(
	                                        12,
	                                      ),
	
	                                      child:
	                                          const Center(
	                                        child:
	                                            Text(
	                                          'Belum ada layanan.\nTekan "+ Tambah Layanan"',
	                                          textAlign:
	                                              TextAlign
	                                                  .center,
	                                          style:
	                                              TextStyle(
	                                            color:
	                                                Colors.black38,
	                                            fontSize:
	                                                11,
	                                          ),
	                                        ),
	                                      ),
	                                    )
	
	                                  // ========================================
	                                  // ADA LAYANAN
	                                  // ========================================
	
	                                  : ListView.separated(
	
	                                      shrinkWrap:
	                                          true,
	
	                                      itemCount:
	                                          selectedServices
	                                              .length,
	
	                                      separatorBuilder:
	                                          (
	                                        context,
	                                        index,
	                                      ) =>
	                                          const SizedBox(
	                                        height: 7,
	                                      ),
	
	                                      itemBuilder:
	                                          (
	                                        context,
	                                        index,
	                                      ) {
	
	                                        final service =
	                                            selectedServices[
	                                                index];
	
	                                        final price =
	                                            (service[
	                                                        'price']
	                                                    as num)
	                                                .toDouble();
	
	                                        final quantity =
	                                            (service[
	                                                        'quantity']
	                                                    as num)
	                                                .toDouble();
	
	                                        final itemTotal =
	                                            price *
	                                                quantity;
	
	                                        return Container(
	                                          padding:
	                                              const EdgeInsets
	                                                  .symmetric(
	                                            horizontal:
	                                                10,
	                                            vertical:
	                                                9,
	                                          ),
	
	                                          decoration:
	                                              BoxDecoration(
	                                            color:
	                                                const Color(
	                                              0xFFFAFAFA,
	                                            ),
	
	                                            borderRadius:
	                                                BorderRadius
	                                                    .circular(
	                                              11,
	                                            ),
	
	                                            border:
	                                                Border.all(
	                                              color:
	                                                  Colors.black12,
	                                            ),
	                                          ),
	
	                                          child: Row(
	                                            children: [
	
	                                              // ==================================
	                                              // NAMA LAYANAN
	                                              // ==================================
	
	                                              Expanded(
	                                                child:
	                                                    Column(
	                                                  crossAxisAlignment:
	                                                      CrossAxisAlignment
	                                                          .start,
	
	                                                  children: [
	
	                                                    Text(
	                                                      service[
	                                                          'name'],
	                                                      style:
	                                                          const TextStyle(
	                                                        fontSize:
	                                                            11,
	                                                        fontWeight:
	                                                            FontWeight.w600,
	                                                      ),
	                                                    ),
	
	                                                    const SizedBox(
	                                                      height:
	                                                          2,
	                                                    ),
	
	                                                    Text(
	                                                      '${formatRupiah(price)} / ${service['unit']}',
	                                                      style:
	                                                          const TextStyle(
	                                                        fontSize:
	                                                            9,
	                                                        color:
	                                                            Colors.black45,
	                                                      ),
	                                                    ),
	                                                  ],
	                                                ),
	                                              ),
	
	                                              // ==================================
	                                              // TOTAL ITEM
	                                              // ==================================
	
	                                              Text(
	                                                formatRupiah(
	                                                  itemTotal,
	                                                ),
	                                                style:
	                                                    const TextStyle(
	                                                  fontSize:
	                                                      11,
	                                                  fontWeight:
	                                                      FontWeight.w600,
	                                                ),
	                                              ),
	
	                                              // ==================================
	                                              // HAPUS ITEM
	                                              // ==================================
	
	                                              IconButton(
	                                                visualDensity:
	                                                    VisualDensity
	                                                        .compact,
	
	                                                padding:
	                                                    const EdgeInsets
	                                                        .only(
	                                                  left:
	                                                      6,
	                                                ),
	
	                                                constraints:
	                                                    const BoxConstraints(),
	
	                                                icon:
	                                                    const Icon(
	                                                  Icons.close_rounded,
	                                                  size: 17,
	                                                  color:
	                                                      Colors.black38,
	                                                ),
	
	                                                onPressed:
	                                                    () {
	
	                                                  setModalState(
	                                                    () {
	                                                      selectedServices
	                                                          .removeAt(
	                                                        index,
	                                                      );
	                                                    },
	                                                  );
	                                                },
	                                              ),
	                                            ],
	                                          ),
	                                        );
	                                      },
	                                    ),
	                        ),
	
	                        const SizedBox(
	                          height: 12,
	                        ),
	
	                        // ==================================================
	                        // 5. AROMA PARFUM
	                        // ==================================================
	
	                        const Text(
	                          'Aroma Parfum',
	                          style: TextStyle(
	                            fontSize: 11,
	                            color:
	                                Colors.black45,
	                            fontWeight:
	                                FontWeight.w500,
	                          ),
	                        ),
	
	                        const SizedBox(
	                          height: 5,
	                        ),
	
	                        Container(
	                          height: 56,
	
	                          padding:
	                              const EdgeInsets
	                                  .symmetric(
	                            horizontal: 12,
	                          ),
	
	                          decoration:
	                              BoxDecoration(
	                            color:
	                                Colors.transparent,
	
	                            borderRadius:
	                                BorderRadius.circular(
	                              12,
	                            ),
	
	                            border:
	                                Border.all(
	                              color:
	                                  Colors.black12,
	                            ),
	                          ),
	
	                          child:
	                              DropdownButtonHideUnderline(
	                            child:
	                                DropdownButton<String>(
	                              value:
	                                  selectedParfum,
	
	                              isExpanded:
	                                  true,
	
	                              icon:
	                                  const Icon(
	                                Icons
	                                    .keyboard_arrow_down_rounded,
	                                size: 20,
	                              ),
	
	                              style:
	                                  const TextStyle(
	                                color:
	                                    _textBlack,
	                                fontSize:
	                                    12,
	                              ),
	
	                              items: const [
	
	                                DropdownMenuItem(
	                                  value:
	                                      'Standard / Original',
	                                  child:
	                                      Text(
	                                    'Standard / Original',
	                                  ),
	                                ),
	
	                                DropdownMenuItem(
	                                  value:
	                                      'Sakura',
	                                  child:
	                                      Text(
	                                    'Sakura',
	                                  ),
	                                ),
	
	                                DropdownMenuItem(
	                                  value:
	                                      'Lavender',
	                                  child:
	                                      Text(
	                                    'Lavender',
	                                  ),
	                                ),
	
	                                DropdownMenuItem(
	                                  value:
	                                      'Melati',
	                                  child:
	                                      Text(
	                                    'Melati',
	                                  ),
	                                ),
	
	                                DropdownMenuItem(
	                                  value:
	                                      'Ocean Fresh',
	                                  child:
	                                      Text(
	                                    'Ocean Fresh',
	                                  ),
	                                ),
	                              ],
	
	                              onChanged:
	                                  (value) {
	
	                                if (value ==
	                                    null) {
	                                  return;
	                                }
	
	                                setModalState(
	                                  () {
	                                    selectedParfum =
	                                        value;
	                                  },
	                                );
	                              },
	                            ),
	                          ),
	                        ),
	
	                        const SizedBox(
	                          height: 12,
	                        ),
	
	                        // ==================================================
	                        // 4. CATATAN ORDER
	                        // ==================================================
	
	                        const Text(
	                          'Catatan Order',
	                          style: TextStyle(
	                            fontSize: 11,
	                            color:
	                                Colors.black45,
	                            fontWeight:
	                                FontWeight.w500,
	                          ),
	                        ),
	
	                        const SizedBox(
	                          height: 5,
	                        ),
	
	                        TextField(
	                          controller:
	                              catatanController,
	
	                          maxLines: 2,
	
	                          style:
	                              const TextStyle(
	                            fontSize: 11,
	                          ),
	
	                          decoration:
	                              InputDecoration(
	                            hintText:
	                                'Contoh: Luntur, Jangan Terlalu Panas, Baju warna putih dipisah',
	
	                            hintStyle:
	                                const TextStyle(
	                              color:
	                                  Colors.black38,
	                              fontSize:
	                                  10,
	                            ),
	
	                            contentPadding:
	                                const EdgeInsets
	                                    .symmetric(
	                              horizontal: 13,
	                              vertical: 12,
	                            ),
	
	                            border:
	                                OutlineInputBorder(
	                              borderRadius:
	                                  BorderRadius.circular(
	                                12,
	                              ),
	
	                              borderSide:
	                                  const BorderSide(
	                                color:
	                                    Colors.black12,
	                              ),
	                            ),
	
	                            enabledBorder:
	                                OutlineInputBorder(
	                              borderRadius:
	                                  BorderRadius.circular(
	                                12,
	                              ),
	
	                              borderSide:
	                                  const BorderSide(
	                                color:
	                                    Colors.black12,
	                              ),
	                            ),
	
	                            focusedBorder:
	                                OutlineInputBorder(
	                              borderRadius:
	                                  BorderRadius.circular(
	                                12,
	                              ),
	
	                              borderSide:
	                                  const BorderSide(
	                                color:
	                                    _goldAccent,
	                              ),
	                            ),
	                          ),
	                        ),
	
	                        const SizedBox(
	                          height: 12,
	                        ),
	
	                        // ==================================================
	                        // 6. DISKON
	                        // ==================================================
	
	                        const Text(
	                          'Diskon / Potongan Harga',
	                          style: TextStyle(
	                            fontSize: 11,
	                            color:
	                                Colors.black45,
	                            fontWeight:
	                                FontWeight.w500,
	                          ),
	                        ),
	
	                        const SizedBox(
	                          height: 5,
	                        ),
	
	                        Container(
	                          height: 56,
	
	                          padding:
	                              const EdgeInsets
	                                  .symmetric(
	                            horizontal: 12,
	                          ),
	
	                          decoration:
	                              BoxDecoration(
	                            color:
	                                Colors.transparent,
	
	                            borderRadius:
	                                BorderRadius.circular(
	                              12,
	                            ),
	
	                            border:
	                                Border.all(
	                              color:
	                                  Colors.black12,
	                            ),
	                          ),
	
	                          child:
	                              DropdownButtonHideUnderline(
	                            child:
	                                DropdownButton<double>(
	                              value:
	                                  selectedDiscount,
	
	                              isExpanded:
	                                  true,
	
	                              icon:
	                                  const Icon(
	                                Icons
	                                    .keyboard_arrow_down_rounded,
	                                size: 20,
	                              ),
	
	                              style:
	                                  const TextStyle(
	                                color:
	                                    _textBlack,
	                                fontSize:
	                                    12,
	                              ),
	
	                              items: const [
	
	                                DropdownMenuItem(
	                                  value: 0,
	                                  child:
	                                      Text(
	                                    'Tanpa Diskon (0%)',
	                                  ),
	                                ),
	
	                                DropdownMenuItem(
	                                  value: 5,
	                                  child:
	                                      Text(
	                                    'Diskon 5%',
	                                  ),
	                                ),
	
	                                DropdownMenuItem(
	                                  value: 10,
	                                  child:
	                                      Text(
	                                    'Diskon 10%',
	                                  ),
	                                ),
	
	                                DropdownMenuItem(
	                                  value: 15,
	                                  child:
	                                      Text(
	                                    'Diskon 15%',
	                                  ),
	                                ),
	
	                                DropdownMenuItem(
	                                  value: 20,
	                                  child:
	                                      Text(
	                                    'Diskon 20%',
	                                  ),
	                                ),
	                              ],
	
	                              onChanged:
	                                  (value) {
	
	                                if (value ==
	                                    null) {
	                                  return;
	                                }
	
	                                setModalState(
	                                  () {
	                                    selectedDiscount =
	                                        value;
	                                  },
	                                );
	                              },
	                            ),
	                          ),
	                        ),
	
	                        const SizedBox(
	                          height: 14,
	                        ),
	
	                        // ==================================================
	                        // 7 + 8. TOTAL + PESAN
	                        // ==================================================
	
	                        Row(
	                          crossAxisAlignment:
	                              CrossAxisAlignment
	                                  .end,
	
	                          children: [
	
	                            // ==============================================
	                            // TOTAL PRICE
	                            // ==============================================
	
	                            Expanded(
	                              child: Column(
	                                crossAxisAlignment:
	                                    CrossAxisAlignment
	                                        .start,
	
	                                children: [
	
	                                  const Text(
	                                    'TOTAL PRICE',
	                                    style:
	                                        TextStyle(
	                                      fontSize: 9,
	                                      color:
	                                          Colors.black45,
	                                      fontWeight:
	                                          FontWeight.w600,
	                                    ),
	                                  ),
	
	                                  const SizedBox(
	                                    height: 3,
	                                  ),
	
	                                  Text(
	                                    formatRupiah(
	                                      total,
	                                    ),
	                                    style:
	                                        const TextStyle(
	                                      fontSize: 17,
	                                      fontWeight:
	                                          FontWeight.bold,
	                                      color:
	                                          _textBlack,
	                                    ),
	                                  ),
	
	                                  // ========================================
	                                  // INFORMASI SUBTOTAL + DISKON
	                                  // ========================================
	
	                                  if (selectedDiscount >
	                                      0)
	                                    Text(
	                                      'Subtotal ${formatRupiah(subtotal)} • Diskon ${selectedDiscount.toStringAsFixed(0)}%',
	                                      style:
	                                          const TextStyle(
	                                        fontSize:
	                                            8,
	                                        color:
	                                            Colors.black38,
	                                      ),
	                                    ),
	                                ],
	                              ),
	                            ),
	
	                            const SizedBox(
	                              width: 12,
	                            ),
	
	                            // ==============================================
	                            // TOMBOL PESAN
	                            // ==============================================
	
	                            SizedBox(
	                              height: 42,
	                              width: 105,
	
	                              child:
	                                  ElevatedButton(
	                                onPressed:
	                                    selectedCustomer ==
	                                                null ||
	                                            selectedServices
	                                                .isEmpty
	                                        ? null
	                                        : () {
	
	                                            // ==================================
	                                            // DATA ORDER
	                                            // ==================================
	                                            //
	                                            // Struktur ini tetap kita pertahankan
	                                            // agar nanti gampang disambungkan
	                                            // ke Supabase.
	                                            //
	
	                                            final order =
	                                                {
	                                              'customer_name':
	                                                  selectedCustomer![
	                                                      'name'],
	
	                                              'customer_phone':
	                                                  selectedCustomer![
	                                                      'phone'],
	
	                                              'services':
	                                                  selectedServices,
	
	                                              'catatan':
	                                                  catatanController
	                                                      .text,
	
	                                              'parfum':
	                                                  selectedParfum,
	
	                                              'discount_percent':
	                                                  selectedDiscount,
	
	                                              'subtotal':
	                                                  subtotal,
	
	                                              'discount_amount':
	                                                  discount,
	
	                                              'total':
	                                                  total,
	
	                                              'type':
	                                                  type,
	                                            };
	
	                                            // ==================================
	                                            // DEBUG
	                                            // ==================================
	
	                                            debugPrint(
	                                              'ORDER BARU: $order',
	                                            );
	
	                                            // ==================================
	                                            // TUTUP FORM
	                                            // ==================================
	
	                                            Navigator.pop(
	                                              dialogContext,
	                                            );
	
	                                            // ==================================
	                                            // TUTUP MENU TRANSAKSI
	                                            // ==================================
	
	                                            Navigator.pop(
	                                              context,
	                                            );
	
	                                            // ==================================
	                                            // REFRESH DATA
	                                            // ==================================
	
	                                            widget
	                                                .onOrderCreated();
	                                          },
	
	                                style:
	                                    ElevatedButton
	                                        .styleFrom(
	                                  backgroundColor:
	                                      const Color(
	                                    0xFFEF4444,
	                                  ),
	
	                                  foregroundColor:
	                                      Colors.white,
	
	                                  disabledBackgroundColor:
	                                      Colors.black12,
	
	                                  elevation: 0,
	
	                                  shape:
	                                      RoundedRectangleBorder(
	                                    borderRadius:
	                                        BorderRadius
	                                            .circular(
	                                      10,
	                                    ),
	                                  ),
	                                ),
	
	                                child:
	                                    const Text(
	                                  'PESAN',
	                                  style:
	                                      TextStyle(
	                                    fontSize:
	                                        11,
	                                    fontWeight:
	                                        FontWeight.bold,
	                                  ),
	                                ),
	                              ),
	                            ),
	                          ],
	                        ),
	                      ],
	                    ),
	                  ),
	                ),
	              ),
	            ),
	          );
	        },
	      );
	    },
	  );
	}
  
  @override
    Widget build(BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _bgDark,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER DIALOG
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Menu Transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _textBlack, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
  
                // 2 TOMBOL KREATIF IN & OUT
                Row(
                  children: [
                    // TOMBOL BUAT ORDERS
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showFormOrder(context, 'IN'),
                        child: Container(
                          height: 95,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                              
                                Color(0xFF34D399), // Mint Emerald
                                Color(0xFF059669), // Deep Emerald
                                
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade600.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Buat Orders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Cucian Masuk',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
  
                    // TOMBOL PENGELUARAN
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showFormOrder(context, 'OUT'),
                        child: Container(
                          height: 95,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                              
                                Color(0xFFFB923C), // Warm Coral
                                Color(0xFFE11D48), // Rose Crimson
                                
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepOrange.shade600.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Pengeluaran',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Biaya Toko',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
  
                const SizedBox(height: 18),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 12),
  
                // TOP CUSTOMERS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Top Customers',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                      ),
                    ),
                    Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  ],
                ),
                const SizedBox(height: 10),
  
                // LIST TOP CUSTOMERS
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _topCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _topCustomers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _cardDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _goldAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer['name']!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _textBlack,
                                      ),
                                    ),
                                    Text(
                                      customer['orders']!,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                customer['status']!,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: _goldAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }


