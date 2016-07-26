import UIKit
import Firebase
import FirebaseAuth

class GoalsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var goalsCollectionView: UICollectionView!
    var goals = [Goal]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("LOAD")
        
        goalLabel.text! = goal
        stepLabel.text! = step
        stepIndexLabel.text! = stepIndex
        
        // bota todos os steps referentes ao goal atual num array de steps, pra gente nao ficar perdendo tempo procurando esse treco no banco toda hora
        var handle : FIRAuthStateDidChangeListenerHandle
        
        handle = (FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                // User is signed in.
                let uid = user.uid;
                
                DAO.USERS_REF.observeEventType(.ChildAdded, withBlock: { (snapshotUser) in
                    if snapshotUser.key == uid {
                        //let userDict = snapshotUser.value as! NSDictionary
                        
                        self.stepIndexLabel.text! = snapshotUser.value!["currentStepNumber"] as! String
                        self.stepIndex = snapshotUser.value!["currentStepNumber"] as! String
                        self.goalKey = snapshotUser.value!["currentGoalKey"] as! String
                        
                        if let safeGoalKey = snapshotUser.value!["currentGoalKey"] {
                            // pega o nome do goal atual e bota na label
                            DAO.STD_GOALS_REF.child(String(safeGoalKey)).observeEventType(.ChildAdded, withBlock: { (snapshotGoal) in
                                
                                if snapshotGoal.key == "name" {
                                    self.goal = String(snapshotGoal.value!)
                                    self.goalLabel.text! = String(snapshotGoal.value!)
                                    
                                    DAO.STD_STEPS_REF.child(String(safeGoalKey)).observeEventType(.ChildAdded, withBlock: { (snapshotSteps) in
                                        
                                        self.steps.append(Step(index: snapshotSteps.key, snapshot: snapshotSteps.value as! Dictionary<String, AnyObject>))
                                        
                                        //print(self.steps.last!.name)
                                        
                                        if snapshotSteps.key == self.stepIndex {
                                            self.stepLabel.text! = snapshotSteps.value!["name"] as! String
                                            self.step = snapshotSteps.value!["name"] as! String
                                        }
                                    })
                                }
                            })
                        }
                    }
                })
            }
            })!
        
        FIRAuth.auth()?.removeAuthStateDidChangeListener(handle)
    }
    
    override func viewDidAppear(animated: Bool) {
        print("APPEAR")
        
        // MOSTRA A TELA DE LOGIN, CASO O USUARIO NAO ESTEJA LOGADO
        if FIRAuth.auth()?.currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("LoginVC")
            self.presentViewController(vc, animated: false, completion: nil)
        }
        
        goalLabel.text! = goal
        stepLabel.text! = step
        stepIndexLabel.text! = stepIndex
        
        var handle : FIRAuthStateDidChangeListenerHandle
        
        handle = (FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                // User is signed in.
                let uid = user.uid;
                
                DAO.USERS_REF.observeEventType(.ChildAdded, withBlock: { (snapshotUser) in
                    if snapshotUser.key == uid {
                        let userDict = snapshotUser.value as! NSDictionary
                        print(userDict)
                        print(snapshotUser.key)
                        
                        self.stepIndexLabel.text! = snapshotUser.value!["currentStepNumber"] as! String
                        self.stepIndex = snapshotUser.value!["currentStepNumber"] as! String
                        self.goalKey = snapshotUser.value!["currentGoalKey"] as! String
                        
                        // pega o nome do goal atual e bota na label
                        DAO.STD_GOALS_REF.child(self.goalKey).observeEventType(.ChildAdded, withBlock: { (snapshotGoal) in
                            
                            if snapshotGoal.key == "name" {
                                self.goal = String(snapshotGoal.value!)
                                self.goalLabel.text! = String(snapshotGoal.value!)
                                
                                DAO.STD_STEPS_REF.child(self.goalKey).observeEventType(.ChildAdded, withBlock: { (snapshotSteps) in
                                    
                                    self.steps.append(Step(index: snapshotSteps.key, snapshot: snapshotSteps.value as! Dictionary<String, AnyObject>))
                                    
                                    if snapshotSteps.key == self.stepIndex {
                                        self.stepLabel.text! = snapshotSteps.value!["name"] as! String
                                    }
                                })
                            }
                        })
                    }
                })
            }
            })!
        
        FIRAuth.auth()?.removeAuthStateDidChangeListener(handle)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("IOIOIOI")
        if segue.identifier == "goToGoals" {
            print("ENTREY")
            
            // seta o step atual do usuário como 0 -- saber se view inicial é a de goals ou a de currentStep
            var handle : FIRAuthStateDidChangeListenerHandle
            
            handle = (FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
                if let user = user {
                    // User is signed in.
                    let uid = user.uid;
                    
                    DAO.USERS_REF.child(uid).observeEventType(.ChildAdded, withBlock: { (snapshot) in
                        
                        if snapshot.key == "currentStepNumber" {
                            let childUpdates = [snapshot.key: "0"]
                            DAO.USERS_REF.child(uid).updateChildValues(childUpdates)
                        }
                        
                        if snapshot.key == "currentGoalKey" {
                            let childUpdates = [snapshot.key: ""]
                            DAO.USERS_REF.child(uid).updateChildValues(childUpdates)
                        }
                    })
                }
                })!
            
            FIRAuth.auth()?.removeAuthStateDidChangeListener(handle)
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func doneWasTapped(sender: AnyObject) {
        
        let alertView = UIAlertController(title: "UAU!",
                                          message: "você se sente totalmente confortável com o passo atual?" as String, preferredStyle:.ActionSheet)
        let okAction = UIAlertAction(title: "sim, bora próximo passo", style: .Default) { UIAlertAction in
            var handle : FIRAuthStateDidChangeListenerHandle
            
            handle = (FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
                if let user = user {
                    // User is signed in.
                    let uid = user.uid;
                    
                    DAO.USERS_REF.child(uid).observeEventType(.ChildAdded, withBlock: { (snapshot) in
                        
                        if snapshot.key == "currentStepNumber" {
                            
                            let updateStepString = snapshot.value as! String
                            var updateStepInt = Int(updateStepString)
                            
                            // se estivermos no ultimo passo, segue de volta pra tela de goals
                            if (self.steps[updateStepInt! - 1].isLastStep == true) {
                                self.performSegueWithIdentifier("goToGoals", sender: self)
                            }
                            else {
                                updateStepInt = updateStepInt! + 1
                                
                                self.stepIndex = String(updateStepInt!)
                                self.step = self.steps[Int(self.stepIndex)! - 1].name
                                
                                let childUpdates = [snapshot.key: String(updateStepInt!)]
                                DAO.USERS_REF.child(uid).updateChildValues(childUpdates)
                                
                                self.viewDidAppear(false)
                            }
                        }
                        
                    })
                }
                })!
            
            FIRAuth.auth()?.removeAuthStateDidChangeListener(handle)
        }
        let cancelAction = UIAlertAction(title: "pensando bem, não", style: .Cancel, handler: nil)
        alertView.addAction(okAction)
        alertView.addAction(cancelAction)
        self.presentViewController(alertView, animated: true, completion: nil)
    }
    
}