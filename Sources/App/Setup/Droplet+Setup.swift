@_exported import Vapor

extension Droplet {
    public func setup() throws {
        // Do any additional droplet setup
        setupcontrollers()
    }
    
    
    func setupcontrollers() {
        _ = BlockchainController(drop: self)
    }
}
