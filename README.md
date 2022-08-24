Copy of https://github.com/karek314/macOS-home-call-drop !

# macOS-home-call-drop

Simple shell script to fix macOS privacy issues and remove mostly useless (at least for me) macOS calls to Cupertino. Great addition to software like Little Snitch. By default it disable useless services, daemons running in background - If you don't use Push Notifications, Spotlight Suggestions or do not like to send your browsing history, bookmarks and more to Apple you should run it. By default the script does not affect iCloud and FindMyMac so if you don't use iCloud you can disable services related to iCloud as well, just edit <b>config.sh</b> to choose which services you want to disable. Most of them are described, uncomment to let script disable it! Comments about agents and daemons are my guesses based on MacOS internal knowledge and research, some may be less accurate than others. I haven't thoroughly checked all of them one by one, so can't know for sure. Please update and make a pull request if you have updates or additions.

By default, the script disables Spotlight suggestions in the system and in Safari, it seems that Spotlight sends each keystroke to Apple.

## Usage
MacOS High Sierra and up, requires that sip is disabled.

Audit current settings
<pre>
bash homecall.sh audit
</pre>

Fix
<pre>
bash homecall.sh fix
</pre>

Optionally you can restore it back to default by
<pre>
bash homecall.sh restore
</pre>

## Contribution
If you find something interesting, please open issue and start disccussion. Feel free to fork and pull request. Any update can bring something that aware macOS user would like to disable.

## Notice
Be careful when modifying and using this script if you do not understand exactly what it does. You could break your system very easily and make it unbootable. This script was developed on macOS Sierra and tested on High Sierra but I believe it will work just fine with previous versions, it may throw some warnings due to services that have been added in later versions. They can safely be ignored.

## License
GNU General Public License v3.0
