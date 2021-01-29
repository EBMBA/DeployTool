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
          "Fixe"{$Os='CLI'}
          "Portable"{$Os='CLI'}
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
          "Ressources Humaines"{$Ser='RH'}
          "Aides-Soignantes"{$Ser='AS'}
          "Medecins"{$Ser='MED'}
          "Infirmieres"{$Ser='INFI'}
          "Accueil"{$Ser='ACC'}
      }
    }
    process{

        if ("$Os" -eq "CLI") {

            $ListName=(Get-ADComputer -Filter "Name -like '$S-$Os-$Ser*'" -Properties Name).name
            
        
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
                    Write-Host 'Error'
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

        else {
            $NewName=(Get-ADComputer -Filter "Name -like '$S-$Os-*'" -Properties Name).name

        }



    }
    




    end{
        return "$NewName"
    }   
    
}
    

    #$AutoName = AutoNameComputer -Site 'Croix-Rousse' -Machine 'Client' -Service 'Informatique'

    #$AutoName2 = AutoNameComputer 'Croix-Rousse' 'Client' 'Informatique'