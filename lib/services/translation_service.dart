import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');

  static const String prefKey = 'pref_language';

  // Initialize language from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String savedLang = prefs.getString(prefKey) ?? 'en';
    if (savedLang == 'Bahasa Indonesia' || savedLang.toLowerCase().contains('indo') || savedLang.toLowerCase().contains('id')) {
      savedLang = 'id';
    } else {
      savedLang = 'en';
    }
    languageNotifier.value = savedLang;
  }

  // Update language and notify listeners
  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    String normalizedCode = code;
    if (code == 'Bahasa Indonesia' || code.toLowerCase().contains('indo') || code.toLowerCase().contains('id')) {
      normalizedCode = 'id';
    } else {
      normalizedCode = 'en';
    }
    await prefs.setString(prefKey, normalizedCode);
    languageNotifier.value = normalizedCode;
  }

  // Current selected code
  static String get currentLang => languageNotifier.value;

  // The translation dictionary
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome': 'Welcome',
      'welcome_greeting': 'Welcome back,',
      'cashier_activity': 'Cashier Activities',
      'courier_task': 'Courier Tasks',
      'pending': 'PENDING',
      'paid': 'PAID',
      'pickup': 'Pick Up',
      'delivery': 'Delivery',
      'total_revenue_today': 'Total Revenue Today',
      'revenue_trending': '+12.5% from yesterday',
      'monitor_orders': 'Monitor Orders',
      'recent_activities': 'Recent Activities',
      'order_incoming': 'Incoming Orders',
      'in_progress': 'In Progress',
      'ready_for_delivery': 'Ready to Deliver',
      'completed': 'Completed',
      'my_profile': 'My Profile',
      'email_address': 'Email Address',
      'vehicle_details': 'Vehicle Details',
      'help_faq': 'Help & FAQ',
      'active': 'Active',
      'busy': 'Busy',
      'status': 'Status',
      'logout_confirm_title': 'Logout',
      'logout_confirm_message': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
      'yes': 'Yes',
      'our_services': 'Our Services',
      'active_orders': 'Active Orders',
      'create_order': 'Create New Order',
      'my_address': 'My Address',
      'change_password': 'Change Password',
      'preferences_language': 'Preferences & Language',
      'order_history': 'Order History',
      'payment_history': 'Payment History',
      'faq': 'FAQ',
      'logout': 'Log Out',
      'edit_profile': 'Edit Profile',
      'no_services': 'No services available',
      'failed_to_load': 'Failed to load services',
      'message': 'Message',
      'courier': 'Courier',
      'preferences': 'Preferences & Language',
      'language_bahasa': 'LANGUAGE / BAHASA',
      'notifications': 'NOTIFICATIONS',
      'push_notif': 'Push Notifications',
      'push_notif_sub': 'Receive instant updates on your screen',
      'email_notif': 'Email Notifications',
      'email_notif_sub': 'Get invoices and receipts in your inbox',
      'status_notif': 'Order Status Updates',
      'status_notif_sub': 'Track washing and courier status',
      'app_settings': 'APPLICATION SETTINGS',
      'dark_theme': 'Dark Theme',
      'dark_theme_sub': 'Reduce eye strain in low-light environment',
      'sound_effects': 'Sound Effects',
      'sound_effects_sub': 'Play interactive sound alerts inside the app',
      'active_order_empty': 'No active order',
      'active_order_empty_sub': 'Your active laundry order will appear here.',
      'make_order_btn': 'Make Order',
      'profile': 'Profile',
      'home': 'Home',
      'orders': 'Orders',
      'address_not_set': 'Address not set yet',
      'phone': 'Phone',
      'email': 'Email',
      'address': 'Address',
      'add_new_address': 'Add New Address',
      'no_saved_addresses': 'No saved addresses yet.',
      'last_used': 'Last Used',
      'suggested_locations': 'Suggested Nearby Locations',
      'no_suggested_locations': 'No suggested locations yet.',
      'suggested_locations_desc': 'Suggested locations will appear when you enable GPS and frequently use the app in this area.',
      'edit_address': 'Edit Address',
      'select_address': 'Select Address',
      'address_details': 'Address Details',
      'address_details_hint': 'e.g. Block, House No., Landmark',
      'address_helper_text': 'Enter House No. (if any), so the Courier can deliver the order easily',
      'recipient_name': 'Recipient Name',
      'recipient_name_hint': 'Enter Recipient Name',
      'phone_number': 'Phone Number',
      'tag_as': 'Tag As',
      'home_tag': 'Home',
      'office_tag': 'Office',
      'other_tag': 'Other',
      'custom_tag_hint': 'e.g. Apartment, Kos, etc.',
      'save_address': 'Save Address',
      'search_location': 'Search location',
      'fill_all_fields': 'Please fill in all fields completely',
      'address_added': 'Address successfully added',
      'address_updated': 'Address successfully updated',
      'cuci_kering_lipat_desc': 'Complete package: washed, dried, and neatly folded.',
      'cuci_kering_desc': 'Thoroughly washed and dried, without ironing.',
      'cuci_dan_setrika_desc': 'Complete package: washed, fragrant, and neatly ironed.',
      'setrika_desc': 'Only neatly ironed and sprayed with premium fragrance.',
      // Service Names
      'cuci_kering_lipat': 'Wash, Dry & Fold',
      'cuci_kering': 'Wash & Dry',
      'cuci_and_setrika': 'Wash & Ironing',
      'setrika': 'Ironing Only',
      'setrika_saja': 'Ironing Only',
      'cuci_dan_setrika': 'Wash & Ironing',
      'cuci_and_setrika_desc': 'Complete package: washed, fragrant, and neatly ironed.',
    },
    'id': {
      'welcome': 'Selamat Datang',
      'welcome_greeting': 'Selamat datang,',
      'cashier_activity': 'Aktivitas Kasir',
      'courier_task': 'Tugas Kurir',
      'pending': 'PENDING',
      'paid': 'LUNAS',
      'pickup': 'Pick Up',
      'delivery': 'Delivery',
      'total_revenue_today': 'Total Pendapatan Hari Ini',
      'revenue_trending': '+12.5% dari kemarin',
      'monitor_orders': 'Pantau Pesanan',
      'recent_activities': 'Aktivitas Terkini',
      'order_incoming': 'Order Masuk',
      'in_progress': 'Diproses',
      'ready_for_delivery': 'Siap Diantar',
      'completed': 'Selesai',
      'my_profile': 'Profil Saya',
      'email_address': 'Email',
      'vehicle_details': 'Detail Kendaraan',
      'help_faq': 'Bantuan & FAQ',
      'active': 'Aktif',
      'busy': 'Sibuk',
      'status': 'Status',
      'logout_confirm_title': 'Keluar',
      'logout_confirm_message': 'Apakah Anda yakin ingin keluar?',
      'cancel': 'Batal',
      'yes': 'Ya',
      'our_services': 'Layanan Kami',
      'active_orders': 'Pesanan Aktif',
      'create_order': 'Buat Pesanan Baru',
      'my_address': 'Alamat Saya',
      'change_password': 'Ubah Kata Sandi',
      'preferences_language': 'Preferensi & Bahasa',
      'order_history': 'Riwayat Pesanan',
      'payment_history': 'Riwayat Pembayaran',
      'faq': 'Pertanyaan Umum (FAQ)',
      'logout': 'Keluar',
      'edit_profile': 'Edit Profil',
      'no_services': 'Tidak ada layanan tersedia',
      'failed_to_load': 'Gagal memuat layanan',
      'message': 'Pesan',
      'courier': 'Kurir',
      'preferences': 'Preferensi & Bahasa',
      'language_bahasa': 'BAHASA / LANGUAGE',
      'notifications': 'NOTIFIKASI',
      'push_notif': 'Notifikasi Push',
      'push_notif_sub': 'Terima pembaruan instan langsung di layar Anda',
      'email_notif': 'Notifikasi Email',
      'email_notif_sub': 'Dapatkan tagihan dan tanda terima di email Anda',
      'status_notif': 'Pembaruan Status Pesanan',
      'status_notif_sub': 'Lacak status pencucian dan pengiriman kurir',
      'app_settings': 'PENGATURAN APLIKASI',
      'dark_theme': 'Tema Gelap',
      'dark_theme_sub': 'Kurangi kelelahan mata dalam kondisi minim cahaya',
      'sound_effects': 'Efek Suara',
      'sound_effects_sub': 'Mainkan peringatan suara interaktif dalam aplikasi',
      'active_order_empty': 'Tidak ada pesanan aktif',
      'active_order_empty_sub': 'Pesanan laundry aktif Anda akan muncul di sini.',
      'make_order_btn': 'Buat Pesanan',
      'profile': 'Profil',
      'home': 'Beranda',
      'orders': 'Pesanan',
      'address_not_set': 'Alamat belum diatur',
      'phone': 'Telepon',
      'email': 'Email',
      'address': 'Alamat',
      'add_new_address': 'Tambahkan Alamat Baru',
      'no_saved_addresses': 'Belum ada alamat tersimpan.',
      'last_used': 'Terakhir Digunakan',
      'suggested_locations': 'Saran Lokasi Terdekat',
      'no_suggested_locations': 'Belum ada saran lokasi terdekat.',
      'suggested_locations_desc': 'Saran lokasi akan muncul ketika Anda mengaktifkan GPS dan sering menggunakan aplikasi di area ini.',
      'edit_address': 'Edit Alamat',
      'select_address': 'Pilih Alamat',
      'address_details': 'Rincian Alamat',
      'address_details_hint': 'Cth. Blok, No. Rumah, Patokan',
      'address_helper_text': 'Masukkan No. Rumah (jika ada), agar Kurir bisa mengantarkan pesanan dengan mudah',
      'recipient_name': 'Nama Penerima',
      'recipient_name_hint': 'Masukkan Nama Penerima',
      'phone_number': 'No. Handphone',
      'tag_as': 'Tandai Sebagai',
      'home_tag': 'Rumah',
      'office_tag': 'Kantor',
      'other_tag': 'Lainnya',
      'custom_tag_hint': 'Cth. Apartemen, Kos, dll',
      'save_address': 'Simpan Alamat',
      'search_location': 'Cari lokasi',
      'fill_all_fields': 'Harap isi semua data dengan lengkap',
      'address_added': 'Alamat berhasil ditambahkan',
      'address_updated': 'Alamat berhasil diubah',
      'cuci_kering_lipat_desc': 'Paket lengkap cuci bersih, kering, dan dilipat rapi.',
      'cuci_kering_desc': 'Dicuci bersih dan dikeringkan, tanpa disetrika.',
      'cuci_dan_setrika_desc': 'Dicuci bersih, diberi pewangi premium, dan disetrika rapi.',
      'setrika_desc': 'Hanya disetrika rapi dan diberi pewangi premium.',
      // Service Names
      'cuci_kering_lipat': 'Cuci Kering Lipat',
      'cuci_kering': 'Cuci Kering',
      'cuci_and_setrika': 'Cuci & Setrika',
      'setrika': 'Setrika',
      'setrika_saja': 'Setrika Saja',
      'cuci_dan_setrika': 'Cuci & Setrika',
      'cuci_and_setrika_desc': 'Dicuci bersih, diberi pewangi premium, dan disetrika rapi.',
    }
  };

  // Helper function to translate a key
  static String translate(String key) {
    final lang = languageNotifier.value;
    return _localizedValues[lang]?[key] ?? key;
  }

  // Translates a database-sourced service name dynamically
  static String translateService(String dbName) {
    if (dbName.isEmpty) return dbName;
    final String key = dbName.toLowerCase().trim().replaceAll(' ', '_').replaceAll('&', 'and');
    final String translated = translate(key);
    // If translation key is not defined, translate() returns the key itself.
    // In that case, fall back to the original database name.
    if (translated == key) {
      return dbName;
    }
    return translated;
  }

  // Translates a database-sourced status name dynamically
  static String translateStatus(String dbStatus) {
    if (dbStatus.isEmpty) return dbStatus;
    
    final Map<String, String> idToEn = {
      'pesanan diterima': 'Order Received',
      'penjemputan': 'Pick Up',
      'proses timbang': 'Weighing Process',
      'proses cuci': 'Washing Process',
      'proses kering': 'Drying Process',
      'proses lipat': 'Folding Process',
      'proses setrika': 'Ironing Process',
      'siap diantar': 'Ready for Delivery',
      'selesai': 'Completed',
    };

    final Map<String, String> enToId = {
      'order received': 'Pesanan Diterima',
      'pick up': 'Penjemputan',
      'weighing process': 'Proses Timbang',
      'washing process': 'Proses Cuci',
      'drying process': 'Proses Kering',
      'folding process': 'Proses Lipat',
      'ironing process': 'Proses Setrika',
      'ready for delivery': 'Siap Diantar',
      'completed': 'Selesai',
    };

    final lowerStatus = dbStatus.toLowerCase().trim();
    if (currentLang == 'en') {
      return idToEn[lowerStatus] ?? dbStatus;
    } else {
      return enToId[lowerStatus] ?? dbStatus;
    }
  }
}
