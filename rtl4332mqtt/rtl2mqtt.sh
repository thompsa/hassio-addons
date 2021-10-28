#!/bin/sh

# A simple script that will receive events from an RTL433 SDR and resend the data via MQTT

# Author: Chris Kacerguis <chriskacerguis@gmail.com>
# Modification for hass.io add-on: James Fry

# Below are rtl_433 options and the supported device protocols as of 25/10/2017
# **NOTE that the protocol number is NOT persistent and seems to change**
# Hence always verify protocol numbers in logs when starting the add-on
# The key arguments required are:
# -F json  --> this sets JSON formatted output for easier MQTT
# -R <protocol number>  --> this tells rtl_433 which protocol(s) to scan for

# Usage:  = Tuner options =
#         [-d <RTL-SDR USB device index>] (default: 0)
#         [-g <gain>] (default: 0 for auto)
#         [-f <frequency>] [-f...] Receive frequency(s) (default: 433920000 Hz)
#         [-H <seconds>] Hop interval for polling of multiple frequencies (default: 600 seconds)
#         [-p <ppm_error] Correct rtl-sdr tuner frequency offset error (default: 0)
#         [-s <sample rate>] Set sample rate (default: 250000 Hz)
#         [-S] Force sync output (default: async)
#         = Demodulator options =
#         [-R <device>] Enable only the specified device decoding protocol (can be used multiple times)
#         [-G] Enable all device protocols, included those disabled by default
#         [-l <level>] Change detection level used to determine pulses [0-16384] (0 = auto) (default: 0)
#         [-z <value>] Override short value in data decoder
#         [-x <value>] Override long value in data decoder
#         [-n <value>] Specify number of samples to take (each sample is 2 bytes: 1 each of I & Q)
#         = Analyze/Debug options =
#         [-a] Analyze mode. Print a textual description of the signal. Disables decoding
#         [-A] Pulse Analyzer. Enable pulse analyzis and decode attempt
#         [-I] Include only: 0 = all (default), 1 = unknown devices, 2 = known devices
#         [-D] Print debug info on event (repeat for more info)
#         [-q] Quiet mode, suppress non-data messages
#         [-W] Overwrite mode, disable checks to prevent files from being overwritten
#         [-y <code>] Verify decoding of demodulated test data (e.g. "{25}fb2dd58") with enabled devices
#         = File I/O options =
#         [-t] Test signal auto save. Use it together with analyze mode (-a -t). Creates one file per signal
#                  Note: Saves raw I/Q samples (uint8 pcm, 2 channel). Preferred mode for generating test files
#         [-r <filename>] Read data from input file instead of a receiver
#         [-m <mode>] Data file mode for input / output file (default: 0)
#                  0 = Raw I/Q samples (uint8, 2 channel)
#                  1 = AM demodulated samples (int16 pcm, 1 channel)
#                  2 = FM demodulated samples (int16) (experimental)
#                  3 = Raw I/Q samples (cf32, 2 channel)
#                  Note: If output file is specified, input will always be I/Q
#         [-F] kv|json|csv Produce decoded output in given format. Not yet supported by all drivers.
#                 append output to file with :<filename> (e.g. -F csv:log.csv), defaults to stdout.
#         [-C] native|si|customary Convert units in decoded output.
#         [-T] specify number of seconds to run
#         [-U] Print timestamps in UTC (this may also be accomplished by invocation with TZ environment variable set).
#         [<filename>] Save data stream to output file (a '-' dumps samples to stdout)
#
# Supported device protocols
# [01]  Silvercrest Remote Control
# [02]  Rubicson Temperature Sensor
# [03]  Prologue, FreeTec NC-7104, NC-7159-675 temperature sensor
# [04]  Waveman Switch Transmitter
# [06]* ELV EM 1000
# [07]* ELV WS 2000
# [08]  LaCrosse TX Temperature / Humidity Sensor
# [10]* Acurite 896 Rain Gauge
# [11]  Acurite 609TXC Temperature and Humidity Sensor
# [12]  Oregon Scientific Weather Sensor
# [13]* Mebus 433
# [14]* Intertechno 433
# [15]  KlikAanKlikUit Wireless Switch
# [16]  AlectoV1 Weather Sensor (Alecto WS3500 WS4500 Ventus W155/W044 Oregon)
# [17]  Cardin S466-TX2
# [18]  Fine Offset Electronics, WH2, WH5, Telldus Temperature/Humidity/Rain Sensor
# [19]  Nexus, FreeTec NC-7345, NX-3980, Solight TE82S, TFA 30.3209 temperature/humidity sensor
# [20]  Ambient Weather Temperature Sensor
# [21]  Calibeur RF-104 Sensor
# [22]* X10 RF
# [23]  DSC Security Contact
# [24]* Brennenstuhl RCS 2044
# [25]  Globaltronics GT-WT-02 Sensor
# [26]  Danfoss CFR Thermostat
# [29]  Chuango Security Technology
# [30]  Generic Remote SC226x EV1527
# [31]  TFA-Twin-Plus-30.3049, Conrad KW9010, Ea2 BL999
# [32]  Fine Offset Electronics WH1080/WH3080 Weather Station
# [33]  WT450, WT260H, WT405H
# [34]  LaCrosse WS-2310 / WS-3600 Weather Station
# [35]  Esperanza EWS
# [36]  Efergy e2 classic
# [37]* Inovalley kw9015b, TFA Dostmann 30.3161 (Rain and temperature sensor)
# [38]  Generic temperature sensor 1
# [39]  WG-PB12V1 Temperature Sensor
# [40]  Acurite 592TXR Temp/Humidity, 5n1 Weather Station, 6045 Lightning, 3N1, Atlas
# [41]  Acurite 986 Refrigerator / Freezer Thermometer
# [42]  HIDEKI TS04 Temperature, Humidity, Wind and Rain Sensor
# [43]  Watchman Sonic / Apollo Ultrasonic / Beckett Rocket oil tank monitor
# [44]  CurrentCost Current Sensor
# [45]  emonTx OpenEnergyMonitor
# [46]  HT680 Remote control
# [47]  Conrad S3318P, FreeTec NC-5849-913 temperature humidity sensor
# [48]  Akhan 100F14 remote keyless entry
# [49]  Quhwa
# [50]  OSv1 Temperature Sensor
# [51]  Proove / Nexa / KlikAanKlikUit Wireless Switch
# [52]  Bresser Thermo-/Hygro-Sensor 3CH
# [53]  Springfield Temperature and Soil Moisture
# [54]  Oregon Scientific SL109H Remote Thermal Hygro Sensor
# [55]  Acurite 606TX Temperature Sensor
# [56]  TFA pool temperature sensor
# [57]  Kedsum Temperature & Humidity Sensor, Pearl NC-7415
# [58]  Blyss DC5-UK-WH
# [59]  Steelmate TPMS
# [60]  Schrader TPMS
# [61]* LightwaveRF
# [62]* Elro DB286A Doorbell
# [63]  Efergy Optical
# [64]* Honda Car Key
# [67]  Radiohead ASK
# [68]  Kerui PIR / Contact Sensor
# [69]  Fine Offset WH1050 Weather Station
# [70]  Honeywell Door/Window Sensor, 2Gig DW10/DW11, RE208 repeater
# [71]  Maverick ET-732/733 BBQ Sensor
# [72]* RF-tech
# [73]  LaCrosse TX141-Bv2, TX141TH-Bv2, TX141-Bv3, TX141W, TX145wsdth sensor
# [74]  Acurite 00275rm,00276rm Temp/Humidity with optional probe
# [75]  LaCrosse TX35DTH-IT, TFA Dostmann 30.3155 Temperature/Humidity sensor
# [76]  LaCrosse TX29IT, TFA Dostmann 30.3159.IT Temperature sensor
# [77]  Vaillant calorMatic VRT340f Central Heating Control
# [78]  Fine Offset Electronics, WH25, WH32B, WH24, WH65B, HP1000 Temperature/Humidity/Pressure Sensor
# [79]  Fine Offset Electronics, WH0530 Temperature/Rain Sensor
# [80]  IBIS beacon
# [81]  Oil Ultrasonic STANDARD FSK
# [82]  Citroen TPMS
# [83]  Oil Ultrasonic STANDARD ASK
# [84]  Thermopro TP11 Thermometer
# [85]  Solight TE44/TE66, EMOS E0107T, NX-6876-917
# [86]  Wireless Smoke and Heat Detector GS 558
# [87]  Generic wireless motion sensor
# [88]  Toyota TPMS
# [89]  Ford TPMS
# [90]  Renault TPMS
# [91]  inFactory, nor-tec, FreeTec NC-3982-913 temperature humidity sensor
# [92]  FT-004-B Temperature Sensor
# [93]  Ford Car Key
# [94]  Philips outdoor temperature sensor (type AJ3650)
# [95]  Schrader TPMS EG53MA4, PA66GF35
# [96]  Nexa
# [97]  Thermopro TP08/TP12/TP20 thermometer
# [98]  GE Color Effects
# [99]  X10 Security
# [100]  Interlogix GE UTC Security Devices
# [101]* Dish remote 6.3
# [102]  SimpliSafe Home Security System (May require disabling automatic gain for KeyPad decodes)
# [103]  Sensible Living Mini-Plant Moisture Sensor
# [104]  Wireless M-Bus, Mode C&T, 100kbps (-f 868950000 -s 1200000)
# [105]  Wireless M-Bus, Mode S, 32.768kbps (-f 868300000 -s 1000000)
# [106]* Wireless M-Bus, Mode R, 4.8kbps (-f 868330000)
# [107]* Wireless M-Bus, Mode F, 2.4kbps
# [108]  Hyundai WS SENZOR Remote Temperature Sensor
# [109]  WT0124 Pool Thermometer
# [110]  PMV-107J (Toyota) TPMS
# [111]  Emos TTX201 Temperature Sensor
# [112]  Ambient Weather TX-8300 Temperature/Humidity Sensor
# [113]  Ambient Weather WH31E Thermo-Hygrometer Sensor, EcoWitt WH40 rain gauge
# [114]  Maverick et73
# [115]  Honeywell ActivLink, Wireless Doorbell
# [116]  Honeywell ActivLink, Wireless Doorbell (FSK)
# [117]* ESA1000 / ESA2000 Energy Monitor
# [118]* Biltema rain gauge
# [119]  Bresser Weather Center 5-in-1
# [120]* Digitech XC-0324 temperature sensor
# [121]  Opus/Imagintronix XT300 Soil Moisture
# [122]* FS20
# [123]* Jansite TPMS Model TY02S
# [124]  LaCrosse/ELV/Conrad WS7000/WS2500 weather sensors
# [125]  TS-FT002 Wireless Ultrasonic Tank Liquid Level Meter With Temperature Sensor
# [126]  Companion WTR001 Temperature Sensor
# [127]  Ecowitt Wireless Outdoor Thermometer WH53/WH0280/WH0281A
# [128]  DirecTV RC66RX Remote Control
# [129]* Eurochron temperature and humidity sensor
# [130]  IKEA Sparsnas Energy Meter Monitor
# [131]  Microchip HCS200 KeeLoq Hopping Encoder based remotes
# [132]  TFA Dostmann 30.3196 T/H outdoor sensor
# [133]  Rubicson 48659 Thermometer
# [134]  Holman Industries iWeather WS5029 weather station (newer PCM)
# [135]  Philips outdoor temperature sensor (type AJ7010)
# [136]  ESIC EMT7110 power meter
# [137]  Globaltronics QUIGG GT-TMBBQ-05
# [138]  Globaltronics GT-WT-03 Sensor
# [139]  Norgo NGE101
# [140]  Elantra2012 TPMS
# [141]  Auriol HG02832, HG05124A-DCF, Rubicson 48957 temperature/humidity sensor
# [142]  Fine Offset Electronics/ECOWITT WH51 Soil Moisture Sensor
# [143]  Holman Industries iWeather WS5029 weather station (older PWM)
# [144]  TBH weather sensor
# [145]  WS2032 weather station
# [146]  Auriol AFW2A1 temperature/humidity sensor
# [147]  TFA Drop Rain Gauge 30.3233.01
# [148]  DSC Security Contact (WS4945)
# [149]  ERT Standard Consumption Message (SCM)
# [150]* Klimalogg
# [151]  Visonic powercode
# [152]  Eurochron EFTH-800 temperature and humidity sensor
# [153]  Cotech 36-7959 wireless weather station with USB
# [154]  Standard Consumption Message Plus (SCMplus)
# [155]  Fine Offset Electronics WH1080/WH3080 Weather Station (FSK)
# [156]  Abarth 124 Spider TPMS
# [157]  Missil ML0757 weather station
# [158]  Sharp SPC775 weather station
# [159]  Insteon
# [160]  ERT Interval Data Message (IDM)
# [161]  ERT Interval Data Message (IDM) for Net Meters
# [162]* ThermoPro-TX2 temperature sensor
# [163]  Acurite 590TX Temperature with optional Humidity
# [164]  Security+ 2.0 (Keyfob)
# [165]  TFA Dostmann 30.3221.02 T/H Outdoor Sensor
# [166]  LaCrosse Technology View LTV-WSDTH01 Breeze Pro Wind Sensor
# [167]  Somfy RTS
# [168]  Schrader TPMS SMD3MA4 (Subaru)
# [169]* Nice Flor-s remote control for gates
# [170]  LaCrosse Technology View LTV-WR1 Multi Sensor
# [171]  LaCrosse Technology View LTV-TH Thermo/Hygro Sensor
# [172]  Bresser Weather Center 6-in-1
# [173]  Bresser Weather Center 7-in-1
# [174]  EcoDHOME Smart Socket and MCEE Solar monitor
# [175]  LaCrosse Technology View LTV-R1 Rainfall Gauge

