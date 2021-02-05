Function Search {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Filter
    )
    process{
        $ListName=(Get-ADComputer -Filter "Name -like '*$filter*'" -Properties * | FT Name,IPv4Address,whenChanged,OperatingSystem,OperatingSystemVersion)
    }

    end{
        return $ListName
    }



}





