//
//  AssignFriendsViewController.swift
//  FriendlyReminder
//
//  Created by Jonathan Chou on 4/12/16.
//  Copyright © 2016 Jonathan Chou. All rights reserved.
//

import UIKit
import Firebase

class AssignFriendsViewController: UITableViewController {
    
    var friends = [Friend]()
    var membersRef: FIRDatabaseReference?
    var task: Task!
    var selectedFriends: [Friend] = []
    var counter: Int = 0
    var taskCounterRef: FIRDatabaseReference!
        
    @IBOutlet weak var activityView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initNavBar()
    }
    
    // reloads the tableview data and friends array
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        FacebookClient.sharedInstance().searchForFriendsList(self.membersRef!, controller: self) {
            (friends, error) -> Void in
            self.friends = friends
            self.activityView.hidden = true
            for friend in friends {
                if friend.isMember {
                    self.counter++
                }
            }
            // if no friends found, present an alert
            if self.counter == 0 {
                let alert = UIAlertController(title: "No Friends Found",
                    message: "Add friends to the event first!",
                    preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: "OK",
                    style: .Default) { (action: UIAlertAction) -> Void in
                        self.navigationController?.popViewControllerAnimated(true)
                }
                alert.addAction(cancelAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            self.tableView.reloadData()
        }
    }
    
    func initNavBar() {
        navigationItem.title = "Assign Friends"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Assign", style: .Plain, target: self, action: "assignFriends")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancel")
    }
    
    func cancel() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // assigns friends to the task
    func assignFriends() {
        // use selectedFriends to add to task.incharge
        if selectedFriends.isEmpty {
            let alert = UIAlertController(title: "No Friends Selected",
                message: "Select friends to add!",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                style: .Default) { (action: UIAlertAction) -> Void in
            }
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        for friend in selectedFriends {
            // checks for nil
            // if it's not nil, it appends
            // if it is nil, it initializes the array
            if task.inCharge?.append(friend.name) == nil {
                task.inCharge = [friend.name]
            }

        }
        // increase task counter for selected friends
        taskCounterRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            for friend in self.selectedFriends {
                var taskCounter = snapshot.value![friend.name] as! Int
                self.taskCounterRef.updateChildValues([friend.name: ++taskCounter])
            }
        })

        task.ref?.child("inCharge").setValue(task.inCharge)
        self.navigationController?.popViewControllerAnimated(true)
    }

    
    func configureCell(cell: FriendCell, indexPath: NSIndexPath) {
        let friend = friends[indexPath.row]
        var isAssigned: Bool = false
        
        // only if friend has been added to the event
        if friend.isMember {
            cell.friendName.text = friend.name
            cell.profilePic.image = friend.image
            
            if task.inCharge != nil {
                for name in task.inCharge! {
                    if name == friend.name {
                        isAssigned = true
                        // disable cell if friend has already been added to the task
                        cell.userInteractionEnabled = false
                    }
                }
            }
            for thisFriend in selectedFriends {
                if thisFriend.name == friend.name {
                    isAssigned = true
                }
            }
            toggleCellCheckbox(cell, isAssigned: isAssigned)
        }
    }
    
    
    func toggleCellCheckbox(cell: UITableViewCell, isAssigned: Bool) {
        let orangeColor = UIColor(colorLiteralRed: 0.891592, green: 0.524435, blue: 0.008936, alpha: 1)
        let darkBlueColor = UIColor(colorLiteralRed: 0.146534, green: 0.187324, blue: 0.319267, alpha: 1)
        if !isAssigned {
            cell.accessoryType = UITableViewCellAccessoryType.None
        } else {
            cell.tintColor = orangeColor
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            cell.backgroundColor = darkBlueColor
        }
    }
    
    // MARK: - Table View
    
    // only account for user's friends that are also members of the event
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return counter
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CellIdentifier = "FriendCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as! FriendCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let friend = friends[indexPath.row]
        var delete = false
        // removes friend from selection if user taps again
        for thisFriend in selectedFriends {
            if thisFriend.name == friend.name {
                selectedFriends = selectedFriends.filter{$0.name != friend.name}
                delete = true
            }
        }
        // adds friend into selected friends
        if !delete {
            selectedFriends.append(friend)
        }
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
}

