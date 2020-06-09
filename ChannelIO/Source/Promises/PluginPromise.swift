//
//  PluginPromise.swift
//  CHPlugin
//
//  Created by Haeun Chung on 06/02/2017.
//  Copyright © 2017 ZOYI. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import ObjectMapper
import SwiftyJSON

struct PluginPromise {
  static func registerPushToken(token: String) -> Observable<Any?> {
    return Observable.create { subscriber in
      let key = UIDevice.current.identifierForVendor?.uuidString ?? ""
      let params = [
        "body": [
          "key": "ios-" + key,
          "token": token
        ]
      ]
      
      let req = AF
        .request(RestRouter.RegisterToken(params as RestRouter.ParametersType))
        .validate(statusCode: 200..<300)
        .responseJSON(completionHandler: { response in
          switch response.result {
          case .success(let data):
            let json = JSON(data)
            if json["pushToken"] == JSON.null {
              subscriber.onError(ChannelError.parseError)
              return
            }

            subscriber.onNext(nil)
            subscriber.onCompleted()
          case .failure(let error):
            subscriber.onError(ChannelError.serverError(
              msg: error.localizedDescription
            ))
          }
        })
      
      return Disposables.create {
        req.cancel()
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos:.background))
  }
  
  static func unregisterPushToken() -> Observable<Any?> {
    return Observable.create { subscriber in

      let key = UIDevice.current.identifierForVendor?.uuidString ?? ""
      let req = AF
        .request(RestRouter.UnregisterToken("ios-\(key)"))
        .validate(statusCode: 200..<300)
        .response { response in
          if let error = response.error {
            subscriber.onError(ChannelError.serverError(msg: error.localizedDescription))
          } else {
            subscriber.onNext(nil)
            subscriber.onCompleted()
          }
        }
      return Disposables.create {
        req.cancel()
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos:.background))
  }
  
  static func checkVersion() -> Observable<Any?> {
    return Observable.create { subscriber in
      let req = AF
        .request(RestRouter.CheckVersion)
        .validate(statusCode: 200..<300)
        .responseJSON(completionHandler: { response in
          switch response.result {
          case .success(let data):
            let json = JSON(data)
            let minVersion = json["minCompatibleVersion"].string ?? ""
            
            guard let version = CHUtils.getSdkVersion() else {
              subscriber.onError(ChannelError.versionError)
              return
            }
            
            if version.versionToInt().lexicographicallyPrecedes(minVersion.versionToInt()) {
              subscriber.onError(ChannelError.versionError)
              return
            }
            
            subscriber.onNext(nil)
            subscriber.onCompleted()
          case .failure(let error):
            subscriber.onError(ChannelError.serverError(
              msg: error.localizedDescription
            ))
          }
        })
      
      return Disposables.create {
        req.cancel()
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos:.background))
  }

  static func getPlugin(pluginKey: String) -> Observable<(CHPlugin, CHBot?)> {
    return Observable.create { (subscriber) in
      let req = AF
        .request(RestRouter.GetPlugin(pluginKey))
        .validate(statusCode: 200..<300)
        .responseJSON(completionHandler: { response in
          switch response.result{
          case .success(let data):
            let json = JSON(data)
            guard let plugin = Mapper<CHPlugin>()
              .map(JSONObject: json["plugin"].object) else {
                subscriber.onError(ChannelError.parseError)
                return
              }
            let bot = Mapper<CHBot>()
              .map(JSONObject: json["bot"].object)
            subscriber.onNext((plugin, bot))
            subscriber.onCompleted()
          case .failure(let error):
            subscriber.onError(ChannelError.serverError(
              msg: error.localizedDescription
            ))
          }
        })
      return Disposables.create {
        req.cancel()
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos:.background))
  }
  
  static func boot(pluginKey: String, params: CHParam) -> Observable<BootResponse?> {
    return Observable.create { (subscriber) in
      let req = AF
        .request(RestRouter.Boot(pluginKey, params as RestRouter.ParametersType))
        .validate(statusCode: 200..<300)
        .responseJSON { response in
          switch response.result {
          case .success(let data):
            let json = SwiftyJSON.JSON(data)
            let result = Mapper<BootResponse>().map(JSONObject: json.object)
            
            subscriber.onNext(result)
            subscriber.onCompleted()
          case .failure(let error):
            subscriber.onError(ChannelError.serverError(
              msg: error.localizedDescription
            ))
          }
        }
      
      return Disposables.create {
        req.cancel()
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos:.background))
  }
  
