Function Connect-ServerBDD {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ServeurSQL
    )
    process{
        try {
            Connect-MDTDatabase -sqlServer $ServeurSQL -instance SQLEXPRESS -database MDT
            
            $title = "DeployTools"
            $Message = "Vous êtes connecté au serveur de base de donnée $ServeurSQL"
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
            $Message = "Le serveur de base de donnée $ServeurSQL n'est pas accessible"
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

    end{
    }



}