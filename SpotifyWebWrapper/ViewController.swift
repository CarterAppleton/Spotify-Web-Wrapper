//
//  ViewController.swift
//  SpotifyWebWrapper
//
//  Created by Carter Appleton on 3/17/15.
//  Copyright (c) 2015 Carter Appleton. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let SPOTIFY_CLIENT_KEY = ""
    let SPOTIFY_REDIRECT_URI = ""
    
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func signIn(sender: AnyObject) {
        
        // Customize the Spotify Login top bar
        SpotifyLogin.shared.backButton.setTitle("Back", forState: .Normal)
        
        // Sign in
        SpotifyLogin.shared.loginWithClientKey(
            SPOTIFY_CLIENT_KEY,
            redirectURI: SPOTIFY_REDIRECT_URI,
            permissions: [.UserLibraryRead]) {
                (success: Bool,error: NSError?) in
                if success { // On successful sign in
                    
                    // Get the current user's info
                    Spotify.shared.userInfo({ (user: SpotifyUser?, error: NSError?) -> Void in
                        if let user = user {
                            
                            // Update the user's name in the GUI
                            if let userName = user.displayName {
                                self.userNameLabel.text = user.displayName
                            }
                            
                            // Load the user's image in the GUI
                            if let userImage = user.images?.first {
                                if let userImageURLString = userImage.url {
                                    var url = NSURL(string: userImageURLString)!
                                    var image = UIImage(data: NSData(contentsOfURL: url)!)
                                    self.userImageView.image = image
                                }
                            }
                            
                        } else { // Some error occurred
                            
                        }
                    })
                    
                } else { // Unsuccessful login
                    NSLog("Login Failed: \(error)")
                }
        }
        
    }

}

