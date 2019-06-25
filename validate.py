import json
import sys

DISABLED = "DISABLED"
FILENAME = "FILENAME"
LAMBDA = "LAMBDA"
S3 = "S3"

query = json.load(sys.stdin)


def conflict(*names):
    for name in names:
        if query[name]:
            build_mode = query["build_mode"]
            sys.stderr.write(
                "build mode {} does not support var.{}".format(build_mode, name)
            )
            sys.exit(1)


def require(*names):
    for name in names:
        if not query[name]:
            build_mode = query["build_mode"]
            sys.stderr.write("build mode {} requires var.{}".format(build_mode, name))
            sys.exit(1)


if query["build_mode"] == DISABLED:

    conflict("source_dir")

elif query["build_mode"] == FILENAME:

    require("filename", "source_dir")
    conflict("s3_bucket", "s3_key", "s3_object_version", "source_code_hash")

elif query["build_mode"] == LAMBDA:

    require("source_dir", "s3_bucket")
    conflict("filename", "s3_key", "s3_object_version", "source_code_hash")

elif query["build_mode"] == S3:

    require("s3_bucket", "s3_key", "source_dir")
    conflict("filename", "s3_object_version", "source_code_hash")

else:

    sys.stderr.write("invalid build mode {}".format(query["build_mode"]))
    sys.exit(1)

json.dump({}, sys.stdout)
