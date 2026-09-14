import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_bootstrap.dart';
import '../models/student_profile.dart';
import '../services/excel_parser_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({
    super.key,
    required this.user,
    required this.onUploaded,
    this.replaceExisting = false,
  });

  final StudentProfile user;
  final VoidCallback onUploaded;
  final bool replaceExisting;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _parser = ExcelParserService();
  bool _busy = false;
  String? _error;
  String? _summary;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Could not read that file. Try another Excel export.');
      return;
    }
    await _ingest(bytes, file.name);
  }

  Future<void> _loadSample() async {
    final data = await rootBundle.load('assets/sample_timetable.xlsx');
    await _ingest(data.buffer.asUint8List(), 'sample_timetable.xlsx');
  }

  Future<void> _ingest(List<int> bytes, String fileName) async {
    setState(() {
      _busy = true;
      _error = null;
      _summary = null;
    });
    try {
      final timetable = _parser.parseBytes(
        bytes: bytes,
        fileName: fileName,
        uploadedBy: widget.user.email,
      );
      await AppBootstrap.timetable.saveOfficialTimetable(timetable);
      await AppBootstrap.analytics.logFileUpload(
        fileName: fileName,
        sessionCount: timetable.sessions.length,
      );
      setState(() {
        _summary =
            'Loaded ${timetable.sessions.length} classes · ${timetable.coreSubjects.length} core · ${timetable.electives.length} electives';
      });
      widget.onUploaded();
    } on ExcelParseException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.replaceExisting ? 'Replace timetable' : 'Office timetable'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => AppBootstrap.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Upload the official Excel file circulated by the PGP/PGPEx office. '
            'The first sheet should include Day, Start Time, End Time, Subject, and Type (Core or Elective).',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Expected columns', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Day · Start Time · End Time · Course Code · Subject · Type · Faculty · Venue'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Excel timetable'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _loadSample,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Load sample PGPEx timetable'),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_summary != null) ...[
            const SizedBox(height: 16),
            Text(_summary!),
          ],
        ],
      ),
    );
  }
}
