function removeApp($appName) {
    Write-Output "Trying to remove $appName"
    try
    {
    Get-AppxPackage $appName -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayName -like $appName | Remove-AppxProvisionedPackage -Online
    }
    catch
    {}  # Prevent unexpected error
}

$removeApps = @(
    "Microsoft.3DBuilder"
    "Microsoft.BingFinance"
    "Microsoft.BingNews"
    "Microsoft.BingSports"
    "Microsoft.BingWeather"
    "Microsoft.CommsPhone"
    "Microsoft.Getstarted"
    "Microsoft.People"
    "Microsoft.WindowsMaps"
    "*MarchofEmpires*"
    "Microsoft.GetHelp"
    "Microsoft.Messaging"
    "*Minecraft*"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.OneConnect"
    "Microsoft.WindowsAlarms"
    "Microsoft.WindowsCamera"
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsPhone"
    "Microsoft.WindowsSoundRecorder"
    "*Solitaire*"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.Office.Sway"
    "Microsoft.Xbox*"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.FreshPaint"
    "Microsoft.Print3D"
    "Microsoft.MSPaint"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.MixedReality.Portal"
    "Microsoft.Windows.Photos"
    "*Autodesk*"
    "*BubbleWitch*"
    "king.com*"
    "G5*"
    "*Dell*"
    "*Facebook*"
    "*Keeper*"
    "*Netflix*"
    "*Twitter*"
    "*Plex*"
    "*.Duolingo-LearnLanguagesforFree"
    "*.EclipseManager"
    "ActiproSoftwareLLC.562882FEEB491"
    "*.AdobePhotoshopExpress"
);

foreach ($app in $removeApps) {
    removeApp $app
}
