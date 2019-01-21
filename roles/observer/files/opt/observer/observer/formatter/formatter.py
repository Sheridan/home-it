import os.path
import sys


class Formatter:
    def __init__(self, options, debug):
        self._options = options
        self._debug = debug

    def format(self, message):
        if self._debug:
            print("Incoming formatter: {0}".format(message))
        return self.process_message(self.get_template_content(message), message)

    def replace(self, template, needle, replacement):
        return template.replace('${%s}' % needle, replacement)

    def process_message(self, template, message):
        for dt_part in 'YmdHMS':
            template = self.replace(template, dt_part, message['timestamp'].strftime('%{0}'.format(dt_part)))
        for key in message:
            if key == 'timestamp':
                template = self.replace(template, key, message['timestamp'].strftime('%Y.%m.%d %H:%M:%S'))
            else:
                template = self.replace(template, key, message[key])
        return template

    def get_template_content(self, message):
        try:
            return self.try_get_template_content(message['output_plugin_name'], message['rule_name'])
        except Exception:
            pass
        try:
            return self.try_get_template_content(message['output_plugin_name'], 'default')
        except Exception:
            pass
        try:
            return self.try_get_template_content('', 'default')
        except Exception:
            pass
        print("Can not find any template! Tryed: ")
        print(self.construct_template_filename(message['output_plugin_name'], message['rule_name']))
        print(self.construct_template_filename(message['output_plugin_name'], 'default'))
        print(self.construct_template_filename('', 'default'))
        sys.exit()

    def try_get_template_content(self, folder, file):
        filename = self.construct_template_filename(folder, file)
        if os.path.isfile(filename):
            return self.load_template_content(filename)
        print('Template not exists: ', filename)
        raise Exception('File not found')

    def construct_template_filename(self, output_plugin_name, rule_name):
        return '{0}/{1}/{2}.html'.format(self._options['templates_path'], output_plugin_name, rule_name)

    def load_template_content(self, filename):
        with open(filename, 'r') as stream:
            return stream.read()
