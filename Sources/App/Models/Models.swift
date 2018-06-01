//
//  Models.swift
//  App
//
//  Created by Mitchell Murphy on 4/28/18.
//
import Vapor
import Cocoa


class BlockchainNode : Codable {
    
    // if only running this locally, you can simulate nodes by running the Vapor server on different ports (default is 8080, so 8081, 8082, 8083, ...)
    var address: String
    
    init?(request: Request) {
        guard let address = request.data["address"]?.string else {
            return nil
        }
        self.address = address
    }
    
    init(address: String) {
        self.address = address
    }
    
    
    
}

protocol SmartContract {
    func apply(transaction :Transaction)
}

class TransactionTypeSmartContract : SmartContract {
    
    func apply(transaction: Transaction) {
        
        var fees = 0.0
        
        switch transaction.transactionType {
        case .domestic:
            fees = 0.02
        case .international:
            fees = 0.05
        }
        
        transaction.fees = transaction.amount * fees
        transaction.amount -= transaction.fees
    }
}

enum TransactionType : String,Codable {
    case domestic
    case international
}

class Transaction : Codable {
    
    var from :String
    var to :String
    var amount :Double
    var fees :Double = 0.0
    var transactionType :TransactionType
    
    init(from :String, to :String, amount :Double, transactionType :TransactionType) {
        self.from = from
        self.to = to
        self.amount = amount
        self.transactionType = transactionType
    }
    
    init?(request: Request) {
        guard let from = request.data["from"]?.string,
        let to = request.data["to"]?.string,
            let amount = request.data["amount"]?.double else {
                return nil
        }
        
        self.from = from
        self.to = to
        self.amount = amount
        self.transactionType = .domestic
    }
    
}

class Block : Codable {
    
    var index :Int = 0
    var previousHash :String = ""
    var hash :String!
    var nonce :Int
    var createdAt: String
    
    private (set) var transactions :[Transaction] = [Transaction]()
    
    var key :String {
        get {
            
            let transactionsData = try! JSONEncoder().encode(self.transactions)
            let transactionsJSONString = String(data: transactionsData, encoding: .utf8)
            
            return String(self.index) + self.previousHash + String(self.nonce) + transactionsJSONString!
        }
    }
    
    func addTransaction(transaction :Transaction) {
        self.transactions.append(transaction)
    }
    
    init() {
        self.nonce = 0
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.createdAt = formatter.string(from: Date())
    }
    
}

class Blockchain : Codable {
    
    var blocks :[Block] = [Block]()
    private (set) var nodes: [BlockchainNode] = [BlockchainNode]()
    private (set) var smartContracts :[SmartContract] = [TransactionTypeSmartContract()]
    
    init(genesisBlock :Block) {
        addBlock(genesisBlock)
    }
    
    private enum CodingKeys : CodingKey {
        case blocks
        case nodes
    }
    
    func addNode(_ node: BlockchainNode) {
        self.nodes.append(node)
    }
    
    
    func addBlock(_ block :Block) {
        
        if self.blocks.isEmpty {
            block.previousHash = "0000000000000000"
            block.hash = generateHash(for :block)
        }
        
        // run the smart contracts
        self.smartContracts.forEach { contract in
            block.transactions.forEach { transaction in
                contract.apply(transaction: transaction)
            }
        }
        
        self.blocks.append(block)
    }
    
    func getNextBlock(transactions :[Transaction]) -> Block {
        
        let block = Block()
        transactions.forEach { transaction in
            block.addTransaction(transaction: transaction)
        }
        
        let previousBlock = getPreviousBlock()
        block.index = self.blocks.count
        block.previousHash = previousBlock.hash
        block.hash = generateHash(for: block)
        return block
        
    }
    
    private func getPreviousBlock() -> Block {
        return self.blocks[self.blocks.count - 1]
    }
    
    func generateHash(for block :Block) -> String {
        
        var hash = block.key.sha1Hash()
        
        while(!hash.hasPrefix("00")) {
            block.nonce += 1
            hash = block.key.sha1Hash()
            print(hash)
        }
        
        return hash
    }
    
}

// String Extension
extension String {
    
    func sha1Hash() -> String {
        
        let task = Process()
        task.launchPath = "/usr/bin/shasum"
        task.arguments = []
        
        let inputPipe = Pipe()
        
        inputPipe.fileHandleForWriting.write(self.data(using: String.Encoding.utf8)!)
        
        inputPipe.fileHandleForWriting.closeFile()
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardInput = inputPipe
        task.launch()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let hash = String(data: data, encoding: String.Encoding.utf8)!
        return hash.replacingOccurrences(of: "  -\n", with: "")
    }
}
