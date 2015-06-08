/*:
**Note:** For **Argo** to be imported into the Playground, ensure that the **Argo-Mac** *scheme* is selected from the list of schemes.

* * *
*/
import Foundation
import Argo
import Runes
/*:
**Helper function** – load JSON from a file
*/
func JSONFromFile(file: String) -> AnyObject? {
  return NSBundle.mainBundle().pathForResource(file, ofType: "json")
    >>- { NSData(contentsOfFile: $0) }
    >>- JSONObjectWithData
}

func JSONObjectWithData(data: NSData) -> AnyObject? {
  do { return try NSJSONSerialization.JSONObjectWithData(data, options: []) }
  catch _ { return .None }
}
/*:
During JSON decoding, a **String** representation of a date needs to be converted to a **NSDate**.
To achieve this, a **NSDateFormatter** and a helper function will be used.
*/
let jsonDateFormatter: NSDateFormatter = {
  let dateFormatter = NSDateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssz"
  return dateFormatter
}()

let toNSDate: String -> Decoded<NSDate> = {
  .fromOptional(jsonDateFormatter.dateFromString($0))
}
/*:
## Decoding selected entries from the iTunes store JSON format

An example JSON file (**tropos.json**) can be found in the **resources** folder.
*/
struct App {
  let name: String
  let formattedPrice: String
  let averageUserRating: Float?
  let releaseDate: NSDate
}

extension App: CustomStringConvertible {
  var description: String {
    return "name: \(name)\nprice: \(formattedPrice), rating: \(averageUserRating), released: \(releaseDate)"
  }
}

extension App: Decodable  {
  static func create(name: String)(formattedPrice: String)(averageUserRating: Float?)(releaseDate: NSDate) -> App {
    return App(name: name, formattedPrice: formattedPrice, averageUserRating: averageUserRating, releaseDate: releaseDate)
  }
  
  static func decode(j: JSON) -> Decoded<App> {
    return create
      <^> j <| "trackName"
      <*> j <| "formattedPrice"
      <*> j <|? "averageUserRating"
      <*> (j <| "releaseDate" >>- toNSDate)
  }
}
/*:
* * *
*/
let app: App? = (JSONFromFile("tropos")?["results"] >>- decode)?.first
print(app!)

