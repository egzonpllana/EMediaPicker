//
//  StoryboardIdentifiable.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

// NOTE: Our Storyboard Identifiable system is based on
// https://medium.com/swift-programming/uistoryboard-safer-with-enums-protocol-extensions-and-generics-7aad3883b44d

import UIKit

protocol StoryboardIdentifiable {
    static var storyboardIdentifier: String { get }
}

extension StoryboardIdentifiable {
    static var storyboardIdentifier: String {
        return String(describing: self)
    }
}

extension UIViewController: StoryboardIdentifiable { }
extension UITableViewCell: StoryboardIdentifiable { }
extension UITableViewHeaderFooterView: StoryboardIdentifiable { }
extension UICollectionReusableView: StoryboardIdentifiable { }

// // https://cocoacasts.com/dequeueing-reusable-views-with-generics-and-protocols

public extension UITableView {

    /// Use with UITableView:
    ///
    /// 1) Use the UITableViewCell subclass name as the reuseIdentifier
    /// 2) Cast the cell like the following:
    ///
    /// `tableView.register(MyCustomCell.self)`

    func register<T: UITableViewCell>(_: T.Type, reuseIdentifier: String? = nil) {
        let nib = UINib(nibName: reuseIdentifier ?? String(describing: T.self), bundle: nil)
        self.register(nib, forCellReuseIdentifier: reuseIdentifier ?? String(describing: T.self))
    }

    /// Use with UITableView:
    ///
    /// 1) Use the UITableViewHeaderFooterView subclass name as the reuseIdentifier
    /// 2) Cast the cell like the following:
    ///
    /// `tableView.register(MyCustomSectionHeaderView.self)`

    func register<T: UITableViewHeaderFooterView>(_: T.Type, reuseIdentifier: String? = nil) {
        let nib = UINib(nibName: reuseIdentifier ?? String(describing: T.self), bundle: nil)
        self.register(nib, forHeaderFooterViewReuseIdentifier: reuseIdentifier ?? String(describing: T.self))
    }

    /// Use with UITableView:
    ///
    /// 1) Use the UITableViewCell subclass name as the reuseIdentifier
    /// 2) Cast the cell like the following:
    ///
    /// `let cell: MyCustomCell = tableView.dequeueReusableCell(for: indexPath)`

    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.storyboardIdentifier, for: indexPath) as? T else {
            fatalError(String(format: "unable to dequeue a cell with identifier %@ - must register a nib or a class for the identifier or connect a prototype cell in a storyboard", arguments: [ T.storyboardIdentifier ]))
        }
        return cell
    }

    /// Use with UITableView:
    ///
    /// 1) Use the UITableViewCell subclass name as the reuseIdentifier
    /// 2) Cast the cell like the following:
    ///
    /// `let cell: MyCustomCell = tableView.dequeueReusableCell()`

    func dequeueReusableCell<T: UITableViewCell>() -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.storyboardIdentifier) as? T else {
            fatalError(String(format: "unable to dequeue a cell with identifier %@ - must register a nib or a class for the identifier or connect a prototype cell in a storyboard", arguments: [ T.storyboardIdentifier ]))
        }
        return cell
    }

    /// Use with UITableView:
    ///
    /// 1) Use the UITableViewCell subclass name as the reuseIdentifier
    /// 2) Cast the cell like the following:
    ///
    /// `let cell: MyCustomCell? = tableView.cellForRow(at: indexPath)`

    func cellForRow<T: UITableViewCell>(at indexPath: IndexPath) -> T? {
        guard let cell = cellForRow(at: indexPath) else { return nil }
        guard let castCell = cell as? T else {
            fatalError(String(format: "Could not get cell as type %@", arguments: [ T.storyboardIdentifier ]))
        }
        return castCell
    }

    /// Use with UITableView:
    ///
    /// 1) Use the UITableViewHeaderFooterView subclass name as the reuseIdentifier
    /// 2) Cast the view like the following:
    ///
    /// `let view: MyHeaderFooterView = tableView.dequeueReusableHeaderFooterView()`

    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>() -> T {
        guard let headerFooterView = dequeueReusableHeaderFooterView(withIdentifier: T.storyboardIdentifier) as? T else {
            fatalError(String(format: "unable to dequeue a table header/footer view with identifier %@ - must register a nib or a class for the identifier or connect a prototype cell in a storyboard", arguments: [ T.storyboardIdentifier ]))
        }
        return headerFooterView
    }

}

public extension UICollectionView {

    /// Use with UICollectionView:
    ///
    /// 1) Use the UICollectionViewCell subclass name as the reuseIdentifier
    /// 2) Cast the cell like the following:
    ///
    /// `let cell: MyCustomCell = collectionView.dequeueReusableCell(for: indexPath)`

    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.storyboardIdentifier, for: indexPath) as? T else {
            fatalError(String(format: "could not dequeue a view of kind: %@ with identifier %@ - must register a nib or a class for the identifier or connect a prototype cell in a storyboard", arguments: [ "UICollectionElementKindCell", T.storyboardIdentifier ]))
        }
        return cell
    }

    /// Use with UICollectionView:
    ///
    /// 1) Use the UICollectionViewCell subclass name as the reuseIdentifier
    /// 2) Cast the cell like the following:
    ///
    /// `let cell: MyCustomCell? = collectionView.cellForItem(at: indexPath)`

    func cellForItem<T: UICollectionViewCell>(at indexPath: IndexPath) -> T? {
        guard let cell = cellForItem(at: indexPath)  else { return nil }
        guard let castCell = cell as? T else {
            fatalError(String(format: "Could not get cell as type %@", arguments: [ T.storyboardIdentifier ]))
        }
        return castCell
    }

    /// Use with UICollectionView:
    ///
    /// 1) Use the UICollectionReusableView subclass name as the reuseIdentifier
    /// 2) Cast the view like the following:
    ///
    /// `let headerView: MyCustomView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, for: indexPath)`

    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind elementKind: String, for indexPath: IndexPath) -> T {
        guard let view = dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: T.storyboardIdentifier, for: indexPath) as? T else {
            fatalError(String(format: "could not dequeue a view of kind: %@ with identifier %@ - must register a nib or a class for the identifier or connect a prototype cell in a storyboard", arguments: [ elementKind, T.storyboardIdentifier ]))
        }
        return view
    }

}
