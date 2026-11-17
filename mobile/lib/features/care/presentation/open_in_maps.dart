import 'package:url_launcher/url_launcher.dart';

/// Opens the place in the maps app (Google Maps link), preferring the saved
/// coordinates when there are any.
Future<bool> openPlaceInMaps(String place, {double? lat, double? lng}) => launchUrl(
      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': lat != null && lng != null ? '$lat,$lng' : place}),
      mode: LaunchMode.externalApplication,
    );
