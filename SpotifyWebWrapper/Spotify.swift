//
//  Spotify.swift
//  GetRadioNow
//
//  Created by Carter Appleton on 3/10/15.
//  Copyright (c) 2015 Carter Appleton. All rights reserved.
//

import UIKit

/// Permissions for Spotify
enum SpotifyPermission: String {
    
    // Reading and changing playlists permissions
    //
    
    // Read access to user's private playlists.
    case PlaylistReadPrivate = "playlist-read-private"
    
    // Write access to a user's public playlists.
    case PlaylistModifyPrivate = "playlist-modify-private"
    
    // Write access to a user's private playlists.
    case PlaylistModifyPublic = "playlist-modify-public"
    
    // Streaming music permission
    //
    
    case Stream = "streaming"
    
    // User following / follower permissions
    //
    
    case UserFollowModify = "user-follow-modify"
    case UserFollowRead = "user-follow-read"
    case UserLibraryRead = "user-library-read"
    case UserLibraryModify = "user-library-modify"
    
    // Personal user permissions
    //
    
    // Read access to user’s subscription details (type of user account).
    case UserReadPrivate = "user-read-private"
    
    // Read access to the user's birthdate.
    case UserReadBirthday = "user-read-birthdate"
    
    // Read access to user’s email address.
    case UserReadEmailAddress = "user-read-email"


}

/// Struct to hold Spotify album art
struct SpotifyImage : JSONJoy {
    var height: Int?
    var width: Int?
    var url: String?
    
    init() {
        // Let's never call this ya
    }
    
    init(_ decoder: JSONDecoder) {
        self.height = decoder["height"].integer
        self.width  = decoder["width"].integer
        self.url    = decoder["url"].string
    }
}

/// Struct to hold Spotify user information
struct SpotifyUser : JSONJoy {
    var country: String?
    var displayName: String?
    var email: String?
    var id: String?
    var product: String?
    var images: [SpotifyImage]?
    
    init() {
        // Let's never call this ya
    }
    
    init(_ decoder: JSONDecoder) {
        self.country        = decoder["country"].string
        self.displayName    = decoder["display_name"].string
        self.email          = decoder["email"].string
        self.id             = decoder["id"].string
        self.product        = decoder["product"].string
        if let artArray = decoder["images"].array {
            self.images = [SpotifyImage]()
            for artDecoder in artArray {
                self.images!.append(SpotifyImage(artDecoder))
            }
        }
    }
}

/// Struct to hold Spotify artist information
struct SpotifyArtist : JSONJoy {
    var id: String?
    var name: String?
    var uri: String?
    
    init() {
        // Let's never call this ya
    }
    
    init(_ decoder: JSONDecoder) {
        self.id     = decoder["id"].string
        self.name   = decoder["name"].string
        self.uri    = decoder["uri"].string
    }
}

/// Struct to hold Spotify album information
struct SpotifyAlbum : JSONJoy {
    var id: String?
    var name: String?
    var images: [SpotifyImage]?
    var uri: String?

    init() {
        // Let's never call this ya
    }
    
    init(_ decoder: JSONDecoder) {
        self.id     = decoder["id"].string
        self.name   = decoder["name"].string
        self.uri    = decoder["uri"].string
        if let artArray = decoder["images"].array {
            self.images = [SpotifyImage]()
            for artDecoder in artArray {
                self.images!.append(SpotifyImage(artDecoder))
            }
        }
    }
}

/// Struct to hold Spotify track information
struct SpotifyTrack : JSONJoy {
    var id: String?
    var artists: [SpotifyArtist]?
    var name: String?
    var previewUrl: String?
    var album: SpotifyAlbum?
    var uri: String?

    init() {
        // Let's never call this ya
    }
    
    init(_ decoder: JSONDecoder) {
        self.id     = decoder["id"].string
        self.name   = decoder["name"].string
        self.previewUrl   = decoder["preview_url"].string
        self.uri   = decoder["uri"].string
        self.album = SpotifyAlbum(decoder["album"])
        if let artistArray = decoder["artists"].array  {
            self.artists = [SpotifyArtist]()
            for artistDecoder in artistArray {
                self.artists!.append(SpotifyArtist(artistDecoder))
            }
        }

    }
}

/// Struct to hold Spotify playlist information
struct SpotifyPlaylist : JSONJoy  {
    
    var id: String?
    var uri: String?
    var name: String?
    
    init() {
        // Let's never call this ya
    }
    
    init(_ decoder: JSONDecoder) {
        self.id     = decoder["id"].string
        self.uri    = decoder["uri"].string
        self.name   = decoder["name"].string
    }
    
}

