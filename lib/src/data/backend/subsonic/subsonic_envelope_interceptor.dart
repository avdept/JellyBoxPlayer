import 'package:dio/dio.dart';
import 'package:jplayer/src/data/api/subsonic/subsonic_api.dart';
import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';

class SubsonicEnvelopeInterceptor extends Interceptor {
  const SubsonicEnvelopeInterceptor();

  static void install(Dio dio) {
    if (dio.interceptors.whereType<SubsonicEnvelopeInterceptor>().isEmpty) {
      dio.interceptors.add(const SubsonicEnvelopeInterceptor());
    }
  }

  static int httpStatusForCode(int? code) => switch (code) {
    40 || 41 => 401,
    50 => 409,
    70 => 404,
    _ => 500,
  };

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!response.requestOptions.path.contains('/rest/')) {
      return handler.next(response);
    }
    final envelope = SubsonicApi.envelopeOf(response.data);
    if (envelope == null) return handler.next(response);

    final parsed = SubsonicEnvelopeDTO.fromJson(envelope);
    if (!parsed.isFailed) return handler.next(response);

    final statusCode = httpStatusForCode(parsed.error?.code);
    final failed = Response<dynamic>(
      requestOptions: response.requestOptions,
      data: response.data,
      statusCode: statusCode,
      statusMessage: parsed.error?.message,
      headers: response.headers,
      isRedirect: response.isRedirect,
      redirects: response.redirects,
      extra: response.extra,
    );
    handler.reject(
      DioException.badResponse(
        statusCode: statusCode,
        requestOptions: response.requestOptions,
        response: failed,
      ),
      true,
    );
  }
}
