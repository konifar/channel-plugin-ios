//
//  ScriptPromiseTests.swift
//  CHPlugin
//
//  Created by Haeun Chung on 08/02/2017.
//  Copyright © 2017 ZOYI. All rights reserved.
//

import Quick
import Nimble
//import RxSwift

@testable import ChannelIO

class ScriptPromiseTests: QuickSpec {
  override func spec() {
    beforeEach {
      PrefStore.setCurrentChannelId(channelId: "7")
      PrefStore.setCurrentUserId(userId: "58a154dec843f78f")
    }
    
    it("normal") {
      
    }
  }
}
