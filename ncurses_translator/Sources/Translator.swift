// Copyright 2015 iAchieved.it LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Glibc
import Foundation
import CcURL
import CJSONC

class Translator {

  let BUFSIZE = 1024

  init() {
  }

  func translate(text:String, from:String, to:String,
                        completion:(translation:String?, error:NSError?) -> Void) {

    let curl = curl_easy_init()

    guard curl != nil else {
      completion(translation:nil,
                 error:NSError(domain:"translator", code:1, userInfo:nil))
      return
    }

    let escapedText = curl_easy_escape(curl, text, Int32(strlen(text)))

    guard escapedText != nil else {
      completion(translation:nil,
                 error:NSError(domain:"translator", code:2, userInfo:nil))
      return
    }
    
    let langPair = from + "%7c" + to
    let wgetCommand = "wget -qO- http://api.mymemory.translated.net/get\\?q\\=" + String.fromCString(escapedText)! + "\\&langpair\\=" + langPair
    
    let pp      = popen(wgetCommand, "r")
    var buf     = [CChar](count:BUFSIZE, repeatedValue:CChar(0))
    
    var response:String = ""
    while fgets(&buf, Int32(BUFSIZE), pp) != nil {
      response = response + String.fromCString(buf)!
    }
    
    let translation = getTranslatedText(response)

    guard translation.error == nil else {
      completion(translation:nil, error:translation.error)
      return
    }

    completion(translation:translation.translation, error:nil)
  }

  private func getTranslatedText(jsonString:String) -> (error:NSError?, translation:String?) {

    let obj = json_tokener_parse(jsonString)

    guard obj != nil else {
      return (NSError(domain:"translator", code:3, userInfo:nil),
             nil)
    }

    let responseData = json_object_object_get(obj, "responseData")

    guard responseData != nil else {
      return (NSError(domain:"translator", code:3, userInfo:nil),
              nil)
    }

    let translatedTextObj = json_object_object_get(responseData,
                                                   "translatedText")

    guard translatedTextObj != nil else {
      return (NSError(domain:"translator", code:3, userInfo:nil),
              nil)
    }

    let translatedTextStr = json_object_get_string(translatedTextObj)

    return (nil, String.fromCString(translatedTextStr)!)
           
  }

}


