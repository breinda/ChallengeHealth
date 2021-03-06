import UIKit
import Firebase
import FirebaseAuth

// só queremos que goalsVC reloade quando tivermos algo pra mudar na collection view (i.e. algum goal novo)
var GoalsVCShouldReload: Bool = true

class GoalsViewController: UIViewController {
    
    // @IBOutlet weak var boddi: BoddiView!
    @IBOutlet weak var goalsCollectionView: UICollectionView!
    
    var goals = [Goal]()
    
    var isSecondVC = false
    
    var cellWidth: CGFloat = 0
    let columnNum: CGFloat = 1
    
    @IBOutlet weak var boddiBubble: UIImageView!
    @IBOutlet weak var boddi: UIImageView!
    
    @IBOutlet weak var bgRectangleImageView: UIImageView!
    @IBOutlet weak var backRectangleImageView: UIImageView!
    @IBOutlet weak var navBarRectangleImageView: UIImageView!
    
    let mountainArray: [UIImage] = [UIImage(named: "iconeMontanha1")!, UIImage(named: "iconeMontanha2")!, UIImage(named: "iconeMontanha4")!, UIImage(named: "iconeMontanha3")!]
    var mountainArrayIndex = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.modalTransitionStyle = .crossDissolve
        
        //boddi.addAppearHappyJumpAnimation()
        
