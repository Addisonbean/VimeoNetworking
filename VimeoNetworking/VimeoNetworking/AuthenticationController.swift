//
//  AuthenticationController.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/21/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

final public class AuthenticationController
{
    static let ErrorDomain = "AuthenticationControllerErrorDomain"
    
    private static let ResponseTypeKey = "response_type"
    private static let CodeKey = "code"
    private static let ClientIDKey = "client_id"
    private static let RedirectURIKey = "redirect_uri"
    private static let ScopeKey = "scope"
    private static let StateKey = "state"
    
    private static let CodeGrantAuthorizationPath = "oauth/authorize"
    
    private static let PinCodeRequestInterval: NSTimeInterval = 5
    
    public typealias AuthenticationCompletion = ResultCompletion<VIMAccountNew>.T
    
    /// State is tracked for the code grant request/response cycle, to avoid interception
    static let state = NSProcessInfo.processInfo().globallyUniqueString
    
    let configuration: AppConfiguration
    let client: VimeoClient
    
    private let accountStore: AccountStore
    
    /// Set to false to stop the refresh cycle for pin code auth
    private var continuePinCodeAuthorizationRefreshCycle: Bool = true
    
    public init(client: VimeoClient)
    {
        self.configuration = client.configuration
        self.client = client
        self.accountStore = AccountStore(configuration: client.configuration)
    }
    
    public init(configuration: AppConfiguration, client: VimeoClient)
    {
        self.configuration = configuration
        self.client = client
        self.accountStore = AccountStore(configuration: configuration)
    }
    
    // MARK: - Saved Accounts
    
    public func loadSavedAccount() throws -> VIMAccountNew?
    {
        var loadedAccount = try self.accountStore.loadAccount(.User)
        
        if loadedAccount == nil
        {
            loadedAccount = try self.accountStore.loadAccount(.ClientCredentials)
        }
        
        if let loadedAccount = loadedAccount
        {
            try self.authenticateClient(account: loadedAccount)
            
            print("loaded account \(loadedAccount)")
            
            // TODO: refresh user [RH] (4/25/16)
            
            // TODO: after refreshing user, send notification [RH] (4/25/16)
        }
        else
        {
            print("no account loaded")
        }
        
        return loadedAccount
    }
    
    // MARK: - Public Authentication
    
