//
//  GameScene.swift
//  SpaceShooter
//
//  Created by Роман Андреев on 27.01.2020.
//  Copyright © 2020 Роман Андреев. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

    var starfield:SKEmitterNode!
    var player:SKSpriteNode!
    var scoreLabel:SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Счет: \(score)"
        }
    }
    var gameTimer:Timer!
    var aliens = ["alien", "alien2", "alien3"]
    
    let alienCategory:UInt32 = 0x1 << 1
    let bulletCategory:UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    var xAccelerate:CGFloat = 0
    
    override func didMove(to view: SKView) {
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0 , y: 1472)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        
        starfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPoint(x: UIScreen.main.bounds.width / 2, y: 40)
        
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Счет: 0")
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.white
        scoreLabel.position = CGPoint(x: 100, y: UIScreen.main.bounds.height - 100)
        score = 0
        
        self.addChild(scoreLabel)
        
        var timeInterval = 0.75
        
        if UserDefaults.standard.bool(forKey: "hard") {
            timeInterval = 0.3
        }
        
        gameTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        //передвижения коробля с помощью акселерометра
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data: CMAccelerometerData?, error: Error?) in
            if let accelerometrData = data {
                let acceleration = accelerometrData.acceleration
                //для плавного передвежения
                self.xAccelerate = CGFloat(acceleration.x) * 0.75 + self.xAccelerate * 0.25
            }
        }
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAccelerate * 50
        
        if player.position.x < 0 {
            player.position = CGPoint(x: UIScreen.main.bounds.width - player.size.width, y: player.position.y)
        } else if player.position.x < UIScreen.main.bounds.width {
            player.position = CGPoint(x: 20, y: player.position.y)
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var alienBody:SKPhysicsBody
        var bulletdBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bulletdBody = contact.bodyA
            alienBody = contact.bodyB
        } else {
            bulletdBody = contact.bodyB
            alienBody = contact.bodyA
        }
        
        //Проверка на побитовом операторе (& плюсует между собой 2 битовых числа)
        if (alienBody.categoryBitMask & alienCategory) != 0 && (bulletdBody.categoryBitMask & bulletCategory) != 0 {
            collisionElements(bulletNode: bulletdBody.node as! SKSpriteNode, alienNode: alienBody.node as! SKSpriteNode)
            
            
        }
    }
    
    func collisionElements(bulletNode:SKSpriteNode, alienNode:SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "Explosion")
        explosion?.position = alienNode.position
        self.addChild(explosion!)
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        bulletNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)){
            explosion?.removeFromParent()
        }
        
        score += 5
    }
        
    @objc func addAlien(){
        aliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: aliens) as! [String]
        let alien = SKSpriteNode(imageNamed: aliens[0])
        let randomPos = GKRandomDistribution(lowestValue: 20, highestValue: Int(UIScreen.main.bounds.size.width - 20))
        let pos = CGFloat(randomPos.nextInt())
        alien.position = CGPoint(x: pos, y: UIScreen.main.bounds.size.height + alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = bulletCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animDuration:TimeInterval = 6
        
        var actions = [SKAction]()
        actions.append(SKAction.move(to: CGPoint(x: pos, y: 0 - alien.size.height), duration: animDuration))
        actions.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actions))
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet()
    }
    
    func fireBullet() {
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
         let bullet = SKSpriteNode(imageNamed: "torpedo")
        bullet.position = player.position
        bullet.position.y += 5
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width / 2)
        bullet.physicsBody?.isDynamic = true
        
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.contactTestBitMask = alienCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(bullet)
        
        let animDuration:TimeInterval = 0.3
        
        var actions = [SKAction]()
        actions.append(SKAction.move(to: CGPoint(x: player.position.x, y: UIScreen.main.bounds.size.height + bullet.size.height), duration: animDuration))
        actions.append(SKAction.removeFromParent())
        
        bullet.run(SKAction.sequence(actions))
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
