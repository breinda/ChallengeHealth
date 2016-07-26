import UIKit
import Firebase
import FirebaseAuth

class GoalsViewController: UIViewController {

    @IBOutlet weak var goalsCollectionView: UICollectionView!

    var goals = [Goal]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // pega os goals do banco e os armazena no array goals
        DAO.STD_GOALS_REF.observeEventType(.ChildAdded, withBlock: { (snapshot) in
            
            self.goals.append(Goal(key: snapshot.key, snapshot: snapshot.value as! Dictionary<String, AnyObject>))
            
            self.goalsCollectionView.reloadData()
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        // MOSTRA A TELA DE LOGIN, CASO O USUARIO NAO ESTEJA LOGADO
        if FIRAuth.auth()?.currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("LoginVC")
            self.presentViewController(vc, animated: false, completion: nil)
        }
        
        goalsCollectionView.backgroundColor = UIColor.clearColor()
        goalsCollectionView.reloadData()
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "goToCurrentStep" {
            
            let cell = sender as! GoalCollectionViewCell
            let indexPath = goalsCollectionView?.indexPathForCell(cell)
            let goal = goals[indexPath!.item]
            let currentStepVC = segue.destinationViewController as! CurrentStepViewController
            
            currentStepVC.goal = goal.name
            currentStepVC.step = goal.firstStep.name
            currentStepVC.goalKey = goal.key
            
            // seta o step atual do usuário como 1 -- saber se view inicial é a de goals ou a de currentStep
            var handle : FIRAuthStateDidChangeListenerHandle
            
            handle = (FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
                if let user = user {
                    // User is signed in.
                    let uid = user.uid;
                    
                    DAO.USERS_REF.child(uid).observeEventType(.ChildAdded, withBlock: { (snapshot) in
                        
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
            })!
            
            FIRAuth.auth()?.removeAuthStateDidChangeListener(handle)
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

}