/// Callback for login
typealias SpotifyLoginCallback = ((Bool,NSError?) -> Void)

/// URL for the current user's information
let SPOTIFY_USER_ME_URL = "https://api.spotify.com/v1/me"

/// URL to request information for multiple tracks
let SPOTIFY_TRACKS_URL = "https://api.spotify.com/v1/tracks"

/// Prefix for Authorization header token
let SPOTIFY_ACCESS_TOKEN_PREFIX = "Bearer "

/// Main Spotify class
class Spotify : NSObject, UIWebViewDelegate {
    
    // Callback on login result
    private var loginCallback: SpotifyLoginCallback?
    
    // Access token for Spotify
    private var accessToken: String?
    
    // The current signed in user
    private(set) var user: SpotifyUser?
    
    // Only use DataManager.sharedManager so everything is kept in sync
    class var shared : Spotify {
        struct Static {
            static let instance : Spotify = Spotify()
        }
        return Static.instance
    }
    
    /**
    Request information on the current Spotify user
    
    :param: callback Callback for when we retrieve the info or fail
    */
    func userInfo(callback: ((SpotifyUser?,NSError?) -> Void)?) {
        
        
        if let user = self.user {
            if let callback = callback {
                callback(self.user,nil)
            }
            return
        }
        
        var request = HTTPTask()
        request.requestSerializer = HTTPRequestSerializer()
        request.requestSerializer.headers["Authorization"] = SPOTIFY_ACCESS_TOKEN_PREFIX + self.accessToken!
        request.GET(SPOTIFY_USER_ME_URL, parameters: nil,
            success: { (response: HTTPResponse) -> Void in
                if let data = response.responseObject as? NSData {
                    let decoder = JSONDecoder(data)
                    self.user = SpotifyUser(decoder)
                    if let callback = callback {
                        callback(self.user,nil)
                    }
                }
                
            }, failure: { (error: NSError, response: HTTPResponse?) -> Void in
                if let callback = callback {
                    callback(self.user,error)
                }
        })
    }
    
    /// Get tracks for the given ids (max 100)
    func tracksForIDs(ids: [String], callback: (([SpotifyTrack]?,NSError?) -> Void)?) {
        var request = HTTPTask()
        request.GET(SPOTIFY_TRACKS_URL, parameters: ["ids" : ",".join(ids)],
            success: { (response: HTTPResponse) -> Void in
                if let data = response.responseObject as? NSData {
                    var tracks = [SpotifyTrack]()
                    let decoder = JSONDecoder(data)
                    if let array = decoder["tracks"].array {
                        for trackDecoder in array {
                            tracks.append(SpotifyTrack(trackDecoder))
                        }
                    }
                    if let callback = callback {
                        callback(tracks,nil)
                    }
                }
                
            }, failure: { (error: NSError, response: HTTPResponse?) -> Void in
                if let callback = callback {
                    callback(nil,error)
                }
        })
    }
    
    func playlistsForUser(user: SpotifyUser, callback: (([SpotifyPlaylist]?,NSError?) -> Void)?) {
        
        var request = HTTPTask()
        request.requestSerializer = JSONRequestSerializer()
        request.requestSerializer.headers["Authorization"] = "Bearer " + self.accessToken!
        request.GET("https://api.spotify.com/v1/users/\(self.user!.id!)/playlists", parameters: ["limit" : 50, "offset" : 0],
            success: { (response: HTTPResponse) -> Void in
                if let data = response.responseObject as? NSData {
                    let decoder = JSONDecoder(data)
                    var playlists = [SpotifyPlaylist]()
                    if let items = decoder["items"].array {
                        for playlistDecoder in items {
                            let playlist = SpotifyPlaylist(playlistDecoder)
                            playlists.append(playlist)
                        }
                    }
                    
                    if let callback = callback {
                        callback(playlists,nil)
                    }
                }
                
            }, failure: { (error: NSError, response: HTTPResponse?) -> Void in
                if let callback = callback {
                    callback(nil,error)
                }
        })
    }
    
