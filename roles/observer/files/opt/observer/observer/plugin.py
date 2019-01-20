from observer.threadhelper import ThreadHelper


class ObserverPlugin(ThreadHelper):
    def __init__(self, options, debug, plugin_name):
        self._options = options
        self._debug = debug
        self._plugin_name = plugin_name

    def plugin_name(self):
        return self._plugin_name
