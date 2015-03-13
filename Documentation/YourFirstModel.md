# Decoding Your First Model #

Let's explore using Argo to decode some basic models. We're going to use some
custom operators and functional concepts that you many not understand. We will
explain those in more detail in later sections, but for now just follow the
pattern.

We will start with a `User` model. Almost, every app will have one of these.

```swift
struct User {
  let id: Int
  let name: String
  let email: String
}
```

OK, here is our super basic `User`. We will be creating and fetching our app's
users through the interwebs where JSON is common form of communication. Now, we
can use Argo to decode that JSON into our `User`.

Let's assume that `data` is the `NSData` object that `NSURLSession` hands back to us
after a successful network request. Also, here is our example JSON response:

```
{
  "id": 5,
  "name": "Some Gob",
  "email": "gob@loose.seal"
}
```

Now, decoding is as easy as:

```swift
let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)
let user: User? = decode(json!)
```

Looks good except `!` can lead to crashes so instead let's use `map`.

```swift
let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)
let user: User? = json.map(decode)
```

If you try to run this, you'll see that it wont compile. In order to use the `decode` function
to decode a `User` from JSON, we need to make `User` conform to the `JSONDecodable` protocol.
This protocol makes `User` implement a static `decode` function that should check if each property
we need for a `User` is in the JSON and if so, return the `User`.

```swift
extension User: JSONDecodable {
  static func decode(j: JSON) -> Decoded<User> {
    if let id: Int = j <| "id",
      name: String = j <| "name",
      email: String = j <| "email"
    {
      return User(id: id, name: name, email: email)
    }
    return .TypeMismatch("\(j) is not a User")
  }
}
```

First, we conform to `JSONDecodable` by creating an extension of `User`. Now,
we have to implement the `decode` function which takes a `JSON` value and
returns a `Decoded<User>`. This `JSON` value is the enum that is used internally
to represent a JSON 
