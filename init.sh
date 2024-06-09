#!/usr/bin/env bash

# Help message
help_message() {
    cat <<EOF
Usage: $(basename "$0") TARGET_HOST

Provisions a new user with sudo and SSH access on a target server.

Arguments:
  TARGET_HOST   The hostname or IP address of the target server.

Options:
  -h, --help    Display this help message and exit

EOF
}

# Parse command line options
while [[ "$1" =~ ^- ]]; do
  case $1 in
    -h | --help )
      help_message
      exit
      ;;
    * )
      echo "Invalid option: $1"
      help_message
      exit 1
      ;;
  esac
  shift
done

# Check if target host is provided
if [ -z "$1" ]; then
    echo "Error: TARGET_HOST is required."
    help_message
    exit 1
fi

# Variables
TARGET_HOST="$1"
ROOT_USER="root"

# Prompt for root password
read -s -p "Enter root password for $TARGET_HOST: " ROOT_PASS
echo

# Prompt for SSH public key path
read -p "Enter path to SSH public key (use ~ for home directory): " SSH_PUBLIC_KEY_PATH_INPUT

# Resolve tilde to full path
SSH_PUBLIC_KEY_PATH=$(eval echo "$SSH_PUBLIC_KEY_PATH_INPUT")

# Read the SSH public key from the file
if [ ! -f "$SSH_PUBLIC_KEY_PATH" ]; then
  echo "Public key file not found: $SSH_PUBLIC_KEY_PATH"
  exit 1
fi

SSH_PUBLIC_KEY=$(cat "$SSH_PUBLIC_KEY_PATH")

# Prompt for new username
read -p "Enter new username: " NEW_USER

# Prompt for new user password
read -s -p "Enter password for $NEW_USER: " NEW_USER_PASS
echo

# Install necessary tools
#echo "Installing sshpass..."
#sudo apt-get install -y sshpass

# Create a script to be executed on the target server
read -r -d '' TARGET_SCRIPT << EOF
#!/bin/bash

# Install sudo
echo "Installing packages..."
apt-get install -y sudo

# Create a new user
echo "Creating user $NEW_USER..."
useradd -m -s /bin/bash $NEW_USER

# Set password for the new user
echo "Setting password for user $NEW_USER..."
echo "$NEW_USER:$NEW_USER_PASS" | chpasswd

# Add the new user to sudo group
echo "Adding $NEW_USER to sudo group..."
usermod -aG sudo $NEW_USER

# Setup SSH key-based authentication
mkdir -p /home/$NEW_USER/.ssh
echo "$SSH_PUBLIC_KEY" > /home/$NEW_USER/.ssh/authorized_keys
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
chmod 700 /home/$NEW_USER/.ssh
chmod 600 /home/$NEW_USER/.ssh/authorized_keys

EOF

# Use sshpass to send the script to the target server and execute it
sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no $ROOT_USER@$TARGET_HOST "bash -s" << EOF
$TARGET_SCRIPT
EOF

echo "User $NEW_USER has been created and provisioned with sudo and SSH access."

# Test the new user by running a command on the target host via SSH
echo "Testing the new user..."
SSH_OUTPUT=$(ssh -i ${SSH_PUBLIC_KEY_PATH} $NEW_USER@$TARGET_HOST "whoami")

if [ "$SSH_OUTPUT" = "$NEW_USER" ]; then
  echo "Test successful. User $NEW_USER can run commands on the target host."
else
  echo "Test failed. User $NEW_USER cannot run commands on the target host."
fi
