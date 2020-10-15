import os, sys, time
import argparse
import json
import logging, coloredlogs
import itertools

# unpacker
import sqlite3

import csv

# TODO: incomplete, use the R script instead

class Unpacker():
    def __init__(self, path):
        self.conn = sqlite3.connect(path)

    def execute(self, sql):
        cur = self.conn.cursor()
        cur.execute(sql)
        self.conn.commit()

    def select(self, sql):
        cur = self.conn.cursor()
        cur.execute(sql)
        return cur.fetchall()

    def unpack(self):
        # Map of labjs session data by ppt id
        sessions = {}
        for row in self.select("select * from labjs where metadata like '%\"payload\":\"full\"%'"):
            rowid = row[0]
            session = row[1]

            # The data is a JSON-encoded array in the last column
            data = json.loads(row[5])

        return sessions
        

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Extract usable data from lab.js sqlite database')
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument('db')
    args = parser.parse_args()

    if args.verbose:
        if args.verbose > 1:
            coloredlogs.install(level='DEBUG')
        elif args.verbose > 0:
            coloredlogs.install(level='INFO')
    else:
        coloredlogs.install(level='WARN')

    if os.path.exists(args.db):
        u = Unpacker(args.db)
        data = u.unpack()

    else:
        logging.error("DB path does not exist")
        sys.exit(1)
