param(
   [string]$files="na",
   [string]$mprefix="",
   [string]$bprefix="",
   [switch]$help=$false,
   [switch]$login=$false,
   [switch]$private=$false,
   [switch]$show=$false
)

If($help) {
	echo "Online use: run script, enter credentials"
	echo "If you've previously used this and have logged in, use -login"
	echo ""
	echo "Offline use (If you have saved the webpages yourself"
	echo "Please put create a directory and 2 subdirectories within it"
	echo "Put bookmark html pages into /dir/bookmarks/"
	echo "Put member html pages into /dir/members/"
	echo 'Then run .\pixivscrape.exe -files "/dir"'
	echo "It is important that you don't put a / after dir"
	echo ""
	echo "If you do run -files then also run -prefix specifying the name"
	echo "of the file before the numerical #, e.g. if your files look like"
	echo 'bookmarks1.html, bookmarks2.html then run -bprefix "bookmarks"'
	echo 'same for followers with -mprefix'
	echo "Example:"
	echo '.\pixivscrape.ps1 -files ".\pixivhtml" -mprefix "[pixiv] フォローユーザー" -bprefix "[pixiv] Bookmarks"'
	echo ""
	echo "-private will include private pages"
	echo ""
	echo "-show will show you what's happening"
	Read-Host -Prompt "Press Enter to continue" ; exit 
}

If(!(Test-Path -Path $files) -And $files -ne "na") { echo "The directory does not exist" ; Read-Host -Prompt "Press Enter to continue" ; exit }

echo "Make sure you have opened command prompt/powershell and are running from command line such as C:\Users\John\Documents>.\pixivscrape.exe"
Read-Host -Prompt "Press Enter to continue if you are ready, otherwise exit and run C:\Users\John\Documents>.\pixivscrape.exe -help" 

If($files -eq "na") {

	echo "Creating temporary directories"

	If(Test-Path -Path .\temppixivhtml\) { Remove-Item -Recurse .\temppixivhtml\ }
	If(!(Test-Path -Path .\temppixivhtml\)) { 
		New-Item -Path .\temppixivhtml\ -ItemType directory 
		New-Item -Path .\temppixivhtml\members -ItemType directory 
		New-Item -Path .\temppixivhtml\bookmarks -ItemType directory 
	}

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
	} else {
		$url = "https://www.pixiv.net/"
		$ie.navigate($url)
		while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }
	}

	[regex]$regex="/member\.php\?id=[0-9]+"
	$homepage = $ie.Document.documentElement.innerHTML
	$links = $regex.Matches($homepage) | foreach-object {$_.Value}
	$thisuser = $links[0]

	$noresult = "No results found for your query"

	$notdone = 1
	$pagenumber = 1

	while($notdone) {
		echo "Scraping follower page: $pagenumber"
		$url = "https://www.pixiv.net/bookmark.php?type=user&rest=show&p=" + $pagenumber
		$ie.navigate($url)

		while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }

		$fileprint = ".\temppixivhtml\members\members" + $pagenumber + ".html"
		$ie.Document.documentElement.innerHTML > $fileprint
		$file = Get-Content $fileprint
		$containsWord = $file | %{$_ -match $noresult}
		If($containsWord -contains $true) {
			$notdone = 0
			$excess = ".\temppixivhtml\members\members" + $pagenumber + ".html"
			Remove-Item $excess
		}
		$pagenumber = $pagenumber + 1
	}

	echo "End of public followers"

	if($private) {
		$continuenum = $pagenumber - 1
		$notdone = 1
		$pagenumber = 1

		while($notdone) {
			echo "Scraping follower page: $pagenumber"
			$url = "https://www.pixiv.net/bookmark.php?type=user&rest=hide&p=" + $pagenumber
			$ie.navigate($url)

			while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }

			$fileprint = ".\temppixivhtml\members\members" + $continuenum + ".html"
			$ie.Document.documentElement.innerHTML > $fileprint
			$file = Get-Content $fileprint
			$containsWord = $file | %{$_ -match $noresult}
			If($containsWord -contains $true) {
				$notdone = 0
				$excess = ".\temppixivhtml\members\members" + $continuenum + ".html"
				Remove-Item $excess
			}
			$pagenumber = $pagenumber + 1
			$continuenum = $continuenum + 1
		}

		echo "End of private followers"
	}

	$notdone = 1
	$pagenumber = 1

	while($notdone) {
		echo "Scraping bookmarks page: $pagenumber"
		$url = "https://www.pixiv.net/bookmark.php?rest=show&p=" + $pagenumber
		$ie.navigate($url)

		while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }

		$fileprint = ".\temppixivhtml\bookmarks\bookmarks" + $pagenumber + ".html"
		$ie.Document.documentElement.innerHTML > $fileprint
		$file = Get-Content $fileprint
		$containsWord = $file | %{$_ -match $noresult}
		If($containsWord -contains $true) {
			$notdone = 0
			$excess = ".\temppixivhtml\bookmarks\bookmarks" + $pagenumber + ".html"
			Remove-Item $excess
		}
		$pagenumber = $pagenumber + 1
	}

	echo "End of public bookmarks"

	if($private) {
		$continuenum = $pagenumber - 1
		$notdone = 1
		$pagenumber = 1

		while($notdone) {
			echo "Scraping bookmarks page: $pagenumber"
			$url = "https://www.pixiv.net/bookmark.php?rest=hide&p=" + $pagenumber
			$ie.navigate($url)

			while($ie.Busy -eq $true -Or $ie.ReadyState -ne 4) { Start-Sleep 1 }

			$fileprint = ".\temppixivhtml\bookmarks\bookmarks" + $continuenum + ".html"
			$ie.Document.documentElement.innerHTML > $fileprint
			$file = Get-Content $fileprint
			$containsWord = $file | %{$_ -match $noresult}
			If($containsWord -contains $true) {
				$notdone = 0
				$excess = ".\temppixivhtml\bookmarks\bookmarks" + $continuenum + ".html"
				Remove-Item $excess
			}
			$pagenumber = $pagenumber + 1
			$continuenum = $continuenum + 1
		}

		echo "End of private bookmarks"
	}

	$ie.Stop()
	$ie.Quit()

	echo "---------------------------------------"
} else {
	if($mprefix -eq "") {
		echo "Error, must specify -mprefix, run again with -help"
		exit
	}
	if($bprefix -eq "") {
		echo "Error, must specify -bprefix, run again with -help"
		exit
	}
}


