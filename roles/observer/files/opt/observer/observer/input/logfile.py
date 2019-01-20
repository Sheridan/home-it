import datetime
import pickle
import socket
import time
import re
import os
from observer.input.base import InputPlugin


class InputLogfile(InputPlugin):
    def __init__(self, outputs, options, debug):
        super(InputLogfile, self).__init__(options, debug, 'logfile')
        self._outputs = outputs
        self._positions_file = options['positions_file']
        self._positions = self.load_positions()

    def gen_position_id(self, rule):
        return '{0}:{1}:{2}'.format(rule['path'],
                                    rule['match']['positive'],
                                    rule['match']['negative'])

    def load_positions(self):
        positions = None
        try:
            with open(self._positions_file, 'rb') as positions_file:
                positions = pickle.load(positions_file)
        except IOError:
            pass
        if positions:
            for rule in self._options['rules']:
                if not rule['store_position']:
                    positions.pop(self.gen_position_id(rule), None)
            return positions
        return {}

    def update_positions(self):
        positions = {}
        for rule in self._options['rules']:
            if rule['store_position']:
                pos_id = self.gen_position_id(rule)
                positions[pos_id] = self._positions[pos_id]
        with open(self._positions_file, 'wb') as positions_file:
            pickle.dump(positions, positions_file)

    def check_log_files(self, rule):
        path_to_log = rule['path']
        pos_id = self.gen_position_id(rule)
        with open(path_to_log, 'r') as log_file:
            if pos_id not in self._positions:
                log_file.seek(0, 2)
                self._positions[pos_id] = log_file.tell()
                if self._debug:
                    print('Initializing read from end', pos_id)
                return
            else:
                statinfo = os.stat(path_to_log)
                if statinfo.st_size < self._positions[pos_id]:
                    print("Log file %s truncated" % (path_to_log))
                    log_file.seek(0, 2)
                else:
                    log_file.seek(self._positions[pos_id], 0)

            logs = log_file.read()
            self._positions[pos_id] = log_file.tell()
            if logs.strip():
                for line in logs.split('\n'):
                    line = line.strip()
                    if line:
                        self.on_entry(line)

    def on_entry(self, entry):
        match_result = self.match(entry)
        if match_result:
            msg = match_result['data']
            msg['full_message'] = entry
            msg['input_plugin_name'] = self.plugin_name()
            msg['identifier'] = match_result['rule']['identifier'] if 'identifier' in match_result['rule'] else 'unset'
            msg['timestamp'] = datetime.datetime.now()
            msg['host'] = socket.gethostname()
            self._outputs.send_message(msg, match_result)

    def run(self):
        while True:
            for rule in self._options['rules']:
                self.check_log_files(rule)
            self.update_positions()
            time.sleep(1)
