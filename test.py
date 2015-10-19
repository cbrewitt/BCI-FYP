__author__ = 'cillian'

import emokit
import gevent

headset = emokit.emotiv.Emotiv()
gevent.spawn(headset.setup)
gevent.sleep(1)

packet = headset.dequeue()

sensor_values = bytearray()
for sensor in packet.sensors:
    sensor_values.append(sensor['value'])
    print sensor

pass