echo "Now creating following list"

If(Test-Path -Path .\pixivfollowers.txt) { Remove-Item .\pixivfollowers.txt }
#[regex]$regex="(?!https://www\.pixiv\.net/member\.php\?id=23017315)(https://www\.pixiv\.net/member\.php\?id=[0-9]+)"
[regex]$regex="/member\.php\?id=[0-9]+"

$i = 1
$moremembers = $true
If($files -eq "na" ) { $membersbasepath = ".\temppixivhtml\members\" ; $mprefix = "members" }
Else {
	$membersbasepath = $files + "\members\"
}

$memberslocation = $membersbasepath + $mprefix + "$i" + ".html"
if(!(Test-Path -LiteralPath $memberslocation)) { echo "$memberslocation does not exist!" ; $moremembers = $false } 

while($moremembers) {
	If($files -eq "na" ) { 
		$memberslocation = $membersbasepath + "members" + "$i" + ".html"
	}
	Else { 
		$memberslocation = $membersbasepath + $mprefix + "$i" + ".html"
	}
	if(!(Test-Path -LiteralPath $memberslocation)) { break } 
	$pixivsource = Get-Content -LiteralPath $memberslocation
	$links = $regex.Matches($pixivsource) | foreach-object {$_.Value}
	$links = $links | select -uniq
	$links = $links | Where-Object { $_ -ne "$thisuser" }
	$links = $links | ForEach-Object {"https://www.pixiv.net$_"}
	[array]::reverse($links)
	Add-Content -Path .\pixivfollowers.txt -Value $links
	$i = $i + 1
}
#Out-File -FilePath .\pixivfollowers.txt -InputObject $links
#Get-Content .\pixivfollowers.txt
$userfile = Get-Content .\pixivfollowers.txt
$userfile = $userfile | select -uniq
$userlength = $userfile.length

echo "Now creating bookmarks list"

If(Test-Path -Path .\pixivbookmarks.txt) { Remove-Item .\pixivbookmarks.txt }
#[regex]$regex="https://www\.pixiv\.net/member_illust\.php\?mode=medium\&illust_id=[0-9]+"
[regex]$regex=[regex]$regex='(?!illust_id=[0-9]+"\starget)(?!illust_id=[0-9]+&)illust_id=[0-9]+'

$i = 1
$morebookmarks = $true
If($files -eq "na" ) { $bookmarkbasepath = ".\temppixivhtml\bookmarks\" ; $bprefix = "bookmarks"}
Else {
	$bookmarkbasepath = $files + "\bookmarks\"
}

$bookmarkslocation = $bookmarkbasepath + $bprefix + "$i" + ".html"
if(!(Test-Path -LiteralPath $bookmarkslocation)) { echo "$bookmarkslocation does not exist!" ; $morebookmarks = $false } 

while($morebookmarks) {
	If($files -eq "na" ) { 
		$bookmarkslocation = $bookmarkbasepath + "bookmarks" + "$i" + ".html"
	}
	Else { 
		$bookmarkslocation = $bookmarkbasepath + $bprefix + "$i" + ".html"
	}
	if(!(Test-Path -LiteralPath $bookmarkslocation)) { break } 
	$pixivsource = Get-Content -LiteralPath $bookmarkslocation
	$links = $regex.Matches($pixivsource) | foreach-object {$_.Value}
	$links = $links | select -uniq
	$links = $links | ForEach-Object {"https://www.pixiv.net/member_illust.php?mode=medium&$_"}
	[array]::reverse($links)
	Add-Content -Path .\pixivbookmarks.txt -Value $links
	$i = $i + 1
}
#Out-File -FilePath .\pixivbookmarks.txt -InputObject $links
#Get-Content .\pixivbookmarks.txt
$bookmarkfile = Get-Content .\pixivbookmarks.txt
$bookmarkfile = $bookmarkfile | select -uniq
$bookmarklength = $bookmarkfile.length

echo "Users you followed: $userlength"
echo "Bookmark count: $bookmarklength"

echo "---------------------------------------"
echo "Following list: pixivfollowers.txt"
echo "Bookmarks list: pixivbookmarks.txt"

If($files -eq "na" -And (Test-Path -Path .\temppixivhtml\)) { Remove-Item -Recurse .\temppixivhtml\ }
Read-Host -Prompt "Press Enter to continue"