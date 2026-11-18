// Backs up or restores every type of every item on the general pasteboard. Usage: swift clipboard.swift save|restore <file>
import AppKit
let pb = NSPasteboard.general, a = CommandLine.arguments, url = URL(fileURLWithPath: a[2])
if a[1] == "save" {
  let items = (pb.pasteboardItems ?? []).map { i in Dictionary(uniqueKeysWithValues: i.types.compactMap { t in i.data(forType: t).map { (t.rawValue, $0) } }) }
  try! PropertyListSerialization.data(fromPropertyList: items, format: .binary, options: 0).write(to: url)
  print("saved", items.count, "items", items.first?.keys.sorted() ?? [])
} else {
  let items = try! PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as! [[String: Data]]
  pb.clearContents()
  pb.writeObjects(items.map { d in let i = NSPasteboardItem(); d.forEach { i.setData($1, forType: .init($0)) }; return i })
  print("restored", items.count, "items")
}
