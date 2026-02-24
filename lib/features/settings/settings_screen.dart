import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/powersync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<String> _backupTables = [
    'firms',
    'areas',
    'farmers',
    'buyers',
    'produce',
    'expense_types',
    'transactions',
    'transaction_expenses',
    'payments',
  ];

  Future<void> _showSoonMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<File> _getLatestBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/bharat_mandi_backup_latest.json');
  }

  Future<void> _insertRow(String table, Map<String, dynamic> row) async {
    if (row.isEmpty) return;
    final columns = row.keys.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    final sql =
        'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)';
    final values = columns.map((c) => row[c]).toList();
    await powerSyncDB.execute(sql, values);
  }

  Future<void> _createBackup() async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = <String, dynamic>{};
      final counts = <String, int>{};

      for (final table in _backupTables) {
        final rows = await powerSyncDB.getAll('SELECT * FROM $table');
        data[table] = rows;
        counts[table] = rows.length;
      }

      final backup = {
        'meta': {
          'created_at': now,
          'app': 'bharat_mandi',
          'version': 1,
          'includes_firm_data': true,
        },
        'counts': counts,
        'data': data,
      };

      final dir = await getApplicationDocumentsDirectory();
      final timestampFile = File(
        '${dir.path}/bharat_mandi_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      final latestFile = await _getLatestBackupFile();
      final content = const JsonEncoder.withIndent('  ').convert(backup);

      await timestampFile.writeAsString(content);
      await latestFile.writeAsString(content);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('बॅकअप तयार झाला: ${timestampFile.path}')),
      );

      await Share.shareXFiles(
        [XFile(timestampFile.path)],
        text: 'भारत मंडी बॅकअप फाईल',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('बॅकअप त्रुटी: $e')));
    }
  }

  Future<void> _restoreFromBackupFile(File backupFile) async {
    final decoded = jsonDecode(await backupFile.readAsString());
    if (decoded is! Map<String, dynamic> || decoded['data'] == null) {
      throw Exception('अवैध backup format');
    }

    final data = decoded['data'] as Map<String, dynamic>;

    // Clear existing data (child to parent order)
    const clearOrder = [
      'transaction_expenses',
      'transactions',
      'payments',
      'expense_types',
      'produce',
      'buyers',
      'farmers',
      'areas',
      'firms',
    ];
    for (final table in clearOrder) {
      await powerSyncDB.execute('DELETE FROM $table');
    }

    // Restore data (parent to child order)
    for (final table in _backupTables) {
      final rows = (data[table] as List?) ?? [];
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          await _insertRow(table, row);
        } else if (row is Map) {
          await _insertRow(table, Map<String, dynamic>.from(row));
        }
      }
    }
  }

  Future<void> _restoreBackup() async {
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('पुनर्संचयित पुष्टी'),
        content: const Text(
          'यामुळे सध्याचा सर्व डेटा बदलला जाईल.\nशेवटचा घेतलेला backup restore करायचा का?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('नाही'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('होय, restore करा'),
          ),
        ],
      ),
    );

    if (shouldRestore != true) return;

    try {
      final backupFile = await _getLatestBackupFile();
      if (!await backupFile.exists()) {
        await _showSoonMessage('Backup फाईल सापडली नाही. आधी backup घ्या.');
        return;
      }

      await _restoreFromBackupFile(backupFile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup यशस्वीरीत्या restore झाला. अ‍ॅप पुन्हा उघडा.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Restore त्रुटी: $e')));
    }
  }

  Future<void> _pickAndRestoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Backup JSON फाईल निवडा',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;
      final selectedPath = result.files.single.path;
      if (selectedPath == null || selectedPath.isEmpty) {
        await _showSoonMessage('निवडलेली फाईल वाचता आली नाही.');
        return;
      }

      final file = File(selectedPath);
      if (!await file.exists()) {
        await _showSoonMessage('फाईल सापडली नाही.');
        return;
      }

      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('निवडलेल्या फाईलमधून पुनर्संचयित'),
          content: Text(
            'ही फाईल restore करायची का?\n$selectedPath\n\nयामुळे सध्याचा डेटा बदलला जाईल.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('रद्द करा'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore करा'),
            ),
          ],
        ),
      );

      if (shouldRestore != true) return;

      await _restoreFromBackupFile(file);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('निवडलेल्या backup फाईलमधून restore पूर्ण झाला.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Restore त्रुटी: $e')));
    }
  }

  Future<void> _showAbout() async {
    showAboutDialog(
      context: context,
      applicationName: 'भारत मंडी',
      applicationVersion: '1.0.0',
      children: const [
        Text(
          'भारत मंडी हे कृषी बाजार व्यवहार व्यवस्थापन अ‍ॅप आहे.\n\n'
          'मुख्य वैशिष्ट्ये:\n'
          '• मास्टर डेटा (शेतकरी, खरेदीदार, माल, खर्च प्रकार)\n'
          '• पावती नोंद आणि खर्च गणना\n'
          '• जमा नोंदी आणि खातेउतारा\n'
          '• उधारी, कॅश रिसीट, विक्री यांसारखे अहवाल\n'
          '• PDF/प्रिंट/शेअर सहाय्य\n\n'
          'हे अ‍ॅप ऑफलाइन-फर्स्ट पद्धतीने डिझाइन केले आहे.',
        ),
      ],
    );
  }

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('मदत - स्टेप बाय स्टेप मार्गदर्शक'),
        content: const SingleChildScrollView(
          child: Text(
            '1) फर्म सेटअप पूर्ण करा.\n'
            '2) मास्टर डेटा भरा: एरिया, शेतकरी, खरेदीदार, माल, खर्च प्रकार.\n'
            '3) नवीन पावती स्क्रीनमध्ये व्यवहाराची नोंद करा.\n'
            '4) जमा एन्ट्रीमधून खरेदीदाराकडून आलेली रक्कम नोंदवा.\n'
            '5) पावती यादी/खातेउतारा मधून तपशील तपासा.\n'
            '6) अहवाल विभागातून उधारी, विक्री, कॅश रिसीट रिपोर्ट बनवा.\n'
            '7) प्रत्येक रिपोर्टमधून PDF/प्रिंट/शेअर वापरा.\n'
            '8) नियमित backup घ्या (सेटिंग्ज > बॅकअप).\n'
            '9) नवीन डिव्हाईसमध्ये restore करून डेटा परत आणा.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ठीक आहे'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('सेटिंग्ज'),
        centerTitle: true,
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: const Text('भाषा'),
                  subtitle: const Text('लवकरच अजून भाषा उपलब्ध होतील'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showSoonMessage(
                    'लवकरच अजून भाषा add केल्या जातील.',
                  ),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading: const Icon(Icons.palette, color: Colors.green),
                  title: const Text('थीम'),
                  subtitle: const Text('लवकरच थीम अपडेट्स उपलब्ध होतील'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showSoonMessage(
                    'लवकरच theme updates येतील.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup, color: Colors.orange),
                  title: const Text('बॅकअप'),
                  subtitle: const Text('संपूर्ण डेटा backup फाईल तयार करा'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _createBackup,
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.purple),
                  title: const Text('पुनर्संचयित'),
                  subtitle: const Text('शेवटचा backup वापरून डेटा restore करा'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _restoreBackup,
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading:
                      const Icon(Icons.folder_open, color: Colors.deepPurple),
                  title: const Text('फाईल निवडा आणि restore करा'),
                  subtitle:
                      const Text('तुमच्या निवडलेल्या JSON backup मधून restore'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _pickAndRestoreBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.teal),
                  title: const Text('अ‍ॅप बद्दल'),
                  subtitle: const Text('सविस्तर माहिती'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showAbout,
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading: const Icon(Icons.help, color: Colors.blueGrey),
                  title: const Text('मदत'),
                  subtitle: const Text('स्टेप बाय स्टेप मार्गदर्शक'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showHelp,
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.indigo),
                  title: const Text('शेअर करा'),
                  subtitle: const Text('लवकरच अ‍ॅप लिंक उपलब्ध होईल'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showSoonMessage(
                    'अ‍ॅप पूर्ण झाल्यावर इथे share link दिली जाईल.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
