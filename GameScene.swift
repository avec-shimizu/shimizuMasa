//
//  GameScene.swift
//  shooting-game
//
//  Created by 清水正明 on 2020/05/10.
//  Copyright © 2020 Ballroom dancing. All rights reserved.
//
//クラスImportする
import SpriteKit//ゲームのフレームワークをインポート.....import -----
import GameplayKit//初期設定
import CoreMotion//端末の傾きのフレームワーク


//クラスを定義　class クラス名{}
class GameScene: SKScene, SKPhysicsContactDelegate {//衝突処理を行う（煙を出す炎）
    //class クラス名: クラス　{}
    var gameVC: GameViewController! //オプション型
    //一時停止してから1秒後にメニュー画面に戻るようにする
    let motionManager = CMMotionManager()//インアスタンス化
    //クラスを利用する
    var accelaration: CGFloat = 0.0
  
    var timer: Timer?//時間クラス追加
    //時間が経過するにつれて難易度が増加
    var timerForAsteroud: Timer?
    //時間によって難易度をあげる
    var asteroudDuration: TimeInterval = 3.0 { //var プロパティ: 型名 = 値
        didSet {
            if asteroudDuration < 2.0 {
                timerForAsteroud?.invalidate()
            }
        }
    }
    //scoreを表示する
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    //ノードを２進数化する
    let spaceshipCategory: UInt32 = 0b0001
    let missileCategory: UInt32 = 0b0010
    let asteroidCategory: UInt32 = 0b0100
    let earthCategory: UInt32 = 0b1000


    
    //SKSpriteNodeはゲーム画面に表示するオブジェクトのクラスです//SKSpriteNodeはゲーム画面に表示するオブジェクトのクラスです
    var spaceship: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var earth : SKSpriteNode!
    var hearts: [SKSpriteNode] = []
    var shikama: SKSpriteNode!
   
    
    override func didMove(to view: SKView) {//オーバーライドを実行、override func メソッド名　{
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
               physicsWorld.contactDelegate = self
        
        //四釜を追加
        self.shikama = SKSpriteNode(imageNamed: "shikama" )
        self.shikama.scale(to: CGSize(width: 0.1,height: 0.1))
        self.shikama.position = CGPoint()
        
        let biggerCircleAction = SKAction.scale(to: 0.5, duration: 2)
        let smallerCircleAction = SKAction.scale(to: 0.1, duration: 2)
        
        let MoveY = SKAction.moveTo(x:-self.frame.width, duration: 3)//
        let MoveX = SKAction.moveTo(x: self.frame.width, duration: 2)
        
        let rotation = SKAction.rotate(byAngle: 1.57, duration: 2)
        let repearrotation = SKAction.repeatForever(rotation)
        
        let AllAction = SKAction.sequence([biggerCircleAction,smallerCircleAction])
        let repeatAllAction1 = SKAction.repeatForever(AllAction)
        
        let moveAllAction = SKAction.sequence([MoveX,MoveY])
        let repeatmoveAllAction = SKAction.repeatForever(moveAllAction)
        
            self.shikama.run(repearrotation)
            self.shikama.run(repeatmoveAllAction)
            self.shikama.run(repeatAllAction1)
            addChild(self.shikama)
        
        self.earth = SKSpriteNode(imageNamed: "earth")
        //SKSpriteNodeクラスを利用してearthを追加
        self.earth.xScale = 1.5
        self.earth.yScale = 0.5
        //self.earth.scale(to: CGSize(width:1.5,height:1))ともかける
        self.earth.position = CGPoint(x: 0, y: -frame.height/2)
        self.earth.zPosition = -1.0
        //衝突処理を実行
        self.earth.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 50))
        self.earth.physicsBody?.categoryBitMask = earthCategory
        self.earth.physicsBody?.contactTestBitMask = asteroidCategory
        self.earth.physicsBody?.collisionBitMask = 0
            addChild(self.earth)
        
        self.spaceship = SKSpriteNode(imageNamed: "spaceship")
        //SKspriteNodeクラすを利用してSpaceshipを追加
        self.spaceship.scale(to: CGSize(width: frame.width / 5, height: frame.width / 5))
        self.spaceship.position = CGPoint(x: 0, y: self.earth.frame.maxY + 50)
        //衝突処理を利用
        self.spaceship.physicsBody = SKPhysicsBody(circleOfRadius: self.spaceship.frame.width * 0.1)
        self.spaceship.physicsBody?.categoryBitMask = spaceshipCategory
        self.spaceship.physicsBody?.contactTestBitMask = asteroidCategory
        self.spaceship.physicsBody?.collisionBitMask = 0
        addChild(self.spaceship)
        //CMMotionManagerを利用して作る
        motionManager.accelerometerUpdateInterval = 0.2//計測間隔
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, _) in// motionの取得を開始
                   guard let data = data else { return }//変数が適切かを判断
                   let a = data.acceleration
                   self.accelaration = CGFloat(a.x) * 0.75 + self.accelaration * 0.25//傾きの動作がいまいちよくわからん
               }
        //小惑星を時間ごと追加
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
            self.addAsteroid() })
        //ハートのアルゴリズム
        for i in 1...5 {
            let heart = SKSpriteNode(imageNamed: "heart")
            heart.position = CGPoint(x: -frame.width / 2 + heart.frame.height * CGFloat(i), y: frame.height / 2 - heart.frame.height)
            addChild(heart)
            hearts.append(heart)
        }
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontName = "Papyrus"
        scoreLabel.fontSize = 50
        scoreLabel.position = CGPoint(x: -frame.width / 2 + scoreLabel.frame.width / 2 + 50, y: frame.height / 2 - scoreLabel.frame.height * 5)
        addChild(scoreLabel)
        //ベストスコアを記録する
        let bestScore = UserDefaults.standard.integer(forKey: "bestScore")
        let bestScoreLabel = SKLabelNode(text: "Best Score: \(bestScore)")
        bestScoreLabel.fontName = "Papyrus"
        bestScoreLabel.fontSize = 30
        bestScoreLabel.position = scoreLabel.position.applying(CGAffineTransform(translationX: 0, y: -bestScoreLabel.frame.height * 1.5))
        addChild(bestScoreLabel)
        //時間が上がっていく
        
        timerForAsteroud = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { _ in
                   self.asteroudDuration -= 0.5
               })
               
           }

    override func didSimulatePhysics() {//傾きの動作がいまいちよくわからん
               let nextPosition = self.spaceship.position.x + self.accelaration * 50
               if nextPosition > frame.width / 2 - 30 { return }
               if nextPosition < -frame.width / 2 + 30 { return }
               self.spaceship.position.x = nextPosition//傾きの動作がいまいちよくわからん
        
        }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
             if isPaused { return }
            
            //飛行船をたっちしたらミサイルの追加
            let missile = SKSpriteNode(imageNamed: "missile")//SKspriteNodeを使用
            missile.position = CGPoint(x: self.spaceship.position.x, y: self.spaceship.position.y + 50)
            missile.physicsBody = SKPhysicsBody(circleOfRadius: missile.frame.height / 2)
                   missile.physicsBody?.categoryBitMask = missileCategory
                   missile.physicsBody?.contactTestBitMask = asteroidCategory
                   missile.physicsBody?.collisionBitMask = 0
            addChild(missile)

            let moveToTop = SKAction.moveTo(y: frame.height + 10, duration: 0.3)//durationはtimeInterbal
            let remove = SKAction.removeFromParent()
            missile.run(SKAction.sequence([moveToTop, remove]))
    }
    
    //小惑星の追加
    func addAsteroid() {
        let names = ["asteroid1", "asteroid2", "asteroid3"]
        let index = Int(arc4random_uniform(UInt32(names.count)))
        let name = names[index]
        let asteroid = SKSpriteNode(imageNamed: name)
        let random = CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX)
        let positionX = frame.width * (random - 0.5)
        asteroid.position = CGPoint(x: positionX, y: frame.height / 2 + asteroid.frame.height)
        asteroid.scale(to: CGSize(width: 140, height: 140))
        
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.frame.width)
        asteroid.physicsBody?.categoryBitMask = asteroidCategory
        asteroid.physicsBody?.contactTestBitMask = missileCategory + spaceshipCategory + earthCategory
        asteroid.physicsBody?.collisionBitMask = 0
        
        addChild(asteroid)

        let move = SKAction.moveTo(y: -frame.height / 2 - asteroid.frame.height, duration: asteroudDuration)
        let remove = SKAction.removeFromParent()
        asteroid.run(SKAction.sequence([move, remove]))
    }
    //衝突したら煙が出る
    func didBegin(_ contact: SKPhysicsContact) {
        var asteroid: SKPhysicsBody
        var target: SKPhysicsBody

        if contact.bodyA.categoryBitMask == asteroidCategory {
            asteroid = contact.bodyA
            target = contact.bodyB
        } else {
            asteroid = contact.bodyB
            target = contact.bodyA
        }

        guard let asteroidNode = asteroid.node else { return }//判別が必要
        guard let targetNode = target.node else { return }
        guard let explosion = SKEmitterNode(fileNamed: "Explosion") else { return }
        explosion.position = asteroidNode.position
        addChild(explosion)

        asteroidNode.removeFromParent()
        if target.categoryBitMask == missileCategory {
            targetNode.removeFromParent()
            
            score += 5
        }

        self.run(SKAction.wait(forDuration: 1.0)) {
            explosion.removeFromParent()
        }
        if target.categoryBitMask == spaceshipCategory || target.categoryBitMask == earthCategory {
                   guard let heart = hearts.last else { return }
                   heart.removeFromParent()
                   hearts.removeLast()
            if hearts.isEmpty {
                           gameOver()
                       }
               }
    }

       func gameOver() {
           isPaused = true
           timer?.invalidate()
        
        //ベストスコアが更新された場合
        let bestScore = UserDefaults.standard.integer(forKey: "bestScore")
               if score > bestScore {
                   UserDefaults.standard.set(score, forKey: "bestScore")
               }
        //一時停止してメニューに戻る
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            self.gameVC.dismiss(animated: true, completion: nil)
        }
       }

}
