import os
import pickle
import re
import time
import sys

import requests
import yaml

import select
from systemd import journal
import threading


class Bot:
    def __init__(self, path_to_config):
        self.running = False
        self._settings = self.load_config(path_to_config)
        self.tmp = self._settings['telegram']['positions_file_location']
        self._proxies = {}
        if 'proxy' in self._settings['telegram']:
            if 'user' in self._settings['telegram']['proxy']:
                self._proxies={self._settings['telegram']['proxy']['type']: 'socks5://%s:%s@%s:%s'%(self._settings['telegram']['proxy']['user'], self._settings['telegram']['proxy']['pass'], self._settings['telegram']['proxy']['host'], self._settings['telegram']['proxy']['port'])}
            else:
                self._proxies={self._settings['telegram']['proxy']['type']: 'socks5://%s:%s'%(self._settings['telegram']['proxy']['host'], self._settings['telegram']['proxy']['port'])}
        self._debug = False

    def load_config(self, file):
        with open(file, 'r') as stream:
            settings = yaml.load(stream)
        return settings

    def botq(self, token, method, params=None):
        url = 'https://api.telegram.org/bot%s/%s' % (token, method)
        try:
            if self._debug:
                print('Sending', params)
            r = requests.post(url, data=params, proxies=self._proxies)
            if r.status_code == 200:
                if self._debug:
                    print('Api return:', r.json())
            else:
                print('API returned code %s'%(r.status_code))
        except Exception as e:
            print(e)

    def send_message(self, to, msg):
        if 'loggerbot' not in msg:
            self.botq(self._settings['telegram']['token'], 'sendMessage', {'chat_id': to, 'text': msg, 'disable_web_page_preview': True, 'parse_mode': 'Markdown'})

    def stop(self):
        self.running = False


class ConfigParserBot(Bot):
    def __init__(self, path_to_config):
        super(ConfigParserBot, self).__init__(path_to_config)
        self._positions = self.load_positions()

    def load_positions(self):
        positions = None
        try:
            with open(self.tmp, 'rb') as tmp_file:
                positions = pickle.load(tmp_file)
        except IOError:
            pass
        if positions:
            for source in self._settings['sources']:
                if not source['store_position']:
                    positions.pop(self.gen_position_id(source), None)
            return positions
        return {}

    def gen_position_id(self, source):
        return '%s:%s'%(source['path'],source['match'])

    def update_positions(self):
        positions = {}
        for source in self._settings['sources']:
            if source['type'] == 'file' and source['store_position']:
                pos_id = self.gen_position_id(source)
                positions[pos_id] = self._positions[pos_id]
        with open(self.tmp, 'wb') as tmp_file:
            pickle.dump(positions, tmp_file)

    def check_log_files(self, source):
        path_to_log = source['path']
        pos_id = self.gen_position_id(source)
        pattern = re.compile(source['match'])
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
                    print("Log file %s truncated"%(path_to_log))
                    log_file.seek(0, 2)
                else:
                    log_file.seek(self._positions[pos_id], 0)

            logs = log_file.read()
            self._positions[pos_id] = log_file.tell()
            if logs.strip():
                for line in logs.split('\n'):
                    line = line.strip()
                    if line and pattern.match(line):
                        self.send_message(source['chat_id'], source['msg_format'] % ("dummy %s"%(line,),))

    def run(self):
        while True:
            for source in self._settings['sources']:
                if source['type'] == 'file':
                    self.check_log_files(source)
            self.update_positions()
            time.sleep(1)

def journal_reader(bot):
    settings = bot._settings
    sources = []
    for source in settings['sources']:
        if source['type'] == 'journal':
            source['pattern'] = re.compile('.*%s.*' % (source['match'],))
            sources.append(source)
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
                    idnt = entry['SYSLOG_IDENTIFIER'] if entry['SYSLOG_IDENTIFIER'] is not None else 'Unknown'
                    match_text = '%s %s' % (idnt, entry['MESSAGE'])
                    for source in sources:
                        if source['pattern'].match(match_text):
                            msg = 'dummy [%s][%s][%s] %s'%(entry['__REALTIME_TIMESTAMP'].strftime("%Y.%m.%d %H:%M:%S"), entry['_HOSTNAME'], idnt , entry['MESSAGE'])
                            bot.send_message(source['chat_id'], source['msg_format'] % (msg,))
        time.sleep(1)

if __name__ == '__main__':
    bot = ConfigParserBot(sys.argv[1])
    t = threading.Thread(target=journal_reader, args=(bot,))
    t.daemon = True
    t.start()
    bot.run()
