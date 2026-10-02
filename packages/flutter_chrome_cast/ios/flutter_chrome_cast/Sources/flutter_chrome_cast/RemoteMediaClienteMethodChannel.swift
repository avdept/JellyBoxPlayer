//
//  RemoteMediaClientMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Flutter
import Foundation
import GoogleCast

/// Flutter method channel for Google Cast remote media client operations
/// 
/// This class manages all media-related operations for Google Cast sessions,
/// including media loading, playback control, queue management, and status monitoring.
/// It implements the Google Cast remote media client listener protocol to receive
/// media state updates and communicates these back to Flutter.
///
/// Key features:
/// - Media loading and queue management
/// - Playback controls (play, pause, stop, seek)
/// - Volume and track controls
/// - Real-time media status updates to Flutter
/// - Position tracking with automatic updates
/// - Singleton pattern for consistent media state
///
/// The class maintains internal state for queue management and provides
/// comprehensive media control capabilities to the Flutter application.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
class RemoteMediaClienteMethodChannel :UIResponder, FlutterPlugin, GCKRemoteMediaClientListener{
    
    // MARK: - Singleton Implementation
    
    /// Private initializer to enforce singleton pattern
    private override init() {
        
    }
    
    /// Shared singleton instance
    static private let _instance = RemoteMediaClienteMethodChannel()
    
    /// Public accessor for the singleton instance
    /// - Returns: The shared RemoteMediaClienteMethodChannel instance
    static var instance : RemoteMediaClienteMethodChannel {
        _instance
    }
    
    // MARK: - Properties
    
    /// Flutter method channel for remote media client communication
    /// Used to send media events and handle method calls from Flutter
    var channel : FlutterMethodChannel?
    
    /// Reference to the current Cast session's remote media client
    /// - Returns: The media client for the current session, or nil if no session
    private var currentRemoteMediaCliente: GCKRemoteMediaClient? {
        GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient
    }
    
    /// Timer for tracking media position updates
    /// Automatically sends position updates to Flutter during playback
    private  var positionTimer: Timer?
    
    /// Array maintaining the order of queue items
    /// Stores NSNumber IDs representing the queue item order
    private var queueOrder : [NSNumber] = []
    
    /// Dictionary storing queue items by their ID
    /// Maps queue item IDs to their corresponding GCKMediaQueueItem objects
    private var queueItems  : Dictionary<UInt, GCKMediaQueueItem> = [:]

    /// The last `contentID` that the Flutter side passed when loading media.
    ///
    /// The Google Cast Default Media Receiver does not always echo the
    /// `contentID` we sent back in the first `mediaStatus` update — in that
    /// case `GCKMediaInformation.contentID` is nil/empty. To match Android
    /// behaviour (where the originally provided `contentID` is delivered from
    /// the very first update), we cache the value sent from Flutter and
    /// substitute it into the media status map whenever the receiver reports
    /// an empty `contentID`.
    private var lastLoadedContentID: String?

    /// Computed property returning queue items in proper order
    /// - Returns: Array of queue items sorted according to queueOrder
    private var orderedQueueItems : Array<GCKMediaQueueItem> {
        var items : [GCKMediaQueueItem] = []
        
        for queueItemId in queueOrder {
            if let value = queueItems[UInt(truncating: queueItemId)] {
                items.append(value)
            }
        }
        return items
    }
    
    // MARK: - Flutter Plugin Registration
    
    
    /// Registers the remote media client method channel with Flutter
    /// 
    /// Sets up the Flutter method channel for media control communication.
    /// The channel name is "google_cast.remote_media_client" and handles all
    /// media-related method calls from Flutter.
    ///
    /// - Parameter registrar: The Flutter plugin registrar for method channel setup
    static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = RemoteMediaClienteMethodChannel.instance
        
        instance.channel = FlutterMethodChannel(name: "google_cast.remote_media_client", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
    }
    
    // MARK: - Flutter Method Call Handling
    
