//
//  Result.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/23/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public enum Result<ResultType>
{
    case Success(result: ResultType)
    case Failure(error: NSError)
}

/// This dummy enum acts as a generic typealias
public enum ResultCompletion<ResultType>
{
    public typealias T = (result: Result<ResultType>) -> Void
}
