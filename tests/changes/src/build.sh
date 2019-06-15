# version.json gets added by the test script
# then the source zip will contain version.json
# this build script moves the file, so the final
# lambda package will have result.json instead.
mv version.json result.json
