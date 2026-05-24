import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class HistoryController extends GetxController {
  final _box = GetStorage('history_box');
  final RxList<Map<String, dynamic>> historyList = <Map<String, dynamic>>[].obs;
  final RxString statusFilter = 'all'.obs;
  final RxString channelFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();

    // Automatically save history whenever the list changes
    ever(historyList, (_) => _saveHistory());
  }

  void _loadHistory() {
    final List<dynamic>? storedData = _box.read<List<dynamic>>('history');
    if (storedData != null && storedData.isNotEmpty) {
      historyList.value = storedData
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return;
    }

    // Seed sample data for first run / preview purposes
    historyList.value = [
      {
        'status': 'success',
        'title': 'Lofi Beats to Relax/Study To',
        'url': 'https://youtube.com/watch?v=lofi123',
        'channel': 'Chillhop Music',
        'format': 'mp3',
        'isAudio': true,
        'size': '4.2 MB',
        'date': DateFormat(
          'MMM d, h:mm a',
        ).format(DateTime.now().subtract(const Duration(days: 1, hours: 2))),
        'thumbnail': null,
      },
      {
        'status': 'success',
        'title': 'Flutter Widgets 101',
        'url': 'https://youtube.com/watch?v=flutter101',
        'channel': 'Flutter Academy',
        'format': 'mp4',
        'isAudio': false,
        'size': '28.6 MB',
        'date': DateFormat(
          'MMM d, h:mm a',
        ).format(DateTime.now().subtract(const Duration(days: 2, hours: 4))),
        'thumbnail': null,
      },
      {
        'status': 'failed',
        'title': 'Big Concert Live',
        'url': 'https://youtube.com/watch?v=concert999',
        'channel': 'LiveEvents',
        'format': 'mp4',
        'isAudio': false,
        'size': '—',
        'date': DateFormat(
          'MMM d, h:mm a',
        ).format(DateTime.now().subtract(const Duration(hours: 6))),
        'thumbnail': null,
      },
      {
        'status': 'success',
        'title': 'Funny Cat Compilation',
        'url': 'https://youtube.com/watch?v=catfun',
        'channel': 'CuteAnimals',
        'format': 'mp4',
        'isAudio': false,
        'size': '12.1 MB',
        'date': DateFormat(
          'MMM d, h:mm a',
        ).format(DateTime.now().subtract(const Duration(days: 5))),
        'thumbnail': null,
      },
      {
        'status': 'success',
        'title': 'Deep Focus Piano',
        'url': 'https://youtube.com/watch?v=piano777',
        'channel': 'RelaxingRecords',
        'format': 'mp3',
        'isAudio': true,
        'size': '6.9 MB',
        'date': DateFormat(
          'MMM d, h:mm a',
        ).format(DateTime.now().subtract(const Duration(days: 7))),
        'thumbnail': null,
      },
    ];
  }

  void _saveHistory() {
    _box.write('history', historyList.toList());
  }

  List<Map<String, dynamic>> get filteredHistory {
    final lowerQuery = searchQuery.value.trim().toLowerCase();
    return historyList.where((item) {
      final statusOk =
          statusFilter.value == 'all' ||
          (item['status'] ?? '').toString() == statusFilter.value;
      final channelOk =
          channelFilter.value == 'all' ||
          (item['channel'] ?? '').toString() == channelFilter.value;
      if (!statusOk || !channelOk) return false;
      if (lowerQuery.isEmpty) return true;
      final title = (item['title'] ?? '').toString().toLowerCase();
      final url = (item['url'] ?? '').toString().toLowerCase();
      final channel = (item['channel'] ?? '').toString().toLowerCase();
      return title.contains(lowerQuery) ||
          url.contains(lowerQuery) ||
          channel.contains(lowerQuery);
    }).toList();
  }

  void setChannelFilter(String filter) {
    channelFilter.value = filter;
  }

  void setSearchQuery(String q) {
    searchQuery.value = q;
  }

  List<String> get availableChannels {
    final set = <String>{};
    for (final item in historyList) {
      final c = item['channel'];
      if (c != null && c.toString().trim().isNotEmpty) set.add(c.toString());
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  void setStatusFilter(String filter) {
    statusFilter.value = filter;
  }

  int countForStatus(String status) {
    if (status == 'all') {
      return historyList.length;
    }

    return historyList
        .where((item) => (item['status'] ?? '').toString() == status)
        .length;
  }

  /// Called by DownloaderController when a task finishes successfully
  void addFinishedTask(
    String title,
    String url,
    String format,
    bool isAudio,
    String size,
    String? channel,
    String? thumbnail,
  ) {
    final now = DateTime.now();
    final formattedDate = DateFormat('MMM d, h:mm a').format(now);

    historyList.insert(0, {
      'status': 'success',
      'title': title,
      'url': url,
      'channel': channel,
      'format': format,
      'isAudio': isAudio,
      'size': size,
      'date': formattedDate,
      'thumbnail': thumbnail, // Generate from URL if possible later
    });

    // Keep history manageable (e.g., last 100 items)
    if (historyList.length > 100) {
      historyList.removeLast();
    }
  }

  void clearHistory() {
    historyList.clear();
  }
}
