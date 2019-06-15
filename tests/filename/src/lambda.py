import json
import os


def handler(event, context):
    data = {"success": True}
    if os.path.exists("hello.json"):
        with open("hello.json") as open_file:
            data.update(json.load(open_file))
    return data
