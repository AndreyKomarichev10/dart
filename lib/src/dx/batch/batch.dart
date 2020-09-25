import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/history.dart';

export 'package:pubnub/src/dx/_endpoints/history.dart'
    show BatchHistoryResult, BatchHistoryResultEntry, CountMessagesResult;

/// Groups common **batch** features together.
///
/// Available as [PubNub.batch].
class BatchDx {
  final Core _core;

  /// @nodoc
  BatchDx(this._core);

  /// Fetch messages for multiple channels using one call.
  ///
  /// If [includeMessageActions] is `true`, then you can only pass in one channel in [channels].
  Future<BatchHistoryResult> fetchMessages(Set<String> channels,
      {Keyset keyset,
      String using,
      int count = 25,
      Timetoken start,
      Timetoken end,
      bool reverse,
      bool includeMeta,
      bool includeMessageActions = false,
      bool includeMessageType = true,
      bool includeUUID = true}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);

    if (includeMessageActions == true) {
      Ensure(channels.length).isEqual(1,
          'History can return actions data for a single channel only. Either pass a single channel or disable the includeMessageActions flag.');
    }
    var fetchMessagesResult = BatchHistoryResult()..channels = {};
    BatchHistoryResult loopResult;
    do {
      loopResult = await defaultFlow<BatchHistoryParams, BatchHistoryResult>(
          core: _core,
          params: BatchHistoryParams(keyset, channels,
              max: count,
              start: start,
              end: end,
              reverse: reverse,
              includeMeta: includeMeta,
              includeMessageActions: includeMessageActions,
              includeMessageType: includeMessageType,
              includeUUID: includeUUID),
          serialize: (object, [_]) => BatchHistoryResult.fromJson(object,
              cipherKey: keyset.cipherKey,
              decryptFunction: _core.crypto.decrypt));
      loopResult.channels.forEach((channel, messages) => {
            if (fetchMessagesResult.channels[channel] == null)
              {
                fetchMessagesResult.channels[channel] =
                    loopResult.channels[channel]
              }
            else
              {
                fetchMessagesResult.channels[channel]
                    .addAll(loopResult.channels[channel])
              }
          });
      if (loopResult.more != null) {
        var moreHistory = loopResult.more;
        start = Timetoken(int.parse(moreHistory.start));
        count = moreHistory.count;
      }
    } while (loopResult.more != null);
    return fetchMessagesResult;
  }

  /// Get multiple channels' message count using one call.
  ///
  /// [channels] can either be a `Map<String, Timetoken>` or `Set<String>`:
  /// * if you want to count messages in all channels up to a common timetoken, pass in a `Set<String>` and a named parameter [timetoken].
  /// * if you want to specify separate timetoken for each channel, pass in a `Map<String, Timetoken>`.
  ///   Additionally, if a value in the map is null, it will use a timetoken from a named parameter [timetoken].
  Future<CountMessagesResult> countMessages(dynamic channels,
      {Keyset keyset, String using, Timetoken timetoken}) {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);

    CountMessagesParams params;
    if (channels is Set<String>) {
      Ensure(timetoken)
          .isNotNull('When you pass in a Set, timetoken cannot be null.');

      params =
          CountMessagesParams(keyset, channels: channels, timetoken: timetoken);
    } else if (channels is Map<String, Timetoken>) {
      params = CountMessagesParams(keyset,
          channelsTimetoken:
              channels.map((key, value) => MapEntry(key, value ?? timetoken)));
    } else {
      Ensure.fail('invalid-type', 'channels',
          ['Set<String>', 'Map<String, Timetoken>']);
    }

    return defaultFlow(
        core: _core,
        params: params,
        serialize: (object, [_]) => CountMessagesResult.fromJson(object));
  }
}
