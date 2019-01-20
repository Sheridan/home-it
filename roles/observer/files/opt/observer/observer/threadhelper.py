from threading import Thread
import sys


class ThreadHelper:
    def __init__(self):
        pass

    def run(self):
        print("You forgot to implement the run method")
        sys.exit()

    def start(self):
        Thread(target=self.run).start()
