//
//  GameScene.swift
//  HoppyBunny
//
//  Created by Cappillen on 3/11/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import SpriteKit
import GameplayKit


enum GameSceneState {
    case Active, GameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var hero : SKSpriteNode!
    var scrollLayer : SKNode!
    var sinceTouch: CFTimeInterval = 0
    var spawnTimer : CFTimeInterval = 0
    let fixedDelta = 1.0 / 60.0 /* 60 FPS */
    let scrollSpeed : CGFloat = 160
    var obstacleLayer : SKNode!
    //UI Connections
    var buttonRestart : MSButtonNode!
    var gameState : GameSceneState = .Active
    
    override func didMove(to view: SKView) {
        //Set up you scene here
        
        //recursive search for the hero
        hero = self.childNode(withName: "//hero") as! SKSpriteNode
        
        //Set referenece to scroll Layer Node
        scrollLayer = self.childNode(withName: "scrollLayer")
        
        //Set reference to abstacle layer node
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        
        //Set physics contact delegate
        physicsWorld.contactDelegate = self
        
        //Set UI connections
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        
        buttonRestart.selectedHandler = {
            
            //Grab reference to our SpriteKit view
            let skView = self.view! as SKView
            
            //load game scene
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            
            //ensure correct aspect mode
            scene?.scaleMode = .aspectFill
            
            //Resart game scene
            skView.presentScene(scene)
            
        }
        // hide restart button
        buttonRestart.state = .Hidden
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        //Ensure only called while game running
        if gameState != .Active { return }
        
        //Hero touches anythin game over
        
        //Change game state to game over 
        gameState = .GameOver
        
        //Stop any ne angular velocity being applied
        hero.physicsBody?.allowsRotation = false
        
        //Reset angular velocity
        hero.physicsBody?.angularVelocity = 0
        
        //Stop hero flapping animation
        hero.removeAllActions()
        
        //Show restart button
        buttonRestart.state = .Active
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Called when a touch begins
        
        //Disable touch if game no longer active
        if gameState != .Active { return }
        
        //Apply vertical implulse
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 250))
        
        //Play SFX
        let flapSFX = SKAction.playSoundFileNamed("sfx_flap", waitForCompletion: false)
        self.run(flapSFX)
        
        //Apply subtle rotation
        hero.physicsBody?.applyAngularImpulse(1)
        
        //reset touch timer
        sinceTouch = 0
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        //Skip game update if game no longer active
        if gameState != .Active { return }
        
        //Grabs current velocity
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        //check and cap vertical velocity
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        //apply falling rotation
        if sinceTouch > 0.1 {
            let impulse = -20000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        //Clamp roatation
        hero.zRotation.clamp(v1: CGFloat(-20).degreesToRadians(), CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(v1: -2, 2)
        
        //Upadte last touch timer
        sinceTouch += fixedDelta
        
        //Process world Scrolling
        scrollWorld()
        
        //Process obstacles
        updateObstacles()
        
        spawnTimer += fixedDelta
        
    }
    
    func scrollWorld() {
        //scrollWorld
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        //loop through scroll layer nodes
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            //Get ground node position, convert node position to scene space
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            //check if ground sprite has left the scene
            if groundPosition.x <= -ground.size.width / 2 {
                
                //reposition ground sprite to the second starting position
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                
                //convert new node position back to scroll layer space
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func updateObstacles() {
        //Update Obstacles 
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        //loop through obstacle layer node
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            //get obstacle node position, convert node position to scene space
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            //check if obstacle has left the scene
            if obstaclePosition.x <= 0 {
                obstacle.removeFromParent()
            }
        }
        
        //Time to add a new obstacle?
        if spawnTimer >= 1.5 {
            
            //Create a new obstacle reference object using our abstacle resource
            let resourcePath = Bundle.main.path(forResource: "Obstacle", ofType: "sks")
            let newObstacle = SKReferenceNode(url: NSURL(fileURLWithPath: resourcePath!) as URL)
            obstacleLayer.addChild(newObstacle)
            
            //Generate new obsatcle position, start just outside screen and with a random y value
            let randomPosition = CGPoint(x: 352, y: CGFloat.random(min: 234, max: 382))
            
            //conver new node position back to obstacle layer space
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            //reset spawn timer
            spawnTimer = 0
        }
    }
}
