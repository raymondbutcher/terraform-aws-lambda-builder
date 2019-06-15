import json
import sys

query = json.load(sys.stdin)

build_mode = query["build_mode"]
filename = query["filename"]
s3_bucket = query["s3_bucket"]
s3_key = query["s3_key"]
s3_object_version = query["s3_object_version"]
source_code_hash = query["source_code_hash"]
source_dir = query["source_dir"]

LAMBDA = "LAMBDA"
S3 = "S3"
ZIPFILE = "ZIPFILE"

if build_mode == LAMBDA:
    assert not filename
    assert s3_bucket
    assert not s3_key
    assert not s3_object_version
    assert not source_code_hash
    assert source_dir
elif build_mode == S3:
    assert not filename
    assert s3_bucket
    assert s3_key
    assert not s3_object_version
    assert not source_code_hash
    assert source_dir
elif build_mode == ZIPFILE:
    assert not filename
    assert not s3_bucket
    assert not s3_key
    assert not s3_object_version
    assert not source_code_hash
    assert source_dir
elif build_mode:
    raise ValueError(build_mode)
else:
    if filename:
        assert not s3_bucket
        assert not s3_key
        assert not s3_object_version
    else:
        assert s3_bucket
        assert s3_key
    assert not source_dir

json.dump({}, sys.stdout)
