//
//  AppDelegate.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/17/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self
        
        // TODO: remove these [RH] (3/23/16)
        // TODO: scrub all tokens from the git history before open sourcing [RH] (3/23/16)
        let authenticationConfiguration = AuthenticationConfiguration(clientKey: "141b94e08884ff39ef7d76256e4a7e3a03f6e865", clientSecret: "d17b26db6d8b0f27ceda882c6d0ba84b3b2e3a9e", scopes: [.Public, .Private])
        
        let sessionManager = VimeoSessionManager(sessionConfiguration: NSURLSessionConfiguration.defaultSessionConfiguration(), authenticationConfiguration: authenticationConfiguration)
        
        let client = VimeoClient(sessionManager: sessionManager)
        
        let authenticationController = AuthenticationController(configuration: authenticationConfiguration, client: client)
        
        authenticationController.clientCredentialsGrant { result in
            switch result
            {
            case .Success(let account):
                print("authenticated successfully: \(account)")
                
                let userURI = "/users/10895030"
                
                let request = UserRequest.user(userURI: userURI)
                
                client.request(request) { result in
                    switch result
                    {
                    case .Success(let user):
                        print("successfully retrieved user: \(user)")
                        print("user bio \(user.bio ?? "🤔")")
                    case .Failure(let error):
                        print("request error: \(error)")
                    }
                }
                
                let followingRequest = UserListRequest.userFollowing(userURI: userURI)
                
                client.request(followingRequest) { (result) in
                    switch result
                    {
                    case .Success(let users):
                        print("successfully retrieved users: \(users)")
                        print("user bio \(users.first?.bio ?? "🤔")")
                    case .Failure(let error):
                        print("request error: \(error)")
                    }
                }
                
            case .Failure(let error):
                print("failure authenticating: \(error)")
            }
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Split view

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.detailItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

}

