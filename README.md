# WhereInTheWorld
Update your Slack status with your current location

![WhereInTheWorld in the MacOS Status Bar](/Docs/Assets/whereintheworld.png?raw=true)
![Slack status showing the location from WhereInTheWorld](/Docs/Assets/slack.png?raw=true)

# Usage

This is a MacOS Agent app that runs in your status bar.
The icon shows whether `WhereInTheWorld` is running or paused.

- It checks your Mac's current location every couple of minutes.
- It uses the post code to look up your known locations.
- If none are found, it uses the airport or city name in combination with country and flag.
- It then updates your Slack status accordingly.

If you don't want `WhereInTheWorld` to override your Slack status, you can simply pause it in the status bar.

## Exceptions

- The Slack status is not updated while the icon is set to `:zoom:` to prevent it from overriding the more detailed status. See [https://github.com/mivok/slack_status_updater](https://github.com/mivok/slack_status_updater).

# Building and Installation

1. Check out the source code and open the project in Finder.
2. Rename `Locations_example.plist` to `Locations.plist`.
3. Rename `Keys_example.plist` to `Keys.plist`.
4. Now open the project in XCode.
5. Get a [Google Geocoding API token](https://developers.google.com/maps/documentation/geocoding/get-api-key). Enable the Geocoding API and make sure to set up billing for your account (even though these APIs are free).
6. Get a Slack token for your user. [Create an application](https://api.slack.com/apps) and add `users.profile:read` and `users.profile:write` User Token scopes. Then copy the `User OAuth Token`.
7. Provide both tokens in the `Keys.plist` dictionary.
8. Provide your known locations in the `Locations.plist` dictionary, such as home, office, etc. The `postcodePrefix` depends on the size and precision of your post code area. For example, `SE1` might be too large while `SE1 0LH` might be too narrow. The `type` can be `office`, `home`, `wework`, `train` or `airport`. Wifi can be set alternatively to Postcode.
9. Build and run the application.
10. Click `Product` > `Archive`.
11. In the folder that opens, right-click on the bundle and select `Show package contents`.
12. Copy the `.app` file and `Info.plist` to a folder of your choice.
13. Open MacOS Settings, select `Users & Groups`, then `Login Items`. Click `+` and select the `.app` file to make it start with MacOS.
14. Allow the app access to your location.