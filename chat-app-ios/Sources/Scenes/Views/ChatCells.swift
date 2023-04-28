//
//  ChatCells.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/27.
//

import UIKit
import SDWebImage

class BaseChatCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
}

class ChatOtherMessageCell: BaseChatCell, CellFactory {
    static var identifier: String = "ChatOtherMessageCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    func bindData(value: Model.Chat.Message) {
        nameLabel.text = value.nickname
        messageLabel.text = value.message
    }
}

class ChatMyMessageCell: BaseChatCell, CellFactory {
    static var identifier: String = "ChatMyMessageCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    func bindData(value: Model.Chat.Message) {
        nameLabel.text = value.nickname
        messageLabel.text = value.message
    }
}

class ChatOtherFileCell: BaseChatCell, CellFactory {
    static var identifier: String = "ChatOtherFileCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var fileImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.fileImageView.sd_cancelCurrentImageLoad()
        self.fileImageView.image = nil
    }
    
    func bindData(value: Model.Chat.File) {
        nameLabel.text = value.sender
        
        if let url = try? value.fileURL.asURL() {
            self.fileImageView.sd_setImage(with: url)
        }
    }
}

class ChatMyFileCell: BaseChatCell, CellFactory {
    static var identifier: String = "ChatMyFileCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var fileImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.fileImageView.sd_cancelCurrentImageLoad()
        self.fileImageView.image = nil
    }
    
    func bindData(value: Model.Chat.File) {
        nameLabel.text = value.sender
        
        if let url = try? value.fileURL.asURL() {
            self.fileImageView.sd_setImage(with: url)
        }
        
        
    }
}

