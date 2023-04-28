//
//  ChannelListController.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ChannelNavigationController: UINavigationController, StoryboardStateSceneType {
    static var storyboardIdentifier: String = "Service"
}

class ChannelListController: BaseController {
    @IBOutlet weak var tableView: UITableView!
    
    lazy var viewModel = { ViewModel(target: self) }()
    
    lazy var createButton: UIBarButtonItem = {
        UIBarButtonItem.init(title: "ADD", style: .done, target: nil, action: nil)
    }()
    
    lazy var myButton: UIBarButtonItem = {
        UIBarButtonItem.init(title: "MY", style: .done, target: nil, action: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "DEMO"
        self.navigationController?.navigationBar.topItem?.setLeftBarButton(myButton, animated: true)
        self.navigationController?.navigationBar.topItem?.setRightBarButton(createButton, animated: true)
        
        self.lifeCycle.signalViewWillAppear()
            .bind(to: self.viewModel.input.load)
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.section.asObservable()
            .bind(to: self.tableView.rx.items(dataSource: RxTableViewSectionedReloadDataSource<Model.Channel.Section>(configureCell: { (ds, tb, ip, data) -> UITableViewCell in
                return tb.getCell(value: ChannelListCell.self, data: data)
            })))
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.itemSelected.asObservable()
            .bind(to: self.viewModel.input.selected)
            .disposed(by: self.disposeBag)
        
        self.createButton.rx.tap.asObservable().collapseType()
            .bind(to: viewModel.input.create)
            .disposed(by: self.disposeBag)
        
        self.myButton.rx.tap.asObservable().collapseType()
            .bind(to: viewModel.input.my)
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.willDisplayCell.asObservable()
            .map{ $0.indexPath }
            .bind(to: self.viewModel.input.displayIndex)
            .disposed(by: self.disposeBag)
    }
}

class ChannelListCell: UITableViewCell, CellFactory {
    static var identifier: String = "ChannelListCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var channel: Model.Channel? {
        didSet { updateUI() }
    }
     
    func bindData(value: Model.Channel) { channel = value }
    
    func updateUI() {
        self.nameLabel.text = channel?.name
        self.messageLabel.text = channel?.lastMessage
    }
}

extension ChannelListController {
    class ViewModel: ViewModelType {
        struct Input {
            let load = PublishRelay<Void>()
            let more = PublishRelay<Void>()
            let create = PublishRelay<Void>()
            let selected = PublishRelay<IndexPath>()
            let my = PublishRelay<Void>()
            let displayIndex = PublishRelay<IndexPath>()
        }
        
        struct Output {
            let lastItemIndex = BehaviorRelay<Int?>(value: nil)
            let section = BehaviorRelay<[Model.Channel.Section]>(value: [])
        }
        
        let channels = BehaviorRelay<[Model.Channel]>(value: [])
        let added = PublishRelay<Model.Channel>()
        let channelEventReceiver = ChatService.ChannelEventReceiver()
        
        let input = Input()
        let output = Output()
        
        weak var target: UIViewController?
        let disposeBag: DisposeBag = DisposeBag()
        
        init(target: UIViewController?) {
            self.target = target
            
            self.input.load.asObservable()
                .flatMapLatest{ ChatService.instance.getGroupChannelList(refresh: true)
                    .catchErrorJustReturn([])
                }
                .bind(to: self.channels)
                .disposed(by: self.disposeBag)

            self.channels.asObservable()
                .filter{ $0.count >= ChatService.Constant.channelLimit }
                .map{$0.count - 1}
                .bind(to: self.output.lastItemIndex)
                .disposed(by: self.disposeBag)
            
            self.channels.asObservable()
                .map{ [Model.Channel.Section(items: $0)] }
                .bind(to: self.output.section)
                .disposed(by: self.disposeBag)
            
            self.input.displayIndex.asObservable()
                .withLatestFrom(self.output.lastItemIndex) { ($0.row == $1) }
                .filter(identical).collapseType()
                .throttle(.seconds(1), scheduler: MainScheduler.instance)
                .flatMapLatest{ ChatService.instance.getGroupChannelList(refresh: false) }
                .withLatestFrom(self.channels) { $1 + $0 }
                .bind(to: self.channels)
                .disposed(by: self.disposeBag)
            
            self.input.selected.asObservable()
                .withLatestFrom(self.channels) { $1[safe: $0.row] }.unwrap()
                .flatMapLatest(weak: self) { (this, channel) -> Observable<Bool> in
                    guard let target = this.target else { return .empty() }
                    return ChatController.createInstance(channel).pushStream(nv: target.navigationController)
                }.subscribe()
                .disposed(by: self.disposeBag)
            
            self.input.create.asObservable()
                .flatMapLatest(weakTo: self) { this -> Observable<Model.Channel> in
                    guard let target = self.target else { return .empty() }
                    return ChannelCreateController.createInstance().pushStream(nv: target.navigationController)
                }
                .bind(to: self.added)
                .disposed(by: self.disposeBag)
            
            self.input.my.asObservable()
                .flatMapLatest(weakTo: self) { this -> Observable<Void> in
                    guard let target = self.target else { return .empty() }
                    return SettingController.createInstance().pushStream(nv: target.navigationController)
                        .collapseType()
                }
                .subscribe()
                .disposed(by: self.disposeBag)
            
            self.added.asObservable().collapseType()
                .bind(to: self.input.load)
                .disposed(by: self.disposeBag)
            
            self.input.load.asObservable()
                .flatMapLatest(weakTo: self) { $0.channelEventReceiver.receiveChatEvent.asObservable() }
                .collapseType()
                .bind(to: self.input.load)
                .disposed(by: self.disposeBag)
        }
    }
}

extension ChannelListController: StateSceneTransitioning {
    func transition(from: StateSceneType) -> StateScene.Transition {
        switch from {
        default: return .fade(scale: 1.0, duration: 0.3)
        }
    }
}
