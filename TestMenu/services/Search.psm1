Function Search {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Filter
    )
    process{
        $ListName=(Get-ADComputer -Filter "Name -like '*$filter*'" -Properties Name).name
    }

    end{
        return $ListName
    }



}