    func createPlaylist(name: String, isPublic: Bool, callback: ((SpotifyPlaylist?,NSError?) -> Void)?) {
        
        if self.user == nil {
            if let callback = callback {
                callback(nil,NSError(domain: "No user signed in", code: 0, userInfo: nil))
            }
            return
        }
        
        var request = HTTPTask()
        request.requestSerializer = JSONRequestSerializer()
        request.requestSerializer.headers["Authorization"] = "Bearer " + self.accessToken!
        request.requestSerializer.headers["Content-Type"] = "application/json"
        request.POST("https://api.spotify.com/v1/users/\(self.user!.id!)/playlists", parameters: ["name" : name, "public" : isPublic ? "true" : "false"],
            success: { (response: HTTPResponse) -> Void in
                if let data = response.responseObject as? NSData {
                    let decoder = JSONDecoder(data)
                    let playlist = SpotifyPlaylist(decoder)
                    if let callback = callback {
                        callback(playlist,nil)
                    }
                }
                
            }, failure: { (error: NSError, response: HTTPResponse?) -> Void in
                if let response = response {
                    if let data = response.responseObject as? NSData {
                        if let str = NSString(data: data, encoding: NSUTF8StringEncoding) {
                            NSLog("\(str)")
                        }
                    }
                }

                NSLog("failure to create playlist")
                if let callback = callback {
                    callback(nil,error)
                }
        })
    }
    
    func addTracks(tracks: [SpotifyTrack], toPlayList playlist: SpotifyPlaylist, callback: ((Bool,NSError?) -> Void)?) {
        // TODO:
    }
    
    func replaceTracks(tracks: [SpotifyTrack], inPlayList playlist: SpotifyPlaylist, callback: ((Bool,NSError?) -> Void)?) {
        
        
        if self.user == nil {
            if let callback = callback {
                callback(false,NSError(domain: "No user signed in", code: 0, userInfo: nil))
            }
            return
        }
        
        var request = HTTPTask()
        request.requestSerializer = JSONRequestSerializer()
        request.requestSerializer.headers["Authorization"] = "Bearer " + self.accessToken!
        request.requestSerializer.headers["Content-Type"] = "application/json"
        //NSLog("%@",",".join(tracks.map({"spotify:track:\($0.id!)"})))
        var trackStrings = tracks.map({"spotify:track:\($0.id!)"})
        request.PUT("https://api.spotify.com/v1/users/\(self.user!.id!)/playlists/\(playlist.id!)/tracks", parameters: ["uris" : trackStrings],
            success: { (response: HTTPResponse) -> Void in
                if let callback = callback {
                    callback(true,nil)
                }
            }, failure: { (error: NSError, response: HTTPResponse?) -> Void in
                if let response = response {
                    if let data = response.responseObject as? NSData {
                        if let str = NSString(data: data, encoding: NSUTF8StringEncoding) {
                            NSLog("\(str)")
                        }
                    }
                }
                
                NSLog("failure to create playlist %@",error)
                if let callback = callback {
                    callback(false,error)
                }
        })
        
    }
    
