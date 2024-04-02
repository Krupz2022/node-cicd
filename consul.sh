#!/bin/bash -x

if [ $# -ne 2 ]; then 
    echo "Usage: $0 <Consul URL> <Consul Token> "
    exit 1
fi

CONSUL_URL="$1"
CONSUL_TOKEN="$2"

# Extracting name for the zip file from the Consul URL
ZIP_NAME=$(echo "$CONSUL_URL" | awk -F'[-]' '{print $2 "-" $3}')
FOLDER_PATH=$(pwd)/$ZIP_NAME

# Appending /v1/kv/ to the URL 
CONSUL_URL="$CONSUL_URL/v1/kv/"

echo "Saving the keys"
echo "Please wait..."

# Function to make a request to Consul and save the response to a file
function get_and_save_key {
    local key="$1"
    local output_file="$2"
    local token="$CONSUL_TOKEN"
    local url="$CONSUL_URL$key"

    # Make the HTTP request and save the response to a file
    curl -s --header "X-Consul-Token: $token" --GET "$url"?raw -o "$output_file"
}

function process_key {
    local key="$1"
    local base_folder="$2/" 
    # Extract the folder path and key name
    folder_path="$(dirname "$key")"
    key_name="$(basename "$key")"

    # Create the full folder path in the local directory
    local_folder="${base_folder}${folder_path}"

    # Create the full key by appending the base folder and key name
    full_key="${folder_path}/${key_name}"

    # Ensure that folder paths represent actual folders
    if [ -n "$folder_path" ]; then
        mkdir -p "$local_folder"  # Create the directory
    fi
 
    # Make a request to Consul and save the response to a JSON file in the local folder
    output_file="${local_folder}/${key_name}.json"
    get_and_save_key "$key" "$output_file"
}

# Function to process keys within a folder
function process_keys_in_folder {
    local folder="$1"
    local base_folder="$2"
    local token="$CONSUL_TOKEN"

    # Get the list of keys within the folder
    keys=($(curl -s --header "X-Consul-Token: $token"  "$CONSUL_URL$folder?keys" | jq -r '.[]'))

    # Iterate through the keys and process them
    for key in "${keys[@]}"; do
        process_key "$key" "$base_folder"
    done
}

# Start the processing with an empty folder and the base local directory
process_keys_in_folder "" "$FOLDER_PATH"

# Create a zip file
zip -r "$ZIP_NAME.zip" "$ZIP_NAME"
#rm -rf "$FOLDER_PATH"

echo "Congratulations! All the keys are saved in '$ZIP_NAME.zip'"
echo "Done"