  static func sendPushAck(chatId: String?) -> Observable<Bool?> {
    return Observable.create { (subscriber) -> Disposable in
      guard let chatId = chatId else {
        subscriber.onNext(nil)
        return Disposables.create()
      }
      
      let req = AF
        .request(RestRouter.SendPushAck(chatId))
        .validate(statusCode: 200..<300)
        .response { response in
          if let error = CHUtils.getServerErrorMessage(data: response.data)?.first {
            let msg = "\n***sendpushack sever fail!!\n"
              + "R: \(response.request)\n"
              + "H: \(response.request?.headers)\n"
              + "E: \(error)"
            let param: [String: Any] = [
              "message": msg
            ]

            let headers: HTTPHeaders = [
              "X-Access-Key": "5b67e6d6700a4a37",
              "X-Access-Secret": "676bd5850d472b6690ce1f605fcf8a41",
              "Content-Type": "application/json",
              "Accept": "application/json"
            ]

            AF.request(
              "https://api.channel.io/open/groups/29756/messages?botName=iOSDebugBot",
              method: .post,
              parameters: param,
              encoding: JSONEncoding.default,
              headers: headers)
              .responseJSON { response in
                print(response)
              }
            subscriber.onError(ChannelError.serverError(msg: error))
          } else if let error = response.error {
            let msg = "\n***sendpushack alamofire fail!!\n"
              + "R: \(response.request)\n"
              + "H: \(response.request?.headers)\n"
              + "E: \(error.errorDescription)"
            let param: [String: Any] = [
              "message": msg
            ]

            let headers: HTTPHeaders = [
              "X-Access-Key": "5b67e6d6700a4a37",
              "X-Access-Secret": "676bd5850d472b6690ce1f605fcf8a41",
              "Content-Type": "application/json",
              "Accept": "application/json"
            ]

            AF.request(
              "https://api.channel.io/open/groups/29756/messages?botName=iOSDebugBot",
              method: .post,
              parameters: param,
              encoding: JSONEncoding.default,
              headers: headers)
              .responseJSON { response in
                print(response)
              }
            subscriber.onError(ChannelError.serverError(msg: error.localizedDescription))
          } else {
           
            let param: [String: Any] = [
              "message": "\n***sendack success!!\n"
            ]

            let headers: HTTPHeaders = [
              "X-Access-Key": "5b67e6d6700a4a37",
              "X-Access-Secret": "676bd5850d472b6690ce1f605fcf8a41",
              "Content-Type": "application/json",
              "Accept": "application/json"
            ]

            AF.request(
              "https://api.channel.io/open/groups/29756/messages?botName=iOSDebugBot",
              method: .post,
              parameters: param,
              encoding: JSONEncoding.default,
              headers: headers)
              .responseJSON { response in
                print(response)
              }
            subscriber.onNext(nil)
            subscriber.onCompleted()
          }
        }
        .responseJSON(completionHandler: { (response) in
          switch response.result {
          case .success(_):
            subscriber.onNext(true)
            subscriber.onCompleted()
          case .failure(let error):
            subscriber.onError(ChannelError.serverError(
              msg: error.localizedDescription
            ))
          }
        })
      
      return Disposables.create {
        req.cancel()
      }
    }
  }
  
  static func getProfileSchemas(pluginId: String) -> Observable<[CHProfileSchema]> {
    return Observable.create { (subscriber) -> Disposable in
      let req = AF
        .request(RestRouter.GetProfileBotSchemas(pluginId))
        .validate(statusCode: 200..<300)
        .responseJSON(completionHandler: { (response) in
          switch response.result {
          case .success(let data):
            let json = SwiftyJSON.JSON(data)
            let profiles = Mapper<CHProfileSchema>()
              .mapArray(JSONObject: json["profileBotSchemas"].object) ?? []
            subscriber.onNext(profiles)
            subscriber.onCompleted()
          case .failure(let error):
            subscriber.onError(ChannelError.serverError(
              msg: error.localizedDescription
            ))
          }
        })
      return Disposables.create {
        req.cancel()
      }
    }
  }
}
