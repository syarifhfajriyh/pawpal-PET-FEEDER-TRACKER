/*
   --------------------------------------------------------------
   Pet Feeder Project Code - Protected by Warranty
   Created by: MUMU SERVICE CENTRE
   Contact: 0108204341
   Date: 22 - 09 - 2025
   Note: This watermark acts as a warranty seal for the project.
         Removing or altering this comment will void the warranty.

   Library Used:
      1. WiFi.h by Arduino
      2. Firebase_ESP_Client.h AND Firebase Arduino Client Libary for ESP8266 and ESP32 by Mobizt
      3. ESP32Servo.h by ESP32 Arduino
      4. addons/TokenHelper.h by Mobizt
      5. addons/RTDBHelper.h by Mobizt

   Safe Changes:
      1. WiFi Credentials KEEP IT 2.4gHz
         #define WIFI_SSID "Your_WiFi_SSID"
         #define WIFI_PASSWORD "Your_WiFi_Password"

      2. Firebase Configuration
         #define API_KEY "Your_Firebase_API_Key"
         #define DATABASE_URL "Your_Firebase_Database_URL"
         #define USER_EMAIL "Your_Firebase_User_Email"
         #define USER_PASSWORD "Your_Firebase_User_Password"

      3. Upload Interval - changing this will affect how often data is sent to Firebase
         const unsigned long DATA_UPDATE_INTERVAL = 1000; // 1000ms = 1 second

      4. Hardware Pin Configuration - change if using different GPIO pins
         const int SERVO_PIN = 4;
         const int TRIG_PIN1 = 13;
         const int ECHO_PIN1 = 12;
         const int TRIG_PIN2 = 26;
         const int ECHO_PIN2 = 27;
         const int FORCE_SENSOR_PIN = 35;
         const int LED_PIN = 2;

      5. Device Behavior Settings - adjust to customize operation
         const int SERVO_FEED_POSITION = 0;
         const int SERVO_IDLE_POSITION = 60;
         const int FORCE_THRESHOLD = 2500;
         const int CAT_DISTANCE = 10;
         const unsigned long FEED_DURATION = 2000;

      6. Food Level Thresholds - adjust based on your container
         const float EMPTY_THRESHOLD = 17.5;
         const float LOW_THRESHOLD = 13.5;
         const float MEDIUM_THRESHOLD = 5.0;

   Unsafe Changes:
      Modifying any code outside of the "Safe Changes" section may cause
      unexpected behavior and will void the warranty.
   --------------------------------------------------------------
*/

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <ESP32Servo.h>

// ============================================================================
//                          CONFIGURATION SETTINGS
// ============================================================================
// WiFi Network Credentials - Safe to change
#define WIFI_SSID "Ainaa"
#define WIFI_PASSWORD "Ainaa1474"

// Firebase Project Details - Safe to change
#define API_KEY "AIzaSyCV0RdBXTHvmoLKbYWe8gN8066Vbx72vQo"
#define DATABASE_URL "https://petfeeder1-713c0-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define USER_EMAIL "samygg0316@gmail.com"
#define USER_PASSWORD "123456"

// Hardware Pin Configuration - Safe to change
const int SERVO_PIN = 4;

const int TRIG_PIN1 = 13;
const int ECHO_PIN1 = 12;

const int TRIG_PIN2 = 26;
const int ECHO_PIN2 = 27;

const int FORCE_SENSOR_PIN = 35;

const int LED_PIN = 2;

// Device Behavior Settings - Safe to change
const int SERVO_FEED_POSITION = 0;
const int SERVO_IDLE_POSITION = 55;

const int FORCE_THRESHOLD = 2500;

const int CAT_DISTANCE = 11;

const unsigned long FEED_DURATION = 2000;

// Food Level Thresholds - Safe to change
const float EMPTY_THRESHOLD = 19.5;
const float LOW_THRESHOLD = 13.5;
const float MEDIUM_THRESHOLD = 5.0;

// Network Settings - Safe to change
const unsigned long DATA_UPDATE_INTERVAL = 1000;

// ============================================================================
//                          HARDWARE OBJECTS
// ============================================================================
Servo servo1;

// ============================================================================
//                          FIREBASE OBJECTS
// ============================================================================
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ============================================================================
//                          STATE VARIABLES
// ============================================================================
unsigned long sendDataPrevMillis = 0;
unsigned long feedStartTime = 0;
bool feedingInProgress = false;

int usdetect = 0;
int fsdetect = 0;
int found = 0;
int lastdetect = 0;
int currentdetect = 0;

String lastFoodLevel = "";

// ============================================================================
//                          FUNCTION PROTOTYPES
// ============================================================================
float readUltrasonicDistance(int trigPin, int echoPin);
void checkWiFi();

