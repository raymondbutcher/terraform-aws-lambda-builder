'use strict';

const aws = require('aws-sdk'),
  cfnresponse = require('cfn-response'),
  fs = require('fs'),
  path = require('path'),
  { execSync } = require('child_process'),
  s3 = new aws.S3();


exports.handler = async (event, context) => {
  let physicalResourceId = null,
    status = null;
  try {

    console.log(JSON.stringify(event));

    const bucket = event.ResourceProperties.Bucket,
      keyTarget = event.ResourceProperties.KeyTarget;
    physicalResourceId = `arn:aws:s3:::${bucket}/${keyTarget}`;

    if (event.RequestType == "Create") {

      await createZip(event);

    } else if (event.RequestType == "Update") {

      await createZip(event);

      const oldPhysicalResourceId = event.PhysicalResourceId;

      if (physicalResourceId != oldPhysicalResourceId) {
        await deleteZip(oldPhysicalResourceId);
      }

    } else if (event.RequestType == "Delete") {

      const physicalResourceId = event.PhysicalResourceId;

      await deleteZip(physicalResourceId);

    } else {

      throw new Error("unknown event.RequestType: " + event.RequestType);

    }

    status = cfnresponse.SUCCESS;

  } catch (error) {

    console.log(error);
    status = cfnresponse.FAILED;

  } finally {

    // cfnresponse calls context.done() when it has finished
    cfnresponse.send(event, context, status, {}, physicalResourceId);
    await new Promise(function (resolve) { });

  }
};

async function createZip(event) {
  const p = event.ResourceProperties,
    bucket = p.Bucket,
    keySource = p.KeySource,
    keyTarget = p.KeyTarget,
    env = Object.assign({}, process.env);

  env.HOME = '/tmp'; // npm writes to home dir which is readonly in Lambda

  console.log('Installing yazl');
  execSync('npm install yazl unzipper', { 'cwd': '/tmp', 'env': env });
  const yazl = require('/tmp/node_modules/yazl'),
    unzipper = require('/tmp/node_modules/unzipper');

  const downloadPath = "/tmp/source.zip";
  console.log(`Downloading s3://${bucket}/${keySource} to ${downloadPath}`);
  const obj = await s3.getObject({ Bucket: bucket, Key: keySource }).promise();
  await new Promise(resolve => {
    const s = fs.createWriteStream(downloadPath);
    s.on('finish', resolve);
    s.write(obj.Body);
    s.end();
  });

  const buildPath = "/tmp/build";
  console.log(`Preparing build path ${buildPath}`);
  execSync(`rm -rf ${buildPath}`);
  execSync(`mkdir ${buildPath}`);
  process.chdir(buildPath);

  console.log(`Extracting ${downloadPath} to ${buildPath}`);
  await new Promise(resolve => {
    fs.createReadStream(downloadPath).pipe(unzipper.Extract({ path: buildPath }).on("close", resolve));
  });
  fs.unlinkSync(downloadPath);

  console.log("Running build script");
  fs.chmodSync("./build.sh", "755");
  execSync("ls -alh");
  execSync("./build.sh", { env: env, stdio: "inherit" });

  const builtPath = "/tmp/built.zip";
  console.log(`Creating ${builtPath} from ${buildPath}`);
  await new Promise(resolve => {
    const zipfile = new yazl.ZipFile();
    zipfile.outputStream.pipe(fs.createWriteStream(builtPath)).on("close", resolve);
    for (const absPath of walkSync(buildPath)) {
      const relPath = path.relative(buildPath, absPath);
      zipfile.addFile(absPath, relPath);
    }
    zipfile.end();
  });

  console.log(`Uploading zip to s3://${bucket}/${keyTarget}`);
  await s3.putObject({ Bucket: bucket, Key: keyTarget, Body: fs.createReadStream(builtPath) }).promise();
}

async function deleteZip(physicalResourceId) {
  const arnParts = physicalResourceId.split(":"),
    bucketAndKey = arnParts[arnParts.length - 1],
    bucket = bucketAndKey.substring(0, bucketAndKey.indexOf('/')),
    key = bucketAndKey.substring(bucketAndKey.indexOf('/') + 1);

  console.log(`Deleting s3://${bucket}/${key}`);
  await s3.deleteObject({ Bucket: bucket, Key: key }).promise();
}

function* walkSync(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fpath = path.join(dir, file),
      isDir = fs.statSync(fpath).isDirectory();
    if (isDir) {
      yield* walkSync(fpath);
    } else {
      yield fpath;
    }
  }
}
