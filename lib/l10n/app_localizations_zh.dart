// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'TCamp 日历';

  @override
  String get monthLabel => '月';

  @override
  String get weekLabel => '周';

  @override
  String get dayLabel => '日';

  @override
  String get settingsLabel => '设置';

  @override
  String get noEvents => '无事件';

  @override
  String get addEvent => '新增事件';

  @override
  String get addEventLower => '新增事件';

  @override
  String get editEvent => '编辑事件';

  @override
  String get allDay => '整日';

  @override
  String get start => '开始';

  @override
  String get end => '结束';

  @override
  String get none => '无';

  @override
  String get reminder5min => '提前5分钟';

  @override
  String get reminder10min => '提前10分钟';

  @override
  String get reminder30min => '提前30分钟';

  @override
  String get reminder1hour => '提前1小时';

  @override
  String get repeat => '重复';

  @override
  String get daily => '每天';

  @override
  String get weekly => '每周';

  @override
  String get monthly => '每月';

  @override
  String get yearly => '每年';

  @override
  String get customRrule => '自定义 (RRULE)';

  @override
  String get save => '保存';

  @override
  String get title => '标题';

  @override
  String get titleRequired => '标题为必填项';

  @override
  String get description => '描述';

  @override
  String get location => '地点';

  @override
  String get rrule => 'RRULE';

  @override
  String get rruleHint => 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR';

  @override
  String get untitled => '(未命名)';

  @override
  String reminderText(Object minutes) {
    return '提醒：提前$minutes分钟';
  }

  @override
  String get reminderLabel => '提醒';

  @override
  String rruleText(Object rrule) {
    return 'RRULE：$rrule';
  }

  @override
  String get eventDetails => '事件详情';

  @override
  String get seriesEditsNote => '编辑将应用于整个系列。';

  @override
  String weekOf(Object date) {
    return '$date 那一周';
  }

  @override
  String get importExport => '导入与导出';

  @override
  String get importIcs => '导入 ICS';

  @override
  String get exportIcs => '导出 ICS';

  @override
  String get networkSubscriptions => '网络订阅';

  @override
  String get subscribeUrl => '订阅 URL';

  @override
  String get subscribeUrlHint => 'https://example.com/calendar.ics';

  @override
  String get addSubscription => '添加订阅';

  @override
  String get noSubscriptions => '未添加订阅。';

  @override
  String get refreshSubscriptions => '刷新订阅';

  @override
  String get saveCalendarAs => '另存为日历';

  @override
  String get notificationAppName => 'TCamp 日历';

  @override
  String get notificationChannelName => '日历提醒';

  @override
  String get notificationChannelDescription => '事件提醒';

  @override
  String get notificationTime => '提醒时间';

  @override
  String get linuxActionOpen => '打开';

  @override
  String get languageLabel => '语言';

  @override
  String get languageSystemDefault => '系统默认';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageChinese => '中文';
}