// ============================================================================
//                                   SETUP
// ============================================================================
void setup() 
{
    Serial.begin(115200);

    // Hardware Initialization
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);

    servo1.attach(SERVO_PIN);
    servo1.write(SERVO_IDLE_POSITION);

    pinMode(TRIG_PIN1, OUTPUT);
    pinMode(ECHO_PIN1, INPUT);
    pinMode(TRIG_PIN2, OUTPUT);
    pinMode(ECHO_PIN2, INPUT);

    // WiFi Connection
    Serial.print("Connecting to WiFi: ");
    Serial.println(WIFI_SSID);

    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) 
    {
        delay(300);
        Serial.print(".");
    }
    Serial.println("\nWiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    // Firebase Configuration
    Serial.println("Configuring Firebase...");
    config.api_key = API_KEY;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    config.database_url = DATABASE_URL;
    config.token_status_callback = tokenStatusCallback;

    Firebase.reconnectNetwork(true);
    fbdo.setBSSLBufferSize(4096, 1024);
    fbdo.setResponseSize(2048);

    Serial.println("Attempting to connect to Firebase...");
    Firebase.begin(&config, &auth);

    if (config.signer.tokens.error.message.length() > 0) 
    {
        Serial.print("Firebase Auth Error: ");
        Serial.println(config.signer.tokens.error.message.c_str());
    } 
    else 
    {
        Serial.println("Firebase authentication successful!");
        
        // Initialize values in Firebase RTDB
        Firebase.RTDB.setInt(&fbdo, "/device/buttonState", 0);
        Firebase.RTDB.setInt(&fbdo, "/device/foodLevel", 0);
        Firebase.RTDB.setInt(&fbdo, "/device/feedCommand", 0);
    }
    
    Firebase.setDoubleDigits(5);
    config.timeout.serverResponse = 10 * 1000;
}

// ============================================================================
//                          ULTRASONIC HELPER FUNCTION
// ============================================================================
float readUltrasonicDistance(int trigPin, int echoPin)
{
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    long duration = pulseIn(echoPin, HIGH, 30000);
    return duration * 0.017;
}

// ============================================================================
//                          WIFI RECONNECTION FUNCTION
// ============================================================================
void checkWiFi()
{
    if (WiFi.status() != WL_CONNECTED)
    {
        Serial.println("WiFi lost, reconnecting...");
        WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
        while (WiFi.status() != WL_CONNECTED)
        {
            delay(500);
            Serial.print(".");
        }
        Serial.println("\nReconnected to WiFi!");
    }
}

// ============================================================================
//                                   LOOP
// ============================================================================
void loop() 
{
    unsigned long currentMillis = millis();
    
    checkWiFi();
    
    if (Firebase.ready()) 
    {
        // Handle feed commands
        if (currentMillis - sendDataPrevMillis > DATA_UPDATE_INTERVAL || sendDataPrevMillis == 0) 
        {
            sendDataPrevMillis = currentMillis;
            
            if (Firebase.RTDB.getInt(&fbdo, "/device/feedCommand")) 
            {
                if (fbdo.dataType() == "int") 
                {
                    int feedCommand = fbdo.intData();
                    if (feedCommand == 1) 
                    {
                        Serial.println("Feed command received!");
                        feedingInProgress = true;
                        feedStartTime = currentMillis;
                        digitalWrite(LED_PIN, HIGH);
                        servo1.write(SERVO_FEED_POSITION);
                        Firebase.RTDB.setInt(&fbdo, "/device/feedCommand", 0);
                    }
                }
            } 
        }

        // Handle feeding process
        if (feedingInProgress && (currentMillis - feedStartTime >= FEED_DURATION))
        {
            feedingInProgress = false;
            digitalWrite(LED_PIN, LOW);
            Serial.println("Feeding completed");
            servo1.write(SERVO_IDLE_POSITION);
        }

        // Cat detection
        float distance_cm2 = readUltrasonicDistance(TRIG_PIN2, ECHO_PIN2);
        usdetect = (distance_cm2 < CAT_DISTANCE) ? 1 : 0;

        int analogReading = analogRead(FORCE_SENSOR_PIN);
        fsdetect = (analogReading >= FORCE_THRESHOLD) ? 1 : 0;

        found = (usdetect == 1 || fsdetect == 1) ? 1 : 0;
        currentdetect = found;

        if (lastdetect != currentdetect) 
        {
            Serial.print("Cat detection state changed: ");
            Serial.println(currentdetect ? "FOUND" : "NOT FOUND");
            if (Firebase.RTDB.setInt(&fbdo, "/device/buttonState", currentdetect)) 
            {
                Serial.println("Cat detection state updated in Firebase");
            } 
            else 
            {
                Serial.print("Failed to update cat detection: ");
                Serial.println(fbdo.errorReason().c_str());
            }
            lastdetect = currentdetect;
        }

        // Food level measurement
        float distance_cm = readUltrasonicDistance(TRIG_PIN1, ECHO_PIN1);
        String foodLevel;

        if (distance_cm > EMPTY_THRESHOLD) 
        {
            foodLevel = "Empty";
        } 
        else if (distance_cm <= EMPTY_THRESHOLD && distance_cm > LOW_THRESHOLD) 
        {
            foodLevel = "Low";
        } 
        else if (distance_cm <= LOW_THRESHOLD && distance_cm > MEDIUM_THRESHOLD) 
        {
            foodLevel = "Medium";
        } 
        else if (distance_cm <= MEDIUM_THRESHOLD && distance_cm > 0) 
        {
            foodLevel = "High";
        } 
        else 
        {
            foodLevel = "Invalid";
        }
        
        if (foodLevel != lastFoodLevel)
        {
            if (Firebase.RTDB.setString(&fbdo, "/device/foodLevel", foodLevel)) 
            {
                Serial.println("Food level updated in Firebase");
                lastFoodLevel = foodLevel;
            } 
            else 
            {
                Serial.print("Failed to update food level: ");
                Serial.println(fbdo.errorReason().c_str());
            }
        }

    } 
    else 
    {
        Serial.println("Firebase is not ready");
        delay(1000);
    }
}