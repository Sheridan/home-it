from systemd import journal
import select
import time
import re
from observer.input.base import InputPlugin


class InputJournald(InputPlugin):

    def __init__(self, outputs, options, debug):
        super(InputJournald, self).__init__(options, debug, 'journald')
        self._outputs = outputs

    def run(self):
        while True:
            j = journal.Reader()

            j.seek_tail()
            j.get_previous()

            p = select.poll()
            p.register(j, j.get_events())

            while p.poll():
                if j.process() != journal.APPEND:
                    continue
                for entry in j:
                    if entry['MESSAGE']:
                        self.on_entry(entry)
            time.sleep(1)

    def on_entry(self, entry):
        idnt = entry['SYSLOG_IDENTIFIER'] if entry['SYSLOG_IDENTIFIER'] is not None else 'Unknown'
        match_text = '{0}: {1}'.format(idnt, entry['MESSAGE'])
        match_result = self.match(match_text)
        if match_result:
            msg = match_result['data']
            msg['full_message'] = entry['MESSAGE']
            msg['input_plugin_name'] = self.plugin_name()
            msg['identifier'] = entry['SYSLOG_IDENTIFIER']
            msg['timestamp'] = entry['__REALTIME_TIMESTAMP']
            msg['host'] = entry['_HOSTNAME']
            self._outputs.send_message(msg, match_result)
