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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        splitViewController.delegate = self
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        
        
        let authenticationController = AuthenticationController(client: VimeoClient.defaultClient)
        let loadedAccount: VIMAccount?
        do
        {
            loadedAccount = try authenticationController.loadSavedAccount()
        }
        catch let error
        {
            loadedAccount = nil
            print("error loading account \(error)")
        }
        
        if loadedAccount == nil
        {
            authenticationController.clientCredentialsGrant { result in
                
                switch result
                {
                case .Success(let account):
                    print("authenticated successfully: \(account)")
                case .Failure(let error):
                    print("failure authenticating: \(error)")
                    
                    let title = "Client Credentials Authentication Failed"
                    let message = "Make sure that your client identifier and client secret are set correctly in VimeoClient+Shared.swift"
                    
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                    splitViewController.presentViewController(alert, animated: true, completion: nil)
                    print(title + ": " + message)
                }
            }
        }
        
        return true
    }
    
    // MARK: - URLs
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool
    {
        AuthenticationController(client: VimeoClient.defaultClient).codeGrant(responseURL: url) { result in
            
            switch result
            {
            case .Success(let account):
                print("authenticated successfully: \(account)")
            case .Failure(let error):
                print("failure authenticating: \(error)")
                
                let title = "Code Grant Authentication Failed"
                let message = "Make sure that your redirect URI is added to the dev portal"
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(action)
                self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
                print(title + ": " + message)
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
}

