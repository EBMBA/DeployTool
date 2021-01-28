﻿[Void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 
foreach ($item in $(gci .\assembly\ -Filter *.dll).name) {
    [Void][System.Reflection.Assembly]::LoadFrom("assembly\$item")
}

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
#                       Functions       								#
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


Function AutoNameComputer {
  param(
    [Parameter(Mandatory,Position=0)]
    [string]$Site,
    [Parameter(Mandatory,Position=1)]
    [string]$Machine,
    [Parameter(Mandatory,Position=2)]
    [string]$Service  
  )

 
  #########################################################################
  #                            Variables                                  #
  #########################################################################
  begin{

    $i=0
    $j=0
    $Count=0
    $Number="0","1","2","3","4","5","6","7","8","9"
    $Type=''
    $NewNameChar=''
    $LastName=''
    $LastNameInt=''

    #########################################################################
    #                            Search Name                                #
    #########################################################################


    switch ($Site)
    {
        "Croix-Rousse"{$S='CR'}
    }

    switch ($Machine)
    {
        "Client"{$Os='CLI'}
        "Serveur"{$Os='SRV'}
    }


    switch ($Service)
    {
        "Administration"{$Ser='ADMIN'}
        "Direction"{$Ser='DIR'}
        "Informatique"{$Ser='INFO'}
        "Laboratoire"{$Ser='LABO'}
        "Pharmacie"{$Ser='PHARMA'}
        "Radiologie"{$Ser='RADIO'}
        "Recherche et Developpement"{$Ser='RD'}
        "Ressources Humaines"{$ser='RH'}
        "Aides-Soignantes"{$ser='AS'}
        "Medecins"{$ser='MED'}
        "Infirmieres"{$ser='INFI'}
    }

    $ListName=(Get-ADComputer -Filter "Name -like '$S-$Os-$Ser*'" -Properties Name).name
  
  }

  process{

    if ($null -eq $ListName){
        $NewName="$S-$Os-$Ser"+"1"
    }

    else {
        $Type=($ListName.GetType().FullName)


        if ($Type -eq 'System.Object[]' ) {
            $LastName=$ListName[-1]
        }
        elseif ($Type -eq 'System.String') {
            $LastName=$ListName
        }
        else {
            Write-Output 'Error'
        }


            #########################################################################
            #                              Auto Name                                #
            #########################################################################

        for ($i = -1; $i -lt $array.Count; $i--) {
            if ($LastName[$i] -in $Number) {
                $Count +=1
            }
            else {
                break
            } 
        }

        $nb = $LastName.Length-$Count

        while (!($j -eq $nb)) {
            $NewNameChar += $LastName[$j]
            $j+=1
        }


        while (!($nb -eq $LastName.Length)) {
            $LastNameInt += $LastName[$nb]
            $nb+=1
        }

        $NewNameInt=([int]$LastNameInt)+1

        $NewName="$NewNameChar"+"$NewNameInt"

    }
  }

  end{
    return "$NewName"
  }   

}



#########################################################################
#                       DATA       						       		    #
#########################################################################

#Données obligatoires à modifier 
$ServeurMDT = 
$DeploymentShareSMB =


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
#                           AFFICHAGE CHOIX DE SERVICE                       #
############################################################################## 
[String]$MachineSelect = ""
$WPF_Machine.add_SelectionChanged({
  
  $MachineSelect = $WPF_Machine.SelectedItem.ToString()
  if($MachineSelect -eq "Client"){
    $WPF_ServiceView.Visibility = "Visible"
    $WPF_ComputerName.IsEnabled = $false
    $WPF_ComputerName.Text = 'Générez son nom'
    $WPF_Generer.IsEnabled= $true
  }
  else{
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
$Machines = ('Client', 'Serveur')
# Ajout des services, des sites et des types de machines dans les combobox 
foreach ($item in $Services) {
  $WPF_Service.Items.Add($item) 
}

foreach ($item in $Sites) {
  $WPF_Site.Items.Add($item) 
}

foreach ($item in $Machines) {
  $WPF_Machine.Items.Add($item) 
}

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

$WPF_ComputerName.Add_TextChanged -and $WPF_MacAddress.Add_TextChanged({
	If (($WPF_ComputerName.text.Length -ge 7) -and ($WPF_MacAddress.text.Length -eq 17)){
    $WPF_Create.IsEnabled = $True
  }
  else{
    $WPF_Create.IsEnabled = $false
  }
})

##############################################################################
#                           RECHERCHE / AFFICHAGE SEQUENCES DE TACHES                                          #
############################################################################## 
<#[XML]$TaskSequencesFile = Get-Content -path \$ServeurMDT\$DeploymentShareSMB\Control\TaskSequences.xml
$TaskSequencesList = $TaskSequencesFile.tss.ts

foreach ($TaskSequence in $TaskSequencesList) {
  $GroupsList = New-Object PSObject
  $GroupsList = $GroupsList | Add-Member NoteProperty ID $TaskSequence.Name -passthru
  $GroupsList = $GroupsList | Add-Member NoteProperty "Nom de la séquence" $TaskSequence.Description -passthru	
  $WPF_Group.Items.Add($GroupsList) > $null
}
#>


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

#Make PowerShell Disappear
#$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
#$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
#$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)
 
# Force garbage collection just to start slightly lower RAM usage.
#[System.GC]::Collect()

$Form.ShowDialog() | Out-Null
