import 'package:optional_features/upnp_quirks.dart';

class FakeSpeakerGroups implements SpeakerGroups {
  FakeSpeakerGroups(this._groups, {this.volumes = const {}})
    : _volumes = Map.of(volumes);

  List<List<SpeakerGroupMember>> _groups;
  final Map<String, int> volumes;
  final Map<String, int> _volumes;
  final log = <String>[];
  int settleAfterPolls = 0;
  Exception? joinError;
  List<List<SpeakerGroupMember>>? _pending;
  var _pollsUntilSettled = 0;

  SpeakerTopology get current => SpeakerTopology([
    for (final members in _groups)
      SpeakerGroup(
        id: '${members.first.id}:1',
        coordinatorId: members.first.id,
        members: members,
      ),
  ]);

  @override
  Future<SpeakerTopology> topology() async {
    log.add('topology');
    final pending = _pending;
    if (pending != null && --_pollsUntilSettled <= 0) {
      _groups = pending;
      _pending = null;
    }
    return current;
  }

  @override
  Future<void> join(String memberId, String coordinatorId) async {
    log.add('join $memberId -> $coordinatorId');
    final error = joinError;
    if (error != null) throw error;
    final member = _take(memberId);
    final next = [
      for (final group in _groups)
        if (group.first.id == coordinatorId) [...group, member] else group,
    ];
    _apply(next);
  }

  @override
  Future<void> leave(String memberId) async {
    log.add('leave $memberId');
    final member = _take(memberId);
    _apply([
      ..._groups,
      [member],
    ]);
  }

  @override
  Future<int?> groupVolume(String coordinatorId) async {
    log.add('groupVolume $coordinatorId');
    return _volumes[coordinatorId];
  }

  @override
  Future<void> setGroupVolume(String coordinatorId, int volume) async {
    log.add('setGroupVolume $coordinatorId $volume');
  }

  @override
  Future<int?> memberVolume(String memberId) async => _volumes[memberId];

  @override
  Future<void> setMemberVolume(String memberId, int volume) async {
    log.add('setMemberVolume $memberId $volume');
    _volumes[memberId] = volume;
  }

  SpeakerGroupMember _take(String memberId) {
    final member = current.member(memberId)!;
    _groups = [
      for (final group in _groups)
        if (group.first.id != memberId || group.length == 1)
          [
            for (final each in group)
              if (each.id != memberId) each,
          ]
        else
          group.sublist(1),
    ].where((group) => group.isNotEmpty).toList();
    return member;
  }

  void _apply(List<List<SpeakerGroupMember>> next) {
    if (settleAfterPolls <= 0) {
      _groups = next;
      return;
    }
    _pending = next;
    _pollsUntilSettled = settleAfterPolls;
  }
}

SpeakerGroupMember speaker(String name, {bool visible = true}) =>
    SpeakerGroupMember(
      id: 'uuid:RINCON_${name.toUpperCase()}',
      name: name,
      location: Uri.parse(
        'http://10.0.0.${name.length}:1400/xml/device_description.xml',
      ),
      visible: visible,
    );
