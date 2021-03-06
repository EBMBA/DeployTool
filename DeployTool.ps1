Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
[Void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 
foreach ($item in $(gci .\assembly\ -Filter *.dll).name) {
    [Void][System.Reflection.Assembly]::LoadFrom("assembly\$item")
}
#########################################################################
#                        Import Module                                  #
#########################################################################
$path = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)

Import-Module -Name "$Path\services\functions.psm1"
Import-Module -Name MDTDB
#########################################################################
#                        Load Main Panel                                #
#########################################################################

$Global:pathPanel= split-path -parent $MyInvocation.MyCommand.Definition

function LoadXaml ($filename){
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}
$XamlMainWindow=LoadXaml($pathPanel+"\main.xaml")
$reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($reader)



#########################################################################
#                       Functions                       								#
#########################################################################
$XamlMainWindow.SelectNodes("//*[@Name]") | %{
    try {Set-Variable -Name "$("WPF_"+$_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
    }
 
Function Get-FormVariables{
  if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
  write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
  get-variable *WPF*
}
  #Get-FormVariables

Function New-MahappsMessage {
  [CmdletBinding()]
  param (
    
    [Parameter(Mandatory=$true)]
    [String]$title,
    [Parameter(Mandatory=$true)]
    [String]$Message
    
  )
  
  $Button_Style = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
  $okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative  
  $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,$title,$Message,$okAndCancel, $Button_Style)   

  
}


function Decode-SecureStringPassword
{
    [CmdletBinding()]
    [Alias('dssp')]
    [OutputType([string])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,                   
                   Position=0) ]     
        $password 
    )
    Begin
    {
    }
    Process
    {        
       return [System.Runtime.InteropServices.Marshal]::PtrToStringUni([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password))              
    }
    End
    {}
}

# Verifie si le champ est vide ou rempli par des espaces
function Validate-IsEmptyTrim ([string] $field) {

  if($field -eq $null -or $field.Trim().Length -eq 0) {
    return $true    
  }
      
  return $false
}
#########################################################################
#                       Page Recherche              		                #
######################################################################### 

$WPF_Filter.Add_Click({
  $WPF_FilterTextBox.Text='test'
})

#########################################################################
#                       Page Identification        		                #
#########################################################################
$PathLogin = "$path\password.pwd"
$PathParameters = "$path\parameters.pwd"
#$PresencePassword = Test-Path $PathPassword

$Form.Add_ContentRendered({
  $WPF_Connexion.IsEnabled = "True"
  $Script:PresencePassword = Test-Path $PathLogin
  $Script:PresenceParameters = Test-Path $PathParameters
  if(($false -eq $Script:PresencePassword) -and ($true -eq $Script:PresenceParameters)){
    $importParameters = Import-Clixml -Path $PathParameters
    $Script:ServeurMDT = $importParameters.ServeurMDT
    $Script:DeploymentShareSMB = $importParameters.DeploymentShareSMB
    $Script:ServeurSQL = $importParameters.ServeurSQL
    $Script:OrgName = $importParameters.OrgName
    $WPF_Onglet_Identification.IsSelected="True"
    New-MahappsMessage -title "Erreur" -Message "Entrez les identifiants de jonction de domaine"
    #$password = Get-Credential
    #Export-Clixml -path $path\password.pwd -InputObject $password
  }
  elseif (($true -eq $Script:PresencePassword) -and ($false -eq $Script:PresenceParameters)) {
    $import=Import-Clixml -Path $PathLogin
    $Script:Password = Decode-SecureStringPassword $import.Password
    $Script:DomainAdmin = $import.UserName
    $WPF_Onglet_Identification.IsSelected="True"
    New-MahappsMessage -title "Erreur" -Message "Entrez les paramètres généraux liées aux serveurs"
  }
  elseif (($false -eq $Script:PresencePassword) -and ($false -eq $Script:PresenceParameters)) {
    $WPF_Onglet_Identification.IsSelected="True"
    New-MahappsMessage -title "Erreur" -Message "Entrez les paramètres généraux liées aux serveurs et les identifiants de jonction de domaine"
  }
  else {
    $import=Import-Clixml -Path $PathLogin
    $Script:Password = Decode-SecureStringPassword $import.Password
    $Script:DomainAdmin = $import.UserName
    $importParameters = Import-Clixml -Path $PathParameters
    $Script:ServeurMDT = $importParameters.ServeurMDT
    $Script:DeploymentShareSMB = $importParameters.DeploymentShareSMB
    $Script:ServeurSQL = $importParameters.ServeurSQL
    $Script:OrgName = $importParameters.OrgName
  } 
})


$WPF_ExitI.Add_Click({
  $Form.Close()
})

<#
$WPF_Password.Add_PasswordChanged({
  if(($WPF_MDTJD.Text.Length -ne 0) -and ($WPF_Password.Password.Length -ne 0)){
    $WPF_Connexion.IsEnabled = "True"
  }
  else {
    $WPF_Connexion.IsEnabled = "False"
  }
})

