Import-Module bjd.Common.Functions
Import-Module bjd.Azure.Functions

Set-Variable -Name cwd                      -Value $PWD.Path
Set-Variable -Name root                     -Value (Get-Item $PWD.Path).Parent.FullName
Set-Variable -Name UriFriendlyAppName       -Value $AppName.Replace("-", "")                    -Option Constant

Set-Variable -Name APP_UI_NAME              -Value ("{0}ui" -f $AppName)                        -Option Constant
Set-Variable -Name APP_UI_RG                -Value ("{0}_global_rg" -f $AppName)                -Option Constant
Set-Variable -Name APP_ACR_NAME             -Value ("{0}acr" -f $UriFriendlyAppName)            -Option Constant

Set-Variable -Name UI_SOURCE_DIR            -Value (Join-Path -Path $root -ChildPath "src/ui")  -Option Constant
Set-Variable -Name APP_SOURCE_DIR           -Value (Join-Path -Path $root -ChildPath "src")     -Option Constant

Set-Variable -Name apim_directory           -Value (Join-Path -Path $root -ChildPath "infrastructure/apim")
Set-Variable -Name apim_product_directory   -Value (Join-Path -Path $root -ChildPath "infrastructure/product")
Set-Variable -Name appgw_directory          -Value (Join-Path -Path $root -ChildPath "infrastructure/gateway")
Set-Variable -Name frontdoor_directory      -Value (Join-Path -Path $root -ChildPath "infrastructure/frontdoor")
Set-Variable -Name local_path               -Value (Join-Path -Path $PWD.Path -ChildPath "build")
