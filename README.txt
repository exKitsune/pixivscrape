I know, this isn't implemented using any APIs, but at least it's precompiled and is basically fully automated

The script is written in powershell, and using ps2exe (Markus Scholtes's version) to convert to exe

pixivscrape will scrape your bookmarks and followed pages and then output 2 txt files containing links
addbookmarks will add those bookmarks to your account specified in pixivbookmarks.txt
followuser will follow those users specified in pixivfollowers.txt

Pixivscrape help:
 "Online use: run script, enter credentials"
 "If you've previously used this and have logged in, use -login"
 ""
 "Offline use (If you have saved the webpages yourself"
 "Please put create a directory and 2 subdirectories within it"
 "Put bookmark html pages into /dir/bookmarks/"
 "Put member html pages into /dir/members/"
 'Then run .\pixivscrape.exe -files "/dir"'
 "It is important that you don't put a / after dir"
 ""
 "If you do run -files then also run -prefix specifying the name"
 "of the file before the numerical #, e.g. if your files look like"
 'bookmarks1.html, bookmarks2.html then run -bprefix "bookmarks"'
 'same for followers with -mprefix'
 "Example:"
 '.\pixivscrape.ps1 -files ".\pixivhtml" -mprefix "[pixiv] フォローユーザー" -bprefix "[pixiv] Bookmarks"'
 ""
 "-private will include private pages"
 ""
 "-show will show you what's happening"
 
 addbookmarks help:
	Similarly to above, you can use
	-login and -show
	-private will add those bookmarks privately 
	Specify location of txt file containing links with -bookdir
	
followuser help:
	Similarly to above, you can use
	-login and -show 
	Specify location of txt file containing links with -followdir
 