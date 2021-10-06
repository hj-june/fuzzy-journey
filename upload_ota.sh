#!/bin/bash

# Add check for package requirements such as aws cli

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
  aws s3 cp ${full_download_path} . && echo "Download successful: ${full_download_path}" || { echo "Download FAILED: ${full_download_path}"; exit 1; }
}

upload_ota() {
  #aws s3 cp ${build_zipfile} ${full_upload_path} && echo "Upload successful: ${build_zipfile}" || { echo "Upload FAILED ${build_zipfile}"; exit 1; }
  pass
}

do_magic() {
  unzip -q ${build_zipfile} -d ${build_name} && echo "Unzip successful: ${build_zipfile} "|| { echo "FAILED to unzip: ${build_zipfile}"; exit 1; }
  sync

  origin_jota="app.enc.jota"
  changed_jota1="${device}-${build}"
  changed_jota2="${device}-${build}0000"

  origin_jotc=$(find ./${build_name} -name "*systemPlus-*" -exec basename {} \;)
  changed_jotc1="${device}-${build}${build}.jotc"

  cp -v "./${build_name}/${origin_jota}" "./${build_name}/${changed_jota1}" || { echo "FAILED to make copy of ${origin_jota}"; exit 1; }
  cp -v "./${build_name}/${origin_jota}" "./${build_name}/${changed_jota2}" || { echo "FAILED to make copy of ${origin_jota}"; exit 1; }
  cp -v "./${build_name}/${origin_jotc}" "./${build_name}/${changed_jotc1}" || { echo "FAILED to make copy of ${origin_jotc}"; exit 1; }
  sync
}

# debug print
echo "device is : $device"
echo "build is : $build"
echo "full build name is: ${build_name}"
echo "full zip file is: ${build_zipfile}"

#download_build
#upload_ota
do_magic