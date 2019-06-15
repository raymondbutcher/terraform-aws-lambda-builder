import glob
import json


def handler(event, context):
    with open("result.json") as open_file:
        result = json.load(open_file)
    result["files"] = sorted(glob.glob("*"))
    return result
