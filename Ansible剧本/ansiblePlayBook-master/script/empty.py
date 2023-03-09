import multiprocessing
from concurrent.futures import ThreadPoolExecutor

import os
import sys

executor = ThreadPoolExecutor(max_workers=multiprocessing.cpu_count())

print("线程数" + str(multiprocessing.cpu_count()))


def emptyFile(file_path):
    os.system('cat /dev/null > ' + file_path)
    print("删除:" + file_path)


if len(sys.argv) < 2:
    print("无参数")
    exit(0)
path = sys.argv[1]

for root, dirs, files in os.walk(path):
    for name in files:
        executor.submit(emptyFile, os.path.join(root, name))
# os.remove(path)