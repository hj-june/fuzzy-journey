#!/bin/bash

# Verify that AWS credentials are present in env
if [[ -z ${AWS_DEFAULT_REGION+x} || (
	  -z ${AWS_PROFILE+x} &&
	      ( -z ${AWS_ACCESS_KEY_ID+x} || -z ${AWS_SECRET_ACCESS_KEY+x})
      )]]; then

    cat <<EOF >&2
AWS credentials are not present in the environment. Please add them by either:
  exporting AWS_PROFILE and AWS_DEFAULT_REGION (preferred), OR
  exporting AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION
EOF
    exit 1
fi

# Verify that the AWS CLI executable can be found
if [ ! "$(which aws)" ]; then
cat <<EOF >&2
The AWS CLI is NOT found, please install it using whatever means is appropriate for your environment, e.g.:
  brew install awscli
  sudo apt-get install awscli
EOF
    exit 1
fi

while getopts d:b: flag
do
    case "${flag}" in
      d) device=${OPTARG};;
      b) build=${OPTARG};;
      *) echo -e "\nUsage: ./${0##*/} -d [galaxy device name] -b [jenkins build number]\n"
         exit 1;;
    esac
done

build_name="${device}-${build}-master"
build_zipfile="${build_name}.zip"

s3_build_base_url="s3://junebuilds/juneoslite"
full_download_path="${s3_build_base_url}/${build_name}/${build_zipfile}"

#s3_ota_base_url="s3://june-ota-server-prod/versions"
s3_ota_base_url="s3://june-ota-server-walker-us-dev/versions"
full_upload_path="${s3_ota_base_url}/${device}/"

download_build() {
  aws s3 cp ${full_download_path} . && { echo "Download successful: ${full_download_path}"; sync; } || { echo "Download FAILED: ${full_download_path}"; exit 1; }
}

upload_ota() {
  local files="${changed_jota1}
  ${changed_jota2}
  ${changed_jotc1}
  "

  for i in ${files}; do
    aws s3 cp "./${build_name}/${i}" ${full_upload_path} --profile walker-cloud && echo "Upload successful: ${i}" || { echo "Upload FAILED ${i}"; exit 1; }
  done
}

do_magic() {
  unzip -q ${build_zipfile} -d ${build_name} && echo "Unzip successful: ${build_zipfile} "|| { echo "FAILED to unzip: ${build_zipfile}"; exit 1; }
  sync

  origin_jota="app.enc.jota"
  changed_jota1="${device}-${build}.jota"
  changed_jota2="${device}-${build}0000.jota"

  origin_jotc=$(find ./${build_name} -name "*systemPlus-*" -exec basename {} \;)
  changed_jotc1="${device}-${build}${build}.jotc"

  cp -v "./${build_name}/${origin_jota}" "./${build_name}/${changed_jota1}" || { echo "FAILED to copy: ${origin_jota}"; exit 1; }
  cp -v "./${build_name}/${origin_jota}" "./${build_name}/${changed_jota2}" || { echo "FAILED to copy: ${origin_jota}"; exit 1; }
  cp -v "./${build_name}/${origin_jotc}" "./${build_name}/${changed_jotc1}" || { echo "FAILED to copy: ${origin_jotc}"; exit 1; }
  sync
  echo "File copy and rename successful!"
}

download_build
do_magic
upload_ota