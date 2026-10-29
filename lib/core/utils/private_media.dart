const privateMediaBuckets = [
  'Report Evidence',
  'Cleanup Task Photos',
  'Report Cleanup',
  'Cleanup Originals',
];
bool isPrivateMedia(String source, String supabaseOrigin) {
  if (source.startsWith('storage:')) return true;
  try {
    final uri = Uri.parse(source), origin = Uri.parse(supabaseOrigin);
    return uri.origin == origin.origin &&
        uri.pathSegments.length >= 5 &&
        uri.pathSegments.take(3).join('/') == 'storage/v1/object' &&
        privateMediaBuckets.contains(uri.pathSegments[4]);
  } catch (_) {
    return false;
  }
}

Uri? privateMediaTarget(
  String source,
  String supabaseOrigin,
  String backendOrigin,
) {
  try {
    String bucket, path;
    if (source.startsWith('storage:')) {
      final match = RegExp(r'^storage://([^/]+)/([^?#]+)$').firstMatch(source);
      if (match == null) return null;
      bucket = Uri.decodeComponent(match.group(1)!);
      path = Uri.decodeComponent(match.group(2)!);
    } else {
      final uri = Uri.parse(source), origin = Uri.parse(supabaseOrigin);
      if (uri.origin != origin.origin || uri.userInfo.isNotEmpty) return null;
      final parts = uri.pathSegments;
      if (parts.length < 6 ||
          parts.take(3).join('/') != 'storage/v1/object' ||
          !['public', 'sign', 'authenticated'].contains(parts[3])) {
        return null;
      }
      bucket = parts[4];
      path = parts.skip(5).join('/');
    }
    final parts = path.split('/');
    if (!privateMediaBuckets.contains(bucket) ||
        path.length > 1024 ||
        parts.any(
          (part) =>
              part.isEmpty ||
              part == '.' ||
              part == '..' ||
              !RegExp(r'^[a-zA-Z0-9._-]{1,128}$').hasMatch(part),
        )) {
      return null;
    }
    if (bucket == 'Report Evidence'
        ? (parts.length < 2 || parts.length > 6)
        : (parts.length != 3 || !['before', 'after'].contains(parts[1]))) {
      return null;
    }
    final backend = Uri.parse(backendOrigin);
    if (!['http', 'https'].contains(backend.scheme) ||
        backend.host.isEmpty ||
        backend.userInfo.isNotEmpty) {
      return null;
    }
    return backend
        .resolve('/api/media/storage')
        .replace(queryParameters: {'bucket': bucket, 'path': path});
  } catch (_) {
    return null;
  }
}
