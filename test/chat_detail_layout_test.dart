import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/chat/pages/chat_detail_page.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test/api');
  });

  testWidgets('nama peserta panjang tidak menyebabkan overflow di AppBar', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(initializeOnCreate: false),
        child: const MaterialApp(
          home: ChatDetailPage(
            chatId: 'user-a_user-b',
            name: 'Muhammad Rifky Saputra Scania Dengan Nama Sangat Panjang',
            avatarUrl: '',
          ),
        ),
      ),
    );
    await tester.pump();

    final name = tester.widget<Text>(
      find.byKey(const ValueKey('chat-participant-name')),
    );
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);

    // Dispose halaman agar timer polling tidak tertinggal setelah test.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
