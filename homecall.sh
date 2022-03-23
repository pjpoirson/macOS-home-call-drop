#!/bin/bash
source config.sh
USER=$(id -un)
echo "Running as $USER"
if id -G $USR | grep -q -w 80
then
  ADMIN=true
else
  ADMIN=false
  echo "WARNING: Some commands may not work. Run again with admin privilege."
fi


check(){
  if csrutil status | grep -q 'enabled'
  then
    echo "SIP is enabled. It may not fully work."
    if sw_vers -productVersion | grep -q '10.13'
    then #high sierra
      echo "High Sierra (10.13.X) requires to have SIP DISABLED"
      echo "Boot into recovery mode and type csrutil disable. It's nice to enable it afterwards."
      exit 1
    fi
  fi
}


help_msg(){
  echo ""
  echo "macOS home call dropper by karek314"
  echo "version 1.0"
  echo ""
  echo "Available commands"
  echo "audit - print current settings"
  echo "fix - fix your macOS to stop/limit invasions of your privacy"
  echo "restore - restore to default settings"
  echo "help - help message"
}


fix_spotlight_a(){
  #Global System Preferences
  TMP1="$(
    plutil -convert xml1 -o - "$HOME"/Library/Preferences/com.apple.Spotlight.plist | \
      sed '
           1,/<key>orderedItems<\/key>/d;
           /<key>showedFTE<\/key>/,$d;
           s/'"$(printf '\t\t\t')"'//g;
    ' | \
      awk '/^</{printf$1}/^\t/{print$1}'
  )"
  #echo "Current Settings"
  #echo $TMP1
  TMP2="$(
    echo "$TMP1" | \
      sed '
           s|\(.*\)<true/>\(.*MENU_SPOTLIGHT_SUGGESTIONS.*\)|\1<false/>\2|;
           s|\(.*\)<true/>\(.*MENU_DEFINITION.*\)|\1<false/>\2|;
           s|\(.*\)<true/>\(.*MENU_CONVERSION.*\)|\1<false/>\2|;
    '
  )"
  #echo "New Settings"
  #echo $TMP2
  defaults delete com.apple.Spotlight.plist orderedItems
  defaults write com.apple.Spotlight.plist orderedItems "$TMP2"
}


fix_spotlight_b(){
  #Global System Preferences
  TMP1b="$(
    defaults read com.apple.Spotlight.plist orderedItems | \
      awk '/^ {8}/{printf$0}!/^ {8}/{print}'
  )"
  #echo "Current Settings"
  #echo $TMP1b
  TMP2b="$(
    echo "$TMP1b" | \
      sed '
         s|\(.*\)= 1\(.*MENU_SPOTLIGHT_SUGGESTIONS.*\)|\1= 0\2|;
         s|\(.*\)= 1\(.*MENU_DEFINITION.*\)|\1= 0\2|;
         s|\(.*\)= 1\(.*MENU_CONVERSION.*\)|\1= 0\2|;
    '
  )"
  #echo "New Settings"
  #echo $TMP2b
  defaults delete com.apple.Spotlight.plist orderedItems
  defaults write com.apple.Spotlight.plist orderedItems "$TMP2b"
}


audit_spotlight(){
  echo "Spotlight settings:"
  defaults read com.apple.Spotlight.plist orderedItems | \
    awk '/^ {8}/{printf$0}!/^ {8}/{print}' | \
    grep -E 'MENU_SPOTLIGHT_SUGGESTIONS|MENU_DEFINITION|MENU_CONVERSION'
}


audit_safari(){
  # Read Safari Preferences
  echo "Safari settings:"
  for x in UniversalSearchEnabled SuppressSearchSuggestions WebsiteSpecificSearchEnabled
  do
    echo -n "$x: "
    defaults read com.apple.Safari.plist "$x"
  done
}


fix_safari(){
  # Write Safari Preferences
  defaults write com.apple.Safari.plist UniversalSearchEnabled -bool NO
  defaults write com.apple.Safari.plist SuppressSearchSuggestions -bool YES
  defaults write com.apple.Safari.plist WebsiteSpecificSearchEnabled -bool NO
}


LaunchAgents(){
  if [ -f "/System/Library/LaunchAgents/${2}.plist" ]
  then
    if $ADMIN
    then
      sudo launchctl "$1" -w "/System/Library/LaunchAgents/${2}.plist"
    fi
    launchctl "$1" -w "/System/Library/LaunchAgents/${2}.plist"
    echo "Agent ${agent} ${1}ed"
  else
    echo "$2 is not a System LaunchAgent"
  fi
}


LaunchDaemons(){
  if [ -f "/System/Library/LaunchDaemons/${2}.plist" ]
  then
    if $ADMIN
    then
      sudo launchctl "$1" -w "/System/Library/LaunchDaemons/${2}.plist"
    fi
    launchctl "$1" -w "/System/Library/LaunchDaemons/${2}.plist"
    echo "Daemon ${daemon} disabled"
  else
    echo "$2 is not a System LaunchDaemon"
  fi
}


start(){
  echo ""
  fix_spotlight_b
  fix_safari
  echo "System Spotlight & Suggestions Fixed"
  echo ""
  for agent in "${AGENTS[@]}"
  do
    LaunchAgents unload "${agent}"
  done
  echo ""
  echo "Specified agents have been disabled"
  echo ""
  for daemon in "${DAEMONS[@]}"
  do
    LaunchDaemons unload "$daemon"
  done
  echo ""
  echo "Specified daemons have been disabled"
  echo ""
  echo "Spotlight and safari suggestions have been fixed, and your keystrokes are no longer sent out to apple!"
  echo ""
  echo "!!!RESTART YOUR COMPUTER NOW TO APPLY CHANGES!!!"
  echo ""
}


restore(){
  for agent in "${AGENTS[@]}"
  do
    LaunchAgents load "${agent}"
  done
  echo ""
  echo "Specified agents have been enabled"
  echo ""
  for daemon in "${DAEMONS[@]}"
  do
    LaunchDaemons load "$daemon"
  done
  echo ""
  echo "Specified daemons have been enabled"
  echo ""
  echo "RESTART YOUR COMPUTER NOW TO APPLY CHANGES"
  echo ""
}


audit_launchctl(){
  echo "Searching for LaunchAgents:"
  launchctl list | while read -r line
  do
    for agent in "${AGENTS[@]}"
    do
      case "$line" in
        *"$agent") echo "Found LaunchAgent $line"
          ;;
      esac
    done
  done

  echo "Searching for LaunchDaemons:"
  launchctl list | while read -r line
  do
    for daemon in "${DAEMONS[@]}"
    do
      case "$line" in
        *"$daemon") echo "Found LaunchDaemon $line"
          ;;
      esac
    done
  done
}


case $1 in
  "audit")
    audit_safari
    audit_spotlight
    audit_launchctl
    ;;
  "fix")
    check
    start
    ;;
  "help")
    help_msg
    ;;
  "restore")
    check
    restore
    ;;
  *)
    help_msg
    ;;
esac

#EOF
