# API Example Android (Agora + Voicemod) 

## Demo structure

This demo adds Voicemod functionality to the following functions:

| Function                                                                        | Location                                                                                                                                 |
| ------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Raw audio and video frames (JNI interface)                                                | [ProcessRawData.java](./app/src/main/java/io/agora/api/example/examples/advanced/ProcessRawData.java)                   |
| Raw audio frames (Native Java interface)                                                         | [ProcessAudioRawData.java](./app/src/main/java/io/agora/api/example/examples/advanced/ProcessAudioRawData.java)         |

Both functions rely on the `net.voicemod.agora.VoicemodAudioFrameObserver` class, which extends the `IAudioFrameObserver` interface, and the `voice_selector.xml` layout, which is a shared user interface component.

## How to run the demo

### Prerequisites

- Physical Android device with Android 5+
- Android Studio (latest version recommended)
- Voicemod SDK for Android (version 0.0.8 or newer)

### Steps to run

1. Place the `Voicemod-uSDK-x.y.z.aar` file in `/Android/APIExample/app/libs` (version 0.0.8 or newer)
2. Place the contents of the `VoiceData` folder from the Voicemod SDK into `/Android/APIExample/app/src/main/assets/VoiceData`
3. In Android Studio, open `/Android/APIExample`.
4. Sync the project with Gradle files.
5. Edit the `/Android/APIExample/app/src/main/res/values/string_config.xml` file.

   - Replace `YOUR APP ID` with your Agora project's App ID.
   - Replace `YOUR ACCESS TOKEN` with the Agora project's Access Token.
   - Replace `YOUR CLIENT KEY` with your Voicemod Client Key.

   ```xml
   <string name="agora_app_id" translatable="false">YOUR APP ID</string>
   <string name="agora_access_token" translatable="false">YOUR ACCESS TOKEN</string>
   <string name="voicemod_client_key" translatable="false">YOUR CLIENT KEY</string>
   ```

   > See [Set up Authentication](https://docs.agora.io/en/Agora%20Platform/token) to learn how to get an App ID and access token. You can get a temporary access token to quickly try out this sample project.
   >
   > The Channel name you used to generate the token must be the same as the channel name you use to join a channel.

   > To ensure communication security, Agora uses access tokens (dynamic keys) to authenticate users joining a channel.
   >
   > Temporary access tokens are for demonstration and testing purposes only and remain valid for 24 hours. In a production environment, you need to deploy your own server for generating access tokens. See [Generate a Token](https://docs.agora.io/en/Interactive%20Broadcast/token_server) for details.

6. Make the project and run the app in a connected physical Android device (simulator is not supported yet).

You are all set!
