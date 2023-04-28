//
//  ChannelController.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ChannelCreateController: BaseController, VCFactory, VCPushStreamable {
    static var storyboardIdentifier: String = "Service"
    
    @IBOutlet weak var channelNameInput: UITextField!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var pushCompletion: ((VCPushResult<Model.Channel>) -> Void)!
    
    let viewModel = ViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.lifeCycle.signalViewWillAppear()
            .bind(to: self.viewModel.input.load)
            .disposed(by: self.disposeBag)
        
        self.channelNameInput.rx.text.asObservable().map{$0 ?? ""}
            .bind(to: self.viewModel.input.name)
            .disposed(by: self.disposeBag)
        
        self.createButton.rx.tap.asObservable()
            .bind(to: self.viewModel.input.create)
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.enabled.asObservable()
            .bind(to: self.createButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.result.asObservable()
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let channel):
                    self?.pushCompletion?(.complete(channel))
                case .failure(let error):
                    self?.view.makeToast(error.localizedDescription)
                    break
                }
            }).disposed(by: self.disposeBag)
        
        self.viewModel.output.section.asObservable()
            .bind(to: self.tableView.rx.items(dataSource: RxTableViewSectionedReloadDataSource<Model.User.Section>(configureCell: { [weak self] (ds, tb, ip, data) -> UITableViewCell in
                let selected = self?.viewModel.output.selected.value ?? []
                return tb.getCell(value: InviteUserCell.self,
                                  data: .init(user: data,
                                              selected: selected.contains(data)))
            })))
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.itemSelected.asObservable()
            .bind(to: self.viewModel.input.selected)
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.selected.asObservable().collapseType()
            .subscribe(onNext: { self.tableView.reloadData() })
            .disposed(by: self.disposeBag)
            
    }
}

class InviteUserCell: UITableViewCell, CellFactory {
    static var identifier: String = "InviteUserCell"
    
    @IBOutlet weak var selectedView: UIView! {
        didSet {
            selectedView.layer.cornerRadius = 10
            selectedView.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    func bindData(value: Info) {
        self.userNameLabel.text = value.user.userIdAndNickname
        self.selectedView.backgroundColor = value.selected ? UIColor.systemBlue : UIColor.systemGray6
    }
    
    struct Info {
        let user: Model.User
        let selected: Bool
    }
}

extension ChannelCreateController {
    class ViewModel: ViewModelType {
        struct Input {
            let load = PublishRelay<Void>()
            let selected = PublishRelay<IndexPath>()
            let name = PublishRelay<String>()
            let create = PublishRelay<Void>()
        }
        
        struct Output {
            let enabled = BehaviorRelay<Bool>(value: false)
            let section = PublishRelay<[Model.User.Section]>()
            let selected = BehaviorRelay<[Model.User]>(value: [])
            let result = PublishRelay<Result<Model.Channel, Error>>()
        }
        
        let input = Input()
        let output = Output()
        
        let params = BehaviorRelay<Model.Channel.Create>(value: .init())
        let userList = BehaviorRelay<[Model.User]>(value: [])
        
        let disposeBag: DisposeBag = DisposeBag()
        
        init() {
            self.input.load.asObservable()
                .flatMapLatest{ ChatService.instance.getUserList(refresh: true) }
                .map{ $0.filter{ $0.userId != AuthService.instance.userId } }
                .bind(to: userList)
                .disposed(by: self.disposeBag)
            
            self.userList.map{ [Model.User.Section.init(items: $0)] }
                .bind(to: self.output.section)
                .disposed(by: self.disposeBag)
            
            self.output.selected.asObservable().map{ $0.map{ $0.id } }
                .withLatestFrom(self.params) { $1.update(userList: $0) }
                .bind(to: self.params)
                .disposed(by: self.disposeBag)
            
            self.input.selected.asObservable()
                .withLatestFrom(self.userList) { $1[safe: $0.row] }
                .withLatestFrom(self.output.selected) { (user: $0, list: $1) }
                .map { value in
                    guard let user = value.user else { return value.list }
                    if value.list.contains(user) == true {
                        return value.list.filter{ $0.id != user.id }
                    } else {
                        return value.list + [user]
                    }
                }
                .bind(to: self.output.selected)
                .disposed(by: self.disposeBag)
            
            self.input.name.asObservable()
                .withLatestFrom(self.params) { $1.update(name: $0) }
                .bind(to: self.params)
                .disposed(by: self.disposeBag)
            
            self.params.asObservable().map{ $0.isValid }
                .bind(to: self.output.enabled)
                .disposed(by: self.disposeBag)
            
            self.input.create.asObservable()
                .withLatestFrom(self.params).filter{ $0.isValid }
                .flatMapLatest { params in
                    ChatService.instance.createChannel(with: params)
                        .map{ .success($0) }
                        .catchError{ .just(.failure($0)) }
                }.bind(to: self.output.result)
                .disposed(by: self.disposeBag)
        }
    }
}
