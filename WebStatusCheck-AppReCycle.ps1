<#
Description:Function to Check the Status of the local webpage and Recycle the App Pool if the Response is 503
Parameter  : Page URL
Created On : 05/06/2023
Created By : Sreejith JN
Sample Execution: WebStatusCheck-AppRecycle -URL 'http://localhost:82/'
#>

Function WebStatusCheck-AppRecycle{[cmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
    [System.Uri]$URL='http://localhost:80/'
    )
    

    $HTTP_Request = ""
    $HTTP_Response = ""
    $HTTP_Status = ""
    $HTTP_Request = [System.Net.WebRequest]::Create($URL)
    
    try {
    
        $HTTP_Response = $HTTP_Request.GetResponse()
        if(!$HTTP_Response){
            Write-Output "WebPage: $($URL)"
            Write-Output "HttpStatus: Empty/Error in Response"
        }
    
        # We then get the HTTP code as an integer.
        $HTTP_Status = [int]$HTTP_Response.StatusCode

        Write-Output "WebPage: $($URL)"
        Write-Output "HttpStatus: $($HTTP_Status)"

        If ($HTTP_Status -eq 200) 
        {
            Write-Host "All good, no changes required"
        }
        if(503 -eq ($HTTP_Response.StatusCode -as [int]))
        {
           
           $sites = Get-website -Name 'Test'| select name,id,state, physicalpath, @{n="Binding"; e= { ($_.bindings | select -expa collection) -join ';' }} ,applicationPool
           Write-Output "Application Pool:$($sites.applicationPool)" 
           $pool = Get-IISAppPool -Name $sites.applicationPool
           if($pool.Status -ne "Started")
           {
             Write-Output "Error: Application Pool cannot be recycled"
             Write-Output "Status of Application Pool: $($pool.Status)"
             # if this needs to be handled 
             #Start-WebAppPool -Name "$pool.Name"
           }
           elseif($pool.Status -eq "Started")
           {
             $pool.Recycle()
             Write-Output "Application Pool recycled"
           }
       
        }
        Else
        {
            Write-Host "The Site may be down, please check!"
        }

        # clean up the http request by closing it.
        If ($HTTP_Response -eq $null) { } 
        Else { $HTTP_Response.Close() }

    }
    catch [System.Net.WebException] {
        # If it fails, get Response from the Exception
        $Response = $_.Exception.InnerException.Response
    }

}


WebStatusCheck-AppRecycle -URL 'http://localhost:82/'