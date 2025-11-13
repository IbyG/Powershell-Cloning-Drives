# ====== VARIABLES - MODIFY BEFORE RUNNING ======

# Get disk numbers for source (Windows OS drive) and target (external SSD)
# To find disk numbers, run: Get-Disk
# Identify your system disk (usually Disk 0) and external SSD (e.g., Disk 1, Disk 2, etc.)
$sourceDiskNumber = 0         # Typically your internal Windows drive number
$targetDiskNumber = 1         # The external SSD disk number to clone to

# Temporary location to store captured image file (ensure sufficient free space)
$imagePath = "C:\temp\windows_image.wim"

# ====== STEP 1: Prepare Target Disk ======

# Create a diskpart script to clean the target disk and create partitions
$diskpartScript = @"
select disk $targetDiskNumber
clean
convert gpt

rem Create EFI System Partition - 100 MB
create partition efi size=100
format quick fs=fat32 label="System"
assign letter=S

rem Create Microsoft Reserved Partition - 16 MB
create partition msr size=16

rem Create Windows Partition with remaining space
create partition primary
format quick fs=ntfs label="Windows"
assign letter=W
"@

# Execute diskpart with the above script to prepare target disk
$diskpartScript | Out-File -FilePath "$env:TEMP\diskpart_script.txt" -Encoding ASCII
diskpart /s "$env:TEMP\diskpart_script.txt"

# ====== STEP 2: Capture Windows Image from source C: drive ======

Write-Output "Capturing Windows image to $imagePath..."
dism.exe /Capture-Image /ImageFile:$imagePath /CaptureDir:C:\ /Name:"WindowsClone" /Compress:max /CheckIntegrity

# ====== STEP 3: Apply Image to target Windows partition (W:) ======

Write-Output "Applying image to external SSD Windows partition..."
dism.exe /Apply-Image /ImageFile:$imagePath /Index:1 /ApplyDir:W:\

# ====== STEP 4: Make the target disk bootable ======

# Copy boot files to the EFI System Partition (S:)
Write-Output "Creating boot files on external SSD..."
bcdboot.exe W:\Windows /s S: /f UEFI

Write-Output "Cloning completed successfully. Please safely eject the drive before rebooting."

# ===== NOTES =====
# - Ensure PowerShell is run as Administrator.
# - External SSD should be connected and recognized before running.
# - Back up data on target SSD; this will erase all content.
# - It's recommended to run this script from Windows PE or a recovery environment if cloning the live OS drive causes issues.
