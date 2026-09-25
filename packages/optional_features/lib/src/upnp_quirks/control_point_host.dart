enum ControlPointHost {
  sustained,
  suspending;

  bool get keepsPollingAlive => this == sustained;
}

bool castingSupported({
  required bool deviceHoldsQueue,
  required ControlPointHost host,
}) => deviceHoldsQueue || host.keepsPollingAlive;

String? castingBlockedReason({
  required bool deviceHoldsQueue,
  required ControlPointHost host,
}) => castingSupported(deviceHoldsQueue: deviceHoldsQueue, host: host)
    ? null
    : 'Needs a speaker that holds its own queue';
