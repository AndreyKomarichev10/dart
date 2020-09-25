import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class ChannelGroupListChannelsParams extends Parameters {
  Keyset keyset;
  String name;

  ChannelGroupListChannelsParams(this.keyset, this.name);

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'channel-registration',
      'sub-key',
      keyset.subscribeKey,
      'channel-group',
      name
    ];

    var queryParameters = {'auth': keyset.authKey, 'uuid': keyset.uuid.value};

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of list channel groups channels endpoint call.
///
/// {@category Results}
class ChannelGroupListChannelsResult extends Result {
  /// Channel group name.
  String name;

  /// Channel group channels.
  Set<String> channels;

  /// @nodoc
  ChannelGroupListChannelsResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);
    var payload = result.otherKeys['payload'];

    name = payload['group'] as String;
    channels = (payload['channels'] as List<dynamic>).cast<String>().toSet();
  }
}

class ChannelGroupChangeChannelsParams extends Parameters {
  Keyset keyset;
  String name;
  Set<String> add;
  Set<String> remove;

  ChannelGroupChangeChannelsParams(this.keyset, this.name,
      {this.add, this.remove});

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'channel-registration',
      'sub-key',
      keyset.subscribeKey,
      'channel-group',
      name
    ];

    var queryParameters = {
      'auth': keyset.authKey,
      'uuid': keyset.uuid.value,
      if (add != null) 'add': add.join(','),
      if (remove != null) 'remove': remove.join(',')
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of add or remove channels of channel group endpoint call.
///
/// {@category Results}
class ChannelGroupChangeChannelsResult extends Result {
  /// @nodoc
  ChannelGroupChangeChannelsResult.fromJson(Map<String, dynamic> object);
}

class ChannelGroupDeleteParams extends Parameters {
  Keyset keyset;
  String name;

  ChannelGroupDeleteParams(this.keyset, this.name);

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'channel-registration',
      'sub-key',
      keyset.subscribeKey,
      'channel-group',
      name,
      'remove'
    ];

    var queryParameters = {'auth': keyset.authKey, 'uuid': keyset.uuid.value};

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of remove channel group endpoint call.
///
/// {@category Results}
class ChannelGroupDeleteResult extends Result {
  /// @nodoc
  ChannelGroupDeleteResult.fromJson(Map<String, dynamic> object);
}
