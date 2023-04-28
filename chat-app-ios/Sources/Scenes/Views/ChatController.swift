//
//  ChatController.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ChatController: BaseController, VCBindFactory, VCPushStreamable {
    static var storyboardIdentifier: String = "Service"
    
    let channel = BehaviorRelay<Model.Channel?>(value: nil)
    
    func bindData(_ data: Model.Channel) { channel.accept(data) }
    
    var pushCompletion: ((VCPushResult<Bool>) -> Void)!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet { tableView.transform = CGAffineTransform(scaleX: 1, y: -1) }
    }

    @IBOutlet weak var textInput: UITextField!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    var keyboardHandler: KeyboardHandler?
    @IBOutlet var keyboardHeight: NSLayoutConstraint! {
        didSet { keyboardHandler = KeyboardHandler(delegate: self, layoutContraints: self.keyboardHeight) }
    }
    
    lazy var viewModel = { ViewModel(target: self) } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        self.lifeCycle.signalViewDidAppear()
            .withLatestFrom(self.channel)
            .bind(to: self.viewModel.input.load)
            .disposed(by: self.disposeBag)
        
        self.textInput.rx.text.asObservable().map{ $0 ?? "" }
            .bind(to: self.viewModel.input.text)
            .disposed(by: self.disposeBag)
        
        self.sendButton.rx.tap.asObservable()
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .bind(to: self.viewModel.input.sendMessage)
            .disposed(by: self.disposeBag)
        
        self.imageButton.rx.tap.asObservable()
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .bind(to: self.viewModel.input.sendFile)
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.section.asObservable()
            .bind(to: self.tableView.rx.items(dataSource: RxTableViewSectionedReloadDataSource<Model.Chat.Section>(configureCell: { (ds, tb, ip, data) -> UITableViewCell in
                switch (data, data.isOthers()) {
                case (.message(let data), .my):
                    return tb.getCell(value: ChatMyMessageCell.self, data: data)
                case (.message(let data), .other):
                    return tb.getCell(value: ChatOtherMessageCell.self, data: data)
                case (.file(let data), .my):
                    return tb.getCell(value: ChatMyFileCell.self, data: data)
                case (.file(let data), .other):
                    return tb.getCell(value: ChatOtherFileCell.self, data: data)
                }
            })))
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.itemSelected.asObservable()
            .bind(to: self.viewModel.input.delete)
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.clearMessage.asObservable().mapTo("")
            .bind(to: self.textInput.rx.text)
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.willDisplayCell.asObservable()
            .map{ $0.indexPath }
            .bind(to: self.viewModel.input.displayIndex)
            .disposed(by: self.disposeBag)
         
    }
}

extension ChatController {
    class ViewModel: ViewModelType {
        struct Input {
            let load = PublishRelay<Model.Channel?>()
            let sendMessage = PublishRelay<Void>()
            let sendFile = PublishRelay<Void>()
            let delete = PublishRelay<IndexPath>()
            let text = PublishRelay<String>()
            let displayIndex = PublishRelay<IndexPath>()
        }
        
        struct Output {
            let lastItemIndex = BehaviorRelay<Int?>(value: nil)
            let completion = PublishRelay<Bool>()
            let section = BehaviorRelay<[Model.Chat.Section]>(value: [])
            let clearMessage = PublishRelay<Void>()
        }
        
        let input = Input()
        let output = Output()
        
        let channel = BehaviorRelay<Model.Channel?>(value: nil)
        
        let sentMessage = PublishRelay<Model.Chat>()
        let deletedMessage = PublishRelay<String>()
        
        let chatList = BehaviorRelay<[Model.Chat]>(value: [])
        let disposeBag: DisposeBag = DisposeBag()
        
        let channelEventReceiver = ChatService.ChannelEventReceiver()

        weak var target: UIViewController?
        
