//
//  EditorToolbar.swift
//  MarkEditiOS
//
//  Keyboard accessory toolbar shown above the software keyboard.
//  Provides common Markdown shortcuts and a Done button.
//

import UIKit

final class EditorToolbar: UIView {

  enum Tag: Int {
    case bold    = 1
    case italic  = 2
    case code    = 3
    case link    = 4
    case heading = 5
    case done    = 6
  }

  private let actionHandler: (Tag) -> Void
  private let toolbar = UIToolbar()

  init(actionHandler: @escaping (Tag) -> Void) {
    self.actionHandler = actionHandler
    super.init(frame: .zero)
    setupToolbar()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: 44)
  }

  // MARK: - Private

  private func setupToolbar() {
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    toolbar.sizeToFit()
    addSubview(toolbar)

    NSLayoutConstraint.activate([
      toolbar.topAnchor.constraint(equalTo: topAnchor),
      toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
      toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
      toolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    let boldItem    = makeItem(title: "B",    image: "bold",            tag: .bold)
    let italicItem  = makeItem(title: "I",    image: "italic",          tag: .italic)
    let codeItem    = makeItem(title: "`",    image: "chevron.left.forwardslash.chevron.right", tag: .code)
    let linkItem    = makeItem(title: "🔗",   image: "link",            tag: .link)
    let headingItem = makeItem(title: "H",    image: "textformat.size", tag: .heading)
    let doneItem    = makeItem(title: "Done", image: nil,               tag: .done)

    toolbar.setItems(
      [boldItem, flex, italicItem, flex, codeItem, flex, linkItem, flex, headingItem, flex, doneItem],
      animated: false
    )
  }

  private func makeItem(title: String, image: String?, tag: Tag) -> UIBarButtonItem {
    let item: UIBarButtonItem
    if let imageName = image, let sfImage = UIImage(systemName: imageName) {
      item = UIBarButtonItem(image: sfImage, style: .plain, target: self, action: #selector(handleTap(_:)))
    } else {
      item = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(handleTap(_:)))
    }
    item.tag = tag.rawValue

    if tag == .done {
      let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 15)]
      item.setTitleTextAttributes(attributes, for: .normal)
      item.setTitleTextAttributes(attributes, for: .highlighted)
    }

    return item
  }

  @objc private func handleTap(_ sender: UIBarButtonItem) {
    guard let tag = Tag(rawValue: sender.tag) else { return }
    actionHandler(tag)
  }
}
