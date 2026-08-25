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

  private let sortLabels = [
    "sortName": "Name",
    "albumArtist": "Album Artist",
    "dateCreated": "Date Added",
    "random": "Random",
  ]

  private let browseEntries: [(type: String, title: String, symbol: String)] = [
    ("albums", "Albums", "square.stack"),
    ("artists", "Artists", "music.mic"),
    ("playlists", "Playlists", "music.note.list"),
    ("songs", "Songs", "music.note"),
  ]

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

    homeTemplate.tabTitle = "Home"
    homeTemplate.tabImage = UIImage(systemName: "house")
    downloadsTemplate.tabTitle = "Downloads"
    downloadsTemplate.tabImage = UIImage(systemName: "arrow.down.circle")
    searchTemplate.tabTitle = "Search"
    searchTemplate.tabImage = UIImage(systemName: "magnifyingglass")
    searchTemplate.emptyViewTitleVariants = ["No results"]

    let tabBar = CPTabBarTemplate(templates: [homeTemplate, downloadsTemplate])
    self.tabBar = tabBar
    interfaceController.setRootTemplate(tabBar, animated: true, completion: nil)

    CarPlayBridge.shared.onContentChanged = { [weak self] in
      self?.reload()
    }
    CarPlayBridge.shared.onPlaybackStateChanged = { [weak self] in
      self?.applyPlaybackState()
    }
    CarPlayBridge.shared.onSearchChanged = { [weak self] query in
      self?.searchQueryChanged(query)
    }
    CPNowPlayingTemplate.shared.isUpNextButtonEnabled = true
    CPNowPlayingTemplate.shared.add(self)
    reload()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    self.interfaceController = nil
    CarPlayBridge.shared.onContentChanged = nil
    CarPlayBridge.shared.onPlaybackStateChanged = nil
    CarPlayBridge.shared.onSearchChanged = nil
    CPNowPlayingTemplate.shared.remove(self)
  }

  func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
    pushQueue()
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
        title: "Playing Next",
        sections: [CPListSection(items: items)]
      )
      template.emptyViewTitleVariants = ["Queue is empty"]
      self.trackedItems["queue"] = pairs
      self.interfaceController?.pushTemplate(template, animated: true) { _, error in
        if let error { NSLog("[CarPlay] push failed: %@", error.localizedDescription) }
      }
      self.applyPlaybackState()
    }
  }

  private func reload() {
    guard CarPlayBridge.shared.isReady else {
      let waiting = ["Open JellyBox on your iPhone to get started"]
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

      self.homeTemplate.updateSections(sections)
      self.trackedItems["home"] = []
      self.applyPlaybackState()
    }
  }

  private func reloadDownloads() {
    CarPlayBridge.shared.fetch("getDownloads") { [weak self] data in
      guard let self, let data else { return }
      let entries = data["items"] as? [[String: Any]] ?? []
      let pairs = entries.compactMap {
        self.makeMediaItem(entry: $0, playType: "download")
      }
      self.downloadsTemplate.emptyViewTitleVariants = ["No downloads"]
      self.downloadsTemplate.updateSections([CPListSection(items: pairs.map(\.item))])
      self.trackedItems["downloads"] = pairs
      self.applyPlaybackState()
    }
  }

  private func selectItem(playType: String, entry: [String: Any]) {
    guard let id = entry["id"] as? String else { return }
    if playType == "artist" {
      pushBrowseList(
        type: "albums",
        title: entry["title"] as? String ?? "Albums",
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
    template.emptyViewTitleVariants = ["Loading…"]
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
      template.emptyViewTitleVariants = ["Loading…"]
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
    template.emptyViewTitleVariants = ["Nothing here yet"]
    let playType = playType(for: type)
    var items = [CPListTemplateItem]()

    if type == "albums" || type == "artists" {
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
        text: "Play All",
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
        text: "Load More…",
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
    let renderedCardUnit: CGFloat = 96
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
    case "albums": return "album"
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
    let cancel = CPAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
      self?.dismissPresentedTemplate()
    }
    let sheet = CPActionSheetTemplate(
      title: "Sort by",
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
        ("albums", "Albums", "albums"),
        ("artists", "Artists", "artists"),
        ("playlists", "Playlists", "playlists"),
        ("songs", "Songs", "songs"),
      ]
      var sections = [CPListSection]()
      for category in categories {
        let entries = data[category.key] as? [[String: Any]] ?? []
        guard !entries.isEmpty else { continue }
        sections.append(
          self.makeSearchSection(title: category.title, type: category.type, entries: entries)
        )
      }
      self.searchTemplate.emptyViewTitleVariants = ["No results for “\(trimmed)”"]
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
        gridElements: gridElements(for: visible, padTo: cardsPerLine()),
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
        text: "Browse",
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
      let visible = mixEntries(entries, limit: cardsPerLine())
      row = CPListImageRowItem(
        text: "Made for You",
        gridElements: gridElements(for: visible, padTo: cardsPerLine()),
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
        entries: mixEntries(entries, limit: 8),
        playType: "mix",
        text: "Made for You"
      )
    }
    row.handler = { [weak self] _, completion in
      self?.pushBrowseList(type: "mixes", title: "Made for You")
      completion()
    }
    return row
  }

  private func mixEntries(_ entries: [[String: Any]], limit: Int) -> [[String: Any]] {
    guard entries.count > limit, limit > 1, let last = entries.last else {
      return Array(entries.prefix(limit))
    }
    return Array(entries.prefix(limit - 1)) + [last]
  }

  private func makeRecentRow(entries: [[String: Any]]) -> CPListImageRowItem {
    let row: CPListImageRowItem
    if #available(iOS 26.0, *) {
      let visible = Array(entries.prefix(cardsPerLine()))
      row = CPListImageRowItem(
        text: "Recently Added",
        gridElements: gridElements(for: visible, padTo: cardsPerLine()),
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
    } else {
      row = makeCoverRow(
        entries: Array(entries.prefix(8)),
        playType: "album",
        text: "Recently Added"
      )
    }
    row.handler = { [weak self] _, completion in
      self?.pushBrowseList(type: "albums", title: "Albums")
      completion()
    }
    return row
  }

  @available(iOS 26.0, *)
  private func gridElements(
    for entries: [[String: Any]],
    padTo: Int = 0
  ) -> [CPListImageRowItemGridElement] {
    var elements = makeGridElements(for: entries)
    if padTo > elements.count {
      let clear = UIGraphicsImageRenderer(
        size: CPListImageRowItemGridElement.maximumImageSize
      ).image { _ in }
      while elements.count < padTo {
        let filler = CPListImageRowItemGridElement(image: clear)
        filler.isEnabled = false
        elements.append(filler)
      }
    }
    return elements
  }

  @available(iOS 26.0, *)
  private func makeGridElements(for entries: [[String: Any]]) -> [CPListImageRowItemGridElement] {
    entries.map { entry -> CPListImageRowItemGridElement in
      let title = entry["title"] as? String ?? ""
      let subtitle = entry["subtitle"] as? String
      let element = CPListImageRowItemGridElement(
        image: composeTile(
          cover: placeholderImage ?? UIImage(),
          title: title,
          subtitle: subtitle
        )
      )
      if let artworkUrl = entry["artworkUrl"] as? String {
        loadArtwork(from: artworkUrl) { [weak self] image in
          guard let self, let image else { return }
          element.image = self.composeTile(cover: image, title: title, subtitle: subtitle)
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
      gridElements: gridElements(for: entries, padTo: cardsPerLine()),
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

  @available(iOS 26.0, *)
  private func composeTile(cover: UIImage, title: String, subtitle: String?) -> UIImage {
    let size = CPListImageRowItemGridElement.maximumImageSize
    let hasSubtitle = !(subtitle?.isEmpty ?? true)
    return UIGraphicsImageRenderer(size: size).image { context in
      aspectFill(cover, to: size).draw(at: .zero)

      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let colors = [
        UIColor.black.withAlphaComponent(0).cgColor,
        UIColor.black.withAlphaComponent(0.8).cgColor,
      ]
      if let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: colors as CFArray,
        locations: [0, 1]
      ) {
        context.cgContext.drawLinearGradient(
          gradient,
          start: CGPoint(x: 0, y: size.height * 0.5),
          end: CGPoint(x: 0, y: size.height),
          options: []
        )
      }

      let paragraph = NSMutableParagraphStyle()
      paragraph.lineBreakMode = .byTruncatingTail
      let titleFont = UIFont.systemFont(ofSize: 27, weight: .semibold)
      let subtitleFont = UIFont.systemFont(ofSize: 21)
      let padding: CGFloat = 14
      let bottomPadding: CGFloat = 22
      let textWidth = size.width - padding * 2
      let subtitleHeight = hasSubtitle ? subtitleFont.lineHeight : 0
      let titleY = size.height - bottomPadding - subtitleHeight - titleFont.lineHeight

      (title as NSString).draw(
        in: CGRect(x: padding, y: titleY, width: textWidth, height: titleFont.lineHeight),
        withAttributes: [
          .font: titleFont,
          .foregroundColor: UIColor.white,
          .paragraphStyle: paragraph,
        ]
      )
      if hasSubtitle, let subtitle {
        (subtitle as NSString).draw(
          in: CGRect(
            x: padding,
            y: titleY + titleFont.lineHeight,
            width: textWidth,
            height: subtitleFont.lineHeight
          ),
          withAttributes: [
            .font: subtitleFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.75),
            .paragraphStyle: paragraph,
          ]
        )
      }
    }
  }

  private func aspectFill(_ image: UIImage, to size: CGSize) -> UIImage {
    guard size.width > 0, size.height > 0, image.size.width > 0, image.size.height > 0 else {
      return image
    }
    return UIGraphicsImageRenderer(size: size).image { _ in
      let scale = max(
        size.width / image.size.width,
        size.height / image.size.height
      )
      let width = image.size.width * scale
      let height = image.size.height * scale
      image.draw(
        in: CGRect(
          x: (size.width - width) / 2,
          y: (size.height - height) / 2,
          width: width,
          height: height
        )
      )
    }
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
    if url.isFileURL {
      guard let image = UIImage(contentsOfFile: url.path) else { return }
      artworkCache[urlString] = image
      completion(image)
      return
    }
    URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
      guard let data, let image = UIImage(data: data) else { return }
      DispatchQueue.main.async {
        self?.artworkCache[urlString] = image
        completion(image)
      }
    }.resume()
  }
}
