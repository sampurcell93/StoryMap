import threading


class Queue():
    def execute(self):
        if (self.queue):
            fn = self.queue.pop()
            if hasattr(fn, '__call__'):
                fn()
        self.timer = threading.Timer(self.interval, self.execute).start()

    def push(self, fn):
        self.queue.append(fn);

    def stop(self):
        if (self.timer):
            self.timer.cancel()

    def __init__(self, _interval=.25):
        self.queue = []
        self.interval = _interval
