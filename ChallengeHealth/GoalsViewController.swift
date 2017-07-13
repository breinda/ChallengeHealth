import UIKit
import Firebase
import FirebaseAuth

class GoalsViewController: UIViewController {
    
    // @IBOutlet weak var boddi: BoddiView!
    @IBOutlet weak var goalsCollectionView: UICollectionView!
    
    var goals = [Goal]()
    
    var isSecondVC = false
    
    var cellWidth: CGFloat = 0
    let columnNum: CGFloat = 1
    
    @IBOutlet weak var boddiBubble: UIImageView!
    @IBOutlet weak var boddi: UIImageView!
    
    let mountainArray: [UIImage] = [UIImage(named: "iconeMontanha1")!, UIImage(named: "iconeMontanha2")!, UIImage(named: "iconeMontanha4")!, UIImage(named: "iconeMontanha3")!]
    var mountainArrayIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.modalTransitionStyle = .crossDissolve
        
//        boddi.layer.shadowColor = UIColor.init(white: 0.0, alpha: 0.1).cgColor
//        boddi.layer.shadowOpacity = 1
//        boddi.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
//        boddi.layer.shadowRadius = 3
//        boddi.layer.shouldRasterize = true
//        
//        boddiBubble.layer.shadowColor = UIColor.init(white: 0.0, alpha: 0.1).cgColor
//        boddiBubble.layer.shadowOpacity = 1
//        boddiBubble.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
//        boddiBubble.layer.shadowRadius = 3
//        boddiBubble.layer.shouldRasterize = true
        
        //boddi.addAppearHappyJumpAnimation()
        
        // pega os goals do banco e os armazena no array goals
        DAO.STD_GOALS_REF.observe(.childAdded, with: { (snapshot) in
            
            self.goals.append(Goal(key: snapshot.key, snapshot: snapshot.value as! Dictionary<String, AnyObject>))
            
            self.goalsCollectionView.reloadData()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // MOSTRA A TELA DE LOGIN, CASO O USUARIO NAO ESTEJA LOGADO
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "loginVC")
            self.present(vc, animated: false, completion: nil)
        }
        
        goalsCollectionView.backgroundColor = UIColor.clear
        goalsCollectionView.reloadData()
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToConfigFromGoals" {
            
            let svc = segue.destination as! ConfigViewController
            // customization:
            svc.modalTransition.edge = .right
            svc.modalTransition.radiusFactor = 0.3
        }
        
        if segue.identifier == "goToCurrentStep" {
            
            let cell = sender as! GoalCollectionViewCell
            let indexPath = goalsCollectionView?.indexPath(for: cell)
            let goal = goals[(indexPath! as NSIndexPath).item]
            let currentStepVC = segue.destination as! CurrentStepViewController
            
            currentStepVC.goal = goal.name
            currentStepVC.step = goal.firstStep.name
            currentStepVC.goalKey = goal.key
            
            // seta o step atual do usuário como 1 -- saber se view inicial é a de goals ou a de currentStep
            var handle : AuthStateDidChangeListenerHandle
            
            handle = (Auth.auth().addStateDidChangeListener { auth, user in
                if let user = user {
                    // User is signed in.
                    let uid = user.uid;
                    
                    DAO.USERS_REF.child(uid).observe(.childAdded, with: { (snapshot) in
                        
                        if snapshot.key == "currentStepNumber" {
                            let childUpdates = [snapshot.key: "1"]
                            DAO.USERS_REF.child(uid).updateChildValues(childUpdates)
                        }
                        
                        if snapshot.key == "currentGoalKey" {
                            let childUpdates = [snapshot.key: goal.key]
                            DAO.USERS_REF.child(uid).updateChildValues(childUpdates)
                        }
                        
                    })
                }
            })
            
            Auth.auth().removeStateDidChangeListener(handle)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let rootVC = appDelegate.window!.rootViewController
            
            if (type(of: rootVC!) == type(of: self) || (String(describing: type(of: rootVC!)) == "LoginViewController" && self.isSecondVC == true)) {
                print("MA OE GOALSVC")
                //self.isSecondVC = false
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "currentStepVC")
                self.present(vc, animated: true, completion: nil)
            }
            else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}
