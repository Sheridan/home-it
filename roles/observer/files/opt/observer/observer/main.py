from observer import ConfigParser, OutputRouter
from observer.input import InputJournald, InputLogfile
import time
import sys


class Observer:
    def __init__(self, path_to_config):
        super(Observer, self).__init__()
        self._options = ConfigParser(path_to_config).load()
        self._output_router = OutputRouter(self._options)
        self._inputs = []
        if 'journald' in self._options['input']:
            self._inputs.append(InputJournald(self._output_router,
                                              self._options['input']['journald'],
                                              self._options['debug']))
        if 'logfile' in self._options['input']:
            self._inputs.append(InputLogfile(self._output_router,
                                             self._options['input']['logfile'],
                                             self._options['debug']))
        if not self._inputs:
            print("You forgot to define any input plugin")
            sys.exit()

    def run(self):
        for x in self._inputs:
            x.start()
        while True:
            time.sleep(60)
