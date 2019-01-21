from observer.output import OutputTelegram
from observer.formatter import Formatter
import sys
import socket


class OutputRouter:
    def __init__(self, options):
        self._options = options
        self._outputs = []
        if 'telegram' in self._options['output']:
            self._outputs.append(OutputTelegram(options['output']['telegram'],
                                                options['proxy'],
                                                options['debug']))
        if not self._outputs:
            print("You forgot to define any output plugin")
            sys.exit()
        self._formatter = Formatter(self._options['formatter'], options['debug'])
        self.send_alive()

    def send_message(self, message, match_result):
        for target_output in self._outputs:
            for target_name in match_result['rule']['outputs']:
                if target_output.target_exists(target_name):
                    message['output_plugin_name'] = target_output.plugin_name()
                    target_output.send_message(self._formatter.format(message), target_name)

    def send_alive(self):
        for target_output in self._outputs:
            for target_name in target_output.targets():
                target_output.send_message('🤖 I am alive at host <code>{0}</code>!'.format(socket.gethostname()), target_name)
