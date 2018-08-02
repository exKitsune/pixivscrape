param(
   [string]$followdir=".\pixivfollowers.txt",
   [switch]$help=$false,
   [switch]$login=$false,
   [switch]$show=$false
)

If($help) {
	echo "Specify where pixivfollowers.txt is with -followdir"
	echo "Do -show:$true to see"
	Read-Host -Prompt "Press Enter to continue" ; exit 
}

If(!(Test-Path -Path $followdir)) { echo "The file does not exist" ; Read-Host -Prompt "Press Enter to continue" ; exit }

Read-Host -Prompt "Press Enter to continue if you are ready, otherwise exit and run C:\Users\John\Documents>.\followuser.exe -help" 

$timeoutMilliseconds = 5000

$ie = new-object -ComObject "InternetExplorer.Application"
if($show) { $ie.Visible= $true }
$ie.silent = $true

if(!$login) {

	echo "Logging out of any accounts"
	$url = "https://www.pixiv.net/logout.php?return_to=%2F"
	$ie.navigate($url)

	while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }

	$url = "https://accounts.pixiv.net/login?lang=en&source=pc&view_type=page&ref=wwwtop_accounts_index"
	$ie.navigate($url)

	while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }

	echo "Initialization complete"
	echo ""
	$username= Read-Host -Prompt 'Input your email'
	$response = Read-Host "Input your password" -AsSecureString 
	$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($response))
	#$password= Read-Host -Prompt 'Input your password'

	$inputs = $ie.document.IHTMLDocument3_getElementsByTagName("input")
	$inputs[6].value = $username
	$inputs[7].value = $password

	#$submitbutton = $ie.document.IHTMLDocument3_getElementsByTagName("button") | Where-Object {$_.type -eq 'submit'}
	$buttons = $ie.document.IHTMLDocument3_getElementsByTagName("button")
	$submitbutton=$buttons[1]
	$submitbutton.click()

	$timeStart = Get-Date
	while($ie.locationurl -eq $url -Or $ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { 
		Start-Sleep 1 
		$timeout = ((Get-Date).subtract($timeStart)).TotalMilliseconds -gt $timeoutMilliseconds
		if($timeout -And $ie.locationurl -eq $url) { echo "Unable to reach pixiv or Incorrect login" ; $ie.Stop() ; $ie.Quit() ; exit }
	}

	If($ie.locationurl -eq "https://www.pixiv.net/" -Or $ie.locationurl -eq "https://www.pixiv.net") { echo "Successfully logged in as $username" }
	Else { echo "Error getting to pixiv home" ; $ie.Stop() ; $ie.Quit() ; exit }
}

$followers = Get-Content $followdir
$listlength = $followers.length
$i = 1
while(($i - 1) -lt $listlength) {
	$url = $followers[$i-1]
	$ie.navigate($url)

	while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }
	$ie.stop()

	$divs = $ie.document.IHTMLDocument3_getElementsByTagName("div")
	$j = 0
	$buttonnotfound = $true
	$profilefound = $true
	while($buttonnotfound) {
		$j = $j + 1
		if($divs[$j].className -eq '_action-button follow-button js-follow-button js-click-trackable off ') { $buttonnotfound = $false }
		if($j -eq $divs.length) { break }
	}

	if($buttonnotfound -eq $false) {
		$followbutton=$divs[$j] #92?
		$followbutton.click()

		$j = 0
		$buttonnotfound = $true
		while($buttonnotfound) {
			$j = $j + 1
			if($divs[$j].className -eq 'profile') { $buttonnotfound = $false }
			if($j -eq $divs.length) { break }
		}

		$divs = $ie.document.IHTMLDocument3_getElementsByTagName("div")
		$pagename = $divs[$j].textContent
		$fixedpn = $pagename -replace "Follow.*"

		while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }
		echo "$i | Followed user $fixedpn"
	} else {

		$j = 0
		$buttonnotfound = $true
		while($buttonnotfound) {
			$j = $j + 1
			if($divs[$j].className -eq 'profile') { $buttonnotfound = $false }
			if($j -eq $divs.length) { $profilefound = $false; break }
		}
		if($profilefound) {
			$divs = $ie.document.IHTMLDocument3_getElementsByTagName("div")
			$pagename = $divs[$j].textContent
			$fixedpn = $pagename -replace "Follow.*"

			echo "$i | User $fixedpn already followed"
		} else {
			echo "$i | $url has left, been banned, or is invalid url"
		}
	}
	$i = $i + 1
}

$i = $i - 1
echo "Followed $i users in total, task complete"
$ie.Stop()
$ie.Quit()