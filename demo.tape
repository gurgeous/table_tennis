#
# script for vhs (https://github.com/charmbracelet/vhs)
#

# vhs settings
Output "/tmp/demo.gif"
Set FontFamily Menlo
Set FontSize 28
Set Width 1520
Set Height 1100
Set Margin 0
Set Padding 0

# fire up the app
Hide
  Type@1ms "tennis --clear --demo 3 --title 'Star Wars People' --zebra --columns name,height,homeworld,species,films --color-scale height"
  Enter
  Wait+Screen /Star/
Show

# now take the screenshot
Sleep 0.5
Screenshot "/tmp/dark.png"