    public func clientCredentialsGrant(completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.clientCredentialsGrantRequest(scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    public var codeGrantRedirectURI: String
    {
        let scheme = "vimeo\(self.configuration.clientKey)"
        let path = "auth"
        let URI = "\(scheme)://\(path)"
        
        return URI
    }
    
    public func codeGrantAuthorizationURL() -> NSURL
    {
        let parameters = [self.dynamicType.ResponseTypeKey: self.dynamicType.CodeKey,
                          self.dynamicType.ClientIDKey: self.configuration.clientKey,
                          self.dynamicType.RedirectURIKey: self.codeGrantRedirectURI,
                          self.dynamicType.ScopeKey: Scope.combine(self.configuration.scopes),
                          self.dynamicType.StateKey: self.dynamicType.state]
        
        guard let urlString = VimeoBaseURLString?.URLByAppendingPathComponent(self.dynamicType.CodeGrantAuthorizationPath).absoluteString
        else
        {
            fatalError("Could not make code grant auth URL")
        }
        
        var error: NSError?
        let urlRequest = VimeoRequestSerializer(appConfiguration: self.configuration).requestWithMethod(VimeoClient.Method.GET.rawValue, URLString: urlString, parameters: parameters, error: &error)
        
        guard let url = urlRequest.URL where error == nil
        else
        {
            fatalError("Could not make code grant auth URL")
        }
        
        return url
    }
    
    public func codeGrant(responseURL responseURL: NSURL, completion: AuthenticationCompletion)
    {
        guard let queryString = responseURL.query,
            let parameters = queryString.parametersFromQueryString(),
            let code = parameters[self.dynamicType.CodeKey],
            let state = parameters[self.dynamicType.StateKey]
        else
        {
            let errorDescription = "Could not retrieve parameters from code grant response"
            
            assertionFailure(errorDescription)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.CodeGrant.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            
            completion(result: .Failure(error: error))
            
            return
        }
        
        if state != self.dynamicType.state
        {
            let errorDescription = "Code grant returned state did not match existing state"
            
            assertionFailure(errorDescription)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.CodeGrantState.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            
            completion(result: .Failure(error: error))
            
            return
        }
        
        let request = AuthenticationRequest.codeGrantRequest(code: code, redirectURI: self.codeGrantRedirectURI)
        
        self.authenticate(request: request, completion: completion)
    }
    
    // MARK: - Private Authentication
    
    public func login(email email: String, password: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.loginRequest(email: email, password: password, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    public func join(name name: String, email: String, password: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.joinRequest(name: name, email: email, password: password, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    public func facebookLogin(facebookToken facebookToken: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.loginFacebookRequest(facebookToken: facebookToken, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    public func facebookJoin(facebookToken facebookToken: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.joinFacebookRequest(facebookToken: facebookToken, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    /// Pin code authentication, for devices like Apple TV.
    public func pinCode(infoHandler infoHandler: (pinCode: String, activateLink: String) -> Void, completion: AuthenticationCompletion)
    {
        weak var weakSelf = self
        func doPinCodeAuthorization(userCode userCode: String, deviceCode: String)
        {
            guard let strongSelf = weakSelf
                else
            {
                return
            }
            
            let authorizationRequest = AuthenticationRequest.authorizePinCodeRequest(userCode: userCode, deviceCode: deviceCode)
            
            strongSelf.authenticate(request: authorizationRequest) { result in
                
                guard let strongSelf = weakSelf
                else
                {
                    return
                }
                
                switch result
                {
                case .Success:
                    completion(result: result)
                    
                case .Failure(let error):
                    if error.statusCode == HTTPStatusCode.BadRequest.rawValue // 400: Bad Request implies the code hasn't been activated yet, so try again.
                    {
                        if strongSelf.continuePinCodeAuthorizationRefreshCycle
                        {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(strongSelf.dynamicType.PinCodeRequestInterval * NSTimeInterval(NSEC_PER_SEC))), dispatch_get_main_queue())
                            {
                                doPinCodeAuthorization(userCode: userCode, deviceCode: deviceCode)
                            }
                        }
                    }
                    else // Any other error is an actual error, and should get reported back.
                    {
                        completion(result: result)
                    }
                }
            }
        }
        
        let infoRequest = PinCodeRequest.getPinCodeRequest(scopes: self.configuration.scopes)
        
        self.client.request(infoRequest) { result in
            switch result
            {
            case .Success(let result):
                
                let info = result.model
                
                guard let userCode = info.userCode, let deviceCode = info.deviceCode, let activateLink = info.activateLink
                else
                {
                    let errorDescription = "Malformed pin code info returned"
                    
                    assertionFailure(errorDescription)
                    
                    let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.PinCodeInfo.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
                    
                    completion(result: .Failure(error: error))
                    
                    return
                }
                
                infoHandler(pinCode: userCode, activateLink: activateLink)
                
                self.continuePinCodeAuthorizationRefreshCycle = true
                doPinCodeAuthorization(userCode: userCode, deviceCode: deviceCode)
                
            case .Failure(let error):
                completion(result: .Failure(error: error))
            }
        }
    }
    
    public func cancelPinCode()
    {
        self.continuePinCodeAuthorizationRefreshCycle = false
    }
    
    // MARK: - Private
    
    private func authenticate(request request: AuthenticationRequest, completion: AuthenticationCompletion)
    {
        self.client.request(request) { result in
            
            let handledResult = self.handleAuthenticationResult(result)
            
            completion(result: handledResult)
        }
    }
    
    private func handleAuthenticationResult(result: Result<Response<VIMAccountNew>>) -> Result<VIMAccountNew>
    {
        guard case .Success(let accountResponse) = result
        else
        {
            let resultError: NSError
            if case .Failure(let error) = result
            {
                resultError = error
            }
            else
            {
                let errorDescription = "Authentication result malformed"
                
                assertionFailure(errorDescription)
                
                resultError = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.NoResponse.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            }
            
            return .Failure(error: resultError)
        }
        
        let account = accountResponse.model
        
        do
        {
            try self.authenticateClient(account: account)
            
            let accountType: AccountStore.AccountType = (account.user != nil) ? .User : .ClientCredentials
            
            try self.accountStore.saveAccount(account, type: accountType)
        }
        catch let error
        {
            return .Failure(error: error as NSError)
        }
        
        return .Success(result: account)
    }
    
    private func authenticateClient(account account: VIMAccountNew) throws
    {
        guard account.accessToken != nil
        else
        {
            let errorDescription = "AuthenticationController did not recieve an access token with account response"
            
            assertionFailure(errorDescription)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.AuthToken.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            
            throw error
        }
        
        self.client.authenticatedAccount = account
    }
}