#!/bin/bash

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

s3_build_baseURL="s3://junebuilds/juneoslite"
full_download_path="${s3_build_baseURL}/${build_name}/${build_zipfile}"

s3_ota_baseURL=""
full_upload_path=""
aws_creds=""

download_build() {
  aws s3 cp ${full_download_path} . && echo "Downloading ${full_download_path}" || echo "FAILED TO DOWNLOAD: ${full_download_path}"
}

upload_ota() {
  aws s3 cp ${build_zipfile} ${full_upload_path} && echo "Uploading ${build_zipfile} to OTA Server!" || echo "FAILED TO UPLOAD ${build_zipfile}"
}

echo "device is : $device"
echo "build is : $build"
echo "full build name is: ${build_name}"
echo "full zip file is: ${build_zipfile}"

download_build
upload_ota