#!/usr/bin/env python2.7
# coding='utf-8'
from tornado import ioloop, gen, websocket, web, autoreload, options
import hid
from array import array
from time import time, sleep
import sqlite3
import logging

l = logging.getLogger("tornado.application")
options.parse_command_line()

def decode(buff):
    data = array('B', buff)
    def swap(i,j):
        data[i], data[j] = data[j], data[i]
    
    swap(0,2)
    swap(1,4)
    swap(3,7)
    swap(5,6)


    xdata = array('B',[i^0x00 for i in data])

    sdata = array('B',[ (xdata[i-1]<<5 | xdata[i]>>3)%256 for i in xrange(7,0,-1)])
    sdata.reverse()
    sdata.insert(0, (xdata[7]<<5|xdata[0]>>3)%256)
    word = [ord(c) for c in 'Htemp99e']
    result = [(v-(word[i]<<4|word[i]>>4))%256 for i,v in enumerate(sdata)]
    return result



class CO2WebsocketHandler(websocket.WebSocketHandler):
    handlers = []
    @classmethod
    def broadcast(cls, tp, value):
        for h in cls.handlers:
            h.handler_measure(tp,value)

    def open(self):
        l.info('Client connected.')
        if self not in self.__class__.handlers:
            self.__class__.handlers.append(self)

    def handler_measure(self, tp, value): 
        self.write_message(dict(tp=tp,val=value))

    def initialize(self, name):
        l.info('Initialized.')

    def on_close(self):
        l.info('Client disconnected.')
        self.__class__.handlers.remove(self)

    def check_origin(self, origin):
        return True

if __name__ == '__main__': 
    dev = hid.device(0x04d9,0xa052)
    dev.close()
    dev.open(0x04d9,0xa052)
    dev.send_feature_report([0x00]*8)
    l.info('Device nonblocking mode: %s', dev.set_nonblocking(0))
    l.info('Device ready.')
    dbconn = sqlite3.connect('./measure.sqite3')
    l.info('Connected to "./measure.sqlite3".')
    dbc = dbconn.cursor()
    dbc.execute(
    '''CREATE TABLE IF NOT EXISTS measures (
    type TEXT,
    value TEXT,
    timestamp REAL
    );
    ''')

    def store(tp,val):
        dbc.execute("INSERT INTO measures VALUES (?,?,?);",[tp, val, time()])
        dbconn.commit()

    def onreload():
        dev.close()
        dbconn.close()
        l.info('Stopped')

    @gen.coroutine
    def update():
        rawdata = dev.read(16, 50)
        if len(rawdata) == 8:
            data = decode(rawdata)
            measureType, msb, lsb, chsum, end, a, b, c = data
            value = (msb<<8) + lsb
            if measureType is 66:
                # Temperature
                val = value*0.0625 - 273.15
                CO2WebsocketHandler.broadcast('temp',val)
                l.info('Temperature: %s', val)
                store('temp', val)
            elif measureType is 80:
                # CO2
                CO2WebsocketHandler.broadcast('co2', value) 
                l.info('CO2: %s', value)
                store('co2', value)


    app = web.Application([
        (r"/sock/",CO2WebsocketHandler, dict(name='co2')),
    ], autoreload=True, xsrf_cookies=False, debug=True)
    app.listen(8888, '0.0.0.0')
    io_loop = ioloop.IOLoop.current()
    autoreload.add_reload_hook(onreload)
    task = ioloop.PeriodicCallback(update, 100, io_loop)
    task.start()
    try:
        io_loop.start()
    except KeyboardInterrupt:
        onreload()
