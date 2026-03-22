import 'api_constants.dart';

const Map<String, String> _bundledProductFallbackByFileName = {
  'women_dress.jpg': 'assets/images/products/women_dress.jpg',
  'women_blouse.jpg': 'assets/images/products/women_blouse.jpg',
  'men_oxford_shirt.jpg': 'assets/images/products/men_oxford_shirt.jpg',
  'men_street_hoodie.jpg': 'assets/images/products/men_street_hoodie.jpg',
};
const String _defaultCatalogFallbackAsset = 'assets/images/carousel_1.jpg';

Uri? _resolveApiOrigin() {
  final apiUri = Uri.tryParse(apiBaseUrl);
  if (apiUri == null || apiUri.host.isEmpty) {
    return null;
  }

  return Uri(
    scheme: apiUri.scheme,
    host: apiUri.host,
    port: apiUri.hasPort ? apiUri.port : null,
  );
}

String? resolveAssetImagePath(String source) {
  final value = source.trim().replaceAll('\\\\', '/');
  if (value.isEmpty) {
    return null;
  }

  if (value.startsWith('/assets/images/products/')) {
    return value.substring(1);
  }

  if (value.startsWith('assets/images/products/')) {
    return value;
  }

  return null;
}

String? resolveBundledFallbackAssetPath(String source) {
  final value = source.trim();
  if (value.isEmpty) {
    return null;
  }

  final directAssetPath = resolveAssetImagePath(value);
  if (directAssetPath != null) {
    return directAssetPath;
  }

  final fileName = _extractImageFileName(value);
  if (fileName != null) {
    final mapped = _bundledProductFallbackByFileName[fileName];
    if (mapped != null) {
      return mapped;
    }
  }

  final normalized = value.replaceAll('\\\\', '/').toLowerCase();
  if (normalized.contains('/images/products/') ||
      normalized.contains('images/products/')) {
    return _defaultCatalogFallbackAsset;
  }

  return null;
}

String? _extractImageFileName(String source) {
  final normalized = source.trim().replaceAll('\\\\', '/');
  if (normalized.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(normalized);
  if (uri != null && uri.path.isNotEmpty) {
    final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    if (fileName.isNotEmpty) {
      return fileName;
    }
  }

  final fileName = normalized.split('/').last;
  return fileName.isEmpty ? null : fileName;
}

String? resolveLegacySeedImageUrl(String source) {
  final assetPath = resolveAssetImagePath(source);
  if (assetPath == null) {
    return null;
  }

  final fileName = assetPath.split('/').last;
  if (fileName.isEmpty) {
    return null;
  }

  final origin = _resolveApiOrigin();
  if (origin == null) {
    return null;
  }

  return origin.resolve('/images/products/$fileName').toString();
}

String? resolveNetworkImageUrl(String source) {
  final value = source.trim().replaceAll('\\\\', '/');
  if (value.isEmpty) {
    return null;
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  // Product images stored as bundled Flutter assets should be rendered
  // by Image.asset at the call site.
  if (resolveAssetImagePath(value) != null) {
    return null;
  }

  final origin = _resolveApiOrigin();
  if (origin == null) {
    return null;
  }

  if (value.startsWith('/')) {
    return origin.resolveUri(Uri.parse(value)).toString();
  }

  if (value.startsWith('static/') || value.startsWith('uploads/')) {
    return origin.resolve(value).toString();
  }

  return null;
}
