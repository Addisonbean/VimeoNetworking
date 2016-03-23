//
//  Request+Me.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/22/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

typealias UserRequest = Request<VIMUser>
typealias UserListRequest = Request<[VIMUser]>

extension Request
{
    static func meRequest() -> Request
    {
        return Request(path: "/me")
    }
    
    static func meFollowingRequest() -> Request
    {
        return Request(path: "/me/following")
    }
}