        init(target: UIViewController?) {
            self.target = target
            
            self.chatList.asObservable()
                .filter{ $0.count >= ChatService.Constant.messageLimit }
                .map{$0.count - 1}
                .bind(to: self.output.lastItemIndex)
                .disposed(by: self.disposeBag)
            
            self.input.load.asObservable().unwrap().take(1)
                .flatMapLatest{ ChatService.instance.getMessages(with: $0, refresh: true) }
                .bind(to: self.chatList)
                .disposed(by: self.disposeBag)
            
            self.input.load.asObservable().unwrap()
                .bind(to: channel)
                .disposed(by: self.disposeBag)
            
            self.input.displayIndex.asObservable()
                .withLatestFrom(self.output.lastItemIndex) { ($0.row == $1) }
                .filter(identical)
                .throttle(.seconds(1), scheduler: MainScheduler.instance)
                .withLatestFrom(self.channel).unwrap()
                .flatMapLatest{ ChatService.instance.getMessages(with: $0, refresh: false) }
                .withLatestFrom(self.chatList) { $1 + $0 }
                .bind(to: self.chatList)
                .disposed(by: self.disposeBag)
    
            self.sentMessage.asObservable()
                .withLatestFrom(self.chatList) { [$0] + $1 }
                .bind(to: self.chatList)
                .disposed(by: self.disposeBag)
            
            self.sentMessage.asObservable().collapseType()
                .bind(to: self.output.clearMessage)
                .disposed(by: self.disposeBag)
            
            self.deletedMessage.asObservable()
                .withLatestFrom(self.chatList) { (deleteId, chatList) in chatList.filter{ $0.id != deleteId } }
                .bind(to: self.chatList)
                .disposed(by: self.disposeBag)
            
            self.chatList.asObservable()
                .map{ [Model.Chat.Section(items: $0)] }
                .bind(to: self.output.section)
                .disposed(by: self.disposeBag)
            
            self.input.delete.asObservable()
                .withLatestFrom(self.chatList) { $1[safe: $0.row] }.unwrap()
                .withLatestFrom(self.channel) { (chat: $0, channel: $1) }
                .flatMapLatest(weak: self) { (this, value) in
                    ChatService.instance.confirmAndDeleteMessage(target: this.target,
                                                                 channel: value.channel,
                                                                 chat: value.chat)
                }
                .bind(to: self.deletedMessage)
                .disposed(by: self.disposeBag)
                
            self.input.sendMessage.asObservable()
                .withLatestFrom(self.input.text)
                .map{ $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .filter{ $0.count > 0 }
                .withLatestFrom(self.channel) { (channel: $1, message: $0) }
                .flatMapLatest{ ChatService.instance.sendMessage(with: $0.channel, message: $0.message) }
                .bind(to: self.sentMessage)
                .disposed(by: self.disposeBag)
            
            self.input.sendFile.asObservable()
                .observeOn(MainScheduler.instance)
                .flatMapLatest(weakTo: self) { AuthService.instance.authPhoto(target: $0.target) }
                .flatMapLatest(weakTo: self) { ImagePicker.getStream($0.target) }
                .unwrap()
                .withLatestFrom(self.channel) { (channel: $1, message: $0) }
                .flatMapLatest{
                    ChatService.instance.sendImage(with: $0.channel, image: $0.message)
                        .bindGlobalActivityIndicator()
                }.bind(to: self.sentMessage)
                .disposed(by: self.disposeBag)
            
            let event =
            self.input.load.asObservable()
                .flatMapLatest(weakTo: self) { $0.channelEventReceiver.receiveChatEvent.asObservable() }
                .withLatestFrom(self.channel) { (event: $0, channel: $1) }
                .filter{ $0.event.isValid(with: $0.channel) }
                .map{ $0.event }
                .share(replay: 1)
            
            event.map{ $0.newMessage }.unwrap()
                .bind(to: self.sentMessage)
                .disposed(by: self.disposeBag)
                
            event.map{ $0.deletedMessageId?.description }.unwrap()
                .bind(to: self.deletedMessage)
                .disposed(by: self.disposeBag)
                
        }
    }
}
