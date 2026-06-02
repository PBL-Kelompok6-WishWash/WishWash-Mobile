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
      'all_history': 'All History',
      'completed_sub': 'Completed',
      'canceled': 'Canceled',
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
      'add_order': 'Add Order',
      'add_account': 'Add Account',
      'back': 'Back',
      'sign_in': 'Sign In',
      'create_account': 'Create Account',
      'landing_title': 'Your Laundry, refreshed',
      'landing_subtitle': 'Save time, stay fresh with Wish Wash.\nYou’ll wish you washed here',
      'landing_title_2': 'Best Express Services',
      'landing_subtitle_2': 'Fast, clean, and maximum freshness in just a few hours to support your productive day.',
      'landing_title_3': 'Exclusive Premium Fragrance',
      'landing_subtitle_3': 'Selection of long-lasting premium scents that keep fabrics soft and fresh all day long.',
      'landing_title_4': 'Real-Time Tracking',
      'landing_subtitle_4': 'Track your clothes status starting from pick up, washing process, up to delivery straight to your door.',
      'login_welcome': 'Welcome! Please sign in to your account.',
      'username_required': 'Oops! Username and Password are required.',
      'remember_me': 'Remember me',
      'forgot_password': 'Forgot Password?',
      'no_account': "Don't have an account? ",
      'register_welcome': 'Welcome! Please create your account here.',
      'email_format_invalid': 'Email format seems incorrect.',
      'password_min_length': 'Password must be at least 6 characters for safety!',
      'already_have_account': 'Already have an account? ',
      'full_name': 'Full Name',
      'username': 'Username',
      'password': 'Password',
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
      'all_history': 'Semua Riwayat',
      'completed_sub': 'Selesai',
      'canceled': 'Dibatalkan',
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
      'add_order': 'Tambah Pesanan',
      'add_account': 'Tambah Akun',
      'back': 'Kembali',
      'sign_in': 'Masuk',
      'create_account': 'Daftar Akun',
      'landing_title': 'Cucian Anda, segar kembali',
      'landing_subtitle': 'Hemat waktu, tetap segar bersama Wish Wash.\nAnda akan berharap mencuci di sini',
      'landing_title_2': 'Layanan Express Terbaik',
      'landing_subtitle_2': 'Cepat, bersih, dan harum maksimal hanya dalam hitungan jam untuk mendukung hari produktif Anda.',
      'landing_title_3': 'Pewangi Premium Eksklusif',
      'landing_subtitle_3': 'Pilihan aroma premium tahan lama yang menjaga kelembutan kain dan keharuman sepanjang hari.',
      'landing_title_4': 'Pantau Real-Time dari HP',
      'landing_subtitle_4': 'Lacak status pakaian Anda mulai dari penjemputan, proses cuci, hingga siap diantar langsung ke pintu Anda.',
      'login_welcome': 'Selamat datang! Silakan masuk ke akun Anda.',
      'username_required': 'Oops! Username dan Password wajib diisi ya.',
      'remember_me': 'Ingat saya',
      'forgot_password': 'Lupa Password?',
      'no_account': 'Belum punya akun? ',
      'register_welcome': 'Selamat datang! Silakan daftarkan akun Anda di sini.',
      'email_format_invalid': 'Format email sepertinya kurang tepat.',
      'password_min_length': 'Password minimal 6 karakter, biar aman!',
      'already_have_account': 'Sudah punya akun? ',
      'full_name': 'Nama Lengkap',
      'username': 'Username',
      'password': 'Password',
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
    
    final lowerStatus = dbStatus.toLowerCase().trim();

    // Map exact or common lowercase database keys to their target language values
    final isEn = currentLang == 'en';
    
    if (lowerStatus.contains('diterima') || lowerStatus.contains('received')) {
      return isEn ? 'Order Received' : 'Pesanan Diterima';
    }
    if (lowerStatus.contains('jemput') || lowerStatus.contains('pickup') || lowerStatus.contains('pick up') || lowerStatus.contains('penjemputan')) {
      return isEn ? 'Pick Up' : 'Penjemputan';
    }
    if (lowerStatus.contains('timbang') || lowerStatus.contains('weigh')) {
      return isEn ? 'Weighing Process' : 'Proses Timbang';
    }
    if (lowerStatus.contains('cuci') || lowerStatus.contains('wash')) {
      return isEn ? 'Washing Process' : 'Proses Cuci';
    }
    if (lowerStatus.contains('kering') || lowerStatus.contains('dry')) {
      return isEn ? 'Drying Process' : 'Proses Kering';
    }
    if (lowerStatus.contains('lipat') || lowerStatus.contains('fold')) {
      return isEn ? 'Folding Process' : 'Proses Lipat';
    }
    if (lowerStatus.contains('setrika') || lowerStatus.contains('iron')) {
      return isEn ? 'Ironing Process' : 'Proses Setrika';
    }
    if (lowerStatus.contains('antar') || lowerStatus.contains('delivery') || lowerStatus.contains('siap diantar')) {
      return isEn ? 'Ready for Delivery' : 'Siap Diantar';
    }
    if (lowerStatus.contains('selesai') || lowerStatus.contains('completed') || lowerStatus.contains('success') || lowerStatus.contains('done')) {
      return isEn ? 'Completed' : 'Selesai';
    }

    return dbStatus;
  }
}
