[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.Application]::EnableVisualStyles();


################################################################################################################
### Begin: Script Information ##################################################################################
################################################################################################################

<#

    .SYNPSIS
        PowerShell GUI script to reset an Active Directory user`s password.
    .NOTES
        PowerShell GUI script to reset an Active Directory user`s password.
    .DESCRIPTION
        Author       : Aleksander Eggen Langlie
        Version      : 1.0
        Changelog    :
               - 1.0 (24-05-2017) Inital Version.
               
    .TODO
        - Add progress bar event
        - Log event
               
#>

################################################################################################################
### End: Script Information ####################################################################################
################################################################################################################

################################################################################################################
### Begin: Main function #######################################################################################
################################################################################################################

#region function Main
Function Main {
<#

    .SYNOPSIS
        The Main function starts the project application.
        
     .NOTES
        Use this function to initalize your script and to call GUI forms.
        
#>

ShowMainForm
}

################################################################################################################
### End: Main function #########################################################################################
################################################################################################################

Function ShowMainForm {

#-------------------------------------
# Region Form Objects
#-------------------------------------

$FormMain = New-Object System.Windows.Forms.Form
$GroupBoxID = New-Object System.Windows.Forms.GroupBox
$GroupBoxPersonalia = New-Object System.Windows.Forms.GroupBox
$GroupBoxUserInformation = New-Object System.Windows.Forms.GroupBox
$GroupBoxResetPassword = New-Object System.Windows.Forms.GroupBox
$GroupBoxInstructions = New-Object System.Windows.Forms.GroupBox
$GroupBoxLog = New-Object System.Windows.Forms.GroupBox
$GroupBoxInfo = New-Object System.Windows.Forms.GroupBox
$TextBoxID = New-Object System.Windows.Forms.TextBox
$ButtonSearchID = New-Object System.Windows.Forms.Button
$ProgressBarSearchID = New-Object System.Windows.Forms.ProgressBar
$LabelFirstName = New-Object System.Windows.Forms.Label
$LabelLastName = New-Object System.Windows.Forms.Label
$LabelPosition = New-Object System.Windows.Forms.Label
$TextBoxFirstName = New-Object System.Windows.Forms.TextBox
$TextBoxLastName = New-Object System.Windows.Forms.TextBox
$TextBoxPosition = New-Object System.Windows.Forms.TextBox
$LabelUserName = New-Object System.Windows.Forms.Label
$LabelAccountExpireDate = New-Object System.Windows.Forms.Label
$LabelPasswordExpireDate = New-Object System.Windows.Forms.Label
$TextBoxUserName = New-Object System.Windows.Forms.TextBox
$TextBoxAccountExpireDate = New-Object System.Windows.Forms.TextBox
$TextBoxPasswordExpireDate = New-Object System.Windows.Forms.TextBox
$TextBoxPasswordInput = New-Object System.Windows.Forms.TextBox
$TextBoxPasswordInputConfirm = New-Object System.Windows.Forms.Textbox
$ButtonResetPasswordConfirm = New-Object System.Windows.Forms.Button
$TextBoxInstructions = New-Object System.Windows.Forms.TextBox
$RichTextBoxLogField = New-Object System.Windows.Forms.RichTextBox
$TextBoxInfo = New-Object System.Windows.Forms.TextBox
$PictureBox = New-Object System.Windows.Forms.PictureBox
# EndRegion Form Objects


<#
# Create log file.
$LogFileTimeStamp = Get-Date -UFormat "%Y%m%d_%H%M%S"
$Global:LogFile = New-Item -ItemType File -Path "$env:USERPROFILE\Documents" -Name "FISBasis_Ugradert_$LogFileTimeStamp.log"
#>

Import-Module ActiveDirectory -ErrorAction "SilentlyContinue"
$global:OUs= "OU=Brukere,OU=ORL,OU=Norge-Nord,DC=fisbasis,DC=forsvaret,DC=no","OU=Soldater,OU=ORL,OU=Norge-Nord,DC=fisbasis,DC=forsvaret,DC=no"

Function ButtonSearchID_Click()
{
    if ($TextBoxID.Text.Length -eq 0)
    {
        $RichTextBoxLogField.SelectionColor = [Drawing.Color]::Red
        $RichTextBoxLogField.AppendText("ERROR: Ingen ansatt nummer registrert.`n")

    }
    else
    {
        $Global:UserID = $TextBoxID.Text
        $Global:UserDetails = ForEach($OU in $OUs) {Get-ADUser -Filter * -Properties Description, sAMAccountName, PasswordLastSet, AccountExpirationDate, Department -SearchBase $OU | where {$_.Description -like $UserID}
        }

    
        if ($UserDetails -eq $null)
        {
            $RichTextBoxLogField.SelectionColor = [Drawing.Color]::Red
            $RichTextBoxLogField.AppendText("ERROR: Ingen bruker med følgende ID-nr funnet: $UserID. Kontakt brukeradministrator for støtte.`n")
        }
        else
        {
    
            $RichTextBoxLogField.SelectionColor = [Drawing.Color]::Green
            $RichTextBoxLogField.AppendText("SUCCESS: Bruker med følgende ID-nr funnet: $UserID`n")
    
            $TextBoxFirstName.Text = $UserDetails.GivenName
            $TextBoxLastName.Text = $UserDetails.Surname
            $TextBoxPosition.Text = $UserDetails.Department
    
            $TextBoxUserName.Text = $UserDetails.sAMAccountName + "@fisbasis"
            $TextBoxAccountExpireDate.Text = $UserDetails.AccountExpirationDate
            $TextBoxPasswordExpireDate.Text = $UserDetails.PasswordLastSet.AddMonths(4)
            
            $TextBoxPasswordInput.Enabled = $True
            $TextBoxPasswordInputConfirm.Enabled = $True
            $ButtonResetPasswordConfirm.Enabled = $True
    
        }
    }
}



# Add ButtonSearchID click event
$ButtonSearchID.Add_Click({ButtonSearchID_Click})


Function ButtonResetPasswordConfirm_Click()
{
   if($TextBoxPasswordInput.Text -eq $TextBoxPasswordInputConfirm.Text)
   {
       Try
       {
            Set-ADAccountPassword -Identity $UserDetails.sAMAccountName -Reset -NewPassword (ConvertTo-SecureString -String $TextBoxPasswordInput.Text -AsPlainText -Force) -ErrorAction "Stop"
            $UserName = $UserDetails.sAMAccountName
            $RichTextBoxLogField.SelectionColor = [Drawing.Color]::Green
            $RichTextBoxLogField.AppendText("SUCCESS: Nytt passord for $UserName er nå satt.`n")
            
            Start-Sleep -s 2
            [System.Windows.Forms.MessageBox]::Show("Nytt passord er nå endret. Ditt nye passord utgår om 120 dager.")
            $TextBoxID.Text = ""
            $TextBoxFirstName.Text = ""
            $TextBoxLastName.Text = ""
            $TextBoxPosition.Text = ""
            $TextBoxUserName.Text = ""
            $TextBoxAccountExpireDate.Text = ""
            $TextBoxPasswordExpireDate.Text = ""
            $TextBoxPasswordInput.Text = ""
            $TextBoxPasswordInputConfirm.Text = ""
            $RichTextBoxLogField.Text = ""
            $TextBoxPasswordInput.Enabled = $False
            $TextBoxPasswordInputConfirm.Enabled = $False
            $ButtonResetPasswordConfirm.Enabled = $False
            
       }
       Catch
       {
            $RichTextBoxLogField.SelectionColor = [Drawing.Color]::Red
            $RichTextBoxLogField.AppendText("ERROR: Passordet møter ikke kravene for lengde, kompleksitet eller historikk krav for passord.`n-HUSK STOR BOKSTAV & TALL`n")    
       }
   }
   Else
   {
            $RichTextBoxLogField.SelectionColor = [Drawing.Color]::Red
            $RichTextBoxLogField.AppendText("ERROR: Passordene matcher ikke.`n")
   }
}   
  
# Add ButtonResetPasswordConfirm click event
$ButtonResetPasswordConfirm.Add_Click({ButtonResetPasswordConfirm_Click})


    # FormMain
    $FormMain.Text = "FISBasis_Ugradert Self-Service"
    $FormMain.Size = New-Object System.Drawing.Size(900,450)
    $FormMain.StartPosition = "CenterScreen"
    $FormMain.Topmost = $True
    $FormMain.MinimizeBox = $False
    $FormMain.MaximizeBox = $False
    $FormMain.FormBorderStyle = "FixedSingle"
    $FormMain.BackColor = "#DCDCDC"
    $FormMain.ShowIcon = $False

    # GroupBoxID
    $FormMain.Controls.Add($GroupBoxID)
    $GroupBoxID.Text = "SKANN FD-ID"
    $GroupBoxID.Size = New-Object System.Drawing.Size(300,100)
    $GroupBoxID.Location = New-Object System.Drawing.Size(10,10)
    $GroupBoxID.Visible = $True
    $GroupBoxID.Font = """,9,style=bold"
    
    # (GroupBoxID)-TextBoxID
    $GroupBoxID.Controls.Add($TextBoxID)
    $TextBoxID.Location = New-Object System.Drawing.Size(25,30)
    $TextBoxID.Size = New-Object System.Drawing.Size(180,60)
    $TextBoxID.Font = """,9,"
    
    # (GroupBoxID)-ButtonSearchID
    $GroupBoxID.Controls.Add($ButtonSearchID)
    $ButtonSearchID.Location = New-Object System.Drawing.Size(220,27)
    $ButtonSearchID.Size = New-Object System.Drawing.Size(50,25)
    $ButtonSearchID.Text = "SØK"
    
    # (GroupBoxID)-ProgressBarSearchID
    $GroupBoxID.Controls.Add($ProgressBarSearchID)
    $ProgressBarSearchID.Maximum = 100
    $ProgressBarSearchID.Minimum = 0
    $ProgressBarSearchID.Style = "Continuous"
    $ProgressBarSearchID.Location = New-Object System.Drawing.Size(15,75)
    $ProgressBarSearchID.Size = New-Object System.Drawing.Size(265,15)
  
    # GroupBoxPersonalia
    $FormMain.Controls.Add($GroupBoxPersonalia)
    $GroupBoxPersonalia.Text = "PERSONALIA"
    $GroupBoxPersonalia.Size = New-Object System.Drawing.Size(300,125)
    $GroupBoxPersonalia.Location = New-Object System.Drawing.Size(10,135)
    $GroupBoxPersonalia.Visible = $True
    $GroupBoxPersonalia.Font = """,9,style=bold"
    
    # (GroupBoxPersonalia)-LabelFirstName
    $GroupBoxPersonalia.Controls.Add($LabelFirstName)
    $LabelFirstName.Location = New-Object System.Drawing.Size(10,20)
    $LabelFirstName.Size = New-Object System.Drawing.Size(60,20)
    $LabelFirstName.Text = "Fornavn:"
    $LabelFirstName.Font = """,9,"
    
    # (GroupBoxPersonalia)-LabelLastName
    $GroupBoxPersonalia.Controls.Add($LabelLastName)
    $LabelLastName.Location = New-Object System.Drawing.Size(10,50)
    $LabelLastName.Size = New-Object System.Drawing.Size(60,20)
    $LabelLastName.Text = "Etternavn:"
    $LabelLastName.Font = """,9,"
   
    # (GroupBoxPersonalia)-LabelPosition
    $GroupBoxPersonalia.Controls.Add($LabelPosition)
    $LabelPosition.Location = New-Object System.Drawing.Size(10,80)
    $LabelPosition.Size = New-Object System.Drawing.Size(60,20)
    $LabelPosition.Text = "Stilling:"
    $LabelPosition.Font = """,9,"
    
    # (GroupBoxPersonalia)-TextBoxFirstName
    $GroupBoxPersonalia.Controls.Add($TextBoxFirstName)
    $TextBoxFirstName.Location = New-Object System.Drawing.Size(100,20)
    $TextBoxFirstName.Size = New-Object System.Drawing.Size(175,1)
    $TextBoxFirstName.Multiline = $false
    $TextBoxFirstName.Text = ""
    $TextBoxFirstName.enabled = $false
    $TextBoxFirstName.Font = """,9,style=regular"
   
    # (GroupBoxPersonalia)-TextBoxLastName
    $GroupBoxPersonalia.Controls.Add($TextBoxLastName)
    $TextBoxLastName.Location = New-Object System.Drawing.Size(100,50)
    $TextBoxLastName.Size = New-Object System.Drawing.Size(175,1)
    $TextBoxLastName.Multiline = $false
    $TextBoxLastName.Text = ""
    $TextBoxLastName.enabled = $false
    $TextBoxLastName.Font = """,9,style=regular"
    
    # (GroupBoxPersonalia)-TextBoxPosition
    $GroupBoxPersonalia.Controls.Add($TextBoxPosition)
    $TextBoxPosition.Location = New-Object System.Drawing.Size(100,80)
    $TextBoxPosition.Size = New-Object System.Drawing.Size(175,1)
    $TextBoxPosition.Multiline = $false
    $TextBoxPosition.Text = ""
    $TextBoxPosition.enabled = $false
    $TextBoxPosition.Font = """,9,style=regular"
 
    # GroupBoxUserInformation
    $FormMain.Controls.Add($GroupBoxUserInformation)
    $GroupBoxUserInformation.Text = "BRUKERINFORMASJON"
    $GroupBoxUserInformation.Size = New-Object System.Drawing.Size(300,125)
    $GroupBoxUserInformation.Location = New-Object System.Drawing.Size(350,135)
    $GroupBoxUserInformation.Visible = $True
    $GroupBoxUserInformation.Font = """,9,style=bold"
    
    # (GroupBoxUserInformation)-LabelUserName
    $GroupBoxUserInformation.Controls.Add($LabelUserName)
    $LabelUserName.Location = New-Object System.Drawing.Size(10,20)
    $LabelUserName.Size = New-Object System.Drawing.Size(80,20)
    $LabelUserName.Text = "Brukernavn:"
    $LabelUserName.Font = """,9,"
    
    # (GroupBoxUserInformation)-LabelAccountExpireDate
    $GroupBoxUserInformation.Controls.Add($LabelAccountExpireDate)
    $LabelAccountExpireDate.Location = New-Object System.Drawing.Size(10,50)
    $LabelAccountExpireDate.Size = New-Object System.Drawing.Size(80,20)
    $LabelAccountExpireDate.Text = "Bruker utgår:"
    $LabelAccountExpireDate.Font = """,9,"
    
    # (GroupBoxUserInformation)-LabelPasswordExpireDate
    $GroupBoxUserInformation.Controls.Add($LabelPasswordExpireDate)
    $LabelPasswordExpireDate.Location = New-Object System.Drawing.Size(10,80)
    $LabelPasswordExpireDate.Size = New-Object System.Drawing.Size(90,20)
    $LabelPasswordExpireDate.Text = "Passord utgår:"
    $LabelPasswordExpireDate.Font = """,9,"
    
    # (GroupBoxUserInformation)-TextBoxUserName
    $GroupBoxUserInformation.Controls.Add($TextBoxUserName)
    $TextBoxUserName.Location = New-Object System.Drawing.Size(100,20)
    $TextBoxUserName.Size = New-Object System.Drawing.Size(175,1)
    $TextBoxUserName.Multiline = $false
    $TextBoxUserName.Text = ""
    $TextBoxUserName.enabled = $false
    $TextBoxUserName.Font = """,9,style=regular"
 
    # (GroupBoxUserInformation)-TextBoxAccountExpireDate
    $GroupBoxUserInformation.Controls.Add($TextBoxAccountExpireDate)
    $TextBoxAccountExpireDate.Location = New-Object System.Drawing.Size(100,50)
    $TextBoxAccountExpireDate.Size = New-Object System.Drawing.Size(175,1)
    $TextBoxAccountExpireDate.Multiline = $false
    $TextBoxAccountExpireDate.Text = ""
    $TextBoxAccountExpireDate.enabled = $false
    $TextBoxAccountExpireDate.Font = """,9,style=regular"
    
    # (GroupBoxUserInformation)-TextBoxPasswordExpireDate
    $GroupBoxUserInformation.Controls.Add($TextBoxPasswordExpireDate)
    $TextBoxPasswordExpireDate.Location = New-Object System.Drawing.Size(100,80)
    $TextBoxPasswordExpireDate.Size = New-Object System.Drawing.Size(175,1)
    $TextBoxPasswordExpireDate.Multiline = $false
    $TextBoxPasswordExpireDate.Text = ""
    $TextBoxPasswordExpireDate.enabled = $false
    $TextBoxPasswordExpireDate.Font = """,9,style=regular"
    
    # GroupBoxResetPassword
    $FormMain.Controls.Add($GroupBoxResetPassword)
    $GroupBoxResetPassword.Text = "RESETT PASSORD"
    $GroupBoxResetPassword.Size = New-Object System.Drawing.Size(175,125)
    $GroupBoxResetPassword.Location = New-Object System.Drawing.Size(700,135)
    $GroupBoxResetPassword.Visible = $True
    $GroupBoxResetPassword.Font = """,9,style=bold"
    
     # (GroupBoxResetPassword)-TextBoxPasswordInput
    $GroupBoxResetPassword.Controls.Add($TextBoxPasswordInput)
    $TextBoxPasswordInput.Location = New-Object System.Drawing.Size(10,30)
    $TextBoxPasswordInput.Size = New-Object System.Drawing.Size(150,1)
    $TextBoxPasswordInput.Multiline = $false
    $TextBoxPasswordInput.PasswordChar = "*"
    $TextBoxPasswordInput.enabled = $false
    $TextBoxPasswordInput.Font = """,9,"
    
    # (GroupBoxResetPassword)-TextBoxPasswordInputConfirm
    $GroupBoxResetPassword.Controls.Add($TextBoxPasswordInputConfirm)
    $TextBoxPasswordInputConfirm.Location = New-Object System.Drawing.Size(10,60)
    $TextBoxPasswordInputConfirm.Size = New-Object System.Drawing.Size(150,1)
    $TextBoxPasswordInputConfirm.Multiline = $false
    $TextBoxPasswordInputConfirm.PasswordChar = "*"
    $TextBoxPasswordInputConfirm.enabled = $false
    $TextBoxPasswordInputConfirm.Font = """,9,"
    
    # (GroupBoxResetPassword)-ButtonResetPasswordConfirm
    $GroupBoxResetPassword.Controls.Add($ButtonResetPasswordConfirm)
    $ButtonResetPasswordConfirm.Location = New-Object System.Drawing.Size(10,90)
    $ButtonResetPasswordConfirm.Size = New-Object System.Drawing.Size(150,20)
    $ButtonResetPasswordConfirm.Text = "Bekreft"
    $ButtonResetPasswordConfirm.Enabled = $False
    
    # GroupBoxInstructions
    $FormMain.Controls.Add($GroupBoxInstructions)
    $GroupBoxInstructions.Text = "INSTRUKSJONER"
    $GroupBoxInstructions.Size = New-Object System.Drawing.Size(300,100)
    $GroupBoxInstructions.Location = New-Object System.Drawing.Size(350,10)
    $GroupBoxInstructions.Visible = $True
    $GroupBoxInstructions.Font = """,9,style=bold"
    
    # (GroupBoxInstructions)-TextBoxInstructions
    $GroupBoxInstructions.Controls.Add($TextBoxInstructions)
    $TextBoxInstructions.Location = New-Object System.Drawing.Size(10,20)
    $TextBoxInstructions.Size = New-Object System.Drawing.Size(280,70)
    $TextBoxInstructions.Multiline = $True
    $TextBoxInstructions.Text = "1. Tast inn ansatt nr. `r`n2. Skriv inn nytt passord og bekreft nytt passord. `r`n3. Trykk bekreft. `r`n4. Ditt nye passord er nå satt.                                           "
    $TextBoxInstructions.enabled = $False
    $TextBoxInstructions.Font = """,9,"
    
    # GroupBoxLog
    $FormMain.Controls.Add($GroupBoxLog)
    $GroupBoxLog.Text = "LOGG"
    $GroupBoxLog.Size = New-Object System.Drawing.Size(640,125)
    $GroupBoxLog.Location = New-Object System.Drawing.Size(10,275)
    $GroupBoxLog.Visible = $True
    $GroupBoxLog.Font = """,9,style=bold"
    
    # (GroupBoxLog)-TextBoxLogField
    $GroupBoxLog.Controls.Add($RichTextBoxLogField)
    $RichTextBoxLogField.Text = ""
    $RichTextBoxLogField.Size = New-Object System.Drawing.Size(615,95)
    $RichTextBoxLogField.Location = New-Object System.Drawing.Size(10,20)
    $RichTextBoxLogField.Font = """,9,"    
    $RichTextBoxLogField.ReadOnly = $True
    $RichTextBoxLogField.Multiline = $True
    
    # GroupBoxInfo
    $FormMain.Controls.Add($GroupBoxInfo)
    $GroupBoxInfo.Text = "INFO"
    $GroupBoxInfo.Size = New-Object System.Drawing.Size(175,125)
    $GroupBoxInfo.Location = New-Object System.Drawing.Size(700,275)
    $GroupBoxInfo.Visible = $True
    $GroupBoxInfo.Font = """,9,style=bold"
    
    
    # (GroupBoxInfo)-TextBoxInfo
    $GroupBoxInfo.Controls.Add($TextBoxInfo)
    $TextBoxInfo.Text = "Laget av: A. Langlie Versjon: 1.0       Kontaktinfo: 474 59 267"
    $TextBoxInfo.Size = New-Object System.Drawing.Size(150,95)
    $TextBoxInfo.Location = New-Object System.Drawing.Size(10,20)
    $TextBoxInfo.Font = """,9,"    
    $TextBoxInfo.Enabled = $False
    $TextBoxInfo.Multiline = $True
    
    # PictureBox
    $FormMain.Controls.Add($PictureBox)
    $PictureBox.Width = "240"
    $PictureBox.Height = "120"
    $PictureBox.SizeMode = "StretchImage"
    $PictureBox.Location = New-Object System.Drawing.Point(650,-10)
    $PictureBox.ImageLocation = "E:\FISBasis_Ugradert\Forsvaret.png"
    

   
   
    $FormMain.ShowDialog() | Out-Null



}
Main