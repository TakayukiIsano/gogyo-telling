#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# This PS DSC resource enables register or unregister a package source through DSC Get, Set and Test operations on DSC managed nodes.

Import-LocalizedData -BindingVariable LocalizedData -filename MSFT_PackageManagementSource.strings.psd1

Import-Module -Name "$PSScriptRoot\..\PackageManagementDscUtilities.psm1"

function Get-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to register/unregister a package source on your computer. 

    Get-TargetResource returns the current state of the resource.

    .PARAMETER Name
    Specifies the name of the package source to be registered or unregistered on your system.

    .PARAMETER ProviderName
    Specifies the name of the PackageManagement provider through which you can interop with the package source.

    .PARAMETER SourceLocation
    Specifies the Uri of the package source.
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ProviderName,

        [parameter(Mandatory = $true)]
        [System.String]
        $SourceLocation
    )

    #initialize a local var
    $ensure = "Absent"

    #Set the installation policy by default, untrusted. 
    $installationPolicy ="Untrusted"

    $PSBoundParameters.Add("Location", $SourceLocation)
    $PSBoundParameters.Remove("SourceLocation")

    #Validate Uri and add Location because PackageManagement uses Location not SourceLocation. 
    #ValidateArgument  -Argument $PSBoundParameters['Location'] -Type 'PackageSource' -ProviderName $ProviderName

    Write-Verbose -Message ($localizedData.StartGetPackageSource -f $($Name))

    #check if the package source already registered on the computer
    # Note: Assume Get-PackageSource returns the first source if multiple are found
    $source = PackageManagement\Get-PackageSource @PSBoundParameters -ForceBootstrap -ErrorAction SilentlyContinue -WarningAction SilentlyContinue  
        

    if (($source.count -gt 0) -and ($source.IsRegistered))
    {
        Write-Verbose -Message ($localizedData.PackageSourceFound -f $($Name))
        $ensure = "Present"
    }
    else
    {
        Write-Verbose -Message ($localizedData.PackageSourceNotFound -f $($Name))
    }

    Write-Debug -Message "Source $($Name) is $($ensure)"
                         
    
    if ($ensure -eq 'Absent')
    {
        return @{
            Ensure       = $ensure
            Name         = $Name
            ProviderName = $ProviderName
        }
    }
    else
    {
        if ($source.IsTrusted)
        {
            $installationPolicy = "Trusted"
        }

        return @{
            Ensure             = $ensure
            Name               = $Name
            ProviderName       = $ProviderName
            SourceLocation          = $source.Location
            InstallationPolicy = $installationPolicy
        }
    } 
}

function Test-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to register/unregister a package source on your computer. 

    Test-TargetResource validates whether the resource is currently in the desired state.

    .PARAMETER Name
    Specifies the name of the package source to be registered or unregistered on your system.

    .PARAMETER ProviderName
    Specifies the name of the PackageManagement provider through which you can interop with the package source.

    .PARAMETER SourceLocation
    Specifies the Uri of the package source.

    .PARAMETER Ensure
    Determines whether the package source to be registered or unregistered.

    .PARAMETER SourceCredential
    Provides access to the package on a remote source. 

    .PARAMETER InstallationPolicy
    Determines whether you trust the package’s source.
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ProviderName,

        [parameter(Mandatory = $true)]
        [System.String]
        $SourceLocation,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present",

        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [ValidateSet("Trusted","Untrusted")]
        [System.String]
        $InstallationPolicy="Untrusted"
    )

    #Get the current status of the package source 
    Write-Debug -Message  "Calling Get-TargetResource"

    $status = Get-TargetResource -Name $Name -ProviderName $ProviderName -SourceLocation $SourceLocation
 
    if($status.Ensure -eq $Ensure)
    {
        
        if ($status.Ensure -eq "Present") 
        {
            #Check if the source location matches. As get-package takes location (SourceLocation) parameter, the result from Get-package should 
            #belong to the particular source location. But currently it does not. Below is the workaround.
            #
            if ($status.SourceLocation -ine $SourceLocation) 
            {
                Write-Verbose -Message ($localizedData.NotInDesiredStateDuetoLocationMismatch -f $($Name), $($SourceLocation), $($status.SourceLocation))
                return $false 
            }  

            #Check if the installationPolicy matches. Sometimes the registered source and desired source can be the same except for InstallationPolicy
            #
            if ($status.InstallationPolicy -ine $InstallationPolicy)
            {
                Write-Verbose -Message ($localizedData.NotInDesiredStateDuetoPolicyMismatch -f $($Name), $($InstallationPolicy), $($status.InstallationPolicy))
                return $false 
            }           
        }

        Write-Verbose -Message ($localizedData.InDesiredState -f $($Name), $($Ensure), $($status.Ensure))                   
        return $true
    }
    else
    {
        Write-Verbose -Message ($localizedData.NotInDesiredState -f $($Name), $($Ensure), $($status.Ensure))
        return $false
    }
}

