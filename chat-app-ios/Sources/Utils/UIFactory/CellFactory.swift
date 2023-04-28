//
//  CellFactory.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/26.
//

import UIKit
import RxSwift
import RxCocoa

protocol CellRegister {
    static var nibName: String { get }
}

extension UITableView {
    func register<T>(_ config: T.Type) where T: CellRegister & CellFactory {
        self.register(UINib(nibName: config.nibName, bundle: nil), forCellReuseIdentifier: config.identifier)
    }
}

protocol CellFactory: AnyObject {
    static var identifier: String { get }
    associatedtype Dependency
    func bindData(value: Dependency)
}

extension CellFactory {
    static var identifier: String { String(describing: self) }
}

extension UITableView {
    func getCell<Cell>(value: Cell.Type, indexPath: IndexPath, data: Cell.Dependency) -> Cell where Cell: CellFactory {
        let cell = self.dequeueReusableCell(withIdentifier: value.identifier, for: indexPath) as! Cell
        cell.bindData(value: data)
        return cell
    }
    
    func getCell<Cell>(value: Cell.Type, data: Cell.Dependency) -> Cell where Cell: CellFactory {
        let cell = self.dequeueReusableCell(withIdentifier: value.identifier) as! Cell
        cell.bindData(value: data)
        return cell
    }
}

protocol CellFactorySimple: AnyObject {
    static var identifier: String { get }
}

extension UITableView {
    func getCell<Cell>(value: Cell.Type, indexPath: IndexPath) -> Cell where Cell: CellFactorySimple {
        return self.dequeueReusableCell(withIdentifier: value.identifier, for: indexPath) as! Cell
    }
}

extension Reactive where Base: UITableView {
    func itemsCustomed<S: Sequence, Cell: UITableViewCell, O: ObservableType>
        (cellType: Cell.Type)
        -> (_ source: O)
        -> Disposable
        where O.Element == S, Cell: CellFactory, S.Iterator.Element == Cell.Dependency {
            return { source in
                return source.bind(to: self.items(cellIdentifier: cellType.identifier, cellType: cellType), curriedArgument: { _, model, cell in
                    cell.bindData(value: model)
                })
            }
    }
}

extension CellFactory where Self: UITableViewCell {
    static func itemsCustomed<S: Sequence, O: ObservableType>
        (view: UITableView)
        -> (_ source: O)
        -> Disposable
        where O.Element == S, S.Iterator.Element == Self.Dependency {
            return { [unowned view] source in
                return source.bind(to: view.rx.items(cellIdentifier: Self.identifier, cellType: Self.self), curriedArgument: { _, model, cell in
                    cell.bindData(value: model)
                })
            }
    }
}

extension UICollectionView {
    func getCell<Cell>(value: Cell.Type, indexPath: IndexPath, data: Cell.Dependency) -> Cell where Cell: CellFactory {
        let cell = self.dequeueReusableCell(withReuseIdentifier: value.identifier, for: indexPath) as! Cell
        cell.bindData(value: data)
        return cell
    }
}

extension UICollectionView {
    func getCell<Cell>(value: Cell.Type, indexPath: IndexPath) -> Cell where Cell: CellFactorySimple {
        return self.dequeueReusableCell(withReuseIdentifier: value.identifier, for: indexPath) as! Cell
    }
}

protocol CellFactoryWithAction: AnyObject {
    static var identifier: String { get }
    var optionalSelection: (() -> Void)! { get set }
    associatedtype Dependency
    func bindData(value: (Dependency, (() -> Void)))
}

extension Reactive where Base: UITableView {
    func itemsCustomedActioned<S: Sequence, Cell: UITableViewCell, O: ObservableType>
        (cellType: Cell.Type)
        -> (_ proxy: PublishSubject<Cell.Dependency>)
        -> (_ source: O)
        -> Disposable
        where O.Element == S, Cell: CellFactoryWithAction, S.Iterator.Element == Cell.Dependency {
            return { proxy in
                return { source in
                    return source.map {
                        $0.map { model in (model, { proxy.onNext(model)}) }
                        }.bind(to: self.items(cellIdentifier: cellType.identifier, cellType: cellType), curriedArgument: { _, model, cell in
                            cell.bindData(value: model)
                        })
                }
            }
    }
}

extension CellFactoryWithAction where Self: UITableViewCell {
    static func itemsCustomedActioned2<S: Sequence, O: ObservableType>
        (proxy: PublishSubject<Self.Dependency>)
        -> (_ view: UITableView)
        -> (_ source: O)
        -> Disposable
        where O.Element == S, S.Iterator.Element == Self.Dependency {
            return { (view: UITableView) in
                return { [unowned view] source in
                    return source.map {
                        $0.map { model in (model, { proxy.onNext(model)}) }
                        }.bind(to: view.rx.items(cellIdentifier: Self.identifier, cellType: Self.self), curriedArgument: { _, model, cell in
                            cell.bindData(value: model)
                        })
                }
            }
    }
}
