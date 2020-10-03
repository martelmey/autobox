import serial
import datetime
ser = serial.Serial('/dev/ttyACM0',9600)
while True:
	now = datetime.datetime.now()
	log = open("autobox-log/logTempHumH2o", "a")
	read_serial=ser.readline()

	print(now.strftime('%H:%M:%S on %A %B %d'))
	print(read_serial)

	log.write(now.strftime('%H:%M:%S on %A %B %d: '))
	log.write(read_serial)
	log.close()