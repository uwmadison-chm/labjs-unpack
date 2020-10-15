import os
import sys
import csv
import json
import argparse
import logging

parser = argparse.ArgumentParser()
parser.add_argument("input")
args = parser.parse_args()

csv.field_size_limit(sys.maxsize)

def flatten(xs):
    return [y for x in xs for y in x]

with open(sys.argv[1], newline='', encoding='utf16') as tsvfile:
    reader = csv.DictReader(tsvfile, dialect=csv.excel_tab)
    # First two rows out of Qualtrics are header-y stuff, ignore
    next(reader)
    next(reader)
    for row in reader:
        stuff = row['labjs-data']
        if not stuff:
            stuff = "{}"
        data = json.loads(stuff)
        if len(data) == 0:
            logging.warning("Got row with no labjs data")
        else:
            output_file = os.path.join("output", row['ResponseId'] + '.tsv')
            os.makedirs("output", exist_ok=True)
            # unique set of all possible column names
            columns = set(flatten([x.keys() for x in data]))

            with open(output_file, mode='w') as out:
                writer = csv.writer(out, delimiter='\t')

                writer.writerow(list(columns))
                for row in data:
                    data = [row.get(col) for col in columns]
                    writer.writerow(data)
                    

