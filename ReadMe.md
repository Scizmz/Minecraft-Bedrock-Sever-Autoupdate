# Minecraft Bedrock Server Auto-Updater

This script automatically downloads and installs the latest Minecraft Bedrock Dedicated Server, keeping your server up-to-date so players don't get locked out due to version mismatches.

## Features

- Automatically detects the latest Bedrock server version from the official Minecraft wiki
- Only updates when a newer version is available (no unnecessary restarts)
- Backs up world data before updating
- Manages the server service (stop/start)
- Logs all activity for troubleshooting
- Can be scheduled to run automatically

## Prerequisites

- Linux system with `systemd` (Ubuntu, Debian, CentOS, etc.)
- Minecraft Bedrock server already installed and configured as a service named `bedrock`
- `curl`, `wget`, `unzip`, and `tar` installed (usually pre-installed)

## Setup Instructions

### 1. Download the Script

```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/minecraft-bedrock-updater/main/update_minecraft.sh
chmod +x update_minecraft.sh
```

### 2. Configure Sudo Permissions

The script needs to stop and start the Minecraft service. To run automatically without password prompts, add these lines to your sudoers file:

```bash
sudo visudo
```

Add these lines (replace `your_username` with your actual username):

```
your_username ALL=(ALL) NOPASSWD: /bin/systemctl stop bedrock
your_username ALL=(ALL) NOPASSWD: /bin/systemctl start bedrock
```

### 3. Test the Script

Run it manually first to make sure everything works:

```bash
./update_minecraft.sh
```

The script will:
- Check for the latest version
- Download and install if newer
- Or skip if already up-to-date

## Scheduling Automatic Updates

To run the updater automatically every day at 5:00 AM:

### 1. Open Crontab

```bash
crontab -e
```

### 2. Add the Scheduled Job

Add this line to run daily at 5:00 AM:

```bash
0 5 * * * /full/path/to/update_minecraft.sh >> /var/log/minecraft_update.log 2>&1
```

Replace `/full/path/to/` with the actual path to your script. For example:

```bash
0 5 * * * /home/minecraft/update_minecraft.sh >> /var/log/minecraft_update.log 2>&1
```

### 3. Alternative Scheduling Options

- **Every 6 hours**: `0 */6 * * *`
- **Twice daily (6 AM and 6 PM)**: `0 6,18 * * *`
- **Weekly on Sundays at 3 AM**: `0 3 * * 0`

## Configuration

### Directory Structure

The script expects this directory structure:

```
/home/your_username/minecraft/
├── bedrock_server          # Server executable
├── worlds/                 # World data (backed up automatically)
├── backups/               # Backup storage (created automatically)
└── current_version.txt    # Version tracking (created automatically)
```

### Service Name

The script manages a systemd service called `bedrock`. If your service has a different name, edit this line in the script:

```bash
SERVICE="your_service_name"
```

## Logs and Troubleshooting

### View Recent Logs

```bash
# If logging to /var/log/minecraft_update.log
sudo tail -f /var/log/minecraft_update.log

# If logging to home directory
tail -f ~/minecraft/update.log
```

### Manual Testing

Run with verbose output:

```bash
./update_minecraft.sh 2>&1 | tee test_run.log
```

### Common Issues

**Permission Denied**: Make sure the script is executable (`chmod +x update_minecraft.sh`) and sudo is configured properly.

**Service Won't Start**: Check that your `bedrock` service is properly configured and the server files have correct permissions.

**Download Fails**: The wiki URL or download URL structure may have changed. Check the script's debug output.

## How It Works

1. **Version Check**: Downloads the official Minecraft wiki page and extracts the latest Bedrock server version
2. **Comparison**: Compares with the currently installed version (stored in `current_version.txt`)
3. **Update Process** (if newer version found):
   - Stops the Minecraft service
   - Backs up world data to `backups/` directory
   - Downloads the new server files
   - Extracts and installs them
   - Restarts the service
   - Updates the version file

## Safety Features

- **World Backup**: Automatically backs up world data before each update
- **Version Tracking**: Prevents unnecessary updates and service restarts
- **Service Verification**: Checks that the service started successfully after update
- **Error Handling**: Exits safely if any step fails

## Contributing

Feel free to submit issues and pull requests to improve the script!

## License

This project is open source and available under the MIT License.