function Set-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to register/unregister a package source on your computer. 

    Set-TargetResource sets the resource to the desired state. "Make it so".

    .PARAMETER Name
    Specifies the name of the package source to be registered or unregistered on your system.

    .PARAMETER ProviderName
    Specifies the name of the PackageManagement provider through which you can interop with the package source.

    .PARAMETER SourceLocation
    Specifies the Uri of the package source.

    .PARAMETER Ensure
    Determines whether the package source to be registered or unregistered.

    .PARAMETER SourceCredential
    Provides access to the package on a remote source. 

    .PARAMETER InstallationPolicy
    Determines whether you trust the package’s source.
    #>

    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ProviderName,

        [parameter(Mandatory = $true)]
        [System.String]
        $SourceLocation,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present",

        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [ValidateSet("Trusted","Untrusted")]
        [System.String]
        $InstallationPolicy="Untrusted"
    )

    #Add Location because PackageManagement uses Location not SourceLocation. 
    $PSBoundParameters.Add("Location", $SourceLocation)

    if ($PSBoundParameters.ContainsKey("SourceCredential"))
    {
        $PSBoundParameters.Add("Credential", $SourceCredential)
    }

    if ($InstallationPolicy -ieq "Trusted")
    {
        $PSBoundParameters.Add("Trusted", $True)
    }
    else
    {
        $PSBoundParameters.Add("Trusted", $False)
    }
    

    if($Ensure -ieq "Present")
    {   
        #
        #Warn a user about the installation policy
        #
        Write-Warning -Message ($localizedData.InstallationPolicyWarning -f $($Name), $($SourceLocation), $($InstallationPolicy))

        $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
                                               -ArgumentNames ("Name","ProviderName", "Location", "Credential", "Trusted")   
        
        Write-Verbose -Message ($localizedData.StartRegisterPackageSource -f $($Name)) 

        if ($name -eq "psgallery")
        {         
            # In WMF 5.0 RTM, we are not able to register 'psgallery' package source. Thus let's try Set-PSRepository to see if we can
            # update the registration. 
            
            # Before calling the Set-PSRepository cmdlet, we need to make sure the PSGallery already registered.

            $psgallery = PackageManagement\Get-PackageSource -name $name -Location $SourceLocation -ProviderName $ProviderName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            if( $psgallery)
            {
                Set-PSRepository -Name $name -SourceLocation $SourceLocation -InstallationPolicy $InstallationPolicy -ErrorVariable ev 
            }
            else
            {
                # The following works if you are running TP5 or later
                $extractedArguments.Remove("Location")
                PackageManagement\Register-PackageSource @extractedArguments -Force -ErrorVariable ev  

            }
        }
        else
        {                                       
            PackageManagement\Register-PackageSource @extractedArguments -Force -ErrorVariable ev  
        }
            
        if($null -ne $ev -and $ev.Count -gt 0)
        {
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage ($localizedData.RegisterFailed -f $Name, $ev.Exception)`
                        -ErrorId "RegisterFailed" `
                        -ErrorCategory InvalidOperation                  
        }
        else
        {
            Write-Verbose -Message ($localizedData.RegisteredSuccess -f $($Name))           
        }                      
    }
    #Ensure=Absent
    else 
    {
        $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
                                               -ArgumentNames $("Name","ProviderName", "Location", "Credential")  
                                                       
        Write-Verbose -Message ($localizedData.StartUnRegisterPackageSource -f $($Name))  
                         
        PackageManagement\Unregister-PackageSource @extractedArguments -Force -ErrorVariable ev 
        
        if($null -ne $ev -and $ev.Count -gt 0)
        {
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage ($localizedData.UnRegisterFailed -f $Name, $ev.Exception)`
                        -ErrorId "UnRegisterFailed" `
                        -ErrorCategory InvalidOperation       
        }
        else
        {
            Write-Verbose -Message ($localizedData.UnRegisteredSuccess -f $($Name))            
        }                    
    }  
 }

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource


# SIG # Begin signature block
# MIInoQYJKoZIhvcNAQcCoIInkjCCJ44CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCi6Bt6dCivNyvz
# gw+R+LTaFT5ZDIx8HkDejTMrDqW9yqCCDYEwggX/MIID56ADAgECAhMzAAACUosz
# qviV8znbAAAAAAJSMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjEwOTAyMTgzMjU5WhcNMjIwOTAxMTgzMjU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDQ5M+Ps/X7BNuv5B/0I6uoDwj0NJOo1KrVQqO7ggRXccklyTrWL4xMShjIou2I
# sbYnF67wXzVAq5Om4oe+LfzSDOzjcb6ms00gBo0OQaqwQ1BijyJ7NvDf80I1fW9O
# L76Kt0Wpc2zrGhzcHdb7upPrvxvSNNUvxK3sgw7YTt31410vpEp8yfBEl/hd8ZzA
# v47DCgJ5j1zm295s1RVZHNp6MoiQFVOECm4AwK2l28i+YER1JO4IplTH44uvzX9o
# RnJHaMvWzZEpozPy4jNO2DDqbcNs4zh7AWMhE1PWFVA+CHI/En5nASvCvLmuR/t8
# q4bc8XR8QIZJQSp+2U6m2ldNAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUNZJaEUGL2Guwt7ZOAu4efEYXedEw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDY3NTk3MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAFkk3
# uSxkTEBh1NtAl7BivIEsAWdgX1qZ+EdZMYbQKasY6IhSLXRMxF1B3OKdR9K/kccp
# kvNcGl8D7YyYS4mhCUMBR+VLrg3f8PUj38A9V5aiY2/Jok7WZFOAmjPRNNGnyeg7
# l0lTiThFqE+2aOs6+heegqAdelGgNJKRHLWRuhGKuLIw5lkgx9Ky+QvZrn/Ddi8u
# TIgWKp+MGG8xY6PBvvjgt9jQShlnPrZ3UY8Bvwy6rynhXBaV0V0TTL0gEx7eh/K1
# o8Miaru6s/7FyqOLeUS4vTHh9TgBL5DtxCYurXbSBVtL1Fj44+Od/6cmC9mmvrti
# yG709Y3Rd3YdJj2f3GJq7Y7KdWq0QYhatKhBeg4fxjhg0yut2g6aM1mxjNPrE48z
# 6HWCNGu9gMK5ZudldRw4a45Z06Aoktof0CqOyTErvq0YjoE4Xpa0+87T/PVUXNqf
# 7Y+qSU7+9LtLQuMYR4w3cSPjuNusvLf9gBnch5RqM7kaDtYWDgLyB42EfsxeMqwK
# WwA+TVi0HrWRqfSx2olbE56hJcEkMjOSKz3sRuupFCX3UroyYf52L+2iVTrda8XW
# esPG62Mnn3T8AuLfzeJFuAbfOSERx7IFZO92UPoXE1uEjL5skl1yTZB3MubgOA4F
# 8KoRNhviFAEST+nG8c8uIsbZeb08SeYQMqjVEmkwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZdjCCGXICAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAlKLM6r4lfM52wAAAAACUjAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgg3k6xwNQ
# o1WoPx/Eum0hOMf6jJDw+B0lq5IkCZ9L86UwQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQC9gBRNg9F4cdHzCFd7gUcB/d/KfvSxeknaRv6Kc1SI
# 6TVqtUo8xvMYueEQ1fCQ338vwLNqckXWYHevUBXNJW0f39tSA3hYmtCGa1btIi9Y
# Xki7+LIWh8xdppHmohi1O1KuZqivqGPuXTf8CSbZJNOmDreFLCr+o5/1dA8IeLxZ
# pFBN0Hq//r6wx2YhxpRiVnGqbMI8cU+ZkcZyC6ejhzA9I6w28Q/ulY2yfMTVnQ/Z
# X0vk1jhtDDHjuolHRuCn85BeivhFkU2B8f7S022oK1HPqIDSzJy8Az5LkCK1rK4e
# rvULL4bUHN5njIOjeNeSSKYaaioCRJpyyRkwWKwTTVc6oYIXADCCFvwGCisGAQQB
# gjcDAwExghbsMIIW6AYJKoZIhvcNAQcCoIIW2TCCFtUCAQMxDzANBglghkgBZQME
# AgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEIP8FNJSv+aNN//VZkFj6YLQc92uv6QJ3Pjk4IgS1
# qVUnAgZitJ9dXJoYEzIwMjIwNzAxMjEwMDAxLjQwOVowBIACAfSggdCkgc0wgcox
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1p
# Y3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1Mg
# RVNOOkU1QTYtRTI3Qy01OTJFMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNloIIRVzCCBwwwggT0oAMCAQICEzMAAAGVt/wN1uM3MSUAAQAAAZUw
# DQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcN
# MjExMjAyMTkwNTEyWhcNMjMwMjI4MTkwNTEyWjCByjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
# T3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RTVBNi1FMjdDLTU5
# MkUxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCfbUEMZ7ZLOz9aoRCeJL4hhT9Q8JZB
# 2xaVlMNCt3bwhcTI5GLPrt2e93DAsmlqOzw1cFiPPg6S5sLCXz7LbbUQpLha8S4v
# 2qccMtTokEaDQS+QJErnAsl6VSmRvAy0nlj+C/PaZuLb3OzY0ARw7UeCZLpyWPPH
# +k5MdYj6NUDTNoXqbzQHCuPs+fgIoro5y3DHoO077g6Ir2THIx1yfVFEt5zDcFPO
# YMg4yBi4A6Xc3hm9tZ6w849nBvVKwm5YALfH3y/f3n4LnN61b1wzAx3ZCZjf13UK
# bpE7p6DYJrHRB/+pwFjG99TwHH6uXzDeZT6/r6qH7AABwn8fpYc1TmleFY8YRuVz
# zjp9VkPHV8VzvzLL7QK2kteeXLL/Y4lvjL6hzyOmE+1LVD3lEbYho1zCt+F7bU+F
# pjyBfTC4i/wHsptb218YlbkQt1i1B6llmJwVFwCLX7gxQ48QIGUacMy8kp1+zczY
# +SxlpaEgNmQkfc1raPh9y5sMa6X48+x0K7B8OqDoXcTiECIjJetxwtuBlQseJ05H
# RfisfgFm09kG7vdHEo3NbUuMMBFikc4boN9Ufm0iUhq/JtqV0Kwrv9Cv3ayDgdNw
# EWiL2a65InEWSpRTYfsCQ03eqEh5A3rwV/KfUFcit+DrP+9VcDpjWRsCokZv4tgn
# 5qAXNMtHa8NiqQIDAQABo4IBNjCCATIwHQYDVR0OBBYEFKuX02ICFFdXgrcCBmDJ
# fH5v/KkXMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRY
# MFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01p
# Y3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEF
# BQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAo
# MSkuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQELBQADggIBAOCzNt4fJ+jOvQuq0Itn37IZrYNBGswAi+IAFM3YGK/wGQlE
# ncgjmNBuac95W2fAL6xtFVfMfkeqSLMLqoidVsU9Bm4DEBjaWNOT9uX/tcYiJSfF
# QM0rDbrl8V4nM88RZF56G/qJW9g5dIqOSoimzKUt/Q7WH6VByW0sar5wGvgovK3q
# FadwKShzRYcEqTkHH2zip5e73jezPHx2+taYqJG5xJzdDErZ1nMixRjaHs3Kpcsm
# ZYuxsIRfBYOJvAFGymTGRv5PuwsNps9Ech1Aasq84H/Y/8xN3GQj4P3MiDn8izUB
# DCuXIfHYk39bqnaAmFbUiCby+WWpuzdk4oDKz/sWwrnsoQ72uEGVEN7+kyw9+HSo
# 5i8l8Zg1Ymj9tUgDpVUGjAduoLyHQ7XqknKmS9kJSBKk4okEDg0Id6LeKLQwH1e4
# aVeTyUYwcBX3wg7pLJQWvR7na2SGrtl/23YGQTudmWOryhx9lnU7KBGV/aNvz0tT
# pcsucsK+cZFKDEkWB/oUFVrtyun6ND5pYZNj0CgRup5grVACq/Agb+EOGLCD+zEt
# GNop4tfKvsYb64257NJ9XrMHgpCib76WT34RPmCBByxLUkHxHq5zCyYNu0IFXAt1
# AVicw14M+czLYIVM7NOyVpFdcB1B9MiJik7peSii0XTRdl5/V/KscTaCBFz3MIIH
# cTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCB
# iDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMp
# TWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEw
# OTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIh
# C3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNx
# WuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFc
# UTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAc
# nVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUo
# veO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyzi
# YrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9
# fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdH
# GO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7X
# KHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiE
# R9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/
# eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3
# FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAd
# BgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEE
# AYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMI
# MBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMB
# Af8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1Ud
# HwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3By
# b2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQRO
# MEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2Vy
# dHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4IC
# AQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pk
# bHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gng
# ugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3
# lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHC
# gRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6
# MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEU
# BHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvsh
# VGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+
# fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrp
# NPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHI
# qzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAs4wggI3AgEBMIH4
# oYHQpIHNMIHKMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUw
# IwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjpFNUE2LUUyN0MtNTkyRTElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA0Y+CyLezGgVHWFNm
# KI1LuE/hY6uggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQUFAAIFAOZpqYQwIhgPMjAyMjA3MDIwMTEyMzZaGA8yMDIyMDcw
# MzAxMTIzNlowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5mmphAIBADAKAgEAAgIe
# WAIB/zAHAgEAAgIR3TAKAgUA5mr7BAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgor
# BgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUA
# A4GBAGizLxBkK6B2oQmB80+aM7sOfXuAgkYj93m3glu2ZQ242mTevtDINaDoV+qc
# 7BhagNfrWoCVESVZEjaqCYrV/VVxnmuKU0VXJoUnLcNW0cmK3aTV1fENg1wMmi/r
# TFKkd1udFGkqk+aoUxPKMtV19/TbRjUL/5qxCuVE0uACxjXOMYIEDTCCBAkCAQEw
# gZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGVt/wN1uM3MSUA
# AQAAAZUwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAvBgkqhkiG9w0BCQQxIgQgv5FJYo3XyHh4DhknKReAc6BhiNHQ3SccvOkW
# Gwz1uRswgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBc5kvhjZALe2mhIz/Q
# d7keVOmA/cC1dzKZT4ybLEkCxzCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwAhMzAAABlbf8DdbjNzElAAEAAAGVMCIEIKYVsiXt/OMHtVXLwf4B
# pSdKHBzozlb2nRtmmiDl84fKMA0GCSqGSIb3DQEBCwUABIICADpGt0VVaI3fyHTc
# 4qOdYU6fRQ0SMf647SIQXLqSkS0+3qKCj6ttruGMTfILZa01RjPIZ8CJzMDOnFYY
# EHc4XoUJ2f61fY3kbcTd++NyTI9CCCQpa4lA7hnoJ+AqvVrDbcJ1MrwbgGg2Ay1O
# 6lp+PqUppArTyR8g6ItUkJ7y+4k0X8aYD20v/MZFYwD/YDFbrNrbmqaA0UM0agtm
# 0cRUbSoissqC1cCSc1P4vh2cvekpg1RQa1Y5pCd3qDyvYUbAIBJ6Q7Uka2UVDzOy
# grSC9VMAIOxBLTpL7mXOCoOdt5+m2pHmtqL4LSeeiFOU57CaE9byCWCTL3z08np+
# r+uTCq/w4YBAvjhkIi0RDu++ddGhUtmID55zXKOzUum2rrSwJYEQERUgxqFvRHrE
# 3Zr4px3PmWD6tRR4wKoI38QUuk0XRxKTK2LeiHqhJsuArlQg0Kc0jxncFjavorc7
# pPAVc5PZtmU645oilipJP8KAzMCl3uMjLCuOULjhTBxncpSB1vCgK5Y/+fyurOpU
# 3LVSZ23nexgbQi7U/DoKgno3SUhgpvpmqnAKtk+PXXsnDIAxDU1fif3028W+uYaL
# IbD9DFH2fSwzm/s9LC5HpeAeQfmOn3GAmfxCNhZDYodIO4rDokY7iIpeGLuFbgWe
# OT6xMJt7JLjHDATIMrCd8AXgJ/vo
# SIG # End signature block