    /**

    */
    func handleURL(url: NSURL) {
        
        // Get the url in a good format
        var urlString: NSMutableString = NSMutableString(string: url.absoluteString!)
        urlString.replaceOccurrencesOfString("#", withString: "?", options: nil, range: NSMakeRange(0,urlString.length))
        
        var urlComponents = NSURLComponents(URL: NSURL(string: urlString)!, resolvingAgainstBaseURL: false)
        
        if let urlComponents = urlComponents {
            if let queryItems = urlComponents.queryItems {
                var code: String?
                var error: String?
                for queryItem in queryItems {
                    switch queryItem.name {
                    case "access_token":
                        self.accessToken = queryItem.value
                        if let loginCallback = self.loginCallback {
                            loginCallback(true,nil)
                        }
                    case "error":
                        error = queryItem.value
                        if let loginCallback = self.loginCallback {
                            loginCallback(false,nil)
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
}

class SpotifyLogin : NSObject, UIWebViewDelegate {
    
    private class SpotifyLoginView : UIView {
        var webView: UIWebView!
        var titleLabel: UILabel!
        var backButton: UIButton!
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.webView = UIWebView(frame: CGRect(x: 0, y: 60.0, width: CGRectGetWidth(UIScreen.mainScreen().bounds), height: CGRectGetHeight(UIScreen.mainScreen().bounds) - 60.0))
            
            var topBar = UIView(frame: CGRect(x: 0, y: 0, width: CGRectGetWidth(UIScreen.mainScreen().bounds), height: 60.0))
            topBar.backgroundColor = UIColor.blackColor()
            
            self.backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60.0, height: 60.0))
            self.backButton.backgroundColor = UIColor.blackColor()
            self.backButton.setImage(UIImage(named: "Back.png"), forState: .Normal)
            topBar.addSubview(self.backButton)
            
            self.titleLabel = UILabel(frame: CGRect(x: 60.0, y: 0.0, width: CGRectGetWidth(UIScreen.mainScreen().bounds) - 120.0, height: 60.0))
            self.titleLabel.text = "Sign In"
            self.titleLabel.font = UIFont(name: "Avenir-Black", size: 20.0)
            self.titleLabel.textColor = UIColor.whiteColor()
            self.titleLabel.textAlignment = .Center
            topBar.addSubview(self.titleLabel)
            
            self.addSubview(self.webView)
            self.addSubview(topBar)
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private override func layoutSubviews() {
            super.layoutSubviews()
        }
    }
    
    private var window: UIWindow!
    private var spotifyRedirectURI: String!
    private var signInPopup: SpotifyLoginView!
    private var signInView: UIView!
    private var backgroundImageView: UIImageView!
    private(set) var titleLabel: UILabel!
    private(set) var backButton: UIButton!

    // Only use SpotifyLogin.shared so everything is kept in sync
    class var shared : SpotifyLogin {
        struct Static {
            static let instance : SpotifyLogin = SpotifyLogin()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        
        self.signInPopup = SpotifyLoginView(frame: CGRectOffset(UIScreen.mainScreen().bounds, 0.0, CGRectGetHeight(UIScreen.mainScreen().bounds)))
        self.signInPopup.webView.delegate = self
        
        self.signInPopup.backButton.addTarget(self, action: "webViewBack", forControlEvents: .TouchUpInside)
        
        self.backgroundImageView = UIImageView(frame: UIScreen.mainScreen().bounds)
        
        self.titleLabel = self.signInPopup.titleLabel
        self.backButton = self.signInPopup.backButton
        
        self.signInView = UIView(frame: UIScreen.mainScreen().bounds)
        self.signInView.addSubview(self.backgroundImageView)
        self.signInView.addSubview(self.signInPopup)
        
        var viewController = UIViewController()
        viewController.view = self.signInView
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window.rootViewController = viewController
        self.window.windowLevel = UIWindowLevelStatusBar
        self.window.hidden = true
    }
    
    func loginWithClientKey(clientKey: String, redirectURI: String, permissions: [SpotifyPermission], callback: SpotifyLoginCallback?) {
        
        self.spotifyRedirectURI = redirectURI
        
        // Create the request properly
        var authorizeRequest = "https://accounts.spotify.com/authorize/?client_id=\(clientKey)&response_type=token&redirect_uri=\(redirectURI)://&state=34fFs29kd09&scope="
        for permission in permissions {
            authorizeRequest += permission.rawValue
            if permission != permissions.last! {
                authorizeRequest += "%20"
            }
        }
        
        // Remember the callback
        Spotify.shared.loginCallback = callback
        
        // Grab an image of the screen
        UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen().bounds.size, false, 0.0);
        var ctx = UIGraphicsGetCurrentContext()
        UIApplication.sharedApplication().keyWindow!.layer.renderInContext(ctx)
        var backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Set it as our background
        self.backgroundImageView.image = backgroundImage
        
        // Initiate the request and show that we're working
        var request = NSURLRequest(URL: NSURL(string: authorizeRequest)!)
        self.signInPopup.webView.loadRequest(request)
        MBProgressHUD.showHUDAddedTo(self.signInView, animated: true)
        
        // Make sure the window is hidden
        self.window.hidden = false
    }
    
    func webViewBack() {
        if self.signInPopup.webView.canGoBack {
            self.signInPopup.webView.goBack()
        } else {
            self.closeSignInView(nil)
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        MBProgressHUD.hideHUDForView(self.signInView, animated: true)
        UIView.animateWithDuration(0.5, delay: 0.0, options: nil, animations: { () -> Void in
            self.signInPopup.frame = UIScreen.mainScreen().bounds
            }, completion: nil)
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        var urlComponents = NSURLComponents(URL: request.URL, resolvingAgainstBaseURL: false)
        
        // If we got the callback, close the window and complete login
        if let urlComponents = urlComponents {
            if let scheme = urlComponents.scheme {
                if scheme == self.spotifyRedirectURI.lowercaseString {
                    self.closeSignInView(request)
                }
            }
        }
        
        return true
    }
    
    func closeSignInView(request: NSURLRequest?) {
        UIView.animateWithDuration(0.5, delay: 0.0, options: nil, animations: { () -> Void in
            self.signInPopup.frame = CGRectOffset(UIScreen.mainScreen().bounds, 0, CGRectGetHeight(UIScreen.mainScreen().bounds))
            }, completion: { (finished: Bool) -> Void in
                if let request = request {
                    Spotify.shared.handleURL(request.URL)
                }
                self.window.hidden = true
        })
    }
    
}