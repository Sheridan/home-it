from observer import ObserverPlugin
import sys

class OutputPlugin(ObserverPlugin):
    def __init__(self, options, debug, plugin_name):
        super(OutputPlugin, self).__init__(options, debug, plugin_name)


    def send_message(self, message):
        print("You forgot to implement the send_message method")
        sys.exit()

    def target_exists(self, target_name):
        for target in self._options['targets']:
            if target_name == target['name']:
                return True
        return False
