#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

kubectl create namespace prow
kubectl create secret -n prow generic hmac-token --from-file=hmac=secret
kubectl create secret -n prow generic github-token --from-file=cert=cert --from-literal=appid=<git-app-id>

tmp_dir=$(mktemp -d)

find_yaml_files() {
  find config/jobs -name '*.yaml'
}

cm_file_content=""
echo "File is $(find_yaml_files)"

for job_file in $(find_yaml_files)
do
  job=$(basename "${job_file}")
  gzip "${job_file}" --stdout > "${tmp_dir}"/"${job}"
  cm_file_content="${cm_file_content} --from-file=${job}=${tmp_dir}/${job}"
done

kubectl create cm job-config ${cm_file_content} -n prow -o=yaml --dry-run=client | kubectl apply -f -