        // setando propriedades das imagens
        bgRectangleImageView.layer.borderWidth = 1
        bgRectangleImageView.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        
        backRectangleImageView.layer.cornerRadius = 39
        backRectangleImageView.layer.borderWidth = 1
        backRectangleImageView.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        
        navBarRectangleImageView.layer.borderWidth = 1
        navBarRectangleImageView.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.12).cgColor
        
        boddiBubble.layer.cornerRadius = 26
        boddiBubble.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        boddiBubble.layer.shadowOpacity = 0.1
        boddiBubble.layer.shadowRadius = 4
        boddiBubble.layer.shadowOffset = CGSize(width: 0, height: 2)
        boddiBubble.layer.shouldRasterize = true
        
        boddi.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        boddi.layer.shadowOpacity = 0.1
        boddi.layer.shadowRadius = 4
        boddi.layer.shadowOffset = CGSize(width: 0, height: 2)
        boddi.layer.shouldRasterize = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("GoalsVC -- INICIO DA viewDidAppear -- GoalsVCShouldReload = \(GoalsVCShouldReload)")
        
        // MOSTRA A TELA DE LOGIN, CASO O USUARIO NAO ESTEJA LOGADO
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "loginVC")
            self.present(vc, animated: false, completion: nil)
        }
        
        goalsCollectionView.backgroundColor = UIColor.clear
        //goalsCollectionView.reloadData()
        
        if GoalsVCShouldReload {
            goals.removeAll()
            
            handleAsynchronousRequestForCstGoalsFromThisUserAtGoalsVC { numberCompleted, totalUsersWithCstGoals, userWasFound in
                
                print("GoalsVC -- numberCompleted = \(numberCompleted)")
                print("GoalsVC -- totalUsersWithCstGoals = \(totalUsersWithCstGoals)")
                print("GoalsVC -- userWasFound = \(userWasFound)")
                print("")
                
                
                if numberCompleted == totalUsersWithCstGoals { // se tivermos chegado ao fim da busca
                    
                    if userWasFound == true { // usuário possui algum custom goal criado!
                        print("GoalsVC -- achei o usuário AFINAL")
                        
                        // pegamos, então, todos os std goals + os custom goals do usuário
                        self.handleAsynchronousRequestForEveryStdGoalAndCstGoal { numberCompleted, totalCstGoalsThisUser, totalStdGoals in
                            if numberCompleted == totalCstGoalsThisUser + totalStdGoals {
                                print("GoalsVC -- userWasFound = TRUE -- PRONTO")
                                //print("userWasFound = TRUE, number completed = \(numberCompleted)")
                                //print("userWasFound = TRUE, totalCstGoals = \(totalCstGoalsThisUser)")
                                //print("userWasFound = TRUE, totalStdGoals = \(totalStdGoals)")
                                
                                self.goalsCollectionView.reloadData()
                                
                                DAO.CST_GOALS_REF.removeAllObservers()
                                DAO.CST_GOALS_REF.child(userID).removeAllObservers()
                                DAO.STD_GOALS_REF.removeAllObservers()
                            }
                                
                            else {
                                print("GoalsVC -- userWasFound = TRUE -- LOADING")
                                //print("userWasFound = TRUE, number completed = \(numberCompleted)")
                                //print("userWasFound = TRUE, totalCstGoals = \(totalCstGoalsThisUser)")
                                //print("userWasFound = TRUE, totalStdGoals = \(totalStdGoals)")
                            }
                        }
                    }
                    else { // não achamos o usuário ao final da busca == usuário não possui nenhum custom goal criado
                        
                        // pegamos, então, apenas os std goals
                        self.handleAsynchronousRequestForEveryStdGoal { numberCompleted, totalStdGoals in
                            
                            if numberCompleted == totalStdGoals {
                                print("GoalsVC -- userWasFound == FALSE -- PRONTO")
                                //print("userWasFound == FALSE, number completed = \(numberCompleted)")
                                //print("userWasFound == FALSE, totalStdGoals = \(totalStdGoals)")
                                
                                self.goalsCollectionView.reloadData()
                                
                                DAO.CST_GOALS_REF.removeAllObservers()
                                DAO.CST_GOALS_REF.child(userID).removeAllObservers()
                                DAO.STD_GOALS_REF.removeAllObservers()
                            }
                                
                            else {
                                print("GoalsVC -- userWasFound == FALSE -- LOADING")
                                //print("userWasFound == FALSE, number completed = \(numberCompleted)")
                                //print("userWasFound == FALSE, totalStdGoals = \(totalStdGoals)")
                            }
                        }
                    }
                }
            }
            GoalsVCShouldReload = false
            print("GoalsVC -- CHEGUEI NO FIM? -- GoalsVCShouldReload = \(GoalsVCShouldReload)")
        }
    }
    
    // MARK: Handlers for Asynchronous Stuff
    
    // checa se o usuário corrente possui algum custom goal criado
    func handleAsynchronousRequestForCstGoalsFromThisUserAtGoalsVC (completionHandlerUsers: @escaping (_ numberCompleted: Int, _ totalUsersWithCstGoals: Int, _ userWasFound: Bool) -> Void) {
        var numberCompleted = 0
        var totalUsersWithCstGoals = -10
        var userWasFound = false
        
        let uid = userID
        print("uid: \(uid)")
        
        let handleCST_CHECK = DAO.CST_GOALS_REF.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.key == "numberOfKeys" {
                print("GoalsVC -- PROCURANDO SABER -- to no numberOfKeys-USERS WITH CST GOALS")
                
                totalUsersWithCstGoals = snapshot.value as! Int
                print("GoalsVC -- PROCURANDO SABER -- totalUsersWithCstGoals = \(totalUsersWithCstGoals)")
                
                completionHandlerUsers(numberCompleted, totalUsersWithCstGoals, userWasFound)
            }
            else {
                if snapshot.key == uid { // usuário encontrado na lista = usuário possui algum custom goal criado
                    userWasFound = true
                    completionHandlerUsers(numberCompleted, totalUsersWithCstGoals, userWasFound)
                }
                
                numberCompleted += 1
                completionHandlerUsers(numberCompleted, totalUsersWithCstGoals, userWasFound)
            }
        })
        
        //DAO.CST_GOALS_REF.removeObserver(withHandle: handleCST_CHECK)
    }

    
    // função que pega todos os std goals + os custom goals do usuário
    func handleAsynchronousRequestForEveryStdGoalAndCstGoal (completionHandlerGoals: @escaping (_ numberCompleted: Int, _ totalCstGoalsThisUser: Int, _ totalStdGoals: Int) -> Void) {
        
        var numberCompleted = 0
        var totalCstGoalsThisUser = -10
        var totalStdGoals = -10

        
        // pega os custom goals do banco e os armazena no array goals
        let uid = userID
        print("uid: \(uid)")
        
        let handleCST = DAO.CST_GOALS_REF.child(uid).observe(.childAdded, with: { (snapshot) in
            
            if snapshot.key == "numberOfKeys" {
                print("GoalsVC -- CST_GOALS+STD_GOALS -- to no numberOfKeys-CST")
                
                totalCstGoalsThisUser = snapshot.value as! Int
                print("GoalsVC -- CST_GOALS+STD_GOALS -- totalCstGoalsThisUser = \(totalCstGoalsThisUser)")
                
                completionHandlerGoals(numberCompleted, totalCstGoalsThisUser, totalStdGoals)
            }
            else {
                self.goals.append(Goal(key: snapshot.key, isCustom: true, snapshot: snapshot.value as! Dictionary<String, AnyObject>))
                
                numberCompleted += 1
                completionHandlerGoals(numberCompleted, totalCstGoalsThisUser, totalStdGoals)
            }
        })
        
        // pega os std goals do banco e os armazena no array goals
        let handleSTD = DAO.STD_GOALS_REF.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.key == "numberOfKeys" {
                print("GoalsVC -- CST_GOALS+STD_GOALS -- to no numberOfKeys-STD")
                
                totalStdGoals = snapshot.value as! Int
                
                print("GoalsVC -- CST_GOALS+STD_GOALS -- totalStdGoals = \(totalStdGoals)")
                
                completionHandlerGoals(numberCompleted, totalCstGoalsThisUser, totalStdGoals)
            }
            else {
                self.goals.append(Goal(key: snapshot.key, isCustom: false, snapshot: snapshot.value as! Dictionary<String, AnyObject>))
                
                numberCompleted += 1
                completionHandlerGoals(numberCompleted, totalCstGoalsThisUser, totalStdGoals)
            }
        })
        
