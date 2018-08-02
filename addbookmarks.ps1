param(
   [string]$bookdir=".\pixivbookmarks.txt",
   [switch]$help=$false,
   [switch]$login=$false,
   [switch]$private=$false,
   [switch]$show=$false
)

If($help) {
	echo "Specify where pixivbookmarks.txt is with -bookdir"
	echo "Add them to private bookmarks with -private"
	echo "Bypass login with -login"
	echo "Do -show to see"
	Read-Host -Prompt "Press Enter to continue" ; exit 
}

If(!(Test-Path -Path $bookdir)) { echo "The file does not exist" ; Read-Host -Prompt "Press Enter to continue" ; exit }

Read-Host -Prompt "Press Enter to continue if you are ready, otherwise exit and run C:\Users\John\Documents>.\addbookmarks.exe -help" 

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

$bookmarks = Get-Content $bookdir
$listlength = $bookmarks.length
$i = 1

while(($i - 1) -lt $listlength) {
	$url = $bookmarks[$i-1]
	$burl = $url -replace "https://www\.pixiv\.net/member_illust\.php\?mode=medium"
	$burl = "https://www.pixiv.net/bookmark_add.php?type=illust" + $burl
	$ie.navigate($burl)

	while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4 -Or $buttons.length -lt 26) { Start-Sleep 1 ; $buttons = $ie.document.IHTMLDocument3_getElementsByTagName("input") ; if($ie.document.IHTMLDocument3_getElementsByTagName("h2").length -ge 1) { break }}# ; $buttons.length}

	$headers = $ie.document.IHTMLDocument3_getElementsByTagName("h2")
	if($headers.length -lt 1) {
		if($headers[0].innerText -ne "An error occurred.") {

			if($private -eq $true) {
				$buttons = $ie.document.IHTMLDocument3_getElementsByTagName("label")

				$privatebutton=$buttons[1] 
				$privatebutton.click()
			}

			$buttons = $ie.document.IHTMLDocument3_getElementsByTagName("input")

			$j = 0
			$buttonnotfound = $true
			while($buttonnotfound) {
				$j = $j + 1
				if($buttons[$j].className -eq '_button-large') { $buttonnotfound = $false }
				if($j -ge $buttons.length) { break }
			}

			if($buttons[$j].value -eq "Edit Bookmark") { $buttonstatus = 0 } else { $buttonstatus = 1 }

			if($buttonstatus) {
				$favoritebutton=$buttons[$j] #6
				$favoritebutton.click()
			}

			$headers = $ie.document.IHTMLDocument3_getElementsByTagName("h1")
			$title = $headers[1].innerText
			if($headers.length -eq 0) { $title = "*No Title*" }

			while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }

			if($buttonstatus) {
				echo "$i | Bookmarked picture $title"
			} else {
				echo "$i | $title already bookmarked"
			}
		}
	} else {
		echo "$i | $url is unavailable"
	}

	$i = $i + 1
} 

$i = $i - 1
echo "Bookmarked $i pictures in total, bookmarking complete"
$ie.Stop()
$ie.Quit()