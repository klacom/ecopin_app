import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecopin_app/core/utils/private_media.dart';

class PrivateMediaImage extends StatefulWidget {
  final String source;
  final double? width, height;
  final BoxFit? fit;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final bool useCache;
  const PrivateMediaImage(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.loadingBuilder,
    this.errorBuilder,
    this.placeholder,
    this.errorWidget,
    this.useCache = false,
  });
  factory PrivateMediaImage.cached({
    required String imageUrl,
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, Object)? errorWidget,
  }) => PrivateMediaImage(
    imageUrl,
    key: key,
    width: width,
    height: height,
    fit: fit,
    placeholder: placeholder,
    errorWidget: errorWidget,
    useCache: true,
  );
  @override
  State<PrivateMediaImage> createState() => _PrivateMediaImageState();
}

class _PrivateMediaImageState extends State<PrivateMediaImage> {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  StreamSubscription<AuthState>? _auth;
  CancelToken? _cancel;
  Uint8List? _bytes;
  Object? _error;
  int _generation = 0;
  bool _private = false, _loading = false;
  @override
  void initState() {
    super.initState();
    _load();
    _auth = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (_private &&
          !(_loading && state.event == AuthChangeEvent.tokenRefreshed)) {
        _load();
      }
    });
  }

  @override
  void didUpdateWidget(covariant PrivateMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _cancel?.cancel();
    final cancel = _cancel = CancelToken();
    final origin = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
    _private = isPrivateMedia(widget.source, origin);
    if (mounted) {
      setState(() {
        _bytes = null;
        _error = null;
        _loading = _private;
      });
    }
    if (!_private) return;
    try {
      final uri = privateMediaTarget(
        widget.source,
        origin,
        dotenv.env['BACKEND_URL'] ?? '',
      );
      if (uri == null) throw StateError('Private image unavailable');
      final auth = Supabase.instance.client.auth;
      var token = auth.currentSession?.accessToken;
      if (token == null) throw StateError('Authentication required');
      Future<Response<List<int>>> read() => _dio.getUri<List<int>>(
        uri,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $token',
            'Cache-Control': 'no-store',
          },
        ),
        cancelToken: cancel,
      );
      Response<List<int>> result;
      try {
        result = await read();
      } on DioException catch (error) {
        if (error.response?.statusCode != 401) rethrow;
        await auth.refreshSession();
        token = auth.currentSession?.accessToken;
        if (token == null) throw StateError('Authentication required');
        result = await read();
      }
      if (mounted && generation == _generation) {
        setState(() {
          _bytes = Uint8List.fromList(result.data!);
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _cancel?.cancel();
    _auth?.cancel();
    _dio.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_private) {
      if (widget.useCache) {
        return CachedNetworkImage(
          imageUrl: widget.source,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholder: widget.placeholder,
          errorWidget: widget.errorWidget,
        );
      }
      return Image.network(
        widget.source,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: widget.loadingBuilder,
        errorBuilder: widget.errorBuilder,
      );
    }
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    }
    Widget child;
    if (_loading) {
      child =
          widget.placeholder?.call(context, widget.source) ??
          widget.loadingBuilder?.call(
            context,
            const SizedBox.shrink(),
            const ImageChunkEvent(
              cumulativeBytesLoaded: 0,
              expectedTotalBytes: 1,
            ),
          ) ??
          const Center(child: CircularProgressIndicator());
    } else {
      final error = _error ?? StateError('Private image unavailable');
      child =
          widget.errorBuilder?.call(context, error, null) ??
          widget.errorWidget?.call(context, widget.source, error) ??
          const Icon(Icons.broken_image);
    }
    return SizedBox(width: widget.width, height: widget.height, child: child);
  }
}
