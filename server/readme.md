# Watering mqtt broker

This just uses Mosquitto broker on a Raspberry PI. Seems to work out of the box.

## Tricks
- My USB wifi dongle wasn't compatible with nl80211 so I had to change it to use wext instead by adding the following to /etc/dhcpcd.conf

    <code>env ifwireless=1 <br>
    env wpa_supplicant_driver=wext</code>



## TODO
 * Add static IP
 * <s>Route mqtt.joelstrand.se to broker</s>