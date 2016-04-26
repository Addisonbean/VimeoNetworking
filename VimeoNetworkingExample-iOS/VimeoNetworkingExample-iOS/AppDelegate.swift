//
//  AppDelegate.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/17/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import UIKit

import VimeoNetworking

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate
{
    var window: UIWindow?
    
    // TODO: remove these [RH] (3/23/16)
    // TODO: scrub all tokens from the git history before open sourcing [RH] (3/23/16)
    let appConfiguration = AppConfiguration(clientKey: "141b94e08884ff39ef7d76256e4a7e3a03f6e865", clientSecret: "d17b26db6d8b0f27ceda882c6d0ba84b3b2e3a9e", scopes: [.Public, .Private, .Create, .Edit, .Delete, .Interact, .Upload])
    
    var authenticationController: AuthenticationController?
    var client: VimeoClient?
    
    var observationToken: ObservationToken?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        splitViewController.delegate = self
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        if #available(iOS 8.0, *)
        {
            navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        }
        else
        {
            // Fallback on earlier versions
        }
        
        let client = VimeoClient(appConfiguration: self.appConfiguration)
        self.client = client
        
        let authenticationController = AuthenticationController(configuration: self.appConfiguration, client: client)
        self.authenticationController = authenticationController
        
        let loadedAccount: VIMAccountNew?
        do
        {
            loadedAccount = try authenticationController.loadSavedAccount()
        }
        catch let error
        {
            loadedAccount = nil
            print("error loading account \(error)")
        }
        
        if loadedAccount != nil
        {
            self.testEndpoints()
        }
        else
        {
            authenticationController.clientCredentialsGrant { result in
                
                switch result
                {
                case .Success(let account):
                    print("authenticated successfully: \(account)")
                    self.testEndpoints()
                case .Failure(let error):
                    print("failure authenticating: \(error)")
                }
            }
        }
        
        self.observationToken = Notification.AuthenticatedAccountDidChange.observe { notification in
            print("authenticated account changed")
        }
        
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timer), userInfo: nil, repeats: true)
        
        return true
    }
    
    func timer()
    {
        Notification.ClientDidReceiveInvalidTokenError.post(object: nil)
    }

    func applicationWillResignActive(application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // This is to test code grant auth
        if let client = self.client,
            let url = self.authenticationController?.codeGrantAuthorizationURL()
            where !client.isAuthenticated
        {
            application.openURL(url)
        }
    }

    func applicationWillTerminate(application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - URLs
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool
    {
        self.authenticationController?.codeGrant(responseURL: url) { result in
            
            switch result
            {
            case .Success(let account):
                print("authenticated successfully: \(account)")
                self.testEndpoints()
            case .Failure(let error):
                print("failure authenticating: \(error)")
            }
        }
        
        return true
    }

    // MARK: - Split view

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool
    {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.detailItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
    // MARK: - Private
    
    
    private func testEndpoints()
    {
        guard let client = self.client
            else
        {
            fatalError("No client")
        }
        
        let userURI = "/users/10895030"
        
        var request = UserRequest.getUserRequest(userURI: userURI)
//        request.cacheFetchPolicy = .CacheOnly
    
        client.request(request) { result in
            switch result
            {
            case .Success(let response):
                let user = response.model
                print("successfully retrieved user: \(user)")
                print("user bio \(user.bio ?? "🤔")")
            case .Failure(let error):
                print("request error: \(error)")
            }
        }
        
        var followingRequest = UserListRequest.getUserFollowingRequest(userURI: userURI)
//        followingRequest.cacheFetchPolicy = .CacheOnly
        
        client.request(followingRequest) { result in
            switch result
            {
            case .Success(let response):
                let users = response.model
                print("successfully retrieved users: \(users)")
                print("user bio \(users.first?.bio ?? "🤔")")
            case .Failure(let error):
                print("request error: \(error)")
            }
        }
        
        var meRequest = UserRequest.getMeRequest()
//        meRequest.cacheFetchPolicy = .CacheOnly
        
        client.request(meRequest) { result in
            switch result
            {
            case .Success(let response):
                let user = response.model
                print("successfully retrieved me: \(user)")
                print("user name \(user.name ?? "🤔")")
                
                let wlRequest = ToggleRequest.watchLaterRequest(videoURI: "")
                
                client.request(wlRequest) { result in
                    
                    switch result
                    {
                    case .Success(let response):
                        print("watch later response: \(response)")
                    case .Failure(let error):
                        print("watch later error: \(error)")
                    }
                    
                }
                
            case .Failure(let error):
                print("request error: \(error)")
            }
        }
        
    }

}

