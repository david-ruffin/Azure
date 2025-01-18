# Define the username and new password
$username = "username" # Replace with the actual username
$newPassword = '' # Replace with the desired password

# Convert the new password to a secure string
$securePassword = ConvertTo-SecureString $newPassword -AsPlainText -Force
