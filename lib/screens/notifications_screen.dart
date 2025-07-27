import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'dart:convert';

class NotificationsScreen extends StatefulWidget {
  final Function(int)? onNotificationCount;
  const NotificationsScreen({Key? key, this.onNotificationCount}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> allNotifications = [];
  bool isLoading = false;
  int currentPage = 1;
  bool hasMore = true;
  int selectedTab = 0;
  final ScrollController _scrollController = ScrollController();

  static const List<Map<String, dynamic>> tabs = [
    {'label': 'ทั้งหมด', 'type': null, 'icon': Icons.notifications},
    {'label': 'ยังไม่อ่าน', 'type': 'unread', 'icon': Icons.fiber_new},
    {'label': 'อ่านแล้ว', 'type': 'read', 'icon': Icons.done_all},
    {'label': 'ประกาศ', 'type': 'announce', 'icon': Icons.campaign},
    {'label': 'ระบบ', 'type': 'system', 'icon': Icons.settings},
    {'label': 'งวดผ่อน', 'type': 'payment', 'icon': Icons.payments},
    {'label': 'สลิป', 'type': 'slip', 'icon': Icons.receipt_long},
    {'label': 'หักเงินล่วงหน้า', 'type': 'advance_deducted', 'icon': Icons.remove_circle},
    {'label': 'ค้างจ่าย', 'type': 'overdue', 'icon': Icons.error},
  ];

  @override
  void initState() {
    super.initState();
    fetchNotifications(reset: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoading &&
          hasMore) {
        fetchNotifications(reset: false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchNotifications({bool reset = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    int page = reset ? 1 : currentPage + 1;
    try {
      final res = await apiService.getNotifications(page: page, perPage: 30);
      List<dynamic> newList = res['data'] ?? [];
      if (reset) {
        allNotifications = [];
        currentPage = 1;
      }
      setState(() {
        allNotifications.addAll(newList);
        hasMore = res['meta']?['has_more'] ?? false;
        currentPage = page;
      });
      widget.onNotificationCount?.call(
        allNotifications.where((n) => n['read_at'] == null).length,
      );
    } catch (e) {
      if (reset) allNotifications = [];
      hasMore = false;
    }
    setState(() => isLoading = false);
  }

  List<dynamic> get filteredNotifications {
    switch (selectedTab) {
      case 1: // ยังไม่อ่าน
        return allNotifications.where((n) => n['read_at'] == null).toList();
      case 2: // อ่านแล้ว
        return allNotifications.where((n) => n['read_at'] != null).toList();
      case 3: // ประกาศ
        return allNotifications.where((n) => n['type'] == 'announce').toList();
      case 4: // ระบบ
        return allNotifications.where((n) => n['type'] == 'system').toList();
      case 5: // งวดผ่อน
        return allNotifications.where((n) => n['type'] == 'payment').toList();
      case 6: // สลิป
        return allNotifications.where((n) => n['type'] == 'slip').toList();
      case 7: // หักเงินล่วงหน้า
        return allNotifications.where((n) => n['type'] == 'advance_deducted').toList();
      case 8: // ค้างจ่าย
        return allNotifications.where((n) => n['type'] == 'overdue').toList();
      default:
        return allNotifications;
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return "-";
    try {
      DateTime dt;
      if (value is DateTime) {
        dt = value;
      } else if (value is String && value.isNotEmpty && !value.startsWith("0000")) {
        dt = DateTime.parse(value);
      } else {
        return "-";
      }
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return "-";
    }
  }

  Future<void> markAsRead(dynamic n) async {
    if (n['id'] == null) {
      _openNotificationAction(n); // dynamic ไม่ต้อง mark
      return;
    }
    if (n['read_at'] == null) {
      try {
        await apiService.markNotificationAsRead(n['id']);
        await fetchNotifications(reset: true); // <<--- โหลดใหม่ทั้ง list
      } catch (_) {}
    }
    _openNotificationAction(n);
  }

  void _openNotificationAction(dynamic n) {
    String type = n['type'] ?? '';
    String title = n['title'] ?? '-';
    String msg = n['message'] ?? '';
    final rawData = n['data'];
    Map data;
    if (rawData is Map) {
        data = rawData;
    } else if (rawData is String) {
        try {
        data = rawData.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(rawData)) : {};
        } catch (_) {
        data = {};
        }
    } else {
        data = {};
    }

    if (type == 'advance_deducted') {
        msg += "\n\nยอดคงเหลือ: ${data['remaining_advance'] ?? '-'} บาท";
        _showDialog('แจ้งเตือนหักเงินล่วงหน้า', msg);
    } else if (type == 'payment') {
        _showDialog('แจ้งเตือนค่างวด', msg);
    } else if (type == 'slip') {
        _showDialog('รายละเอียดสลิป', msg);
    } else if (type == 'announce') {
        _showDialog('ข่าวสาร/ประกาศ', msg);
    } else if (type == 'overdue') {
        _showDialog('แจ้งเตือนค้างจ่าย', msg);
    } else {
        _showDialog(title, msg);
    }
    }

  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title, style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: Text(msg, style: GoogleFonts.prompt()),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('ปิด'))
        ],
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'payment':
        return Colors.blue.shade50;
      case 'slip':
        return Colors.green.shade50;
      case 'system':
        return Colors.grey.shade200;
      case 'announce':
        return Colors.purple.shade50;
      case 'advance_deducted':
        return Colors.orange.shade100;
      case 'overdue':
        return Colors.red.shade50;
      default:
        return Colors.orange.shade50;
    }
  }

  IconData _getTypeIcon(String? type, bool isRead) {
    switch (type) {
      case 'payment':
        return isRead ? Icons.payments_outlined : Icons.payments;
      case 'slip':
        return isRead ? Icons.receipt_long_outlined : Icons.receipt_long;
      case 'system':
        return Icons.settings;
      case 'announce':
        return isRead ? Icons.campaign_outlined : Icons.campaign;
      case 'advance_deducted':
        return isRead ? Icons.remove_circle_outline : Icons.remove_circle;
      case 'overdue':
        return Icons.error;
      default:
        return isRead ? Icons.notifications_none : Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('แจ้งเตือน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => fetchNotifications(reset: true)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = selectedTab == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: ChoiceChip(
                    selected: selected,
                    label: Row(
                      children: [
                        Icon(tabs[i]['icon'], size: 17, color: selected ? accent : Colors.black38),
                        const SizedBox(width: 2),
                        Text(
                          tabs[i]['label'],
                          style: GoogleFonts.prompt(
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? accent : Colors.black54,
                          ),
                        ),
                        if (i == 1)
                          ...[
                            const SizedBox(width: 5),
                            CircleAvatar(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              radius: 8,
                              child: Text(
                                '${allNotifications.where((n) => n['read_at'] == null).length}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]
                      ],
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedTab = i;
                      });
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => fetchNotifications(reset: true),
        child: isLoading && allNotifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : filteredNotifications.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_off, size: 52, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('ไม่มีแจ้งเตือน',
                                style: GoogleFonts.prompt(fontSize: 17, color: Colors.black38)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: filteredNotifications.length + (hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == filteredNotifications.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ));
                      }
                      final n = filteredNotifications[i];
                      final isRead = n['read_at'] != null;
                      final type = n['type'] ?? '';
                      final title = n['title'] ?? '-';
                      final message = n['message'] ?? '';
                      final date = formatDate(n['created_at']);

                      return GestureDetector(
                        onTap: () async {
                          await markAsRead(n);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getTypeColor(type),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                            border: Border.all(
                                color: isRead
                                    ? Colors.grey.withOpacity(0.10)
                                    : accent.withOpacity(0.19)),
                          ),
                          child: ListTile(
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  backgroundColor: isRead ? Colors.grey[200] : accent.withOpacity(0.14),
                                  child: Icon(
                                    _getTypeIcon(type, isRead),
                                    color: isRead ? Colors.grey[700] : accent,
                                    size: 27,
                                  ),
                                  radius: 24,
                                ),
                                if (!isRead)
                                  const Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Icon(Icons.brightness_1, color: Colors.red, size: 16),
                                  ),
                              ],
                            ),
                            title: Text(
                              title,
                              style: GoogleFonts.prompt(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                color: isRead ? Colors.grey[800] : accent,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message, style: GoogleFonts.prompt(fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(date, style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[400])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.black26, size: 30),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