$WPF_MDTJD.Add_TextChanged({
  if(($WPF_MDTJD.Text.Length -ne 0) -and ($WPF_Password.Password.Length -ne 0)){
    $WPF_Connexion.IsEnabled = "True"
  }
  else {
    $WPF_Connexion.IsEnabled = "False"
  }
})
#>

$WPF_Connexion.Add_Click({
  if (Validate-IsEmptyTrim($WPF_MDTJD.Text)) {
    $parameters = New-Object -TypeName PSCustomObject -Property @{
      "ServeurMDT" = $($WPF_ServeurMDT.Text.Trim())
      "DeploymentShareSMB" = $($WPF_DeploymentShareSMB.Text.Trim())
      "ServeurSQL" = $($WPF_ServeurSQL.Text.Trim())
      "OrgName" = $($WPF_OrgName.Text.Trim())
    }
    Export-Clixml -Path $PathParameters -InputObject $parameters
    $importParameters = Import-Clixml -Path $PathParameters
    $Script:ServeurMDT = $importParameters.ServeurMDT
    $Script:DeploymentShareSMB = $importParameters.DeploymentShareSMB
    $Script:ServeurSQL = $importParameters.ServeurSQL
    $Script:OrgName = $importParameters.OrgName
    $title = "DeployTools"
    $Message = "Paramètres enregistrés"
    $Type = "Info"

    try {
      $titleConnexion = "DeployTools"
      $MessageConnexion = "Connexion au serveur de base de donnée $Script:ServeurSQL, merci de patienter"
      $TypeConnexion = "Info"

      [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
      $notify = new-object system.windows.forms.notifyicon
      $notify.icon = $icon
      $notify.visible = $true
      $notify.showballoontip(10,$titleConnexion,$MessageConnexion, [system.windows.forms.tooltipicon]::$TypeConnexion)

      Connect-MDTDatabase -sqlServer $Script:ServeurSQL -instance SQLEXPRESS -database MDT
      
      $titleConnexion = "DeployTools"
      $MessageConnexion = "Vous êtes connecté au serveur de base de donnée $Script:ServeurSQL"
      $TypeConnexion = "Info"

      [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
      $notify = new-object system.windows.forms.notifyicon
      $notify.icon = $icon
      $notify.visible = $true
      $notify.showballoontip(10,$titleConnexion,$MessageConnexion, [system.windows.forms.tooltipicon]::$TypeConnexion)
    }
    catch {
      $titleConnexion = "DeployTools"
      $MessageConnexion = "Le serveur de base de donnée $Script:ServeurSQL n'est pas accessible"
      $TypeConnexion = "Error"

      [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
      $notify = new-object system.windows.forms.notifyicon
      $notify.icon = $icon
      $notify.visible = $true
      $notify.showballoontip(10,$titleConnexion,$MessageConnexion, [system.windows.forms.tooltipicon]::$TypeConnexion)
    }

    [XML]$TaskSequencesFile = Get-Content -path \\$Script:ServeurMDT\$Script:DeploymentShareSMB\Control\TaskSequences.xml
    $TaskSequencesList = $TaskSequencesFile.tss.ts

    foreach ($TaskSequence in $TaskSequencesList) {
      $GroupsList = New-Object PSObject
      $GroupsList = $GroupsList | Add-Member NoteProperty ID $TaskSequence.ID -passthru
      $GroupsList = $GroupsList | Add-Member NoteProperty "Nom de la séquence" $TaskSequence.Name -passthru	
      $WPF_TaskSequences.Items.Add($GroupsList) > $null
    }
    $Script:PresenceParameters = Test-Path $PathParameters
    if(($null -eq $TaskSequencesList) -and ($true -eq $Script:PresenceParameters)){
      New-MahappsMessage -title "Erreur" -Message "Aucune TaskSequences d'active"
    }
  }
  elseif (Validate-IsEmptyTrim($WPF_ServeurMDT.Text)) {
    $DomainAdminEnter = $WPF_MDTJD.Text.Trim()
    $password = ConvertTo-SecureString $WPF_Password.Password -AsPlainText -Force  
    $login = New-Object System.Management.Automation.PSCredential -ArgumentList $DomainAdminEnter,$password
    Export-Clixml -path $path\password.pwd -InputObject $login
    $import=Import-Clixml -Path $PathLogin
    $Script:Password=Decode-SecureStringPassword $import.Password
    $Script:DomainAdmin = $import.UserName
    $title = "DeployTools"
    $Message = "Identifiants enregistrés"
    $Type = "Info"
  }

  elseif (-not(Validate-IsEmptyTrim($WPF_ServeurMDT.Text)) -and -not(Validate-IsEmptyTrim($WPF_MDTJD.Text))) {
    $parameters = New-Object -TypeName PSCustomObject -Property @{
      "ServeurMDT" = $($WPF_ServeurMDT.Text.Trim())
      "DeploymentShareSMB" = $($WPF_DeploymentShareSMB.Text.Trim())
      "ServeurSQL" = $($WPF_ServeurSQL.Text.Trim())
      "OrgName" = $($WPF_OrgName.Text.Trim())
    }
    Export-Clixml -Path $PathParameters -InputObject $parameters
    $importParameters = Import-Clixml -Path $PathParameters
    $Script:ServeurMDT = $importParameters.ServeurMDT
    $Script:DeploymentShareSMB = $importParameters.DeploymentShareSMB
    $Script:ServeurSQL = $importParameters.ServeurSQL
    $Script:OrgName = $importParameters.OrgName
    $DomainAdminEnter = $WPF_MDTJD.Text.Trim()
    $password = ConvertTo-SecureString $WPF_Password.Password -AsPlainText -Force  
    $login = New-Object System.Management.Automation.PSCredential -ArgumentList $DomainAdminEnter,$password
    Export-Clixml -path $path\password.pwd -InputObject $login
    $import=Import-Clixml -Path $PathLogin
    $Script:Password=Decode-SecureStringPassword $import.Password
    $Script:DomainAdmin = $import.UserName
    $title = "DeployTools"
    $Message = "Identifiants et paramètres enregistrés"
    $Type = "Info"

    try {
      $titleConnexion = "DeployTools"
      $MessageConnexion = "Connexion au serveur de base de donnée $Script:ServeurSQL, merci de patienter"
      $TypeConnexion = "Info"

      [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
      $notify = new-object system.windows.forms.notifyicon
      $notify.icon = $icon
      $notify.visible = $true
      $notify.showballoontip(10,$titleConnexion,$MessageConnexion, [system.windows.forms.tooltipicon]::$TypeConnexion)

      Connect-MDTDatabase -sqlServer $Script:ServeurSQL -instance SQLEXPRESS -database MDT
      
      $titleConnexion = "DeployTools"
      $MessageConnexion = "Vous êtes connecté au serveur de base de donnée $Script:ServeurSQL"
      $TypeConnexion = "Info"

      [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
      $notify = new-object system.windows.forms.notifyicon
      $notify.icon = $icon
      $notify.visible = $true
      $notify.showballoontip(10,$titleConnexion,$MessageConnexion, [system.windows.forms.tooltipicon]::$TypeConnexion)
    }
    catch {
      $titleConnexion = "DeployTools"
      $MessageConnexion = "Le serveur de base de donnée $Script:ServeurSQL n'est pas accessible"
      $TypeConnexion = "Error"

      [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
      $notify = new-object system.windows.forms.notifyicon
      $notify.icon = $icon
      $notify.visible = $true
      $notify.showballoontip(10,$titleConnexion,$MessageConnexion, [system.windows.forms.tooltipicon]::$TypeConnexion)
    }

    [XML]$TaskSequencesFile = Get-Content -path \\$Script:ServeurMDT\$Script:DeploymentShareSMB\Control\TaskSequences.xml
    $TaskSequencesList = $TaskSequencesFile.tss.ts

    foreach ($TaskSequence in $TaskSequencesList) {
      $GroupsList = New-Object PSObject
      $GroupsList = $GroupsList | Add-Member NoteProperty ID $TaskSequence.ID -passthru
      $GroupsList = $GroupsList | Add-Member NoteProperty "Nom de la séquence" $TaskSequence.Name -passthru	
      $WPF_TaskSequences.Items.Add($GroupsList) > $null
    }
    
    if(($null -eq $TaskSequencesList)){
      New-MahappsMessage -title "Erreur" -Message "Aucune TaskSequences d'active"
    }
  }

  [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
  $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
  $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
  $notify = new-object system.windows.forms.notifyicon
  $notify.icon = $icon
  $notify.visible = $true
  $notify.showballoontip(10,$Title,$Message, [system.windows.forms.tooltipicon]::$Type)
})

#########################################################################
#                       Page Paramètres          		                    #
#########################################################################
$Form.Add_ContentRendered({
  switch ($WPF_ServiceView.Visibility ) {
    'Visible' { $Script:SMSTSORGNAMEs="Deploiement du service $($WPF_Service.SelectedItem.ToString()) de $Script:OrgName" }
    'Collapsed' { $Script:SMSTSORGNAMEs="Deploiement d'un serveur de $Script:OrgName" }
    Default {}
  }
  $FinishActions=("LOGOFF","SHUTDOWN","REBOOT","blank")
  $TimeZoneNames=("Romance Standard Time", "GMT Standard Time","W. Europe Standard Time")
  $SkipFinalSummarys=("NO","YES")
  $UILangages=("fr-FR", "en-US", "es-ES", "en-GB", "de-DE")
  $InputLocales=("fr-FR", "en-US", "es-ES", "en-GB", "de-DE")
  $KeyboardLocales=("fr-FR", "en-US", "es-ES", "en-GB", "de-DE")

  foreach ($UILangage in $UILangages) {
    $WPF_UILangage.Items.Add($UILangage)
  }

  foreach ($InputLocale in $InputLocales) {
    $WPF_InputLocale.Items.Add($InputLocale)
  }

  foreach ($KeyboardLocale in $KeyboardLocales) {
    $WPF_KeyboardLocale.Items.Add($KeyboardLocale)
  }

  foreach ($FinishAction in $FinishActions) {
    $WPF_FinishAction.Items.Add($FinishAction)
  }

  foreach ($TimeZoneName in $TimeZoneNames) {
    $WPF_TimeZoneName.Items.Add($TimeZoneName)
  }

  foreach ($SkipFinalSummary in $SkipFinalSummarys) {
    $WPF_SkipFinalSummary.Items.Add($SkipFinalSummary)
  }

  $WPF_SMSTSORGNAME.Text=$Script:SMSTSORGNAMEs
  $WPF_FinishAction.SelectedIndex=0
  $WPF_SkipFinalSummary.SelectedIndex=0
  $WPF_TimeZoneName.SelectedIndex=0
  $WPF_UILangage.SelectedIndex=0
  $WPF_InputLocale.SelectedIndex=0
  $WPF_KeyboardLocale.SelectedIndex=0
  $WPF_Home_Page=$DomainRoot
  $WPF_Enregister.IsEnabled="True"
})

$WPF_ExitP.Add_Click({
  $Form.Close()
})

$WPF_Service.add_SelectionChanged({
  switch ($WPF_ServiceView.Visibility ) {
    'Visible' { $Script:SMSTSORGNAMEs="Deploiement du service $($WPF_Service.SelectedItem.ToString()) de $Script:OrgName" }
    'Collapsed' { $Script:SMSTSORGNAMEs="Deploiement d'un serveur de $Script:OrgName" }
    Default {}
  }
  $WPF_SMSTSORGNAME.Text=$Script:SMSTSORGNAMEs
})

$WPF_Machine.add_SelectionChanged({
  switch ($WPF_ServiceView.Visibility ) {
    'Visible' { $Script:SMSTSORGNAMEs="Deploiement du service $($WPF_Service.SelectedItem.ToString()) de $Script:OrgName" }
    'Collapsed' { $Script:SMSTSORGNAMEs="Deploiement d'un serveur de $Script:OrgName" }
    Default {$Script:SMSTSORGNAMEs="Deploiement d'un serveur de $Script:OrgName" }
  }
  $WPF_SMSTSORGNAME.Text=$Script:SMSTSORGNAMEs
})

$WPF_UILangage.add_SelectionChanged({
  $WPF_InputLocale.SelectedIndex=$WPF_UILangage.SelectedIndex
  $WPF_KeyboardLocale.SelectedIndex=$WPF_UILangage.SelectedIndex
})

$WPF_Enregister.Add_Click({
  $WPF_Onglet_Deploiement.IsSelected="True"
})

$WPF_Defaut.Add_Click({
  switch ($WPF_ServiceView.Visibility ) {
    'Visible' { $Script:SMSTSORGNAMEs="Deploiement du service $($WPF_Service.SelectedItem.ToString()) de $Script:OrgName" }
    'Collapsed' { $Script:SMSTSORGNAMEs="Deploiement d'un serveur de $Script:OrgName" }
    Default {}
  }

  $WPF_SMSTSORGNAME.Text=$Script:SMSTSORGNAMEs
  $WPF_FinishAction.SelectedIndex=0
  $WPF_SkipFinalSummary.SelectedIndex=0
  $WPF_TimeZoneName.SelectedIndex=0
  $WPF_UILangage.SelectedIndex=0
  $WPF_InputLocale.SelectedIndex=0
  $WPF_KeyboardLocale.SelectedIndex=0
  $WPF_Home_Page=$DomainRoot
})
#########################################################################
#                       DATA       						       		                #
#########################################################################

#Données obligatoires à modifier 
#$ServeurMDT = "CR-SRV-MDT1"
#$DeploymentShareSMB = "DEPLOYMENTSHARE$"
#$ServeurSQL = "CR-SRV-MDT1"
#$OrgName = "CHL"
$DomainRoot = (get-ADDomain).DNSRoot
$JoinDomain = "$DomainRoot"
$DomainAdminDomain = "$DomainRoot"


$WPF_Theme.Add_Click({
  $Theme1 = [ControlzEx.Theming.ThemeManager]::Current.DetectTheme($form)
   $my_theme = ($Theme1.BaseColorScheme)
 If($my_theme -eq "Light")
   {
           [ControlzEx.Theming.ThemeManager]::Current.ChangeThemeBaseColor($form,"Dark")
           $WPF_Theme.ToolTip = "Theme Dark"
   }
 ElseIf($my_theme -eq "Dark")
   {					
           [ControlzEx.Theming.ThemeManager]::Current.ChangeThemeBaseColor($form,"Light")
           $WPF_Theme.ToolTip = "Theme Light"
   }		
})

$WPF_BaseColor.Add_Click({

   $Script:Colors=@()
   $Accent = [ControlzEx.Theming.ThemeManager]::Current.ColorSchemes
   foreach ($item in $Accent)
   {
       $Script:Colors += $item
   }

   $Value = $Script:Colors[$(Get-Random -Minimum 0 -Maximum 23)]
   [ControlzEx.Theming.ThemeManager]::Current.ChangeThemeColorScheme($form ,$Value)
   $WPF_BaseColor.ToolTip = "BaseColor : $Value"

})

$WPF_Gitlab.Add_Click({
  start https://gitlab.com/Vikzer
  start https://gitlab.com/EBMBA
})

##############################################################################
#                           CONNECTION A LA  BDD                             #
############################################################################## 
$Form.Add_ContentRendered({
  if($true -eq $Script:PresenceParameters){
    try {
      $title = "DeployTools"
      $Message = "Connexion au serveur de base de donnée $Script:ServeurSQL, merci de patienter"
      $Type = "Info"

      [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
      $notify = new-object system.windows.forms.notifyicon
      $notify.icon = $icon
      $notify.visible = $true
      $notify.showballoontip(10,$Title,$Message, [system.windows.forms.tooltipicon]::$Type)

      Connect-MDTDatabase -sqlServer $Script:ServeurSQL -instance SQLEXPRESS -database MDT
      
      $title = "DeployTools"
      $Message = "Vous êtes connecté au serveur de base de donnée $Script:ServeurSQL"
      $Type = "Info"

      [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
      $notify = new-object system.windows.forms.notifyicon
      $notify.icon = $icon
      $notify.visible = $true
      $notify.showballoontip(10,$Title,$Message, [system.windows.forms.tooltipicon]::$Type)
    }
    catch {
      $title = "DeployTools"
      $Message = "Le serveur de base de donnée $Script:ServeurSQL n'est pas accessible"
      $Type = "Error"

      [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
      $notify = new-object system.windows.forms.notifyicon
      $notify.icon = $icon
      $notify.visible = $true
      $notify.showballoontip(10,$Title,$Message, [system.windows.forms.tooltipicon]::$Type)
    }
  }
})

##############################################################################
#                           AFFICHAGE CHOIX DE SERVICE                       #
############################################################################## 
[String]$MachineSelect = ""
$WPF_Machine.add_SelectionChanged({
  
  $MachineSelect = $WPF_Machine.SelectedItem.ToString()
  if( $MachineSelect -eq "Fixe" -or $MachineSelect -eq "Portable" ){
    $WPF_ServiceView.Visibility = "Visible"
    $WPF_ComputerName.IsEnabled = $false
    $WPF_ComputerName.Text = 'Générez son nom'
    $WPF_Generer.IsEnabled= $true
  }
  else{
    $WPF_ComputerName.Text =''
    $WPF_ServiceView.Visibility = "Collapsed"
    $WPF_Generer.IsEnabled= $false
    $WPF_ComputerName.IsEnabled = $true
  }

  return 
})

##############################################################################
#           SERVICE || TYPE DE MACHINE || SITE && REMPLISSAGE AUTOMATIQUE    #
############################################################################## 
$Services = ('Informatique','Medecins','Infirmieres','Aides-Soignantes','Direction','Laboratoire','Recherche et Developpement','Radiologie','Pharmacie','Administration','Accueil','Ressources Humaines')
$Sites = ('Croix-Rousse')
$Machines = ('Fixe', 'Portable', 'Serveur')
# Ajout des services, des sites et des types de machines dans les combobox 
foreach ($item in $Services) {
  $WPF_Service.Items.Add($item) | Out-Null
}

foreach ($item in $Sites) {
  $WPF_Site.Items.Add($item) | Out-Null
}

foreach ($item in $Machines) {
  $WPF_Machine.Items.Add($item) | Out-Null
}

<#$WPF_Search.Add_Click({
  $Recherche='12'
  $ResultSearch = Search -Filter $Recherche
  if ($ResultSearch -eq $Null) {
    New-MahappsMessage -title 'Recherche' -Message 'Aucun element trouvé'
  }
  else {
    New-MahappsMessage -title 'Recherche' -Message $ResultSearch
  }


})#>
$WPF_Service.SelectedIndex = 0
$WPF_Site.SelectedIndex = 0
$WPF_Machine.SelectedIndex = 0

# Remplissage automatique du champ ComputerName
$WPF_Generer.Add_Click({
  $Service = $WPF_Service.SelectedItem.ToString()
  $Site = $WPF_Site.SelectedItem.ToString()
  $Machine = $WPF_Machine.SelectedItem.ToString()
  $WPF_ComputerName.Text= AutoNameComputer -Site $Site -Service $Service -Machine $Machine
})

#TODO verifier si machine est serveur 
<#$WPF_Service.add_SelectionChanged -and $WPF_Site.add_SelectionChanged -and $WPF_Machine.add_SelectionChanged({
    Write-Host "Lancement fonction"
    if ($MachineSelect -eq "Client" -and $WPF_Service.SelectedIndex -ne 0){
      $Service = $WPF_Service.SelectedItem.ToString()
      $Site = $WPF_Site.SelectedItem.ToString()
      $Machine = $WPF_Machine.SelectedItem.ToString()

      $WPF_ComputerName.text= AutoNameComputer -Site $Site -Service $Service -Machine $Machine
      Write-Host "Lancement fonction"
    }
  })


#>

##############################################################################
#                           ACTIVATION DE LA VALIDATION                                          #
############################################################################## 
$WPF_MacAddress.Add_TextChanged({
	If (($WPF_MacAddress.text -match "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$" ) -and ($WPF_ComputerName.text.Length -ge 7)){
    $WPF_MacAddress.Background = [System.Windows.Media.Brushes]::PaleGreen
    $WPF_Create.IsEnabled = $True
  }
  else{
    $WPF_MacAddress.Background = [System.Windows.Media.Brushes]::PaleVioletRed
    $WPF_Create.IsEnabled = $false
  }
})

$WPF_ComputerName.Add_TextChanged({
	If (($WPF_ComputerName.text.Length -ge 7) -and ($WPF_MacAddress.text -match "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$" )){
    $WPF_MacAddress.Background = [System.Windows.Media.Brushes]::PaleGreen
    $WPF_Create.IsEnabled = $True

  }
  else{
    $WPF_MacAddress.Background = [System.Windows.Media.Brushes]::PaleVioletRed
    $WPF_Create.IsEnabled = $false
  }
})

##############################################################################
#                  RECHERCHE / AFFICHAGE SEQUENCES DE TACHES                 #
############################################################################## 
#$Script:PresenceParameters = Test-Path $PathParameters
$Form.Add_ContentRendered({
  if ($Script:PresenceParameters) {
    [XML]$TaskSequencesFile = Get-Content -path \\$Script:ServeurMDT\$Script:DeploymentShareSMB\Control\TaskSequences.xml
    $TaskSequencesList = $($TaskSequencesFile.tss.ts | Where-Object {$_.enable -eq 'True'})
  
    foreach ($TaskSequence in $TaskSequencesList) {
      $GroupsList = New-Object PSObject
      $GroupsList = $GroupsList | Add-Member NoteProperty ID $TaskSequence.ID -passthru
      $GroupsList = $GroupsList | Add-Member NoteProperty "Nom de la séquence" $TaskSequence.Name -passthru	      
      $WPF_TaskSequences.Items.Add($GroupsList) > $null
    }
  }

  if(($null -eq $TaskSequencesList) -and ($true -eq $Script:PresenceParameters)){
    New-MahappsMessage -title "Erreur" -Message "Aucune TaskSequences d'active"
  }
})
<#
if ($Script:PresenceParameters) {
  [XML]$TaskSequencesFile = Get-Content -path \\$Script:ServeurMDT\$Script:DeploymentShareSMB\Control\TaskSequences.xml
  $TaskSequencesList = $TaskSequencesFile.tss.ts

  foreach ($TaskSequence in $TaskSequencesList) {
    $GroupsList = New-Object PSObject
    $GroupsList = $GroupsList | Add-Member NoteProperty ID $TaskSequence.ID -passthru
    $GroupsList = $GroupsList | Add-Member NoteProperty "Nom de la séquence" $TaskSequence.Name -passthru	
    $WPF_TaskSequences.Items.Add($GroupsList) > $null
  }
}


# Erreur aucune TS active
$Form.Add_ContentRendered({
  if(($null -eq $TaskSequencesList) -and ($true -eq $Script:PresenceParameters)){
    New-MahappsMessage -title "Erreur" -Message "Aucune TaskSequences d'active"
  }
})
#>
##############################################################################
#                  INTERACTION AVEC LA BASE DE DONNEE MDT                    #
############################################################################## 
$WPF_Create.Add_Click({
  try {
    $Machine = $WPF_Machine.SelectedItem.ToString()
    switch ($($WPF_InputLocale.SelectedItem.ToString())) {
      "fr-FR" { $Script:InputLocale="040c:0000040c" }
      "en-US" { $Script:InputLocale="0409:00000409" }
      "es-ES" { $Script:InputLocale="0c0a:0000040a" }
      "en-GB" { $Script:InputLocale="0809:00000809" }
      "de-DE" { $Script:InputLocale="0407:00000407" }
    }
    switch ($Machine) {
      "Serveur" {
        $MacAddress = $WPF_MacAddress.Text
        $ComputerName = $WPF_ComputerName.Text
        $TaskSequenceSelect = $($WPF_TaskSequences.SelectedItems).ID
        $SearchBase=(Get-ADDomain).DistinguishedName
        $MachineObjectOU =$((Get-ADOrganizationalUnit -filter {Name -like $Machine} -SearchBase $SearchBase).DistinguishedName)  
        New-MDTComputer -macAddress "$MacAddress" -description $ComputerName -settings @{ 
          OSInstall='YES' ; 
          OSDComputerName="$ComputerName"; 
          ComputerName="$ComputerName"; 
          FullName="$ComputerName"; 
          OrgName= "$Script:OrgName";
          TaskSequenceID="$TaskSequenceSelect"; 
          FinishAction="$($WPF_FinishAction.SelectedItem.ToString())"; 
          TimeZoneName="$($WPF_TimeZoneName.SelectedItem.ToString())"; 
          _SMSTSORGNAME="$($WPF_SMSTSORGNAME.Text)"; 
          JoinDomain="$JoinDomain";
          DomainAdmin="$Script:DomainAdmin"; 
          DomainAdminDomain="$DomainAdminDomain"; 
          DomainAdminPassword="$Script:Password"; 
          MachineObjectOU=$MachineObjectOU;
          SkipFinalSummary="$($WPF_SkipFinalSummary.SelectedItem.ToString())";
          UILanguage="$($WPF_UILangage.SelectedItem.ToString())";
          InputLocale="$Script:InputLocale";
          KeyboardLocale="$($WPF_KeyboardLocale.SelectedItem.ToString())";
          Home_Page="$($WPF_Home_Page.Text)";
          SkipAdminPassword="YES";
          SkipProductKey="YES";
          SkipComputerName="YES";
          SkipDomainMembership="YES";
          SkipUserData="YES";
          SkipLocaleSelection="YES";
          SkipTaskSequence="YES";
          SkipTimeZone="YES";
          SkipApplications="YES";
          SkipBitLocker="YES";
          SkipSummary="YES";
          SkipCapture="YES";
          SkipBDDWelcome="YES";}
        }
      "Portable" {
        $MacAddress = $WPF_MacAddress.Text
        $ComputerName = $WPF_ComputerName.Text
        $TaskSequenceSelect = $($WPF_TaskSequences.SelectedItems).ID
        $Service = $WPF_Service.SelectedItem.ToString()
        $SearchBase=(Get-ADDomain).DistinguishedName
        $MachineObjectOU ="OU=Ordinateurs "+ $Machine+ "s,OU=Materiels," + $((Get-ADOrganizationalUnit -filter {Name -like $Service} -SearchBase $SearchBase).DistinguishedName)  
        New-MDTComputer -macAddress "$MacAddress" -description $ComputerName -settings @{ 
          OSInstall='YES' ; 
          OSDComputerName="$ComputerName"; 
          OrgName= "$Script:OrgName";
          ComputerName="$ComputerName"; 
          FullName="$ComputerName"; 
          TaskSequenceID="$TaskSequenceSelect"; 
          FinishAction="$($WPF_FinishAction.SelectedItem.ToString())"; 
          TimeZoneName="$($WPF_TimeZoneName.SelectedItem.ToString())"; 
          _SMSTSORGNAME="$($WPF_SMSTSORGNAME.Text)"; 
          JoinDomain="$JoinDomain"; 
          DomainAdmin="$Script:DomainAdmin"; 
          DomainAdminDomain="$DomainAdminDomain"; 
          DomainAdminPassword="$Script:Password"; 
          MachineObjectOU=$MachineObjectOU;
          SkipFinalSummary="$($WPF_SkipFinalSummary.SelectedItem.ToString())";
          UILanguage="$($WPF_UILangage.SelectedItem.ToString())";
          InputLocale="$Script:InputLocale";
          KeyboardLocale="$($WPF_KeyboardLocale.SelectedItem.ToString())";
          Home_Page="$($WPF_Home_Page.Text)";
          SkipAdminPassword="YES";
          SkipProductKey="YES";
          SkipComputerName="YES";
          SkipDomainMembership="YES";
          SkipUserData="YES";
          SkipLocaleSelection="YES";
          SkipTaskSequence="YES";
          SkipTimeZone="YES";
          SkipApplications="YES";
          SkipBitLocker="YES";
          SkipSummary="YES";
          SkipCapture="YES";
          SkipBDDWelcome="YES";}
        }
      "Fixe" { 
        $MacAddress = $WPF_MacAddress.Text
        $ComputerName = $WPF_ComputerName.Text
        $TaskSequenceSelect = $($WPF_TaskSequences.SelectedItems).ID
        $Service = $WPF_Service.SelectedItem.ToString()
        $SearchBase=(Get-ADDomain).DistinguishedName
        $MachineObjectOU ="OU=Ordinateurs "+ $Machine+ "s,OU=Materiels," + $((Get-ADOrganizationalUnit -filter {Name -like $Service} -SearchBase $SearchBase).DistinguishedName)  
        New-MDTComputer -macAddress "$MacAddress" -description $ComputerName -settings @{ 
          OSInstall='YES' ; 
          OSDComputerName="$ComputerName";
          ComputerName="$ComputerName"; 
          FullName="$ComputerName";  
          OrgName= "$Script:OrgName";
          TaskSequenceID="$TaskSequenceSelect"; 
          FinishAction="$($WPF_FinishAction.SelectedItem.ToString())"; 
          TimeZoneName="$($WPF_TimeZoneName.SelectedItem.ToString())"; 
          _SMSTSORGNAME="$($WPF_SMSTSORGNAME.Text)"; 
          JoinDomain="$JoinDomain"; 
          DomainAdmin="$Script:DomainAdmin"; 
          DomainAdminDomain="$DomainAdminDomain"; 
          DomainAdminPassword="$Script:Password"; 
          MachineObjectOU=$MachineObjectOU;
          SkipFinalSummary="$($WPF_SkipFinalSummary.SelectedItem.ToString())";
          UILanguage="$($WPF_UILangage.SelectedItem.ToString())";
          InputLocale="$Script:InputLocale";
          KeyboardLocale="$($WPF_KeyboardLocale.SelectedItem.ToString())";
          Home_Page="$($WPF_Home_Page.Text)";
          SkipAdminPassword="YES";
          SkipProductKey="YES";
          SkipComputerName="YES";
          SkipDomainMembership="YES";
          SkipUserData="YES";
          SkipLocaleSelection="YES";
          SkipTaskSequence="YES";
          SkipTimeZone="YES";
          SkipApplications="YES";
          SkipBitLocker="YES";
          SkipSummary="YES";
          SkipCapture="YES";
          SkipBDDWelcome="YES";}
        }
      Default {}
    }
    
    $title = "DeployTools"
    $Message = "Poste créé"
    $Type = "Info"

    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
    $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
    $notify = new-object system.windows.forms.notifyicon
    $notify.icon = $icon
    $notify.visible = $true
    $notify.showballoontip(10,$Title,$Message, [system.windows.forms.tooltipicon]::$Type)
  }
  catch {
    $title = "DeployTools"
    $Message = "Impossible de créer le poste"
    $Type = "Error"
      
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | out-null
    $path = Get-Process -id $pid | Select-Object -ExpandProperty Path
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
    $notify = new-object system.windows.forms.notifyicon
    $notify.icon = $icon
    $notify.visible = $true
    $notify.showballoontip(10,$Title,$Message, [system.windows.forms.tooltipicon]::$Type)
    
  }
})




<#
$WPF_Create.Add_Click({

  # On teste si le checkBox et décoché 
  if ($WPF_override.IsChecked -eq $false)
  {
      # On teste si l'utilisateur existe ou non  
    If ((Get-ADUser -Filter {Name -eq $WPF_User.Text }) -eq $Null)
    {
      New-AdUser -Name $WPF_User.Text -Enabled $True -ChangePasswordAtLogon $true -AccountPassword (ConvertTo-SecureString  $WPF_Password.Password -AsPlainText -force)
      
      New-MahappsMessage -title Creation -Message "L'utilisateur $($WPF_User.Text) a ete cree. ;) "
   
      $WPF_User.Text = $null
      $WPF_Password.Password= $null
    }
    Else
    {
      $index = Get-Random -Minimum 1 -maximum 200
      New-MahappsMessage -title "Oups :(" -Message "L'utilisateur $($WPF_User.Text) existe déjà. ;) vous pouvez essayer $($WPF_User.Text)$index "
      $WPF_User.Text = $($WPF_User.Text)+$index
    }

  }
  if ($WPF_override.IsChecked -eq $true)
{
  
  If ((Get-ADUser -Filter {Name -eq $WPF_User.Text }) -eq $Null)
	
  {
    New-AdUser -Name $WPF_User.Text -path $WPF_Path.SelectedItem -Enabled $True -ChangePasswordAtLogon $true -AccountPassword (ConvertTo-SecureString  $WPF_Password.Password -AsPlainText -force) 

    New-MahappsMessage -title Creation -Message "L'utilisateur $($WPF_User.Text) a ete cree. ;) "

    if ($WPF_Group.SelectedItems -ne $null)
    {
      foreach ($value in $WPF_Group.SelectedItems){
       Add-ADGroupMember -Identity "$($value.Name)" -Members $WPF_User.Text
      }
    }


    $WPF_User.Text = $null
    $WPF_Password.Password= $null

  }
  Else
  {
    New-MahappsMessage -title "Oups :(" -Message "L'utilisateur $($WPF_User.Text) existe déjà. ;) "

  }
}

})
$WPF_Exit.Add_Click({
  $Form.Close()
})

$SearchBase=(Get-ADDomain).DistinguishedName
$DN = (Get-ADOrganizationalUnit -filter * -SearchBase $SearchBase).DistinguishedName

foreach ($item in $DN) {
  
    $WPF_Path.Items.Add($item) | Out-Null

}

$WPF_override.Add_Click({

  if ($WPF_override.IsChecked -eq $false){
    $WPF_S_Path.Visibility = "Collapsed"
  }

  if ($WPF_override.IsChecked -eq $true){
    $WPF_S_Path.Visibility = "Visible"
  }
  
})

$GroupGlobaux = Get-ADGroup -Filter "GroupScope -eq 'Global'"

foreach ($item in $GroupGlobaux) {
  
  $GroupsList = New-Object PSObject
  $GroupsList = $GroupsList | Add-Member NoteProperty Name $item.Name -passthru
  $GroupsList = $GroupsList | Add-Member NoteProperty DistinguishedName $item.DistinguishedName -passthru	
  $WPF_Group.Items.Add($GroupsList) > $null

}

$WPF_Path.SelectedIndex=1
#>
#Make PowerShell Disappear
#$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
#$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
#$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)
 
# Force garbage collection just to start slightly lower RAM usage.
#[System.GC]::Collect()

$WPF_ExitD.Add_Click({
  $Form.Close()
})

$Form.ShowDialog() | Out-Null

