//
//  VimeoSessionManager.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 10/17/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

import AFNetworking

final public class VimeoSessionManager: AFHTTPSessionManager
{
    // MARK: Initialization
    
    init(sessionConfiguration: NSURLSessionConfiguration, requestSerializer: VimeoRequestSerializer)
    {        
        super.init(baseURL: VimeoBaseURLString, sessionConfiguration: sessionConfiguration)
        
        self.requestSerializer = requestSerializer
        self.responseSerializer = VimeoResponseSerializer()
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Authentication
    
    func clientDidAuthenticateWithAccount(account: VIMAccountNew)
    {
        guard let requestSerializer = self.requestSerializer as? VimeoRequestSerializer
        else
        {
            return
        }
        
        let accessToken = account.accessToken
        requestSerializer.accessTokenProvider = {
            return accessToken
        }
    }
    
    func clientDidClearAccount()
    {
        guard let requestSerializer = self.requestSerializer as? VimeoRequestSerializer
            else
        {
            return
        }
        
        requestSerializer.accessTokenProvider = nil
    }
}
