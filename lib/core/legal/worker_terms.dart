class WorkerTermsSection {
  const WorkerTermsSection({
    required this.title,
    required this.paragraphs,
    this.points = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> points;
}

/// Sumber tunggal Syarat & Ketentuan khusus akun Worker.
///
/// Setiap perubahan substantif wajib menggunakan versi baru agar persetujuan
/// yang tersimpan di backend tetap dapat diaudit.
abstract final class WorkerTerms {
  static const String version = 'worker-2026-07-28-v1';
  static const String effectiveDate = '28 Juli 2026';
  static const String title = 'Syarat & Ketentuan Worker Neo Formula';

  static const String introduction =
      'Dokumen ini mengatur penggunaan Neo Formula oleh penyedia jasa '
      '("Worker"). Dengan mendaftar dan menggunakan platform, Worker '
      'menyetujui ketentuan berikut.';

  static const List<String> highlights = [
    'Data akun, keahlian, dan dokumen KYC harus benar serta dapat diverifikasi.',
    'Pesanan dan pembayaran wajib diproses melalui alur resmi aplikasi.',
    'Worker wajib menjaga keselamatan, kualitas layanan, dan privasi Customer.',
    'Pembatalan, refund, garansi, dan sengketa mengikuti status serta bukti pesanan.',
  ];

  static const List<WorkerTermsSection> sections = [
    WorkerTermsSection(
      title: 'Definisi',
      paragraphs: [
        'Neo Formula adalah platform yang mempertemukan Customer dengan Worker '
            'untuk pemesanan jasa. Customer adalah pengguna yang memesan jasa. '
            'Worker adalah pengguna yang menawarkan dan melaksanakan jasa.',
        'Pesanan adalah permintaan jasa yang tercatat di aplikasi. Layanan '
            'adalah pekerjaan yang ditawarkan Worker, termasuk ruang lingkup, '
            'harga, area operasional, jadwal, dan ketentuan terkait.',
      ],
    ),
    WorkerTermsSection(
      title: 'Kelayakan, akun, dan verifikasi',
      paragraphs: [
        'Worker harus cakap secara hukum, menggunakan identitas sendiri, dan '
            'memberikan informasi yang benar, lengkap, serta terbaru.',
        'Pendaftaran Worker tunduk pada pemeriksaan identitas dan KYC. Neo '
            'Formula dapat meminta klarifikasi atau dokumen tambahan sebelum '
            'menyetujui akun.',
      ],
      points: [
        'Worker bertanggung jawab menjaga kerahasiaan akun dan perangkat.',
        'Satu akun tidak boleh dipindahtangankan atau digunakan bersama.',
        'Perubahan data penting wajib segera diperbarui melalui kanal resmi.',
        'Pemalsuan identitas atau dokumen dapat menyebabkan penolakan atau penutupan akun.',
      ],
    ),
    WorkerTermsSection(
      title: 'Peran platform',
      paragraphs: [
        'Neo Formula menyediakan sarana pencarian, komunikasi, pemesanan, '
            'pembayaran, dokumentasi pekerjaan, ulasan, dan penyelesaian '
            'kendala. Worker tetap bertanggung jawab atas layanan yang '
            'ditawarkan dan dilaksanakan.',
        'Hubungan penggunaan platform tidak dengan sendirinya membentuk '
            'hubungan kerja antara Worker dan Neo Formula. Worker mengatur '
            'cara kerja, alat, serta kewajiban profesionalnya sepanjang tetap '
            'mematuhi pesanan dan ketentuan platform.',
      ],
    ),
    WorkerTermsSection(
      title: 'Layanan dan area operasional',
      paragraphs: [
        'Worker hanya boleh menawarkan layanan yang sesuai dengan kemampuan, '
            'pengalaman, izin, atau sertifikasi yang dimilikinya apabila hal '
            'tersebut dipersyaratkan.',
        'Area operasional dan radius layanan digunakan untuk membantu Customer '
            'menemukan Worker yang relevan. Worker wajib menjaga informasi '
            'area tersebut tetap akurat.',
      ],
      points: [
        'Judul, deskripsi, harga, dan batasan layanan tidak boleh menyesatkan.',
        'Biaya tambahan wajib dijelaskan dan disetujui Customer sebelum pekerjaan dilanjutkan.',
        'Worker tidak boleh menjanjikan hasil yang tidak realistis atau di luar kewenangannya.',
      ],
    ),
    WorkerTermsSection(
      title: 'Penerimaan dan pelaksanaan pesanan',
      paragraphs: [
        'Sebelum menerima pesanan, Worker wajib memeriksa lokasi, jadwal, ruang '
            'lingkup, harga, dan kebutuhan Customer. Penerimaan pesanan '
            'merupakan komitmen untuk melaksanakan pekerjaan secara profesional.',
      ],
      points: [
        'Datang atau memulai pekerjaan sesuai jadwal yang disepakati.',
        'Berkomunikasi melalui kanal aplikasi dan memberi kabar jika ada kendala.',
        'Memperbarui status pesanan secara jujur sesuai kondisi pekerjaan.',
        'Mengunggah bukti sebelum dan sesudah pekerjaan bila diwajibkan.',
        'Menjaga keselamatan, kebersihan, properti, dan privasi Customer.',
      ],
    ),
    WorkerTermsSection(
      title: 'Harga, pembayaran, dan pencairan dana',
      paragraphs: [
        'Pembayaran pesanan diproses melalui metode pembayaran yang tersedia '
            'di aplikasi. Worker dilarang mengarahkan Customer untuk '
            'menghindari alur pembayaran resmi atas pesanan yang berasal dari '
            'Neo Formula.',
        'Nominal yang diterima Worker dapat memperhitungkan biaya platform, '
            'biaya pembayaran, penyesuaian, refund, atau kewajiban lain yang '
            'ditampilkan atau disepakati dalam alur transaksi.',
      ],
      points: [
        'Pencairan hanya dilakukan ke rekening yang sah dan terverifikasi.',
        'Worker bertanggung jawab atas kebenaran data rekening dan kewajiban pajaknya.',
        'Pencairan dapat ditahan sementara saat transaksi sedang diperiksa atau disengketakan.',
      ],
    ),
    WorkerTermsSection(
      title: 'Pembatalan, refund, garansi, dan sengketa',
      paragraphs: [
        'Pembatalan dan refund dinilai berdasarkan status pesanan, alasan, '
            'komunikasi, bukti pekerjaan, serta kebijakan yang berlaku. '
            'Pengajuan refund tidak otomatis berarti dana dikembalikan.',
        'Worker berhak memberikan penjelasan dan bukti pendukung. Selama '
            'pemeriksaan, Neo Formula dapat menahan perubahan status atau '
            'pencairan dana yang terkait dengan pesanan.',
      ],
      points: [
        'Worker wajib menanggapi permintaan klarifikasi dalam batas waktu yang diberikan.',
        'Perbaikan dalam masa garansi harus dilakukan sesuai ruang lingkup yang disepakati.',
        'Keputusan dapat mencakup penolakan, refund sebagian/penuh, perbaikan, atau tindakan akun.',
      ],
    ),
    WorkerTermsSection(
      title: 'Perilaku yang dilarang',
      paragraphs: [
        'Worker dilarang menggunakan platform untuk tindakan melanggar hukum, '
            'penipuan, pelecehan, diskriminasi, ancaman, manipulasi transaksi, '
            'atau penyalahgunaan data pribadi.',
      ],
      points: [
        'Membuat pesanan atau ulasan palsu dan memanipulasi rating.',
        'Mengakses, membagikan, atau menjual data Customer tanpa dasar yang sah.',
        'Mengunggah konten berbahaya, melanggar hak pihak lain, atau mengandung malware.',
        'Menyalahgunakan voucher, pembayaran, refund, garansi, atau program promosi.',
      ],
    ),
    WorkerTermsSection(
      title: 'Tanggung jawab Worker',
      paragraphs: [
        'Worker bertanggung jawab menyediakan alat, perlindungan keselamatan, '
            'izin, dan kompetensi yang diperlukan untuk pekerjaannya. Worker '
            'juga bertanggung jawab atas kerugian yang timbul karena '
            'kesengajaan, kelalaian, pelanggaran hukum, atau pelanggaran '
            'kesepakatan layanan.',
        'Jika pekerjaan membutuhkan izin khusus atau berisiko tinggi, Worker '
            'wajib memastikan persyaratan tersebut terpenuhi sebelum menerima '
            'pesanan.',
      ],
    ),
    WorkerTermsSection(
      title: 'Data pribadi dan lokasi',
      paragraphs: [
        'Neo Formula memproses data akun, KYC, komunikasi, transaksi, dan '
            'lokasi untuk verifikasi, penyediaan layanan, keamanan, dukungan, '
            'pencegahan penyalahgunaan, serta pemenuhan kewajiban hukum.',
        'Koordinat presisi area operasional disimpan sebagai data privat. '
            'Customer hanya ditampilkan nama area dan informasi jarak yang '
            'diperlukan untuk pencarian layanan, kecuali pengungkapan lebih '
            'lanjut dibutuhkan untuk pelaksanaan pesanan.',
      ],
      points: [
        'Worker tidak boleh memakai data Customer di luar kebutuhan pesanan.',
        'Dokumen KYC tidak boleh dipublikasikan sebagai bagian profil Worker.',
        'Worker wajib melaporkan dugaan pengambilalihan akun atau kebocoran data.',
      ],
    ),
    WorkerTermsSection(
      title: 'Konten, portofolio, dan ulasan',
      paragraphs: [
        'Worker menjamin bahwa foto, deskripsi, dan portofolio yang diunggah '
            'adalah miliknya atau digunakan dengan izin yang sah. Worker '
            'memberikan izin kepada Neo Formula untuk menampilkan konten '
            'tersebut selama diperlukan untuk mengoperasikan dan mempromosikan '
            'layanan di platform.',
        'Ulasan dapat dimoderasi apabila terbukti melanggar kebijakan, tetapi '
            'tidak diubah semata-mata karena berisi penilaian yang tidak '
            'disukai oleh salah satu pihak.',
      ],
    ),
    WorkerTermsSection(
      title: 'Pembatasan, penangguhan, dan penghentian akun',
      paragraphs: [
        'Neo Formula dapat membatasi fitur, menangguhkan, menolak, atau '
            'menghentikan akun untuk melindungi pengguna dan platform, '
            'termasuk ketika terdapat dugaan penipuan, risiko keselamatan, '
            'dokumen tidak valid, pelanggaran berulang, atau kewajiban hukum.',
        'Jika memungkinkan, Worker akan menerima pemberitahuan dan kesempatan '
            'memberikan klarifikasi. Tindakan segera dapat dilakukan bila '
            'dibutuhkan untuk mencegah kerugian atau risiko keamanan.',
      ],
    ),
    WorkerTermsSection(
      title: 'Perubahan ketentuan',
      paragraphs: [
        'Ketentuan dapat diperbarui untuk menyesuaikan layanan, risiko, atau '
            'peraturan. Perubahan substantif akan menggunakan versi baru dan '
            'dapat meminta persetujuan ulang sebelum Worker melanjutkan '
            'penggunaan fitur tertentu.',
      ],
    ),
    WorkerTermsSection(
      title: 'Hukum, keluhan, dan penyelesaian perselisihan',
      paragraphs: [
        'Ketentuan ini tunduk pada hukum Republik Indonesia. Keluhan atau '
            'perselisihan diupayakan terlebih dahulu melalui dukungan aplikasi '
            'dan penyelesaian secara itikad baik dengan mempertimbangkan data '
            'serta bukti transaksi.',
        'Hak pengguna yang tidak dapat dikesampingkan berdasarkan peraturan '
            'yang berlaku tetap dihormati.',
      ],
    ),
    WorkerTermsSection(
      title: 'Kontak',
      paragraphs: [
        'Pertanyaan, laporan keamanan, atau keberatan terkait ketentuan ini '
            'dapat disampaikan melalui kanal Bantuan atau Dukungan yang '
            'tersedia di aplikasi.',
      ],
    ),
  ];

  static String get plainText {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('Versi $version • Berlaku $effectiveDate')
      ..writeln()
      ..writeln(introduction);
    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      buffer
        ..writeln()
        ..writeln('${index + 1}. ${section.title}');
      for (final paragraph in section.paragraphs) {
        buffer.writeln(paragraph);
      }
      for (final point in section.points) {
        buffer.writeln('• $point');
      }
    }
    return buffer.toString().trim();
  }
}
