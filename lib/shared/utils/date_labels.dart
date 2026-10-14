const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// "martes 13 oct"
String shortDateLabel(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

/// "Buenos días" / "Buenas tardes" / "Buenas noches"
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Buenos días';
  if (now.hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// "Ahora", "hace 4 min", "hace 2 h", "Ayer" o "13 oct".
String relativeTime(DateTime at, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(at);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inHours < 48) return 'Ayer';
  return '${at.day} ${_months[at.month - 1]}';
}