export LANG=C
PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

CONFIG_PATH=/data/options.json
MQTT_HOST="$(jq --raw-output '.mqtt_host' $CONFIG_PATH)"
MQTT_USER="$(jq --raw-output '.mqtt_user' $CONFIG_PATH)"
MQTT_PASS="$(jq --raw-output '.mqtt_password' $CONFIG_PATH)"
MQTT_TOPIC="$(jq --raw-output '.mqtt_topic' $CONFIG_PATH)"
PROTOCOL="$(jq --raw-output '.protocol' $CONFIG_PATH)"
FREQUENCY="$(jq --raw-output '.frequency' $CONFIG_PATH)"
GAIN="$(jq --raw-output '.gain' $CONFIG_PATH)"
OFFSET="$(jq --raw-output '.frequency_offset' $CONFIG_PATH)"

# Start the listener and enter an endless loop
echo "Starting RTL_433 with parameters:"
echo "MQTT Host =" $MQTT_HOST
echo "MQTT User =" $MQTT_USER
echo "MQTT Password =" $MQTT_PASS
echo "MQTT Topic =" $MQTT_TOPIC
echo "RTL_433 Protocol =" $PROTOCOL
echo "RTL_433 Frequency =" $FREQUENCY
echo "RTL_433 Gain =" $GAIN
echo "RTL_433 Frequency Offset =" $OFFSET

function protocolhandler {
  for v in $(echo ${PROTOCOL}|tr -d '[]'|tr ',' ' ')
  do
   echo -n "-R $v "
  done
}

#set -x  ## uncomment for MQTT logging...
export LD_LIBRARY_PATH=/usr/local/lib64

/usr/local/bin/rtl_433 -C si -M newmodel \
  -F "mqtt://${MQTT_HOST}:1883,user=${MQTT_USER},pass=${MQTT_PASS},retain=0" \
  $(protocolhandler) -f $FREQUENCY -g $GAIN -p $OFFSET &

/usr/bin/python3 /usr/local/bin/rtl_433_mqtt_hass.py -H ${MQTT_HOST} -i 60 \
  -u ${MQTT_USER} -P ${MQTT_PASS}
