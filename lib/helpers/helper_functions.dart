import 'package:cloud_firestore/cloud_firestore.dart';

String convertTimestamp(Timestamp timestamp) {
  final date = timestamp.toDate();
  var h = date.hour.toInt();
  var hour = h.toString();
  var amPm = 'AM';
  if (h == 0) {
    hour = '12';
    amPm = 'AM';
  } else if (h == 12) {
    hour = '12';
    amPm = 'PM';
  } else if (h > 12) {
    hour = '${h - 12}';
    amPm = 'PM';
  }
  var minute = date.minute.toString();
  if (hour.length < 2) hour = '0$hour';
  if (minute.length < 2) minute = '0$minute';

  return '$hour:$minute $amPm (${date.day}/${date.month}/${date.year})';
}

String convertDateTime(DateTime date) {
  var h = date.hour.toInt();
  var hour = h.toString();
  var amPm = 'AM';
  if (h == 0) {
    hour = '12';
    amPm = 'AM';
  } else if (h == 12) {
    hour = '12';
    amPm = 'PM';
  } else if (h > 12) {
    hour = '${h - 12}';
    amPm = 'PM';
  }
  var minute = date.minute.toString();
  if (hour.length < 2) hour = '0$hour';
  if (minute.length < 2) minute = '0$minute';

  return '$hour:$minute $amPm (${date.day}/${date.month}/${date.year})';
}
