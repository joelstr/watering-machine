/*
*******************************************************************************
* Copyright (c) 2021 by M5Stack
*                  Equipped with M5Core2 sample source code
* Visit for more information: https://docs.m5stack.com/en/core/core2
*
* Description: MQTT.
* Date: 2021/11/5
* Modified for LEDs , 2022-08-15 AE
* Modified for touch
* Press A B or C button to send a status
*******************************************************************************
*/
#include "M5Core2.h" // M5stack Core2 driver 0.1.5
#include <WiFi.h> // wifi functions
#include <PubSubClient.h> // PubSubClient 2.8 (MQTT client)
#include "FastLED.h"  // FastLED 3.5.0 (LED-bar driver)

#define LEDS_PIN 25  // pin used for LED-n
#define LEDS_NUM 10
CRGB ledsBuff[LEDS_NUM];

WiFiClient espClient;
PubSubClient client(espClient);

// Configure the name and password of the connected wifi and your MQTT Broker host.
/*
const char* ssid = "CCIZ";
const char* password = "+1Makers2morrow";
*/
const char* ssid = "CCGuest"; // wifi ap name
const char* password = "Makersoftomorrow!"; // wifi password

const char* mqtt_server = "test.mosquitto.org"; // MQTT broker address

unsigned long lastMsg = 0;
#define MSG_BUFFER_SIZE (50)
char msg[MSG_BUFFER_SIZE];
int value = 0;

void setupWifi();
void callback(char* topic, byte* payload, unsigned int length);
void reConnect();

void setup() {
  M5.begin();
  setupWifi();
  client.setServer(mqtt_server, 1883);  //Sets the server details.
  client.setCallback(callback);         //Sets the message callback function.

  M5.Touch.begin();  // Touch begin after AXP begin. (Reset at the start of AXP)
}

void loop() {
  if (!client.connected()) {
    reConnect();
  }
  client.loop();  //This function is called periodically to allow clients to process incoming messages and maintain connections to the server.

  //unsigned long now = millis();  //Obtain the host startup duration.

    if (M5.BtnA.wasPressed()) {
      pub_color("r");
      ++value;
    }
    if (M5.BtnB.wasPressed()) {
      pub_color("g");
      ++value;
    }
    if (M5.BtnC.wasPressed()) {
      pub_color("k");
      ++value;
    }

  M5.update(); // update touch events
  delay(10); // to avoid too fast polling
}

void pub_color(char* col_char) {
      snprintf(
      msg, MSG_BUFFER_SIZE, col_char,
      value);  //Format to the specified string and store it in MSG.
    M5.Lcd.print("Publish message: ");
    M5.Lcd.println(msg);
    client.publish( "knowit/color", msg);  //Publishes a message to the specified topic.
    if (value % 12 == 0) { // every 12th messege clear the screen, and reset cursor
      M5.Lcd.clear();
      M5.Lcd.setCursor(0, 0);
    }
};

void setupWifi() {
  delay(10);
  M5.Lcd.printf("Connecting to %s", ssid);
  WiFi.mode(WIFI_STA);         //Set the mode to WiFi station mode.
  WiFi.begin(ssid, password);  //Start Wifi connection.

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    M5.Lcd.print(".");
  }
  M5.Lcd.printf("\nSuccess\n");
}

void callback(char* topic, byte* payload, unsigned int length) {
  M5.Lcd.print("Message arrived [");
  M5.Lcd.print(topic);
  M5.Lcd.print("] ");
  for (int i = 0; i < length; i++) {
    M5.Lcd.print((char)payload[i]);
  }
  M5.Lcd.println();
  bool red = (payload[0] == 'r');
  bool green = (payload[0] == 'g');
  bool blue = (payload[0] == 'b');
  bool yellow = (payload[0] == 'y');
  bool purple = (payload[0] == 'p');
  bool cyan = (payload[0] == 'c');
  bool orange = (payload[0] == 'o');
  bool black = (payload[0] == 'k');

  if (red) {
    FastLED.addLeds<SK6812, LEDS_PIN, GRB>(ledsBuff, LEDS_NUM);
    for (int i = 0; i < LEDS_NUM; i++) {
      ledsBuff[i].setRGB(255, 0, 0);
    }
    FastLED.show();
  }
  if (green) {
    FastLED.addLeds<SK6812, LEDS_PIN, GRB>(ledsBuff, LEDS_NUM);
    for (int i = 0; i < LEDS_NUM; i++) {
      ledsBuff[i].setRGB(0, 255, 0);
    }
    FastLED.show();
  }
  if (blue) {
    FastLED.addLeds<SK6812, LEDS_PIN, GRB>(ledsBuff, LEDS_NUM);
    for (int i = 0; i < LEDS_NUM; i++) {
      ledsBuff[i].setRGB(0, 0, 255);
    }
    FastLED.show();
  }
  if (black) {
    FastLED.addLeds<SK6812, LEDS_PIN, GRB>(ledsBuff, LEDS_NUM);
    for (int i = 0; i < LEDS_NUM; i++) {
      ledsBuff[i].setRGB(0, 0, 0);
    }
    FastLED.show();
  }
}

void reConnect() {
  while (!client.connected()) {
    M5.Lcd.print("Attempting MQTT connection...");
    // Create a random client ID.
    String clientId = "M5Stack-";
    clientId += String(random(0xffff), HEX);
    // Attempt to connect.
    if (client.connect(clientId.c_str())) {
      M5.Lcd.printf("\nSuccess\n");
      // Once connected, publish an announcement to the topic.
      client.publish("knowit/M5Stack", "hello world");
      // ... and resubscribe.
      client.subscribe("knowit/color");
    } else {
      M5.Lcd.print("failed, rc=");
      M5.Lcd.print(client.state());
      M5.Lcd.println("try again in 5 seconds");
      delay(5000);
    }
  }
}