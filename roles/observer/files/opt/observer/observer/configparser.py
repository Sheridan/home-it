import yaml


class ConfigParser:

    def __init__(self, path_to_config):
        self._config_file = path_to_config

    def load(self):
        with open(self._config_file, 'r') as stream:
            return self.check(yaml.load(stream))

    def check(self, options):
        if 'proxy' not in options:
            options['proxy'] = {
                'enabled': False
            }
        else:
            if 'enabled' not in options['proxy']:
                options['proxy']['enabled'] = True
        if 'debug' not in options:
            options['debug'] = False
        return options
