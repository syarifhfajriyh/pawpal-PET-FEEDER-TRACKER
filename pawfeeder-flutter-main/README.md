## PawFeeder

A flutter based app built for a remote petfeeder system.

### Description

-   An automated pet feeder system, which we can control with an android app remotely (through the internet).
-   Can send a signal to the system to release food instantly or schedule it.
-   The system is connected with a [backend server](https://github.com/bibekkakati/pawfeeder-backend) which is hosted in AWS and it communicates via WebSocket.
-   The android app sends the signals to the server using Rest API.
-   IoT system is built using ESP8266 NodeMCU development board, continuous servo motor and programmed it in such a way that one can configure the WiFi from the app itself. A custom sound module is also integrated to call the pet's name while releasing food.

### Technology Used:

-   Flutter
-   Dart

<p align="center">
    <img width="260" src="/mockup/screen.png">
    <img width="260" src="/mockup/1.jpeg">
</p>
<p align="center">
    <img width="260" src="/mockup/2.jpeg">
    <img width="260" src="/mockup/3.jpeg">
</p>
<p align="center">
    <img width="260" src="/mockup/4.jpeg">
    <img width="260" src="/mockup/5.jpeg">
</p>
<p align="center">
    <img src="/mockup/PawFeeder_Flow.png">
</p>
