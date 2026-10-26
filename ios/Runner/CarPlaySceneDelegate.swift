import CarPlay
import Flutter
import UIKit

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate,
  CPNowPlayingTemplateObserver {
  private var interfaceController: CPInterfaceController?
  private var tabBar: CPTabBarTemplate?
  private let homeTemplate = CPListTemplate(title: "JellyBox", sections: [])
  private let downloadsTemplate = CPListTemplate(title: "Downloads", sections: [])
  private let searchTemplate = CPListTemplate(title: "Search", sections: [])
  private weak var pushedTemplate: CPListTemplate?
  private var pushedType: String?
  private var pushedQuery: String?
  private var pushedArtistId: String?
  private var pushedEntries = [[String: Any]]()
  private var pushedHasMore = false
  private var pushedLoading = false
  private var lastQuery = ""
  private var lastSearchResults: [String: Any]?
  private var artworkCache = [String: UIImage]()
  private var trackedItems = [String: [(id: String, item: CPListItem)]]()
  private var sortField = "dateCreated"
  private var sortDescending = true
  private weak var carWindow: UIWindow?

  private var carScreenWidth: CGFloat {
    if let window = carWindow, window.bounds.width > 0 {
      return window.bounds.width
    }
    let external = UIScreen.screens.first { $0 !== UIScreen.main }
    return external?.bounds.width ?? 0
  }

  private func str(_ key: String, _ fallback: String) -> String {
    CarPlayBridge.shared.string(key, fallback)
  }

  private var sortLabels: [String: String] {
    [
      "sortName": str("sortName", "Name"),
      "albumArtist": str("sortAlbumArtist", "Album Artist"),
      "dateCreated": str("sortDateCreated", "Date Added"),
      "random": str("sortRandom", "Random"),
    ]
  }

  private var browseEntries: [(type: String, title: String, symbol: String)] {
    [
      ("albums", str("albums", "Albums"), "square.stack"),
      ("artists", str("artists", "Artists"), "music.mic"),
      ("playlists", str("playlists", "Playlists"), "music.note.list"),
      ("songs", str("songs", "Songs"), "music.note"),
    ]
  }

  private lazy var placeholderImage: UIImage? = {
    let key = FlutterDartProject.lookupKey(forAsset: "assets/images/album.png")
    guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
      return UIImage(systemName: "music.note")
    }
    return UIImage(contentsOfFile: path) ?? UIImage(systemName: "music.note")
  }()

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    self.interfaceController = interfaceController
    carWindow = templateApplicationScene.carWindow

    applyStaticLabels()
    homeTemplate.tabImage = UIImage(systemName: "house")
    downloadsTemplate.tabImage = UIImage(systemName: "arrow.down.circle")
    searchTemplate.tabImage = UIImage(systemName: "magnifyingglass")

    let tabBar = CPTabBarTemplate(templates: [homeTemplate, downloadsTemplate])
    self.tabBar = tabBar
    interfaceController.setRootTemplate(tabBar, animated: true, completion: nil)

    CarPlayBridge.shared.onContentChanged = { [weak self] in
      self?.reload()
    }
    CarPlayBridge.shared.onHomeChanged = { [weak self] in
      self?.reloadHome()
    }
    CarPlayBridge.shared.onPlaybackStateChanged = { [weak self] in
      self?.applyPlaybackState()
    }
    CarPlayBridge.shared.onModesChanged = { [weak self] in
      self?.applyNowPlayingButtons()
    }
    CarPlayBridge.shared.onSearchChanged = { [weak self] query in
      self?.searchQueryChanged(query)
    }
    CarPlayBridge.shared.onStringsChanged = { [weak self] in
      self?.applyStaticLabels()
      self?.reload()
    }
    CPNowPlayingTemplate.shared.isUpNextButtonEnabled = true
    CPNowPlayingTemplate.shared.add(self)
    applyNowPlayingButtons()
    reload()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    self.interfaceController = nil
    CarPlayBridge.shared.onContentChanged = nil
    CarPlayBridge.shared.onHomeChanged = nil
    CarPlayBridge.shared.onPlaybackStateChanged = nil
    CarPlayBridge.shared.onModesChanged = nil
    CarPlayBridge.shared.onSearchChanged = nil
    CarPlayBridge.shared.onStringsChanged = nil
    CPNowPlayingTemplate.shared.remove(self)
  }

  private func applyStaticLabels() {
    homeTemplate.tabTitle = str("home", "Home")
    downloadsTemplate.tabTitle = str("downloads", "Downloads")
    searchTemplate.tabTitle = str("search", "Search")
    searchTemplate.emptyViewTitleVariants = [str("noResults", "No results")]
  }

  func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
    pushQueue()
  }

  private static let accentColor = UIColor(
    red: 0xFD / 255.0,
    green: 0x2F / 255.0,
    blue: 0x2F / 255.0,
    alpha: 1
  )

  private func applyNowPlayingButtons() {
    let repeatMode = CarPlayBridge.shared.repeatMode
    let liked = CarPlayBridge.shared.likedCurrent
    let shuffle = CPNowPlayingImageButton(
      image: modeImage("shuffle", active: CarPlayBridge.shared.shuffleEnabled)
    ) { _ in
      CarPlayBridge.shared.toggleShuffle()
    }
    let repeatButton = CPNowPlayingImageButton(
      image: modeImage(
        repeatMode == "one" ? "repeat.1" : "repeat",
        active: repeatMode != "off"
      )
    ) { _ in
      CarPlayBridge.shared.toggleRepeat()
    }
    let like = CPNowPlayingImageButton(
      image: modeImage(liked ? "heart.fill" : "heart", active: liked)
    ) { _ in
      CarPlayBridge.shared.toggleLike()
    }
    CPNowPlayingTemplate.shared.updateNowPlayingButtons([shuffle, repeatButton, like])
  }

  private func modeImage(_ symbol: String, active: Bool) -> UIImage {
    let image = UIImage(systemName: symbol) ?? UIImage()
    guard active else { return image }
    return image.withTintColor(Self.accentColor, renderingMode: .alwaysOriginal)
  }

  private func pushQueue() {
    CarPlayBridge.shared.fetch("getQueue") { [weak self] data in
      guard let self, let data else { return }
      let entries = data["items"] as? [[String: Any]] ?? []
      var pairs = [(id: String, item: CPListItem)]()
      let items = entries.compactMap { entry -> CPListItem? in
        guard
          let id = entry["id"] as? String,
          let title = entry["title"] as? String,
          let index = entry["index"] as? Int
        else { return nil }
        let subtitle = entry["subtitle"] as? String
        let item = CPListItem(
          text: title,
          detailText: (subtitle?.isEmpty ?? true) ? nil : subtitle,
          image: self.placeholderImage
        )
        item.handler = { [weak self] _, completion in
          CarPlayBridge.shared.playQueueItem(index: index)
          self?.interfaceController?.popTemplate(animated: true, completion: nil)
          completion()
        }
        if let artworkUrl = entry["artworkUrl"] as? String {
          self.loadArtwork(from: artworkUrl) { image in
            item.setImage(image)
          }
        }
        pairs.append((id: id, item: item))
        return item
      }
      let template = CPListTemplate(
        title: self.str("playingNext", "Playing Next"),
        sections: [CPListSection(items: items)]
      )
      template.emptyViewTitleVariants = [self.str("queueIsEmpty", "Queue is empty")]
      self.trackedItems["queue"] = pairs
      self.interfaceController?.pushTemplate(template, animated: true) { _, error in
        if let error { NSLog("[CarPlay] push failed: %@", error.localizedDescription) }
      }
      self.applyPlaybackState()
    }
  }

  private func reload() {
    guard CarPlayBridge.shared.isReady else {
      let waiting = [str("openToStart", "Open JellyBox on your iPhone to get started")]
      homeTemplate.emptyViewTitleVariants = waiting
      downloadsTemplate.emptyViewTitleVariants = waiting
      return
    }
    reloadHome()
    reloadDownloads()
    refreshPushedList()
  }

  private func reloadHome() {
    CarPlayBridge.shared.fetch("getHome") { [weak self] data in
      guard let self, let data else { return }

      let recentEntries = data["recent"] as? [[String: Any]] ?? []
      let playedEntries = data["played"] as? [[String: Any]] ?? []
      let mixEntries = data["mixes"] as? [[String: Any]] ?? []
      var sections = [CPListSection(items: [self.makeBrowseRow()])]
      if !mixEntries.isEmpty {
        sections.append(
          CPListSection(items: [self.makeMixRow(entries: mixEntries)])
        )
      }
      if !recentEntries.isEmpty {
        sections.append(
          CPListSection(items: [self.makeRecentRow(entries: recentEntries)])
        )
      }
      if !playedEntries.isEmpty {
        sections.append(
          CPListSection(items: [self.makePlayedRow(entries: playedEntries)])
        )
      }

      self.homeTemplate.updateSections(sections)
      self.trackedItems["home"] = []
      self.applyPlaybackState()
    }
  }

  private func reloadDownloads() {
    CarPlayBridge.shared.fetch("getDownloads") { [weak self] data in
      guard let self, let data else { return }
      let items = { (key: String) in
        (data[key] as? [[String: Any]] ?? []).compactMap {
          self.makeMediaItem(entry: $0, playType: "download")
        }
      }
      let albums = items("albums")
      let playlists = items("playlists")
      let grouped = !albums.isEmpty && !playlists.isEmpty
      let sections = [
        (self.str("albums", "Albums"), albums),
        (self.str("playlists", "Playlists"), playlists),
      ]
        .filter { !$0.1.isEmpty }
        .map {
          CPListSection(
            items: $0.1.map(\.item),
            header: grouped ? $0.0 : nil,
            sectionIndexTitle: nil
          )
        }
      self.downloadsTemplate.emptyViewTitleVariants = [self.str("noDownloads", "No downloads")]
      self.downloadsTemplate.updateSections(sections)
      self.trackedItems["downloads"] = albums + playlists
      self.applyPlaybackState()
    }
  }

  private func selectItem(playType: String, entry: [String: Any]) {
    guard let id = entry["id"] as? String else { return }
    if playType == "artist" {
      pushBrowseList(
        type: "albums",
        title: entry["title"] as? String ?? str("albums", "Albums"),
        artistId: id
      )
    } else {
      CarPlayBridge.shared.play(type: playType, id: id)
      pushNowPlaying()
    }
  }

  private func pushBrowseList(
    type: String,
    title: String,
    query: String? = nil,
    artistId: String? = nil
  ) {
    let template = CPListTemplate(title: title, sections: [])
    template.emptyViewTitleVariants = [str("loading", "Loading…")]
    if query == nil, let fields = sortFields(for: type) {
      template.trailingNavigationBarButtons = [
        CPBarButton(image: UIImage(systemName: "arrow.up.arrow.down")!) { [weak self] _ in
          self?.presentSortSheet(fields: fields)
        }
      ]
    }
    pushedTemplate = template
    pushedType = type
    pushedQuery = query
    pushedArtistId = artistId
    pushedEntries = []
    pushedHasMore = false
    interfaceController?.pushTemplate(template, animated: true) { _, error in
      if let error { NSLog("[CarPlay] push failed: %@", error.localizedDescription) }
    }
    fetchPushedPage(reset: true)
  }

  private func refreshPushedList() {
    fetchPushedPage(reset: true)
  }

  private func fetchPushedPage(reset: Bool) {
    guard let type = pushedType, let template = pushedTemplate, !pushedLoading else { return }
    pushedLoading = true
    if reset, !pushedEntries.isEmpty {
      template.emptyViewTitleVariants = [str("loading", "Loading…")]
      template.updateSections([])
      trackedItems["pushed"] = []
    }
    let startIndex = reset ? 0 : pushedEntries.count
    var arguments: [String: Any] = ["type": type, "startIndex": startIndex]
    if let pushedQuery {
      arguments["query"] = pushedQuery
    }
    if let pushedArtistId {
      arguments["artistId"] = pushedArtistId
    }
    CarPlayBridge.shared.fetch("getList", arguments: arguments) { [weak self] data in
      guard let self else { return }
      self.pushedLoading = false
      guard let data else { return }
      if let sort = data["sort"] as? [String: Any] {
        self.sortField = sort["field"] as? String ?? self.sortField
        self.sortDescending = sort["desc"] as? Bool ?? self.sortDescending
      }
      let newEntries = data["items"] as? [[String: Any]] ?? []
      self.pushedHasMore = data["hasMore"] as? Bool ?? false
      self.pushedEntries = reset ? newEntries : self.pushedEntries + newEntries
      self.renderPushedList()
    }
  }

  private func renderPushedList() {
    guard let template = pushedTemplate, let type = pushedType else { return }
    template.emptyViewTitleVariants = [str("nothingHereYet", "Nothing here yet")]
    let playType = playType(for: type)
    var items = [CPListTemplateItem]()

    if type == "albums" || type == "artists" || type == "played" {
      if #available(iOS 26.0, *) {
        let chunk = cardsPerLine()
        items = stride(from: 0, to: pushedEntries.count, by: chunk).map { start in
          self.makeGridItem(
            entries: Array(pushedEntries[start..<min(start + chunk, pushedEntries.count)]),
            playType: playType
          )
        }
      } else {
        let perRow = 4
        items = stride(from: 0, to: pushedEntries.count, by: perRow).map { start in
          self.makeCoverRow(
            entries: Array(pushedEntries[start..<min(start + perRow, pushedEntries.count)]),
            playType: playType,
            text: ""
          )
        }
      }
      trackedItems["pushed"] = []
    } else {
      let pairs = pushedEntries.compactMap {
        self.makeMediaItem(entry: $0, playType: playType)
      }
      items = pairs.map(\.item)
      trackedItems["pushed"] = pairs
    }

    if let artistId = pushedArtistId {
      let playAll = CPListItem(
        text: str("playAll", "Play All"),
        detailText: nil,
        image: UIImage(systemName: "play.circle")
      )
      playAll.handler = { [weak self] _, completion in
        CarPlayBridge.shared.play(type: "artist", id: artistId)
        self?.pushNowPlaying()
        completion()
      }
      items.insert(playAll, at: 0)
    }

    var sections = [CPListSection(items: items)]
    if pushedHasMore {
      let more = CPListItem(
        text: str("loadMore", "Load More…"),
        detailText: nil,
        image: UIImage(systemName: "ellipsis.circle")
      )
      more.handler = { [weak self] _, completion in
        self?.fetchPushedPage(reset: false)
        completion()
      }
      sections.append(CPListSection(items: [more]))
    }

    template.updateSections(sections)
    applyPlaybackState()
  }

  @available(iOS 26.0, *)
  private func cardsPerLine() -> Int {
    guard carScreenWidth > 0 else { return 4 }
    let sideChrome: CGFloat = 64
    let renderedCardUnit: CGFloat = 84
    return max(2, Int((carScreenWidth - sideChrome) / renderedCardUnit))
  }

  private func sortFields(for type: String) -> [String]? {
    switch type {
    case "albums", "songs":
      return ["sortName", "dateCreated", "random"]
    case "artists":
      return ["sortName", "random"]
    case "playlists":
      return ["sortName", "dateCreated"]
    default:
      return nil
    }
  }

  private func playType(for type: String) -> String {
    switch type {
    case "albums", "played": return "album"
    case "artists": return "artist"
    case "playlists": return "playlist"
    case "mixes": return "mix"
    case "songs": return "song"
    default: return type
    }
  }

  private func presentSortSheet(fields: [String]) {
    guard let interfaceController, interfaceController.presentedTemplate == nil else { return }
    let actions = fields.map { field -> CPAlertAction in
      var title = sortLabels[field] ?? field
      if field == sortField {
        title += sortDescending ? " ↓" : " ↑"
      }
      return CPAlertAction(title: title, style: .default) { [weak self] _ in
        self?.dismissPresentedTemplate()
        CarPlayBridge.shared.setSort(field: field)
      }
    }
    let cancel = CPAlertAction(title: str("cancel", "Cancel"), style: .cancel) { [weak self] _ in
      self?.dismissPresentedTemplate()
    }
    let sheet = CPActionSheetTemplate(
      title: str("sortBy", "Sort by"),
      message: nil,
      actions: actions + [cancel]
    )
    interfaceController.presentTemplate(sheet, animated: true) { _, error in
      if let error { NSLog("[CarPlay] present failed: %@", error.localizedDescription) }
    }
  }

  private func setSearchTabVisible(_ visible: Bool) {
    guard let tabBar else { return }
    let hasSearch = tabBar.templates.contains { $0 === searchTemplate }
    if visible, !hasSearch {
      tabBar.updateTemplates([homeTemplate, downloadsTemplate, searchTemplate])
    } else if !visible, hasSearch {
      tabBar.updateTemplates([homeTemplate, downloadsTemplate])
    }
  }

  private func searchQueryChanged(_ query: String) {
    let trimmed = query.trimmingCharacters(in: .whitespaces)
    lastQuery = trimmed
    guard trimmed.count >= 2 else {
      lastSearchResults = nil
      searchTemplate.updateSections([])
      setSearchTabVisible(false)
      return
    }
    CarPlayBridge.shared.fetch("search", arguments: ["query": trimmed]) { [weak self] data in
      guard let self, self.lastQuery == trimmed, let data else { return }
      self.lastSearchResults = data
      let categories: [(key: String, title: String, type: String)] = [
        ("albums", self.str("albums", "Albums"), "albums"),
        ("artists", self.str("artists", "Artists"), "artists"),
        ("playlists", self.str("playlists", "Playlists"), "playlists"),
        ("songs", self.str("songs", "Songs"), "songs"),
      ]
      var sections = [CPListSection]()
      for category in categories {
        let entries = data[category.key] as? [[String: Any]] ?? []
        guard !entries.isEmpty else { continue }
        sections.append(
          self.makeSearchSection(title: category.title, type: category.type, entries: entries)
        )
      }
      self.searchTemplate.emptyViewTitleVariants = [
        String(format: self.str("noResultsFormat", "No results for “%@”"), trimmed)
      ]
      self.searchTemplate.updateSections(sections)
      self.setSearchTabVisible(true)
    }
  }

  private func makeSearchSection(
    title: String,
    type: String,
    entries: [[String: Any]]
  ) -> CPListSection {
    let playType = playType(for: type)
    let row: CPListImageRowItem
    if #available(iOS 26.0, *) {
      let visible = Array(entries.prefix(cardsPerLine()))
      row = CPListImageRowItem(
        text: title,
        elements: rowElements(for: visible, padTo: cardsPerLine()),
        allowsMultipleLines: false
      )
      row.listImageRowHandler = { [weak self] _, index, completion in
        guard index < visible.count else {
          completion()
        return
        }
        self?.selectItem(playType: playType, entry: visible[index])
        completion()
      }
    } else {
      row = makeCoverRow(
        entries: Array(entries.prefix(8)),
        playType: playType,
        text: title
      )
    }
    row.handler = { [weak self] _, completion in
      guard let self else {
        completion()
        return
      }
      self.pushBrowseList(type: type, title: title, query: self.lastQuery)
      completion()
    }
    return CPListSection(items: [row])
  }

  private func dismissPresentedTemplate() {
    guard let interfaceController, interfaceController.presentedTemplate != nil else { return }
    interfaceController.dismissTemplate(animated: true) { _, error in
      if let error { NSLog("[CarPlay] dismiss failed: %@", error.localizedDescription) }
    }
  }

  private func pushNowPlaying() {
    guard let interfaceController else { return }
    guard interfaceController.topTemplate !== CPNowPlayingTemplate.shared else { return }
    interfaceController.pushTemplate(CPNowPlayingTemplate.shared, animated: true) { _, error in
      if let error { NSLog("[CarPlay] push failed: %@", error.localizedDescription) }
    }
  }

  private func applyPlaybackState() {
    let setId = CarPlayBridge.shared.playingSetId
    let songId = CarPlayBridge.shared.playingSongId
    let playing = CarPlayBridge.shared.isPlaying
    for (bucket, pairs) in trackedItems {
      let target = bucket == "queue" ? songId : setId
      for entry in pairs {
        entry.item.isPlaying = playing && entry.id == target
      }
    }
  }

  private func makeBrowseRow() -> CPListImageRowItem {
    let row: CPListImageRowItem
    if #available(iOS 26.0, *) {
      let elements = browseEntries.map { entry in
        CPListImageRowItemCondensedElement(
          image: makeTile(
            symbol: entry.symbol,
            size: CPListImageRowItemCondensedElement.maximumImageSize
          ),
          imageShape: .roundedRectangle,
          title: entry.title,
          subtitle: nil,
          accessorySymbolName: "chevron.right"
        )
      }
      row = CPListImageRowItem(
        text: nil,
        condensedElements: elements,
        allowsMultipleLines: true
      )
    } else {
      row = CPListImageRowItem(
        text: str("browse", "Browse"),
        images: browseEntries.map {
          makeTile(symbol: $0.symbol, size: CPListImageRowItem.maximumImageSize)
        },
        imageTitles: browseEntries.map(\.title)
      )
    }
    row.listImageRowHandler = { [weak self] _, index, completion in
      guard let self, index < self.browseEntries.count else {
        completion()
        return
      }
      let entry = self.browseEntries[index]
      self.pushBrowseList(type: entry.type, title: entry.title)
      completion()
    }
    row.handler = { _, completion in
      completion()
    }
    return row
  }

  private func makeTile(symbol: String, size: CGSize) -> UIImage {
    return UIGraphicsImageRenderer(size: size).image { _ in
      UIColor(white: 1, alpha: 0.15).setFill()
      UIBezierPath(
        roundedRect: CGRect(origin: .zero, size: size),
        cornerRadius: size.width * 0.18
      ).fill()
      let config = UIImage.SymbolConfiguration(
        pointSize: size.width * 0.4,
        weight: .medium
      )
      guard
        let glyph = UIImage(systemName: symbol, withConfiguration: config)?
          .withTintColor(.white, renderingMode: .alwaysOriginal)
      else { return }
      glyph.draw(
        in: CGRect(
          x: (size.width - glyph.size.width) / 2,
          y: (size.height - glyph.size.height) / 2,
          width: glyph.size.width,
          height: glyph.size.height
        )
      )
    }
  }

  private func makeMixRow(entries: [[String: Any]]) -> CPListImageRowItem {
    let row: CPListImageRowItem
    if #available(iOS 26.0, *) {
      let visible = Array(entries.prefix(cardsPerLine()))
      row = CPListImageRowItem(
        text: str("madeForYou", "Made for You"),
        elements: rowElements(for: visible, padTo: cardsPerLine()),
        allowsMultipleLines: false
      )
      row.listImageRowHandler = { [weak self] _, index, completion in
        guard index < visible.count else {
          completion()
          return
        }
        self?.selectItem(playType: "mix", entry: visible[index])
        completion()
      }
    } else {
      row = makeCoverRow(
        entries: Array(entries.prefix(8)),
        playType: "mix",
        text: str("madeForYou", "Made for You")
      )
    }
    row.handler = { [weak self] _, completion in
      guard let self else {
        completion()
        return
      }
      self.pushBrowseList(type: "mixes", title: self.str("madeForYou", "Made for You"))
      completion()
    }
    return row
  }

  private func makeRecentRow(entries: [[String: Any]]) -> CPListImageRowItem {
    let row = makeAlbumRow(entries: entries, text: str("recentlyAdded", "Recently Added"))
    row.handler = { [weak self] _, completion in
      guard let self else {
        completion()
        return
      }
      self.pushBrowseList(type: "albums", title: self.str("albums", "Albums"))
      completion()
    }
    return row
  }

  private func makePlayedRow(entries: [[String: Any]]) -> CPListImageRowItem {
    let row = makeAlbumRow(entries: entries, text: str("recentlyPlayed", "Recently Played"))
    row.handler = { [weak self] _, completion in
      guard let self else {
        completion()
        return
      }
      self.pushBrowseList(type: "played", title: self.str("recentlyPlayed", "Recently Played"))
      completion()
    }
    return row
  }

  private func makeAlbumRow(
    entries: [[String: Any]],
    text: String
  ) -> CPListImageRowItem {
    if #available(iOS 26.0, *) {
      let visible = Array(entries.prefix(cardsPerLine()))
      let row = CPListImageRowItem(
        text: text,
        elements: rowElements(for: visible, padTo: cardsPerLine()),
        allowsMultipleLines: false
      )
      row.listImageRowHandler = { [weak self] _, index, completion in
        guard index < visible.count else {
          completion()
        return
        }
        self?.selectItem(playType: "album", entry: visible[index])
        completion()
      }
      return row
    }
    return makeCoverRow(
      entries: Array(entries.prefix(8)),
      playType: "album",
      text: text
    )
  }

  @available(iOS 26.0, *)
  private func rowElements(
    for entries: [[String: Any]],
    padTo: Int = 0
  ) -> [CPListImageRowItemRowElement] {
    var elements = makeRowElements(for: entries)
    if padTo > elements.count {
      let clear = UIGraphicsImageRenderer(
        size: CPListImageRowItemRowElement.maximumImageSize
      ).image { _ in }
      while elements.count < padTo {
        let filler = CPListImageRowItemRowElement(
          image: clear,
          title: nil,
          subtitle: nil
        )
        filler.isEnabled = false
        elements.append(filler)
      }
    }
    return elements
  }

  @available(iOS 26.0, *)
  private func makeRowElements(for entries: [[String: Any]]) -> [CPListImageRowItemRowElement] {
    entries.map { entry -> CPListImageRowItemRowElement in
      let subtitle = entry["subtitle"] as? String
      let element = CPListImageRowItemRowElement(
        image: placeholderImage ?? UIImage(),
        title: entry["title"] as? String,
        subtitle: (subtitle?.isEmpty ?? true) ? nil : subtitle
      )
      if let artworkUrl = entry["artworkUrl"] as? String {
        loadArtwork(from: artworkUrl) { image in
          guard let image else { return }
          element.image = image
        }
      }
      return element
    }
  }

  @available(iOS 26.0, *)
  private func makeGridItem(
    entries: [[String: Any]],
    playType: String
  ) -> CPListImageRowItem {
    let item = CPListImageRowItem(
      text: nil,
      elements: rowElements(for: entries, padTo: cardsPerLine()),
      allowsMultipleLines: true
    )
    item.listImageRowHandler = { [weak self] _, index, completion in
      guard index < entries.count else {
        completion()
      return
      }
      self?.selectItem(playType: playType, entry: entries[index])
      completion()
    }
    item.handler = { _, completion in
      completion()
    }
    return item
  }

  private func makeCoverRow(
    entries: [[String: Any]],
    playType: String,
    text: String
  ) -> CPListImageRowItem {
    var covers = entries.map { _ in self.placeholderImage ?? UIImage() }
    let titles = entries.map { $0["title"] as? String ?? "" }
    let row = CPListImageRowItem(text: text, images: covers, imageTitles: titles)
    row.listImageRowHandler = { [weak self] _, index, completion in
      guard index < entries.count else {
        completion()
      return
      }
      self?.selectItem(playType: playType, entry: entries[index])
      completion()
    }
    row.handler = { _, completion in
      completion()
    }
    for (index, entry) in entries.enumerated() {
      guard let artworkUrl = entry["artworkUrl"] as? String else { continue }
      loadArtwork(from: artworkUrl) { image in
        guard let image else { return }
        covers[index] = image
        row.update(covers)
      }
    }
    return row
  }

  private func makeMediaItem(
    entry: [String: Any],
    playType: String
  ) -> (id: String, item: CPListItem)? {
    guard
      let id = entry["id"] as? String,
      let title = entry["title"] as? String
    else { return nil }

    let subtitle = entry["subtitle"] as? String
    let item = CPListItem(
      text: title,
      detailText: (subtitle?.isEmpty ?? true) ? nil : subtitle,
      image: placeholderImage
    )
    item.handler = { [weak self] _, completion in
      self?.selectItem(playType: playType, entry: entry)
      completion()
    }
    if let artworkUrl = entry["artworkUrl"] as? String {
      loadArtwork(from: artworkUrl) { image in
        item.setImage(image)
      }
    }
    return (id: id, item: item)
  }

  private func loadArtwork(from urlString: String, completion: @escaping (UIImage?) -> Void) {
    if let cached = artworkCache[urlString] {
      completion(cached)
      return
    }
    guard let url = URL(string: urlString) else { return }
    if url.scheme == "asset" {
      let key = FlutterDartProject.lookupKey(forAsset: String(url.path.dropFirst()))
      guard let path = Bundle.main.path(forResource: key, ofType: nil),
            let image = UIImage(contentsOfFile: path) else { return }
      artworkCache[urlString] = image
      completion(image)
      return
    }
    if url.isFileURL {
      guard let image = UIImage(contentsOfFile: url.path) else { return }
      artworkCache[urlString] = image
      completion(image)
      return
    }
    CarPlayBridge.shared.artworkFile(for: urlString) { [weak self] path in
      guard let path else { return }
      DispatchQueue.global(qos: .userInitiated).async {
        guard let image = UIImage(contentsOfFile: path) else { return }
        DispatchQueue.main.async {
          self?.artworkCache[urlString] = image
          completion(image)
        }
      }
    }
  }
}
