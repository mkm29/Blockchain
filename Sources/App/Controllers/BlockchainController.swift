//
//  BlockchainController.swift
//  App
//
//  Created by Mitchell Murphy on 4/28/18.
//

import Foundation
import Vapor
import HTTP

class BlockchainController {
    
    private (set) var drop: Droplet
    private (set) var blockchainService: BlockchainService
    
    init(drop: Droplet) {
        self.drop = drop
        self.blockchainService = BlockchainService()
        setupRoutes()
    }
    
    
    private func setupRoutes() {
        
        
        self.drop.post("/nodes/register") { request in
            if let blockchainNode = BlockchainNode(request: request) {
                // now we can add it
                self.blockchainService.registerNode(blockchainNode)
            }
            return try JSONEncoder().encode(["message":"success"])
        }
        
        self.drop.get("/nodes/resolve") { request in
            
            return try Response.async({ (portal) in
                
                self.blockchainService.resolve(completion: { (blockchain) in
                    let blockchain = try! JSONEncoder().encode(blockchain)
                    portal.close(with: blockchain.makeResponse())
                })
                
            })
            
        }
        
        self.drop.get("/nodes") { request in
            let nodes = self.blockchainService.blockchain.nodes
            return try JSONEncoder().encode(nodes)
        }
        
        self.drop.post("mine") { request in
            
            if let transaction = Transaction(request: request) {
                let block = self.blockchainService.getMinedBlock(transactions: [transaction])
                //block.addTransaction(transaction: transaction)
                return try JSONEncoder().encode(block)
            }
            return try JSONEncoder().encode(["message" : "There was an error mining the block!"])
            
        }
        
        self.drop.get("blockchain") { request in
            let blockchain = self.blockchainService.getBlockchain()
            return try! JSONEncoder().encode(blockchain)
        }
        
    }
    
}
