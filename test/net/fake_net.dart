import 'dart:async';
import 'dart:convert';

import 'package:pubnub/core.dart';

class MockException extends PubNubException {
  MockException(String message) : super(message);
}

class FakeRequestHandler extends IRequestHandler {
  Request request;
  Mock mock;

  FakeRequestHandler(this.mock);

  @override
  Future<IResponse> response(Request request) {
    var actualUri = prepareUri(request.uri);
    var expectedUri = prepareUri(Uri.parse(mock.request.path));

    var doesMethodMatch =
        mock.request.method.toUpperCase() == request.type.method.toUpperCase();

    String body;
    if (request.body is String) {
      body = request.body;
    } else if (request.body == null) {
      body = null;
    } else {
      body = json.encode(request.body);
    }

    String mockBody;

    if (request.body is String) {
      mockBody = mock.request.body;
    } else if (request.body == null) {
      mockBody = null;
    } else {
      mockBody = json.encode(json.decode(mock.request.body));
    }

    var doesBodyMatch = mockBody == body;

    var doesUriMatch = expectedUri.toString() == actualUri.toString();

    return Future.microtask(() {
      if (doesMethodMatch && doesBodyMatch && doesUriMatch) {
        if (![200, 204].contains(mock.response.statusCode)) {
          throw PubNubRequestFailureException(mock.response);
        } else {
          return mock.response;
        }
      } else {
        var exceptionBody = '';

        if (!doesMethodMatch) {
          exceptionBody +=
              '\n* method:\n| EXPECTED: ${mock.request.method.toUpperCase()}\n| ACTUAL:   ${request.type.method.toUpperCase()}';
        }
        if (!doesUriMatch) {
          exceptionBody +=
              '\n* uri:\n| EXPECTED: ${expectedUri}\n| ACTUAL:   ${actualUri}';
        }
        if (!doesBodyMatch) {
          exceptionBody +=
              '\n* body:\n| EXPECTED:\n${mockBody}\n| ACTUAL:\n${body}';
        }

        throw MockException(
            'mock request does not match the expected request $exceptionBody');
      }
    });
  }

  @override
  void cancel([dynamic reason]) {}
}

class MockRequest {
  final String method;
  final String path;
  final dynamic body;
  final Map<String, List<String>> headers;

  const MockRequest(this.method, this.path,
      [this.headers = const {}, this.body]);
}

class MockResponse implements IResponse {
  final dynamic body;

  @override
  final Map<String, List<String>> headers;

  @override
  final int statusCode;

  const MockResponse({this.body, this.headers = const {}, this.statusCode});

  @override
  List<int> get byteList => body;

  @override
  String get text => body;
}

class Mock {
  final MockRequest request;
  final MockResponse response;

  Mock(this.request, this.response);
}

class MockBuilder {
  final List<Mock> _queue;
  final MockRequest _request;

  MockBuilder(this._queue, this._request);

  void then(
      {Map<String, List<String>> headers,
      dynamic body,
      int status,
      MockResponse response}) {
    var mock = Mock(
        _request,
        response ??
            MockResponse(statusCode: status, body: body, headers: headers));

    _queue.add(mock);
  }
}

List<Mock> _queue = [];

MockBuilder when(
    {String method,
    String path,
    Map<String, List<String>> headers,
    dynamic body,
    MockRequest request}) {
  return MockBuilder(
      _queue, request ?? MockRequest(method, path, headers, body));
}

class FakeNetworkingModule implements INetworkingModule {
  FakeNetworkingModule() {
    _queue.clear();
  }

  @override
  Future<IRequestHandler> handler() async {
    if (_queue.isEmpty) {
      throw MockException('set up the mock first');
    }

    return FakeRequestHandler(_queue.removeAt(0));
  }

  @override
  void register(Core core) {}
}