//        DAO.CST_GOALS_REF.child(uid).removeObserver(withHandle: handleCST)
//        DAO.STD_GOALS_REF.removeObserver(withHandle: handleSTD)
    }
    
    // função que pega apenas os std goals
    func handleAsynchronousRequestForEveryStdGoal (completionHandlerGoals: @escaping (_ numberCompleted: Int, _ totalStdGoals: Int) -> Void) {
        
        var numberCompleted = 0
        var totalStdGoals = -10
        
        // pega os std goals do banco e os armazena no array goals
        let handleSTD = DAO.STD_GOALS_REF.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.key == "numberOfKeys" {
                print("GoalsVC -- STD_GOALS -- to no numberOfKeys-STD")
                
                totalStdGoals = snapshot.value as! Int
                
                print("GoalsVC -- STD_GOALS -- totalStdGoals = \(totalStdGoals)")
                
                completionHandlerGoals(numberCompleted, totalStdGoals)
            }
            else {
                self.goals.append(Goal(key: snapshot.key, isCustom: false, snapshot: snapshot.value as! Dictionary<String, AnyObject>))
                
                numberCompleted += 1
                completionHandlerGoals(numberCompleted, totalStdGoals)
            }
        })
        
        // DAO.STD_GOALS_REF.removeObserver(withHandle: handleSTD)
    }
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToConfigFromGoals" {
            
            let svc = segue.destination as! ConfigViewController
            // customization:
            svc.modalTransition.edge = .right
            svc.modalTransition.radiusFactor = 0.3
        }
        
        if segue.identifier == "goToGoalEditingFromGoals" {
            let cell = sender as! GoalCollectionViewCell
            let indexPath = goalsCollectionView?.indexPath(for: cell)
            let goal = goals[(indexPath! as NSIndexPath).item]
            let goalEditingVC = segue.destination as! GoalEditingViewController
            
            goalEditingVC.placeholderStr = goal.name
        }
        
        if segue.identifier == "goToCurrentStep" {
            
            let cell = sender as! GoalCollectionViewCell
            let indexPath = goalsCollectionView?.indexPath(for: cell)
            let goal = goals[(indexPath! as NSIndexPath).item]
            let currentStepVC = segue.destination as! CurrentStepViewController
            
            currentStepVC.goal = goal.name
            currentStepVC.step = goal.firstStep.name
            currentStepVC.goalKey = goal.key
            currentStepVC.goalIsCustom = goal.isCustom!
            
            print("GOALSVC -- goal.isCustom = \(goal.isCustom!)")
            
            // seta o step atual do usuário como 1 -- saber se view inicial é a de goals ou a de currentStep
            var handle : AuthStateDidChangeListenerHandle
            
            handle = (Auth.auth().addStateDidChangeListener { auth, user in
                if let user = user {
                    // User is signed in.
                    let uid = user.uid;
                    
                    DAO.USERS_REF.child(uid).observe(.childAdded, with: { (snapshot) in
                        
                        if snapshot.key == "goalIsCustom" {
                            if goal.isCustom == true {
                                let childUpdates = [snapshot.key: true]
                                DAO.USERS_REF.child(uid).updateChildValues(childUpdates)
                            }
                        }
                        
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