    /// Handles method calls from the Flutter side
    /// 
    /// Processes incoming method calls for media control operations.
    /// Supports comprehensive media management including loading, playback control,
    /// queue management, and track selection.
    ///
    /// Supported methods:
    /// - `loadMedia`: Load a single media item
    /// - `queueLoadItems`: Load multiple items into a queue
    /// - `stop`: Stop media playback
    /// - `play`: Start or resume playback
    /// - `pause`: Pause playback
    /// - `setActiveTrackIDs`: Select specific media tracks
    /// - And many more media control operations...
    ///
    /// - Parameters:
    ///   - call: The Flutter method call containing method name and arguments
    ///   - result: Callback to return results or errors to Flutter
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadMedia":
            loadMedia(call.arguments as! Dictionary<String,Any>,result: result)
            break
        case "queueLoadItems":
            queueLoadItem(call.arguments as! Dictionary, result: result)
            break
        case "stop":
            stop(result)
            break
        case "play":
            play(result)
            break
        case "pause":
            pause(result)
            break
        case "setActiveTrackIDs":
            setActiveTrackIDs(result, call.arguments as! [NSNumber])
            break
        case "seek":
            seek(result, call.arguments as! Dictionary<String, Any>)
            break
        case "queueNextItem":
            queueNextItem(result)
            break
        case "queuePrevItem":
            queuePreviousItem(result)
            break
        case "queueInsertItems":
            queueInsertItems(call.arguments as! Dictionary<String, Any>, result:result)
            break
        case "queueInsertItemAndPlay":
            queueInsertItemAndPlay(call.arguments as! Dictionary<String, Any>, result:result)
            break
        case "queueJumpToItemWithId":
            queueJumpToItemWithId(call.arguments as! UInt, result: result)
            break
        case "queueReorderItems":
            queueReorderItems(call.arguments as! Dictionary<String,Any?>, result: result)
            break;
        case "queueRemoveItemsWithIds":
            queueRemoveItemsWithIds(call.arguments as? [NSNumber] ?? [], result: result)
            break
        case "setPlaybackRate":
            setPlaybackRate(result, call.arguments as! Double)
            break       
        default:
            break
        }
        
        
    }
    
    
    func queueReorderItems(_ arguments : Dictionary<String,Any?>, result: FlutterResult){
        let itemIds = arguments["itemsIds"] as! [NSNumber]
        let beforeItemId = (arguments["beforeItemWithId"] as? NSNumber)?.uintValue ?? kGCKMediaQueueInvalidItemID
        let request = currentRemoteMediaCliente?.queueReorderItems(withIDs: itemIds, insertBeforeItemWithID: beforeItemId)
        result(request?.toMap())
    }

    func queueRemoveItemsWithIds(_ itemIds: [NSNumber], result: FlutterResult) {
        let request = currentRemoteMediaCliente?.queueRemoveItems(withIDs: itemIds)
        result(request?.toMap())
    }
    
    func queueJumpToItemWithId(_ id: UInt, result: FlutterResult){
        currentRemoteMediaCliente?.queueJumpToItem(withID: id)
        result(true)
    }
    
    
    private func queueInsertItemAndPlay(_ arguments: Dictionary<String,Any>, result : FlutterResult) {
        let itemDict = arguments["item"] as! Dictionary<String,Any>
        let beforItemWithId = arguments["beforeItemWithId"] as! UInt
        guard let item = GCKMediaQueueItem.fromMap(itemDict) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid item", details: nil))
            return
        }
        let request =  currentRemoteMediaCliente?.queueInsertAndPlay(item, beforeItemWithID: beforItemWithId)
        result(request?.toMap())
    }
    
    private func queueInsertItems(_ arguments: Dictionary<String,Any>, result : FlutterResult) {
        let itemsDict = arguments["items"] as! [Dictionary<String,Any>]
        let beforItemWithId = arguments["beforeItemWithId"] as? UInt
        let items = itemsDict.compactMap{
            dict in
            GCKMediaQueueItem.fromMap(dict)
        }
        let request =  currentRemoteMediaCliente?.queueInsert(items,beforeItemWithID: beforItemWithId ?? kGCKMediaQueueInvalidItemID )
        result(request?.toMap())
    }
    
    private func queueLoadItem(_ arguments: Dictionary<String,Any>, result : FlutterResult) {
        let itemsDict = arguments["items"] as! [Dictionary<String, Any>]
        let items = itemsDict.compactMap{
            map in
            GCKMediaQueueItem.fromMap(map)
        }
        let optionsDict = arguments["options"] as? Dictionary<String, Any>
        let options = GCKMediaQueueLoadOptions.fromMap(optionsDict) ?? GCKMediaQueueLoadOptions.init()
        let autoPlay = optionsDict?["autoPlay"] as? Bool ?? true

        let queueData = GCKMediaQueueDataBuilder(queueType: .generic)
        queueData.items = items
        queueData.startIndex = options.startIndex
        queueData.repeatMode = options.repeatMode

        let requestData = GCKMediaLoadRequestDataBuilder()
        requestData.queueData = queueData.build()
        requestData.autoplay = NSNumber(value: autoPlay)
        requestData.startTime = options.playPosition
        requestData.customData = options.customData

        lastLoadedContentID = nil
        let request = currentRemoteMediaCliente?.loadMedia(with: requestData.build())
        result(request?.toMap())
    }
    
    private  func loadMedia(_ arguments : Dictionary<String,Any>, result : FlutterResult )  {
        let sensitiveKeys: Set<String> = ["customData", "credentials"]
        let safeArgs = arguments.filter { !sensitiveKeys.contains($0.key) }
        print("[GoogleCast] loadMedia() called with arguments: \(safeArgs)")
        guard let mediaInfo = GCKMediaInformation.fromMap(arguments) else {
            print("[GoogleCast] loadMedia() failed to create GCKMediaInformation")
            result(FlutterError.init(code: "1", message:"fail to generate media info", details: nil))
            return
            
        }

        // Cache the contentID that Flutter passed so we can inject it into
        // subsequent media status updates where the receiver reports no
        // contentID back (see `applyContentIDFallback`).
        if let contentID = arguments["contentID"] as? String, !contentID.isEmpty {
            self.lastLoadedContentID = contentID
        } else {
            self.lastLoadedContentID = nil
        }
        
        print("[GoogleCast] loadMedia() mediaInfo created - contentID: \(mediaInfo.contentID ?? "nil"), contentType: \(mediaInfo.contentType ?? "nil"), streamType: \(mediaInfo.streamType.rawValue)")
        
        let requestDataBuilder = GCKMediaLoadRequestDataBuilder()
        requestDataBuilder.mediaInformation = mediaInfo
        if let autoPlay = arguments["autoPlay"] as? Bool {
            requestDataBuilder.autoplay = NSNumber(value: autoPlay)
        }
        if let playPosition = arguments["playPosition"] as? TimeInterval {
            requestDataBuilder.startTime = playPosition
        }
        if let playbackRate = arguments["playbackRate"] as? Float {
            requestDataBuilder.playbackRate = playbackRate
        }
        if let activeTrackIds = arguments["activeTrackIds"] as? [NSNumber] {
            requestDataBuilder.activeTrackIDs = activeTrackIds
        }
        if let credentialType = arguments["credentialsType"] as? String {
            requestDataBuilder.credentialsType = credentialType
        }
        if let credentials = arguments["credentials"] as? String {
            requestDataBuilder.credentials = credentials
        }
        if let customData = arguments["customData"] as? [String: Any] {
            requestDataBuilder.customData = customData as NSObject
        }
        let requestData = requestDataBuilder.build()

        let request = currentRemoteMediaCliente?.loadMedia(with: requestData)

        result(request?.toMap())
        
        
    }
    
    private func pause(_ result : FlutterResult){
        print("[GoogleCast] pause() called, remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        let request =  currentRemoteMediaCliente?.pause()
        print("[GoogleCast] pause() request: \(String(describing: request))")
        result(  request?.toMap() )
        
        
    }
    
    private func stop(_ result : FlutterResult){
        print("[GoogleCast] stop() called, remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        let request =  currentRemoteMediaCliente?.stop()
        result(  request?.toMap() )
        
        
    }
    
    private func play(_ result : FlutterResult){
        print("[GoogleCast] play() called, remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        let request =  currentRemoteMediaCliente?.play()
        print("[GoogleCast] play() request: \(String(describing: request))")
        result(  request?.toMap() )
        
        
    }
    
    private func setActiveTrackIDs(_ result : FlutterResult, _ args : [NSNumber] ){
        let request =  currentRemoteMediaCliente?.setActiveTrackIDs(args)
        result(request?.toMap())
    }
    
    private func seek(_ result : FlutterResult, _ args : Dictionary<String, Any>){
        print("[GoogleCast] seek() called with args: \(args), remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        let seekOptions = GCKMediaSeekOptions.fromMap(args: args)
        print("[GoogleCast] seek() options - interval: \(seekOptions.interval), relative: \(seekOptions.relative)")
        let request =  currentRemoteMediaCliente?.seek(with: seekOptions)
        print("[GoogleCast] seek() request: \(String(describing: request))")
        result(request?.toMap())
    }
    
    private func setPlaybackRate(_ result: FlutterResult, _ rate: Double) {
        print("[GoogleCast] setPlaybackRate() called with rate: \(rate)")
        let request = currentRemoteMediaCliente?.setPlaybackRate(Float(rate))
        result(request?.toMap())
    }
    
    private func queueNextItem(_ result : FlutterResult){
        let request =  currentRemoteMediaCliente?.queueNextItem()
        result(request?.toMap())
    }
    
    private func queuePreviousItem(_ result : FlutterResult){
        let request =  currentRemoteMediaCliente?.queuePreviousItem()
        result(request?.toMap())
    }
    
    public func startListen(){
        print("[GoogleCast] startListen() called, adding listener to remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        currentRemoteMediaCliente?.add(self)
    }
    
    
    //MARK: - GCKRemoteMediaClientListener
    

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        print("[GoogleCast] didUpdate mediaStatus - playerState: \(mediaStatus?.playerState.rawValue ?? -1), idleReason: \(mediaStatus?.idleReason.rawValue ?? -1)")
        print("[GoogleCast] mediaStatus contentID: \(mediaStatus?.mediaInformation?.contentID ?? "nil")")
        startListenPlayerPosition()
        var data = mediaStatus?.toMap()
        applyContentIDFallback(&data)

        channel?.invokeMethod("onUpdateMediaStatus", arguments:data)
        if client.mediaStatus?.idleReason == .finished && client.mediaStatus?.queueHasNextItem != true {
         onSessionEnd()
        }
    }

    /// Ensures the media status map forwarded to Flutter always contains a
    /// usable `contentID` inside `mediaInformation`.
    ///
    /// Priority:
    ///   1. `contentID` already populated by the receiver (kept as-is).
    ///   2. The `contentID` originally passed from Flutter in `loadMedia`
    ///      (cached in `lastLoadedContentID`).
    ///   3. `contentURL` as a last-resort fallback.
    private func applyContentIDFallback(_ data: inout Dictionary<String, Any>?) {
        guard var status = data,
              var mediaInformation = status["mediaInformation"] as? Dictionary<String, Any> else {
            return
        }

        let existing = mediaInformation["contentID"] as? String
        if existing == nil || existing?.isEmpty == true {
            if let cached = lastLoadedContentID, !cached.isEmpty {
                mediaInformation["contentID"] = cached
            } else if let contentURL = mediaInformation["contentURL"] as? String, !contentURL.isEmpty {
                mediaInformation["contentID"] = contentURL
            }
            status["mediaInformation"] = mediaInformation
            data = status
        }
    }
    
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didReceive queueItems: [GCKMediaQueueItem]) {
        for queuItem in queueItems {
            self.queueItems[queuItem.itemID] = queuItem
        }
        updateQueueItems()
      
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int) {
        print("[GoogleCast] didStartMediaSessionWithID: \(sessionID)")
        startListenPlayerPosition()
    }
    
    
    
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didRemoveQueueItemsWithIDs queueItemIDs: [NSNumber]) {
        
        self.queueOrder.removeAll{
            index in
            queueItemIDs.contains(index)
        }
        
        for index in queueItemIDs {
            self.queueItems.removeValue(forKey: UInt(truncating: index))
        }
        
        updateQueueItems()
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdateQueueItemsWithIDs queueItemIDs: [NSNumber]) {
        client.queueFetchItems(forIDs: queueItemIDs)
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didInsertQueueItemsWithIDs queueItemIDs: [NSNumber], beforeItemWithID beforeItemID: UInt) {
        guard let index = queueOrder.firstIndex(of: NSNumber(value: beforeItemID)) else {
            queueOrder.append(contentsOf: queueItemIDs)
            client.queueFetchItems(forIDs: queueItemIDs)
            return
        }
        queueOrder.insert(contentsOf: queueItemIDs, at: index)
        client.queueFetchItems(forIDs: queueItemIDs)
        
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didReceiveQueueItemIDs queueItemIDs: [NSNumber]) {
        queueOrder = queueItemIDs
        client.queueFetchItems(forIDs: queueItemIDs)
    }
    
    
 
  
    
    
    private func updateQueueItems() {
        
        channel?.invokeMethod("updateQueueItems", arguments: orderedQueueItems.map{
            queueItem in
            queueItem.toMap()
        })
    }
    
    public func onSessionEnd(){
        queueItems.removeAll()
        queueOrder.removeAll()
        lastLoadedContentID = nil
        updateQueueItems()
    }
    
    /// Full state cleanup: removes the listener from the media client,
    /// stops the position timer, and clears the queue.
    /// Used when forcefully resetting a stuck session.
    public func cleanUp() {
        currentRemoteMediaCliente?.remove(self)
        positionTimer?.invalidate()
        positionTimer = nil
        queueItems.removeAll()
        queueOrder.removeAll()
    }
    
    
    public func resumeSession(){
        currentRemoteMediaCliente?.requestStatus()
        currentRemoteMediaCliente?.queueFetchItemIDs();
    }
    
    private func startListenPlayerPosition(){
        self.positionTimer?.invalidate()
        self.positionTimer = nil
        
        self.positionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ [weak self] _ in
            guard let self = self else { return }
            let position = self.currentRemoteMediaCliente?.approximateStreamPosition() ?? 0
            self.channel?.invokeMethod("onUpdatePlayerPosition", arguments: Int(position * 1000))
        }
    }

}
