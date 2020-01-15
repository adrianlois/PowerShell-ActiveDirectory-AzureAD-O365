﻿# Load Active Directory module
Import-Module ActiveDirectory

# LoadBox File Prompt: Select CSV file
# Comma separated values and UTF-8 encoding
New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'Documents (*.csv)|*.csv'
}
$FileImportCSV = $FileBrowser.ShowDialog()

# InputBox Text Prompt: Enter AD MemberOf groups
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$ADGroup = [Microsoft.VisualBasic.Interaction]::InputBox("Introduce el nombres de los grupos AD necesarios. `n`nPuedes introducir varios grupos separados por 'punto y coma' ;", "Grupos AD (MemberOf)", "")

# Create dump file users
$FileADUserExist = "%userprofile%\Desktop\ADUsers_exists.txt"

# Import file and start loop
Import-Csv $FileImportCSV | foreach-object {

# Set variables
    $Name = $_."Name"
    $DisplayName = $_."DisplayName"
    $GivenName = $_."GivenName"
    $SurName = $_."SurName"
    $SamAccountName = $_."SamAccountName"
    $UserPrincipalName = $_."UserPrincipalName"
    $EmailAddress = $_."EmailAddress"
    $Path = $_."Path"
    $PasswordUserAD = $_."AccountPassword"

# Check if user already exists (SamAccountName and EmailAddress)
        $SamAccountExist = Get-ADUser -Filter 'SamAccountName -Like $SamAccountName'
        $EmailExist = Get-ADUser -Filter 'EmailAddress -Like $EmailAddress'
        
        if ( -not $SamAccountExist -and -not $EmailExist ) {
            New-ADUser `
                -Name $Name `
                -DisplayName $DisplayName `
                -GivenName $GivenName `
                -SurName $SurName `
                -SamAccountName $SamAccountName `
                -UserPrincipalName $UserPrincipalName `
                -EmailAddress $EmailAddress `
                -Path $Path `
                -AccountPassword (ConvertTo-SecureString "$PasswordUserAD" -AsPlainText -force) `
                -Enabled $True `

                # Add group to users (MemberOf)
                Add-ADGroupMember -Identity "$ADGroup" -Members "$SamAccountName"
        } else {
            # File with the dump of existing users
                "El siguiente usuario ya existe en AD: " + $SamAccountName +" - "+ $EmailAddress +" - "+ $SamAccountExist | Out-File $FileADUserExist -Append
          }
        }
