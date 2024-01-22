#!/usr/bin/env bash

img_rcd_file=record.yml
json_file=temp.json
output_file=output.txt
CONFIG_FILE=mktemp

rm -f $img_rcd_file
rm -f $json_file
rm -f $output_file
rm -f $CONFIG_FILE

# Use exitfool to extract photo metadata
exiftool examples/image.jpeg -json > $json_file

# Iterate over the array using jq
jq -c '.[]' "$json_file" | while IFS= read -r item; do
  # Iterate over the key-value pairs dynamically
  echo "$item" | jq -r 'to_entries[] | "\(.key) \(.value)"' | while IFS= read -r line; do
    key=$(echo "$line" | awk '{print $1}')
    # surround the value with single quotes to make valid YAML
    value=$(echo "$line" | awk '{$1=""; print $0}' | awk '{print "\x27" $0 "\x27"}')
    # write each record with 4 spaces for record.yml formatting
    echo "    $key: $value" >> $output_file
  done
done

results=$(cat output.txt)

cat <<EOF > "$img_rcd_file"
record:
  type: GeneralRecord
  name: image-registration-record
  version: 0.0.2
  value: "cute-rare-animal"
  category: birbit
  tags:
    - golden
    - pheasant
    - trespassing
  meta:
$results
EOF

cat <<EOF > "$CONFIG_FILE"
services:
  cns:
    restEndpoint: '${CERC_REGISTRY_REST_ENDPOINT:-http://138.197.130.188:1317}'
    gqlEndpoint: '${CERC_REGISTRY_GQL_ENDPOINT:-http://138.197.130.188:9473/api}'
    chainId: ${CERC_REGISTRY_CHAIN_ID:-laconic_9000-1}
    gas: 550000
    fees: 200000aphoton
EOF

cat $img_rcd_file

RECORD_ID=$(laconic -c $CONFIG_FILE cns record publish --filename $img_rcd_file --user-key "${CERC_REGISTRY_USER_KEY}" --bond-id ${CERC_REGISTRY_BOND_ID} | jq -r '.id')
echo $RECORD_ID

