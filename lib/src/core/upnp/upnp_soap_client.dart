import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

class UpnpSoapFault implements Exception {
  const UpnpSoapFault({
    required this.action,
    this.statusCode,
    this.errorCode,
    this.description,
  });

  final String action;
  final int? statusCode;
  final String? errorCode;
  final String? description;

  @override
  String toString() =>
      'UpnpSoapFault($action, http $statusCode, code $errorCode: $description)';
}

class UpnpSoapClient {
  UpnpSoapClient({Dio? dio, this.timeout = const Duration(seconds: 5)})
    : _dio = dio ?? Dio();

  final Dio _dio;
  final Duration timeout;

  Future<Map<String, String>> invoke({
    required Uri controlUrl,
    required String serviceType,
    required String action,
    Map<String, String> arguments = const <String, String>{},
  }) async {
    final body = StringBuffer()
      ..write('<?xml version="1.0" encoding="utf-8"?>')
      ..write('<s:Envelope ')
      ..write('xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" ')
      ..write(
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">',
      )
      ..write('<s:Body><u:$action xmlns:u="$serviceType">');
    for (final argument in arguments.entries) {
      body.write(
        '<${argument.key}>${escapeXml(argument.value)}</${argument.key}>',
      );
    }
    body.write('</u:$action></s:Body></s:Envelope>');

    final response = await _dio.postUri<String>(
      controlUrl,
      data: body.toString(),
      options: Options(
        responseType: ResponseType.plain,
        contentType: 'text/xml; charset="utf-8"',
        headers: {'SOAPACTION': '"$serviceType#$action"'},
        sendTimeout: timeout,
        receiveTimeout: timeout,
        validateStatus: (_) => true,
      ),
    );

    final payload = response.data ?? '';
    final document = _tryParse(payload);

    if (response.statusCode != 200) {
      throw UpnpSoapFault(
        action: action,
        statusCode: response.statusCode,
        errorCode: _childText(document, 'errorCode'),
        description: _childText(document, 'errorDescription'),
      );
    }
    if (document == null) {
      throw UpnpSoapFault(
        action: action,
        statusCode: response.statusCode,
        description: 'unparsable response',
      );
    }

    final result = _element(document, '${action}Response');
    if (result == null) {
      throw UpnpSoapFault(
        action: action,
        statusCode: response.statusCode,
        errorCode: _childText(document, 'errorCode'),
        description:
            _childText(document, 'errorDescription') ??
            'no ${action}Response element',
      );
    }

    return {
      for (final child in result.childElements)
        child.localName: child.innerText,
    };
  }

  XmlDocument? _tryParse(String payload) {
    try {
      return XmlDocument.parse(payload);
    } on XmlException {
      return null;
    }
  }

  XmlElement? _element(XmlDocument document, String localName) => document
      .descendantElements
      .firstWhereOrNull((element) => element.localName == localName);

  String? _childText(XmlDocument? document, String localName) {
    if (document == null) return null;
    final element = _element(document, localName);
    final text = element?.innerText.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}

String escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
